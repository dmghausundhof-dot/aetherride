import 'dart:convert';

import 'package:flutter/services.dart';

/// Bundled OSRM-prebake / editorial polylines for public catalog tours.
///
/// Loaded from [assets/catalog/tour-geometry-overrides.json] so Discover
/// can paint Wiesloch and the rest of DACH without a live routing round-trip.
class CatalogTourGeometryStore {
  CatalogTourGeometryStore._();

  static const assetPath = 'assets/catalog/tour-geometry-overrides.json';

  static Map<String, List<List<double>>>? _cache;
  static Future<Map<String, List<List<double>>>>? _inflight;

  static Future<Map<String, List<List<double>>>> load() {
    final hit = _cache;
    if (hit != null) return Future.value(hit);
    return _inflight ??= _read();
  }

  static Future<List<List<double>>?> geometryFor(String tourId) async {
    if (tourId.isEmpty) return null;
    final all = await load();
    final g = all[tourId];
    if (g == null || g.length < 8) return null;
    return g;
  }

  static Map<String, List<List<double>>> parseOverrides(String raw) {
    final decoded = jsonDecode(raw);
    final out = <String, List<List<double>>>{};
    if (decoded is! Map) return out;
    for (final e in decoded.entries) {
      final id = e.key.toString();
      final val = e.value;
      if (val is! Map) continue;
      final coords = val['coordinates'];
      if (coords is! List) continue;
      final pts = <List<double>>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          pts.add([
            (c[0] as num).toDouble(),
            (c[1] as num).toDouble(),
          ]);
        }
      }
      if (pts.length >= 8) out[id] = pts;
    }
    return out;
  }

  static Future<Map<String, List<List<double>>>> _read() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final out = parseOverrides(raw);
      _cache = out;
      return out;
    } catch (_) {
      _cache = {};
      return {};
    } finally {
      _inflight = null;
    }
  }
}
