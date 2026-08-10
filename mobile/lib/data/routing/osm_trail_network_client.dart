import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../domain/routing/trail_difficulty.dart';

/// OSM-Way im Trailnetz ([lng,lat] Geometrie).
class OsmTrailSegment {
  const OsmTrailSegment({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.lengthKm,
    required this.center,
    required this.geometry,
    this.surface,
    this.highway,
    this.url,
  });

  final String id;
  final String name;
  final TrailDifficulty difficulty;
  final double lengthKm;
  final LatLng center;
  final List<List<double>> geometry;
  final String? surface;
  final String? highway;
  final String? url;

  /// Menschlich zuerst ("Mittel (S2)"), Rohwert in Klammern — statt nur "S2".
  String get difficultyLabel => trailDifficultyFullLabel(difficulty);
  String get lineColor => trailDifficultyColor(difficulty);
}

/// Lädt Trailnetz: Backend `/api/osm-trails`, sonst Overpass direkt.
class OsmTrailNetworkClient {
  Future<List<OsmTrailSegment>> fetchNearby({
    required double lat,
    required double lon,
    double radiusKm = 8,
  }) async {
    final fromApi = await _fromApi(lat: lat, lon: lon, radiusKm: radiusKm);
    if (fromApi.isNotEmpty) return fromApi;
    return _fromOverpass(lat: lat, lon: lon, radiusKm: radiusKm);
  }

  Future<List<OsmTrailSegment>> _fromApi({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/osm-trails').replace(
        queryParameters: {
          'lat': '$lat',
          'lon': '$lon',
          'radiusKm': '${radiusKm.round()}',
        },
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 16));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(res.body);
      if (data is! Map) return const [];
      final raw = data['trails'] as List? ?? const [];
      return _parseList(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<List<OsmTrailSegment>> _fromOverpass({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    final radiusM = (radiusKm.clamp(3, 18) * 1000).round();
    // Bewusst nicht auf mtb_scale beschränkt (siehe /api/osm-trails —
    // gleiche Query, hier nur der Direkt-Overpass-Fallback ohne Backend):
    // sac_scale-Wanderpfade und untagged Wald-/Feldwege sind die Mehrheit
    // realer deutscher Trails. sac_scale wird NICHT auf S0–S3+ umgemünzt
    // (erfundene Genauigkeit) — erscheint ehrlich als "offen".
    final query = '''
[out:json][timeout:26];
(
  way["highway"~"path|track"]["mtb_scale"](around:$radiusM,$lat,$lon);
  way["highway"="cycleway"](around:$radiusM,$lat,$lon);
  way["highway"="path"]["bicycle"~"yes|designated"](around:$radiusM,$lat,$lon);
  way["highway"~"path|track"]["sac_scale"](around:$radiusM,$lat,$lon);
  way["highway"="path"]["surface"~"ground|gravel|dirt|grass|compacted|fine_gravel|earth|unpaved"]["bicycle"!="no"](around:$radiusM,$lat,$lon);
  way["highway"="track"]["tracktype"~"grade2|grade3|grade4|grade5"]["bicycle"!="no"](around:$radiusM,$lat,$lon);
);
out body geom;
''';
    try {
      final res = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded;charset=UTF-8',
              'Accept': 'application/json',
            },
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(res.body);
      if (data is! Map) return const [];
      final elements = data['elements'] as List? ?? const [];
      final hits = <Map<String, dynamic>>[];
      for (final raw in elements) {
        if (raw is! Map) continue;
        if (raw['type'] != 'way') continue;
        final tags = Map<String, dynamic>.from(
          (raw['tags'] as Map?) ?? const {},
        );
        final geom = raw['geometry'] as List? ?? const [];
        final geometry = <List<double>>[];
        for (final g in geom) {
          if (g is! Map) continue;
          final glat = (g['lat'] as num?)?.toDouble();
          final glon = (g['lon'] as num?)?.toDouble();
          if (glat == null || glon == null) continue;
          geometry.add([glon, glat]);
        }
        if (geometry.length < 2) continue;
        final step = (geometry.length / 80).floor().clamp(1, 40);
        final simplified = <List<double>>[];
        for (var i = 0; i < geometry.length; i += step) {
          simplified.add(geometry[i]);
        }
        final last = geometry.last;
        if (simplified.isEmpty ||
            simplified.last[0] != last[0] ||
            simplified.last[1] != last[1]) {
          simplified.add(last);
        }
        final lengthKm = _pathLengthKm(simplified);
        if (lengthKm < 0.12 || lengthKm > 25) continue;
        final scale = (tags['mtb_scale'] as String?) ?? '';
        final name = (tags['name'] as String?) ??
            (tags['name:de'] as String?) ??
            (tags['ref'] as String?) ??
            (scale.isNotEmpty
                ? 'Trail ${parseTrailDifficulty(scale).name.toUpperCase()}'
                : 'Pfad');
        final mid = simplified[simplified.length ~/ 2];
        hits.add({
          'id': 'osm-way-${raw['id']}',
          'name': name,
          'mtbScale': trailDifficultyLabel(parseTrailDifficulty(scale)),
          'surface': tags['surface'] ?? tags['tracktype'],
          'highway': tags['highway'],
          'lengthKm': (lengthKm * 100).round() / 100,
          'center': [mid[0], mid[1]],
          'geometry': simplified,
          'url': 'https://www.openstreetmap.org/way/${raw['id']}',
        });
      }
      return _parseList(hits);
    } catch (_) {
      return const [];
    }
  }

  List<OsmTrailSegment> _parseList(List raw) {
    final out = <OsmTrailSegment>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = (m['id'] as String?) ?? '';
      final name = (m['name'] as String?) ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      final geomRaw = m['geometry'];
      if (geomRaw is! List || geomRaw.length < 2) continue;
      final geometry = <List<double>>[];
      for (final c in geomRaw) {
        if (c is! List || c.length < 2) continue;
        geometry.add([(c[0] as num).toDouble(), (c[1] as num).toDouble()]);
      }
      if (geometry.length < 2) continue;
      LatLng center;
      final cr = m['center'];
      if (cr is List && cr.length >= 2) {
        center = LatLng((cr[1] as num).toDouble(), (cr[0] as num).toDouble());
      } else {
        final mid = geometry[geometry.length ~/ 2];
        center = LatLng(mid[1], mid[0]);
      }
      out.add(
        OsmTrailSegment(
          id: id,
          name: name,
          difficulty: parseTrailDifficulty(
            (m['mtbScale'] as String?) ?? (m['difficulty'] as String?),
          ),
          lengthKm: (m['lengthKm'] as num?)?.toDouble() ??
              _pathLengthKm(geometry),
          center: center,
          geometry: geometry,
          surface: m['surface'] as String?,
          highway: m['highway'] as String?,
          url: m['url'] as String?,
        ),
      );
    }
    return out;
  }

  double _pathLengthKm(List<List<double>> coords) {
    var sum = 0.0;
    for (var i = 1; i < coords.length; i++) {
      sum += _haversine(
        coords[i - 1][1],
        coords[i - 1][0],
        coords[i][1],
        coords[i][0],
      );
    }
    return sum;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}
