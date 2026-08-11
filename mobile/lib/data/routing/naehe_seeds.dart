import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/bike.dart';
import '../../domain/active_route.dart';
import '../../domain/routing/nav_cues.dart';

/// Nähe-Peek / 60-Min-Loop Seed (bundled JSON, D-60-03).
class NaeheSeedPoi {
  const NaeheSeedPoi({
    required this.atMin,
    required this.title,
    required this.kind,
  });

  final int atMin;
  final String title;
  final String kind;

  factory NaeheSeedPoi.fromJson(Map<String, dynamic> m) => NaeheSeedPoi(
        atMin: (m['at_min'] as num?)?.round() ?? 0,
        title: (m['title'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'poi',
      );
}

class NaeheSeedRoute {
  const NaeheSeedRoute({
    required this.id,
    required this.title,
    required this.distanceKm,
    required this.ascentM,
    required this.durationMin,
    required this.effortLabel,
    required this.sportTags,
    required this.centerLat,
    required this.centerLng,
    required this.isLoop,
    this.durationBand,
    this.poiStops = const [],
    this.surfaceMix,
    this.type = 'route',
  });

  final String id;
  final String title;
  final double distanceKm;
  final int ascentM;
  final int durationMin;
  final String effortLabel;
  final List<String> sportTags;
  final double centerLat;
  final double centerLng;
  final bool isLoop;
  final String? durationBand;
  final List<NaeheSeedPoi> poiStops;
  final Map<String, dynamic>? surfaceMix;
  final String type;

  bool get isRoute => type == 'route';

  factory NaeheSeedRoute.fromJson(Map<String, dynamic> m) {
    final center = m['center'];
    double lat = 52.52;
    double lng = 13.405;
    if (center is Map) {
      lat = (center['lat'] as num?)?.toDouble() ?? lat;
      lng = (center['lng'] as num?)?.toDouble() ?? lng;
    }
    final tags = <String>[];
    final rawTags = m['sport_tags'];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t != null) tags.add(t.toString());
      }
    }
    final pois = <NaeheSeedPoi>[];
    final rawPois = m['poi_stops'];
    if (rawPois is List) {
      for (final p in rawPois) {
        if (p is Map) {
          pois.add(NaeheSeedPoi.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    Map<String, dynamic>? mix;
    final rawMix = m['surface_mix'];
    if (rawMix is Map) {
      mix = Map<String, dynamic>.from(rawMix);
    }
    return NaeheSeedRoute(
      id: (m['id'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
      ascentM: (m['ascent_m'] as num?)?.round() ?? 0,
      durationMin: (m['duration_min'] as num?)?.round() ?? 0,
      effortLabel: (m['effort_label'] as String?) ?? 'Mittel',
      sportTags: tags,
      centerLat: lat,
      centerLng: lng,
      isLoop: m['is_loop'] == true,
      durationBand: m['duration_band'] as String?,
      poiStops: pois,
      surfaceMix: mix,
      type: (m['type'] as String?) ?? 'route',
    );
  }

  List<BikeCategory> get categories {
    final out = <BikeCategory>[];
    for (final t in sportTags) {
      final c = _categoryFromSportTag(t);
      if (c != null && !out.contains(c)) out.add(c);
    }
    if (out.isEmpty) {
      return const [
        BikeCategory.urban,
        BikeCategory.road,
        BikeCategory.gravel,
      ];
    }
    return out;
  }

  /// Surface-Tag aus surface_mix (größter Anteil).
  String get surfaceTag {
    final mix = surfaceMix;
    if (mix == null || mix.isEmpty) return 'mixed/urban';
    String best = 'asphalt';
    num bestV = -1;
    mix.forEach((k, v) {
      final n = v is num ? v : 0;
      if (n > bestV) {
        bestV = n;
        best = k;
      }
    });
    return switch (best) {
      'asphalt' => 'asphalt/paved',
      'gravel' => 'gravel/compacted',
      'trail' => 'trail/root',
      _ => 'mixed/urban',
    };
  }

  /// Geschlossene Näherungs-Polyline [[lng,lat],…] für offline Losfahren.
  List<List<double>>? get trackLngLat {
    if (!isLoop || distanceKm < 1) return null;
    return syntheticLoopLngLat(
      lat: centerLat,
      lng: centerLng,
      distanceKm: distanceKm,
    );
  }

  ActiveRoute toActiveRoute() {
    final track = trackLngLat ??
        [
          [centerLng, centerLat],
          [centerLng + 0.01, centerLat],
          [centerLng + 0.01, centerLat + 0.01],
          [centerLng, centerLat + 0.01],
          [centerLng, centerLat],
        ];
    final steps = navStepsFromPolyline([
      for (final c in track) (lat: c[1], lng: c[0]),
    ]);
    return ActiveRoute(
      id: id,
      name: title,
      distanceKm: distanceKm,
      elevationM: ascentM.toDouble(),
      durationMin: durationMin,
      coordinates: track,
      steps: [
        for (final st in steps)
          NavStep(
            id: st.id,
            instruction: st.instruction,
            distanceAlongM: st.distanceAlongM,
          ),
      ],
      poiStops: [
        for (final p in poiStops)
          ActiveRoutePoi(
            atMin: p.atMin,
            title: p.title,
            kind: p.kind,
          ),
      ],
    );
  }
}

BikeCategory? _categoryFromSportTag(String raw) {
  final t = raw.toLowerCase().trim();
  return switch (t) {
    'mtb' || 'trail' || 'enduro' => BikeCategory.mtbAm,
    'gravel' => BikeCategory.gravel,
    'road' || 'rennrad' => BikeCategory.road,
    'city' || 'urban' => BikeCategory.urban,
    'touring' || 'trekking' || 'etrekking' => BikeCategory.etrekking,
    'emtb' => BikeCategory.emtb,
    _ => null,
  };
}

/// Synthetischer Rundkurs (geschlossen) um [lat]/[lng] mit ~[distanceKm] Umfang.
List<List<double>> syntheticLoopLngLat({
  required double lat,
  required double lng,
  required double distanceKm,
  int points = 28,
}) {
  final radiusKm = math.max(0.8, distanceKm / (2 * math.pi));
  final dLat = radiusKm / 111.0;
  final cosLat = math.cos(lat * math.pi / 180).abs().clamp(0.2, 1.0);
  final dLng = radiusKm / (111.0 * cosLat);
  final out = <List<double>>[];
  for (var i = 0; i <= points; i++) {
    final a = 2 * math.pi * i / points;
    out.add([lng + dLng * math.cos(a), lat + dLat * math.sin(a)]);
  }
  return out;
}

class NaeheSeedsBundle {
  const NaeheSeedsBundle({
    required this.routes,
    required this.labelWithoutLocation,
    required this.labelWithLocation,
    required this.defaultCenterLat,
    required this.defaultCenterLng,
  });

  static const assetPath =
      'assets/seeds/naehe-peek-seeds-berlin-v1.json';

  final List<NaeheSeedRoute> routes;
  final String labelWithoutLocation;
  final String labelWithLocation;
  final double defaultCenterLat;
  final double defaultCenterLng;

  /// Nur echte ~60-Min-Loops (is_loop).
  List<NaeheSeedRoute> get loops =>
      routes.where((r) => r.isRoute && r.isLoop).toList();

  NaeheSeedRoute? byId(String id) {
    for (final r in routes) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Future<NaeheSeedsBundle> load({
    String path = assetPath,
  }) async {
    final raw = await rootBundle.loadString(path);
    return parse(raw);
  }

  /// Pure parse (unit-testable without Flutter binding).
  static NaeheSeedsBundle parse(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map) {
      return const NaeheSeedsBundle(
        routes: [],
        labelWithoutLocation: '~60 Min in deiner Region',
        labelWithLocation: '~60 Min um dich',
        defaultCenterLat: 52.52,
        defaultCenterLng: 13.405,
      );
    }
    final m = Map<String, dynamic>.from(data);
    final center = m['default_center'];
    double lat = 52.52;
    double lng = 13.405;
    if (center is Map) {
      lat = (center['lat'] as num?)?.toDouble() ?? lat;
      lng = (center['lng'] as num?)?.toDouble() ?? lng;
    }
    final routes = <NaeheSeedRoute>[];
    final seeds = m['seeds'];
    if (seeds is List) {
      for (final s in seeds) {
        if (s is! Map) continue;
        final route = NaeheSeedRoute.fromJson(Map<String, dynamic>.from(s));
        if (route.id.isEmpty || !route.isRoute) continue;
        routes.add(route);
      }
    }
    return NaeheSeedsBundle(
      routes: routes,
      labelWithoutLocation:
          (m['label_without_location'] as String?) ?? '~60 Min in deiner Region',
      labelWithLocation:
          (m['label_with_location'] as String?) ?? '~60 Min um dich',
      defaultCenterLat: lat,
      defaultCenterLng: lng,
    );
  }
}
