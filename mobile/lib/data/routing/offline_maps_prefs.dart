import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Shared prefs file for offline maps / region packs (`offline_maps_prefs.json`).
abstract final class OfflineMapsPrefs {
  static const fileName = 'offline_maps_prefs.json';

  /// Bumps when the activated pack path changes (Hof / chip refresh).
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<File> file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<Map<String, dynamic>> read() async {
    try {
      final f = await file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> merge(Map<String, dynamic> patch) async {
    final f = await file();
    final m = await read();
    for (final e in patch.entries) {
      if (e.value == null) {
        m.remove(e.key);
      } else {
        m[e.key] = e.value;
      }
    }
    await f.writeAsString(jsonEncode(m));
    if (patch.containsKey('activatedPackPath') ||
        patch.containsKey('streetHudAt')) {
      revision.value++;
    }
  }

  /// [west, south, east, north] of the activated pack, if stored.
  static List<double>? packBboxFrom(Map<String, dynamic> m) {
    final raw = m['packBbox'];
    if (raw is! List || raw.length < 4) return null;
    final bbox = <double>[];
    for (final x in raw.take(4)) {
      if (x is! num) return null;
      bbox.add(x.toDouble());
    }
    return bbox;
  }

  /// Street-HUD cache bbox of the activated pack, if stored.
  static List<double>? streetHudBboxFrom(Map<String, dynamic> m) {
    final raw = m['streetHudBbox'];
    if (raw is! List || raw.length < 4) return null;
    final bbox = <double>[];
    for (final x in raw.take(4)) {
      if (x is! num) return null;
      bbox.add(x.toDouble());
    }
    return bbox;
  }

  static String? streetHudPackIdFrom(Map<String, dynamic> m) {
    final id = (m['streetHudPackId'] as String?)?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  static String? streetHudKindRawFrom(Map<String, dynamic> m) {
    final k = (m['streetHudKind'] as String?)?.trim();
    return (k == null || k.isEmpty) ? null : k;
  }

  /// Directory name of [activatedPackPath], e.g. `rhein-neckar`.
  static String? packIdFromActivatedPath(String? path) {
    final n = (path ?? '').trim().replaceAll('\\', '/');
    if (n.isEmpty) return null;
    final i = n.lastIndexOf('/');
    final id = (i < 0 ? n : n.substring(i + 1)).trim();
    return id.isEmpty ? null : id;
  }

  /// Activated region directory (contains `offline_graph.json`) or null.
  static Future<String?> activatedPackPath() async {
    final m = await read();
    final path = m['activatedPackPath'] as String?;
    if (path == null || path.isEmpty) return null;
    return path;
  }

  static DateTime? activatedAtFrom(Map<String, dynamic> m) {
    final raw = m['activatedAt'];
    if (raw is! String) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// When the current pack was activated. Legacy installs without a stamp
  /// get one on first read so the next A→B can use the graph.
  static Future<DateTime?> activatedAt() async {
    try {
      final m = await read();
      final parsed = activatedAtFrom(m);
      if (parsed != null) return parsed.toUtc();
      final path = (m['activatedPackPath'] as String?)?.trim() ?? '';
      if (path.isEmpty) return null;
      final stamp = DateTime.now().toUtc();
      await merge({'activatedAt': stamp.toIso8601String()});
      return stamp;
    } catch (_) {
      return null;
    }
  }

  static bool pointInBbox(List<double> bbox, double lng, double lat) {
    return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
  }

  /// Start, Ziel, optionale Vias und Strecken-Samples in einer Pack-Box.
  static bool routeCoveredByBbox({
    required List<double> bbox,
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    List<({double lng, double lat})> vias = const [],
    List<({double lng, double lat})> along = const [],
  }) {
    if (!pointInBbox(bbox, fromLng, fromLat)) return false;
    if (!pointInBbox(bbox, toLng, toLat)) return false;
    for (final v in vias) {
      if (!pointInBbox(bbox, v.lng, v.lat)) return false;
    }
    for (final p in along) {
      if (!pointInBbox(bbox, p.lng, p.lat)) return false;
    }
    return true;
  }

  /// True when the activated pack covers this GPS point.
  static Future<bool> coversPoint(double lng, double lat) async {
    try {
      final m = await read();
      final path = (m['activatedPackPath'] as String?)?.trim() ?? '';
      if (path.isEmpty) return false;
      final bbox = packBboxFrom(m);
      if (bbox == null) return false;
      return pointInBbox(bbox, lng, lat);
    } catch (_) {
      return false;
    }
  }

  /// True when from, to, vias and optional polyline samples lie in the pack.
  static Future<bool> coversRoute({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    List<({double lng, double lat})> vias = const [],
    List<({double lng, double lat})> along = const [],
  }) async {
    try {
      final m = await read();
      final path = (m['activatedPackPath'] as String?)?.trim() ?? '';
      if (path.isEmpty) return false;
      final bbox = packBboxFrom(m);
      if (bbox == null) return false;
      return routeCoveredByBbox(
        bbox: bbox,
        fromLng: fromLng,
        fromLat: fromLat,
        toLng: toLng,
        toLat: toLat,
        vias: vias,
        along: along,
      );
    } catch (_) {
      return false;
    }
  }
}
