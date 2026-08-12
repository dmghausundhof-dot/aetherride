import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/saved_route_note.dart';

/// Lokale Meta-Schicht für eigene Strecken (Fotos, Notizen, Beschreibung).
///
/// Sidecar-JSON wie [RouteCollectionsStore] — kein Drift-Schema-Bump nötig.
/// Foto-Pfade bleiben geräte-lokal; Notizen/Beschreibung sind sync-fähig.
abstract final class SavedRouteMetaStore {
  static const fileName = 'saved_route_meta.json';
  static const syncField = 'savedRouteMeta';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<Map<String, SavedRouteMeta>> _readAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return {};
      final routes = decoded['routes'];
      if (routes is! Map) return {};
      final out = <String, SavedRouteMeta>{};
      for (final e in routes.entries) {
        final id = '${e.key}';
        final v = e.value;
        if (v is Map) {
          out[id] = SavedRouteMeta.fromJson(Map<String, dynamic>.from(v));
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, SavedRouteMeta> all) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({
        'routes': {
          for (final e in all.entries) e.key: e.value.toJson(),
        },
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  static Future<SavedRouteMeta> get(String routeId) async {
    final all = await _readAll();
    return all[routeId] ?? SavedRouteMeta.empty;
  }

  static Future<Map<String, SavedRouteMeta>> listAll() => _readAll();

  static Future<void> put(String routeId, SavedRouteMeta meta) async {
    final all = await _readAll();
    if (meta.isEmpty) {
      all.remove(routeId);
    } else {
      all[routeId] = meta.copyWith(updatedAt: DateTime.now().toUtc());
    }
    await _writeAll(all);
  }

  static Future<void> delete(String routeId) async {
    final all = await _readAll();
    if (all.remove(routeId) != null) {
      await _writeAll(all);
    }
  }

  static Future<SavedRouteMeta> setPhotos(
    String routeId,
    List<String> photoPaths,
  ) async {
    final cur = await get(routeId);
    final next = cur.copyWith(photoPaths: List<String>.from(photoPaths));
    await put(routeId, next);
    return next;
  }

  static Future<SavedRouteMeta> setDescription(
    String routeId,
    String description,
  ) async {
    final cur = await get(routeId);
    final next = cur.copyWith(description: description.trim());
    await put(routeId, next);
    return next;
  }

  static Future<SavedRouteMeta> addNote(
    String routeId,
    SavedRouteNote note,
  ) async {
    final cur = await get(routeId);
    final next = cur.copyWith(notes: [...cur.notes, note]);
    await put(routeId, next);
    return next;
  }

  static Future<SavedRouteMeta> removeNote(
    String routeId,
    String noteId,
  ) async {
    final cur = await get(routeId);
    final next = cur.copyWith(
      notes: [for (final n in cur.notes) if (n.id != noteId) n],
    );
    await put(routeId, next);
    return next;
  }

  /// Sync-Fragment: Notizen + Beschreibung (ohne lokale Foto-Pfade).
  static Future<Map<String, dynamic>> syncPayload() async {
    final all = await _readAll();
    return {
      syncField: {
        for (final e in all.entries)
          e.key: {
            'description': e.value.description,
            'notes': [for (final n in e.value.notes) n.toJson()],
            if (e.value.rideId != null) 'rideId': e.value.rideId,
            'updatedAt':
                (e.value.updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
          },
      },
    };
  }

  static Future<void> applySync(dynamic raw) async {
    if (raw is! Map) return;
    final all = await _readAll();
    for (final e in raw.entries) {
      final id = '${e.key}';
      final v = e.value;
      if (v is! Map) continue;
      final incoming = SavedRouteMeta.fromJson(Map<String, dynamic>.from(v));
      final local = all[id];
      // Fotos bleiben lokal — nur Text-Felder mergen (LWW auf updatedAt).
      final localTs = local?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final remoteTs =
          incoming.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (local == null || remoteTs.isAfter(localTs)) {
        all[id] = (local ?? SavedRouteMeta.empty).copyWith(
          description: incoming.description,
          notes: incoming.notes,
          rideId: incoming.rideId,
          updatedAt: remoteTs,
        );
      }
    }
    await _writeAll(all);
  }
}
