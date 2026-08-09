import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';

/// OSM Rad-/MTB-/Wander-Relation mit vereinfachter Polyline ([lng, lat]).
class OsmRouteHit {
  const OsmRouteHit({
    required this.id,
    required this.title,
    required this.type,
    required this.lengthKm,
    required this.durationMin,
    required this.center,
    required this.geometry,
    this.difficulty,
    this.summary,
    this.url,
  });

  final String id;
  final String title;
  final String type;
  final double lengthKm;
  final int durationMin;
  final LatLng center;
  final List<List<double>> geometry;
  final String? difficulty;
  final String? summary;
  final String? url;
}

/// Lädt Live-Routen: zuerst Backend `/api/osm-routes`, sonst Overpass direkt.
class OsmRoutesClient {
  Future<List<OsmRouteHit>> fetchNearby({
    required double lat,
    required double lon,
    double radiusKm = 18,
  }) async {
    final fromApi = await _fromApi(lat: lat, lon: lon, radiusKm: radiusKm);
    if (fromApi.isNotEmpty) return fromApi;
    return _fromOverpass(lat: lat, lon: lon, radiusKm: radiusKm);
  }

  Future<List<OsmRouteHit>> _fromApi({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/osm-routes').replace(
        queryParameters: {
          'lat': '$lat',
          'lon': '$lon',
          'radiusKm': '${radiusKm.round()}',
        },
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 14));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(res.body);
      if (data is! Map) return const [];
      final raw = data['routes'] as List? ?? data['tours'] as List? ?? const [];
      return _parseList(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<List<OsmRouteHit>> _fromOverpass({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    final radiusM = (radiusKm.clamp(5, 40) * 1000).round();
    final query = '''
[out:json][timeout:28];
(
  relation["route"="bicycle"](around:$radiusM,$lat,$lon);
  relation["route"="mtb"](around:$radiusM,$lat,$lon);
  relation["route"="hiking"](around:$radiusM,$lat,$lon);
  relation["route"="cycling"](around:$radiusM,$lat,$lon);
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
      final hits = <OsmRouteHit>[];
      for (final raw in elements) {
        if (raw is! Map) continue;
        if (raw['type'] != 'relation') continue;
        final tags = Map<String, dynamic>.from(
          (raw['tags'] as Map?) ?? const {},
        );
        final name = (tags['name'] as String?) ??
            (tags['name:de'] as String?) ??
            (tags['ref'] as String?) ??
            (tags['operator'] as String?);
        if (name == null || name.isEmpty) continue;

        final geometry = <List<double>>[];
        final members = raw['members'] as List? ?? const [];
        for (final m in members) {
          if (m is! Map) continue;
          final geom = m['geometry'] as List? ?? const [];
          for (final g in geom) {
            if (g is! Map) continue;
            final glat = (g['lat'] as num?)?.toDouble();
            final glon = (g['lon'] as num?)?.toDouble();
            if (glat == null || glon == null) continue;
            geometry.add([glon, glat]);
          }
        }
        if (geometry.length < 2) continue;

        final step = (geometry.length / 180).floor().clamp(1, 50);
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
        if (lengthKm < 1.5 || lengthKm > 180) continue;

        final mid = simplified[simplified.length ~/ 2];
        final routeType = (tags['route'] as String?) ?? 'bicycle';
        final id = 'osm-${raw['id']}';
        hits.add(
          OsmRouteHit(
            id: id,
            title: name,
            type: routeType,
            lengthKm: (lengthKm * 10).round() / 10,
            durationMin: ((lengthKm / 14) * 60).round(),
            center: LatLng(mid[1], mid[0]),
            geometry: simplified,
            difficulty: (tags['mtb_scale'] as String?) ??
                (tags['sac_scale'] as String?) ??
                (tags['network'] as String?),
            summary: routeType == 'mtb'
                ? 'OSM MTB-Route'
                : 'OSM Rad-/Wanderroute',
            url: 'https://www.openstreetmap.org/relation/${raw['id']}',
          ),
        );
      }
      hits.sort((a, b) => a.lengthKm.compareTo(b.lengthKm));
      return hits.take(24).toList();
    } catch (_) {
      return const [];
    }
  }

  List<OsmRouteHit> _parseList(List raw) {
    final out = <OsmRouteHit>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = (m['id'] as String?) ?? '';
      final title = (m['title'] as String?) ?? (m['name'] as String?) ?? '';
      if (id.isEmpty || title.isEmpty) continue;
      final geomRaw = m['geometry'];
      if (geomRaw is! List || geomRaw.length < 2) continue;
      final geometry = <List<double>>[];
      for (final c in geomRaw) {
        if (c is! List || c.length < 2) continue;
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        geometry.add([lng, lat]);
      }
      if (geometry.length < 2) continue;
      LatLng center;
      final centerRaw = m['center'];
      if (centerRaw is List && centerRaw.length >= 2) {
        center = LatLng(
          (centerRaw[1] as num).toDouble(),
          (centerRaw[0] as num).toDouble(),
        );
      } else {
        final mid = geometry[geometry.length ~/ 2];
        center = LatLng(mid[1], mid[0]);
      }
      out.add(
        OsmRouteHit(
          id: id.startsWith('osm-') ? id : 'osm-$id',
          title: title,
          type: (m['type'] as String?) ?? 'bicycle',
          lengthKm: (m['lengthKm'] as num?)?.toDouble() ??
              _pathLengthKm(geometry),
          durationMin: (m['durationMin'] as num?)?.round() ?? 90,
          center: center,
          geometry: geometry,
          difficulty: m['difficulty'] as String?,
          summary: m['summary'] as String?,
          url: m['url'] as String?,
        ),
      );
    }
    return out;
  }

  double _pathLengthKm(List<List<double>> coords) {
    var sum = 0.0;
    for (var i = 1; i < coords.length; i++) {
      sum += _haversineKm(
        coords[i - 1][1],
        coords[i - 1][0],
        coords[i][1],
        coords[i][0],
      );
    }
    return sum;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
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
