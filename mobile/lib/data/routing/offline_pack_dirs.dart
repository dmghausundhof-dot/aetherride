import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'offline_maps_prefs.dart';
import 'offline_pack_catalog.dart';
import 'overlay_regions.dart';

/// On-disk region packs under app documents `regions/{id}/`.
abstract final class OfflinePackDirs {
  static Future<Directory> root() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'regions'));
  }

  static Future<bool> directoryIsLegitimate(Directory dir) async {
    final id = p.basename(dir.path);
    final graph = File(p.join(dir.path, 'offline_graph.json'));
    if (!await graph.exists()) return false;
    final n = await graph.length();
    String? manifestId;
    final manFile = File(p.join(dir.path, 'manifest.json'));
    if (await manFile.exists()) {
      try {
        final man = jsonDecode(await manFile.readAsString());
        if (man is Map) manifestId = man['id'] as String?;
      } catch (_) {}
    }
    String? sha;
    if (manifestId != id) {
      try {
        sha = sha256.convert(await graph.readAsBytes()).toString();
      } catch (_) {
        return false;
      }
    }
    return packGraphBelongsToRegion(
      regionId: id,
      graphBytes: n,
      manifestId: manifestId,
      graphSha256: sha,
    );
  }

  static Future<Set<String>> legitimateIds() async {
    final ids = <String>{};
    try {
      final rootDir = await root();
      if (!await rootDir.exists()) return ids;
      await for (final e in rootDir.list()) {
        if (e is! Directory) continue;
        if (await directoryIsLegitimate(e)) {
          ids.add(p.basename(e.path));
        }
      }
    } catch (_) {}
    return ids;
  }

  static List<double>? bboxForId(String id, {List<double>? fromManifest}) {
    if (fromManifest != null && fromManifest.length >= 4) {
      return fromManifest;
    }
    for (final r in kOverlayRegions) {
      if (r.id == id) return r.bbox;
    }
    return null;
  }

  static Future<List<double>?> bboxFromDir(Directory dir) async {
    final manFile = File(p.join(dir.path, 'manifest.json'));
    if (await manFile.exists()) {
      try {
        final man = jsonDecode(await manFile.readAsString());
        final b = man is Map ? man['bbox'] : null;
        if (b is List && b.length >= 4) {
          return [
            for (final x in b.take(4))
              if (x is num) x.toDouble(),
          ];
        }
      } catch (_) {}
    }
    return bboxForId(p.basename(dir.path));
  }

  static Future<String?> nameFromDir(Directory dir) async {
    final manFile = File(p.join(dir.path, 'manifest.json'));
    if (await manFile.exists()) {
      try {
        final man = jsonDecode(await manFile.readAsString());
        if (man is Map && man['name'] is String) {
          return man['name'] as String;
        }
      } catch (_) {}
    }
    final id = p.basename(dir.path);
    for (final r in kOverlayRegions) {
      if (r.id == id) return r.name;
    }
    return id;
  }

  /// If a legitimate pack covers from+to, make it the active routing pack.
  /// Returns true when a covering pack is now in prefs (caller should clear
  /// the tiles-path cache).
  static Future<bool> switchToPackCovering({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
  }) async {
    try {
      final rootDir = await root();
      if (!await rootDir.exists()) return false;
      Directory? hit;
      List<double>? hitBbox;
      var hitArea = double.infinity;
      await for (final e in rootDir.list()) {
        if (e is! Directory) continue;
        if (!await directoryIsLegitimate(e)) continue;
        final bbox = await bboxFromDir(e);
        if (bbox == null || bbox.length < 4) continue;
        if (!pointInLngLatBbox(bbox, fromLng, fromLat) ||
            !pointInLngLatBbox(bbox, toLng, toLat)) {
          continue;
        }
        final area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
        if (area < hitArea) {
          hit = e;
          hitBbox = bbox;
          hitArea = area;
        }
      }
      if (hit == null || hitBbox == null) return false;
      final current = await OfflineMapsPrefs.activatedPackPath();
      if (current == hit.path) {
        final m = await OfflineMapsPrefs.read();
        if (OfflineMapsPrefs.packBboxFrom(m) == null) {
          await OfflineMapsPrefs.merge({'packBbox': hitBbox});
        }
        return true;
      }
      await OfflineMapsPrefs.merge({
        'activatedPackPath': hit.path,
        'regionPack': await nameFromDir(hit),
        'packBbox': hitBbox,
        'engineHint': 'offline_graph',
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
