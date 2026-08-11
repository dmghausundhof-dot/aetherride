import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../garage/bike_photo_sync.dart';
import '../local/app_database.dart';
import '../local/garage_repository.dart';
import '../local/ride_chunk_repository.dart';
import 'sync_payload.dart';

/// Auth-Zustand der Sync-Engine (für UI-Banner).
enum SyncAuthStatus { unknown, ok, noAuth, unauthorized }

/// Sync-Engine: UI bleibt offline; Netz nur hier.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required GarageRepository garage,
    RideChunkRepository? rideChunks,
    http.Client? httpClient,
    void Function(SyncPayload merged)? onSynced,
    void Function(SyncAuthStatus status)? onAuthStatus,
  })  : _db = db,
        _garage = garage,
        _rideChunks = rideChunks,
        _http = httpClient ?? http.Client(),
        _onSynced = onSynced,
        _onAuthStatus = onAuthStatus;

  final AppDatabase _db;
  final GarageRepository _garage;
  final RideChunkRepository? _rideChunks;
  final http.Client _http;
  final void Function(SyncPayload merged)? _onSynced;
  final void Function(SyncAuthStatus status)? _onAuthStatus;
  bool _running = false;
  Timer? _periodic;
  SyncAuthStatus _authStatus = SyncAuthStatus.unknown;

  bool get isRunning => _running;
  SyncAuthStatus get authStatus => _authStatus;

  void _setAuth(SyncAuthStatus s) {
    _authStatus = s;
    _onAuthStatus?.call(s);
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    debugPrint('SyncEngine: gestartet');
    _periodic?.cancel();
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(() async {
        try {
          await syncNow();
        } catch (e) {
          debugPrint('SyncEngine periodic: $e');
        }
      }());
    });
    try {
      await syncNow();
    } catch (e) {
      debugPrint('SyncEngine start sync: $e');
    }
  }

  Future<void> stop() async {
    _periodic?.cancel();
    _periodic = null;
    _running = false;
  }

  Future<String?> _accessToken({bool forceRefresh = false}) async {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      final auth = Supabase.instance.client.auth;
      if (forceRefresh) {
        try {
          await auth.refreshSession();
        } catch (e) {
          debugPrint('SyncEngine refreshSession: $e');
        }
      }
      return auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Bei 401 einmal Session refreshen und Token neu holen.
  Future<String?> _tokenAfterUnauthorized() async {
    final refreshed = await _accessToken(forceRefresh: true);
    if (refreshed == null) {
      _setAuth(SyncAuthStatus.unauthorized);
      debugPrint('SyncEngine: Status=unauthorized (Refresh fehlgeschlagen)');
    }
    return refreshed;
  }

  Future<({SyncPayload? payload, String? updatedAt})> pullNow() async {
    var token = await _accessToken();
    if (token == null) {
      _setAuth(SyncAuthStatus.noAuth);
      debugPrint('SyncEngine: Status=noAuth — Sync nur mit Login');
      return (payload: null, updatedAt: null);
    }
    var res = await _http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode == 401) {
      token = await _tokenAfterUnauthorized();
      if (token == null) {
        return (payload: null, updatedAt: null);
      }
      res = await _http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 401) {
        _setAuth(SyncAuthStatus.unauthorized);
        debugPrint('SyncEngine: Status=unauthorized (401 nach Refresh)');
        return (payload: null, updatedAt: null);
      }
    }
    if (res.statusCode != 200) {
      throw Exception('Sync pull failed: ${res.statusCode}');
    }
    _setAuth(SyncAuthStatus.ok);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['payload'];
    final updatedAt = data['updatedAt'] as String?;
    if (raw is! Map) return (payload: null, updatedAt: updatedAt);
    return (
      payload: SyncPayload.fromJson(Map<String, dynamic>.from(raw)),
      updatedAt: updatedAt ?? raw['updatedAt'] as String?,
    );
  }

  Future<String> pushNow(SyncPayload payload, {String? clientUpdatedAt}) async {
    var token = await _accessToken();
    if (token == null) {
      _setAuth(SyncAuthStatus.noAuth);
      throw Exception('unauthorized');
    }
    Future<http.Response> post(String t) => _http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/sync'),
          headers: {
            'Authorization': 'Bearer $t',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'payload': payload.toJson(),
            'clientUpdatedAt': clientUpdatedAt ?? payload.updatedAt,
          }),
        );
    var res = await post(token);
    if (res.statusCode == 401) {
      token = await _tokenAfterUnauthorized();
      if (token == null) throw Exception('unauthorized');
      res = await post(token);
      if (res.statusCode == 401) {
        _setAuth(SyncAuthStatus.unauthorized);
        throw Exception('unauthorized');
      }
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 409) {
      final err = SyncConflictException(
        remote: data['payload'] is Map
            ? SyncPayload.fromJson(
                Map<String, dynamic>.from(data['payload'] as Map),
              )
            : null,
        remoteUpdatedAt: data['remoteUpdatedAt'] as String?,
      );
      throw err;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Sync push failed: ${res.statusCode}');
    }
    _setAuth(SyncAuthStatus.ok);
    return data['updatedAt'] as String? ?? DateTime.now().toIso8601String();
  }

  /// How to handle 409 when pushing a newer local snapshot.
  /// [preferRemote] (default): take cloud. [preferLocal]: force push.
  /// [ask]: rethrow [SyncConflictException] for UI.
  Future<({SyncPayload merged, String direction})> syncNow({
    SyncConflictStrategy onConflict = SyncConflictStrategy.preferRemote,
  }) async {
    await _flushBikePhotos();
    final local = await _garage.buildSyncPayload();
    final remote = await pullNow();

    final localAt = DateTime.tryParse(local.updatedAt ?? '')?.millisecondsSinceEpoch ?? 0;
    final remoteAt =
        DateTime.tryParse(remote.updatedAt ?? '')?.millisecondsSinceEpoch ?? 0;

    if (remote.payload == null) {
      final stamped = local.copyWith(
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      try {
        final updatedAt = await pushNow(stamped);
        final merged = stamped.copyWith(updatedAt: updatedAt);
        await _record('pushed', updatedAt);
        _onSynced?.call(merged);
        await _flushRideChunks();
        return (merged: merged, direction: 'pushed');
      } catch (e) {
        debugPrint('SyncEngine push empty-remote: $e');
        await _flushRideChunks();
        return (merged: local, direction: 'noop');
      }
    }

    if (remoteAt > localAt) {
      final merged =
          remote.payload!.copyWith(updatedAt: remote.updatedAt);
      await _garage.applyRemotePayload(merged);
      await _record('pulled', remote.updatedAt);
      _onSynced?.call(merged);
      await _flushRideChunks();
      return (merged: merged, direction: 'pulled');
    }

    if (localAt > remoteAt) {
      try {
        final updatedAt = await pushNow(local, clientUpdatedAt: remote.updatedAt);
        await _record('pushed', updatedAt);
        final merged = local.copyWith(updatedAt: updatedAt);
        _onSynced?.call(merged);
        await _flushRideChunks();
        return (merged: merged, direction: 'pushed');
      } on SyncConflictException catch (e) {
        return _resolvePushConflict(
          e,
          local: local,
          strategy: onConflict,
        );
      }
    }

    await _record('noop', remote.updatedAt ?? local.updatedAt);
    await _flushRideChunks();
    return (merged: local, direction: 'noop');
  }

  Future<({SyncPayload merged, String direction})> _resolvePushConflict(
    SyncConflictException e, {
    required SyncPayload local,
    required SyncConflictStrategy strategy,
  }) async {
    if (strategy == SyncConflictStrategy.ask) {
      // Not in a catch clause here — re-throw for UI (Profile).
      throw e;
    }
    if (strategy == SyncConflictStrategy.preferLocal) {
      final force = local.copyWith(
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      final updatedAt = await pushNow(
        force,
        clientUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      final merged = force.copyWith(updatedAt: updatedAt);
      await _record('pushed_force', updatedAt);
      _onSynced?.call(merged);
      await _flushRideChunks();
      return (merged: merged, direction: 'pushed');
    }
    // preferRemote
    if (e.remote != null) {
      await _garage.applyRemotePayload(e.remote!);
      await _record('pulled', e.remoteUpdatedAt);
      _onSynced?.call(e.remote!);
      await _flushRideChunks();
      return (merged: e.remote!, direction: 'pulled');
    }
    throw e;
  }

  /// Apply user choice after [SyncConflictException] with strategy [ask].
  Future<({SyncPayload merged, String direction})> resolveConflict({
    required SyncConflictException conflict,
    required bool keepLocal,
  }) async {
    final local = await _garage.buildSyncPayload();
    return _resolvePushConflict(
      conflict,
      local: local,
      strategy: keepLocal
          ? SyncConflictStrategy.preferLocal
          : SyncConflictStrategy.preferRemote,
    );
  }

  Future<void> _flushBikePhotos() async {
    final store = _garage.profileStore;
    if (store == null) return;
    try {
      await store.flushPendingBikePhotoUploads(
        (bikeId, file) => uploadBikePhotoToStorage(bikeId: bikeId, file: file),
      );
    } catch (e) {
      debugPrint('SyncEngine bike-photos: $e');
    }
  }

  Future<void> _flushRideChunks() async {
    final chunks = _rideChunks;
    if (chunks == null) return;
    try {
      final n = await chunks.uploadPending();
      if (n > 0) debugPrint('SyncEngine: $n Ride-Chunks hochgeladen');
    } catch (e) {
      debugPrint('SyncEngine ride-chunks: $e');
    }
  }

  Future<void> _record(String direction, String? at) async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(1),
            lastDirection: Value(direction),
            remoteUpdatedAt: Value(at),
            localUpdatedAt: Value(at),
          ),
        );
  }
}

enum SyncConflictStrategy { preferRemote, preferLocal, ask }

class SyncConflictException implements Exception {
  SyncConflictException({this.remote, this.remoteUpdatedAt});
  final SyncPayload? remote;
  final String? remoteUpdatedAt;

  @override
  String toString() =>
      'SyncConflictException(remoteUpdatedAt: $remoteUpdatedAt)';
}
