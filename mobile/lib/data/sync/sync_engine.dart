import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../local/app_database.dart';
import '../local/garage_repository.dart';
import '../local/ride_chunk_repository.dart';
import 'sync_payload.dart';

/// Sync-Engine: UI bleibt offline; Netz nur hier.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required GarageRepository garage,
    RideChunkRepository? rideChunks,
    http.Client? httpClient,
    void Function(SyncPayload merged)? onSynced,
  })  : _db = db,
        _garage = garage,
        _rideChunks = rideChunks,
        _http = httpClient ?? http.Client(),
        _onSynced = onSynced;

  final AppDatabase _db;
  final GarageRepository _garage;
  final RideChunkRepository? _rideChunks;
  final http.Client _http;
  final void Function(SyncPayload merged)? _onSynced;
  bool _running = false;
  Timer? _periodic;

  bool get isRunning => _running;

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

  Future<String?> _accessToken() async {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<({SyncPayload? payload, String? updatedAt})> pullNow() async {
    final token = await _accessToken();
    if (token == null) {
      debugPrint('SyncEngine: pull übersprungen (kein Auth)');
      return (payload: null, updatedAt: null);
    }
    final res = await _http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode == 401) {
      return (payload: null, updatedAt: null);
    }
    if (res.statusCode != 200) {
      throw Exception('Sync pull failed: ${res.statusCode}');
    }
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
    final token = await _accessToken();
    if (token == null) throw Exception('unauthorized');
    final res = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'payload': payload.toJson(),
        'clientUpdatedAt': clientUpdatedAt ?? payload.updatedAt,
      }),
    );
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
    return data['updatedAt'] as String? ?? DateTime.now().toIso8601String();
  }

  /// LWW bidirectional — mirrors web `syncBidirectional`.
  Future<({SyncPayload merged, String direction})> syncNow() async {
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
        if (e.remote != null) {
          await _garage.applyRemotePayload(e.remote!);
          await _record('pulled', e.remoteUpdatedAt);
          _onSynced?.call(e.remote!);
          await _flushRideChunks();
          return (merged: e.remote!, direction: 'pulled');
        }
        rethrow;
      }
    }

    await _record('noop', remote.updatedAt ?? local.updatedAt);
    await _flushRideChunks();
    return (merged: local, direction: 'noop');
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

class SyncConflictException implements Exception {
  SyncConflictException({this.remote, this.remoteUpdatedAt});
  final SyncPayload? remote;
  final String? remoteUpdatedAt;
}
