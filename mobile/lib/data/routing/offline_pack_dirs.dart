import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'coverage_graph_ring.dart';
import 'coverage_label.dart';
import 'map_style_url.dart';
import 'offline_maps_prefs.dart';
import 'offline_pack_catalog.dart';
import 'offline_pmtiles_store.dart';
import 'overlay_regions.dart';

/// On-disk region packs under app documents `regions/{id}/`.
abstract final class OfflinePackDirs {
  static Future<Directory> root() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'regions'));
  }

  /// Activated pack path exists and the graph belongs to that region.
  static Future<bool> hasLegitimateActivatedPack() async {
    final path = await OfflineMapsPrefs.activatedPackPath();
    if (path == null || path.isEmpty) return false;
    try {
      return directoryIsLegitimate(Directory(path));
    } catch (_) {
      return false;
    }
  }

  /// Manifest/overlay bbox of the activated graph — not a stale prefs box.
  static Future<List<double>?> activatedCoverageBbox() async {
    final path = await OfflineMapsPrefs.activatedPackPath();
    if (path == null || path.isEmpty) return null;
    try {
      final dir = Directory(path);
      if (!await directoryIsLegitimate(dir)) return null;
      final disk = await bboxFromDir(dir);
      final prefs =
          OfflineMapsPrefs.packBboxFrom(await OfflineMapsPrefs.read());
      return preferDiskPackBbox(fromDisk: disk, fromPrefs: prefs);
    } catch (_) {
      return null;
    }
  }

  /// Graph occupancy of the activated pack. Null outline = chamfered bbox.
  static Future<List<List<double>>?> activatedCoverageRing() async {
    return (await activatedCoverageRingResult())?.outline;
  }

  static Future<CoverageRingCache?> activatedCoverageRingResult() async {
    final path = await OfflineMapsPrefs.activatedPackPath();
    if (path == null || path.isEmpty) return null;
    try {
      final dir = Directory(path);
      if (!await directoryIsLegitimate(dir)) return null;
      return coverageRingResultForDir(dir);
    } catch (_) {
      return null;
    }
  }

  static Future<CoverageRingCache?> coverageRingCacheOnly(Directory dir) async {
    final graph = File(p.join(dir.path, 'offline_graph.json'));
    if (!await graph.exists()) return null;
    final bytes = await graph.length();
    final cache = File(p.join(dir.path, kCoverageRingFileName));
    if (!await cache.exists()) return null;
    try {
      return coverageRingFromCacheJson(
        await cache.readAsString(),
        graphBytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<CoverageRingCache?> coverageRingResultForDir(
    Directory dir,
  ) async {
    final graph = File(p.join(dir.path, 'offline_graph.json'));
    if (!await graph.exists()) return null;
    final bytes = await graph.length();
    final cache = File(p.join(dir.path, kCoverageRingFileName));
    if (await cache.exists()) {
      try {
        final hit = coverageRingFromCacheJson(
          await cache.readAsString(),
          graphBytes: bytes,
        );
        if (hit != null) return hit;
      } catch (_) {}
    }
    final graphPath = graph.path;
    final payload = await Isolate.run(
      () => coverageRingEvaluateGraphFile(graphPath),
    );
    final hit = coverageRingCacheFromPayload(payload);
    if (hit == null) return null;
    try {
      await cache.writeAsString(
        coverageRingCacheJson(
          ring: hit.ring,
          graphBytes: bytes,
          solid: hit.solid,
          dots: hit.dots,
          traces: hit.traces,
        ),
      );
    } catch (_) {}
    return hit;
  }

  static Future<List<List<double>>?> coverageRingForDir(Directory dir) async {
    return (await coverageRingResultForDir(dir))?.outline;
  }

  /// Graph on disk and that pack's occupancy cover this GPS point.
  static Future<bool> legitimateCoversPoint(double lng, double lat) async {
    final bbox = await activatedCoverageBbox();
    if (bbox == null) return false;
    final ring = await activatedCoverageRing();
    return coveragePointInCoverage(
      lng: lng,
      lat: lat,
      bbox: bbox,
      ring: ring,
    );
  }

  /// Smallest installed pack whose occupancy covers this GPS point.
  /// Activated pack uses the computed ring; other packs use the cache.
  static Future<({String id, String name})?> coveringPackForPoint(
    double lng,
    double lat,
  ) async {
    try {
      final activatedPath = await OfflineMapsPrefs.activatedPackPath();
      if (activatedPath != null &&
          activatedPath.isNotEmpty &&
          await legitimateCoversPoint(lng, lat)) {
        final dir = Directory(activatedPath);
        final id = OfflineMapsPrefs.packIdFromActivatedPath(activatedPath) ??
            p.basename(dir.path);
        final name = await nameFromDir(dir);
        return (id: id, name: (name == null || name.isEmpty) ? id : name);
      }
      final rootDir = await root();
      if (!await rootDir.exists()) return null;
      Directory? hit;
      var hitArea = double.infinity;
      await for (final e in rootDir.list()) {
        if (e is! Directory) continue;
        if (activatedPath != null && e.path == activatedPath) continue;
        if (!await directoryIsLegitimate(e)) continue;
        final bbox = await bboxFromDir(e);
        if (bbox == null || bbox.length < 4) continue;
        final cached = await coverageRingCacheOnly(e);
        if (!coveragePointInCoverage(
          lng: lng,
          lat: lat,
          bbox: bbox,
          ring: cached?.outline,
        )) {
          continue;
        }
        final area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
        if (area < hitArea) {
          hit = e;
          hitArea = area;
        }
      }
      if (hit == null) return null;
      final id = p.basename(hit.path);
      final name = await nameFromDir(hit);
      return (id: id, name: (name == null || name.isEmpty) ? id : name);
    } catch (_) {
      return null;
    }
  }

  /// Graph on disk and that pack's occupancy cover this A→B (and optional vias).
  static Future<bool> legitimateCoversRoute({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    List<({double lng, double lat})> vias = const [],
    List<({double lng, double lat})> along = const [],
  }) async {
    final bbox = await activatedCoverageBbox();
    if (bbox == null) return false;
    final ring = await activatedCoverageRing();
    return coverageCoversLngLats(
      points: [
        (lng: fromLng, lat: fromLat),
        (lng: toLng, lat: toLat),
        ...vias,
        ...along,
      ],
      bbox: bbox,
      ring: ring,
    );
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

  /// If a legitimate pack covers from+to (+ vias), make it the active pack.
  /// Returns true when a covering pack is now in prefs (caller should clear
  /// the tiles-path cache).
  static Future<bool> switchToPackCovering({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    List<({double lng, double lat})> vias = const [],
  }) async {
    try {
      final rootDir = await root();
      if (!await rootDir.exists()) return false;
      Directory? hit;
      List<double>? hitBbox;
      var hitArea = double.infinity;
      final points = <({double lng, double lat})>[
        (lng: fromLng, lat: fromLat),
        (lng: toLng, lat: toLat),
        ...vias,
      ];
      await for (final e in rootDir.list()) {
        if (e is! Directory) continue;
        if (!await directoryIsLegitimate(e)) continue;
        final bbox = await bboxFromDir(e);
        if (bbox == null || bbox.length < 4) continue;
        final cached = await coverageRingCacheOnly(e);
        if (!coverageCoversLngLats(
          points: points,
          bbox: bbox,
          ring: cached?.outline,
        )) {
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
      final hitId = p.basename(hit.path);
      final mapOk = await OfflinePmtilesStore.isReady(
        basemapArchiveIdForBbox(hitBbox),
      );
      final current = await OfflineMapsPrefs.activatedPackPath();
      if (current == hit.path) {
        final m = await OfflineMapsPrefs.read();
        final patch = <String, dynamic>{
          if (OfflineMapsPrefs.packBboxFrom(m) == null) 'packBbox': hitBbox,
          if (m['basemapReady'] != mapOk) 'basemapReady': mapOk,
        };
        if (patch.isNotEmpty) await OfflineMapsPrefs.merge(patch);
        return true;
      }
      final prev = await OfflineMapsPrefs.read();
      final prevStreetId = OfflineMapsPrefs.streetHudPackIdFrom(prev);
      await OfflineMapsPrefs.merge({
        'activatedPackPath': hit.path,
        'regionPack': await nameFromDir(hit),
        'packBbox': hitBbox,
        'engineHint': 'offline_graph',
        'activatedAt': DateTime.now().toUtc().toIso8601String(),
        'basemapReady': mapOk,
        if (prevStreetId != null && prevStreetId != hitId) ...{
          'streetHudAt': null,
          'streetHudBbox': null,
          'streetHudKind': null,
          'streetHudPackId': null,
        },
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> builtAtFromDir(Directory dir) async {
    final manFile = File(p.join(dir.path, 'manifest.json'));
    if (!await manFile.exists()) return null;
    try {
      final man = jsonDecode(await manFile.readAsString());
      if (man is Map && man['builtAt'] is String) {
        final s = (man['builtAt'] as String).trim();
        return s.isEmpty ? null : s;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>> builtAtById() async {
    final out = <String, String>{};
    try {
      final rootDir = await root();
      if (!await rootDir.exists()) return out;
      await for (final e in rootDir.list()) {
        if (e is! Directory) continue;
        if (!await directoryIsLegitimate(e)) continue;
        final built = await builtAtFromDir(e);
        if (built != null) out[p.basename(e.path)] = built;
      }
    } catch (_) {}
    return out;
  }

  static Future<int> totalBytes() async {
    try {
      final rootDir = await root();
      if (!await rootDir.exists()) return 0;
      var n = 0;
      await for (final e in rootDir.list(recursive: true, followLinks: false)) {
        if (e is File) n += await e.length();
      }
      return n;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> deleteId(String id) async {
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (safe.isEmpty) return;
    final dir = Directory(p.join((await root()).path, safe));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
