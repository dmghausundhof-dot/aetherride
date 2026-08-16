import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Shared prefs file for offline maps / region packs (`offline_maps_prefs.json`).
abstract final class OfflineMapsPrefs {
  static const fileName = 'offline_maps_prefs.json';

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

  /// Activated region directory (contains `offline_graph.json`) or null.
  static Future<String?> activatedPackPath() async {
    final m = await read();
    final path = m['activatedPackPath'] as String?;
    if (path == null || path.isEmpty) return null;
    return path;
  }

  static bool pointInBbox(List<double> bbox, double lng, double lat) {
    return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
  }

  /// True when from+to lie in the activated pack bbox.
  static Future<bool> coversRoute({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
  }) async {
    try {
      final m = await read();
      final path = (m['activatedPackPath'] as String?)?.trim() ?? '';
      if (path.isEmpty) return false;
      final bbox = packBboxFrom(m);
      if (bbox == null) return false;
      return pointInBbox(bbox, fromLng, fromLat) &&
          pointInBbox(bbox, toLng, toLat);
    } catch (_) {
      return false;
    }
  }
}
