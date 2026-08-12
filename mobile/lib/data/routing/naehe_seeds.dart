import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/bike.dart';
import '../../domain/active_route.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/tour_filters.dart';

/// Nähe-Peek / 60-Min-Loop Seed (bundled JSON, D-60-03).
///
/// Canonical POI (discover-seed-card-fields-v1):
/// `{ id, type, title, offset_min, why_good? }`.
/// Aliases: `name`→title, `kind`→type, `at_min`→offset_min.
/// Premium Bike Knowledge currently ships `{ name, type, offset_min, why_good }`
/// — missing `id` is synthesized stably at parse time (no asset mutation).
class NaeheSeedPoi {
  const NaeheSeedPoi({
    required this.id,
    required this.atMin,
    required this.title,
    required this.kind,
    this.whyGood,
  });

  /// Stable POI id (JSON `id`, else synthesized).
  final String id;

  /// Minutes from loop start (canonical JSON: `offset_min`, alias: `at_min`).
  final int atMin;
  final String title;

  /// POI kind/type (canonical JSON: `type`, alias: `kind`).
  final String kind;

  /// Optional one-liner (Premium-Pass / Bike Knowledge).
  final String? whyGood;

  factory NaeheSeedPoi.fromJson(Map<String, dynamic> m) {
    final offset = m['offset_min'] ?? m['at_min'];
    final atMin = (offset as num?)?.round() ?? 0;
    final type = (m['type'] ?? m['kind'])?.toString() ?? 'poi';
    final title =
        (m['title'] as String?) ?? (m['name'] as String?) ?? '';
    final why = m['why_good'];
    final whyStr = why is String && why.trim().isNotEmpty ? why.trim() : null;
    final rawId = m['id']?.toString().trim();
    final id = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : 'poi-$atMin-${type.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    return NaeheSeedPoi(
      id: id,
      atMin: atMin,
      title: title,
      kind: type,
      whyGood: whyStr,
    );
  }
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
    this.surfaceMixText,
    this.type = 'route',
    this.tip,
    this.season,
    this.highlightPoi,
    this.disciplineNote,
    this.corridorNote,
    this.shortPitch,
    this.thumbnailUrl,
    this.bakedGeometry,
    this.geometryEngine,
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

  /// Premium Bike Knowledge ships surface_mix as a free-text string.
  final String? surfaceMixText;
  final String type;

  /// Premium-Pass card/detail fields (discover-seed-card-fields-v1).
  final String? tip;
  final String? season;
  final String? highlightPoi;
  final String? disciplineNote;
  final String? corridorNote;
  final String? shortPitch;

  /// Hero image — asset path (`assets/…`) or https URL.
  final String? thumbnailUrl;

  /// Pre-baked street loop [[lng, lat],…] from seed JSON (`geometry`).
  final List<List<double>>? bakedGeometry;

  /// e.g. `osrm-cycling-prebake-v1` when [bakedGeometry] was offline-routed.
  final String? geometryEngine;

  /// True when JSON shipped a usable polyline (not synthetic circle).
  bool get hasBakedGeometry =>
      bakedGeometry != null && bakedGeometry!.length >= 4;

  bool get isRoute => type == 'route';

  /// Primary sport tag for card chrome (ebike / city / gravel …).
  String? get sportLabel {
    if (sportTags.isEmpty) return null;
    return sportTags.first;
  }

  /// Season chip label (DE) for card chrome.
  String? get seasonLabel {
    final s = season?.trim();
    if (s == null || s.isEmpty) return null;
    return switch (s.toLowerCase()) {
      'year_round' || 'ganzjaehrig' || 'ganzjährig' => 'Ganzjährig',
      'spring_summer' || 'fruehling_sommer' || 'frühling–sommer' =>
        'Frühling–Sommer',
      'autumn' || 'herbst' => 'Herbst',
      'winter' => 'Winter',
      _ => s,
    };
  }

  /// Human surface mix line for detail (map % or premium free text).
  String? get surfaceMixLabel {
    final text = surfaceMixText?.trim();
    if (text != null && text.isNotEmpty) return text;
    final mix = surfaceMix;
    if (mix == null || mix.isEmpty) return null;
    final parts = <String>[];
    for (final e in mix.entries) {
      final n = e.value is num ? (e.value as num).round() : null;
      if (n == null || n <= 0) continue;
      final label = switch (e.key) {
        'asphalt' => 'Asphalt',
        'gravel' => 'Gravel',
        'trail' => 'Trail',
        _ => e.key,
      };
      parts.add('$label $n%');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

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
    String? mixText;
    final rawMix = m['surface_mix'];
    if (rawMix is Map) {
      mix = Map<String, dynamic>.from(rawMix);
    } else if (rawMix is String && rawMix.trim().isNotEmpty) {
      mixText = rawMix.trim();
    }
    String? opt(String key) {
      final v = m[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final baked = parseSeedGeometryLngLat(
      m['geometry'] ?? m['track'] ?? m['coordinates'],
    );

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
      // Nähe uses is_loop; legacy/premium packs use loop / closed.
      isLoop: m['is_loop'] == true ||
          m['loop'] == true ||
          m['closed'] == true,
      durationBand: m['duration_band'] as String?,
      poiStops: pois,
      surfaceMix: mix,
      surfaceMixText: mixText,
      type: (m['type'] as String?) ?? 'route',
      tip: opt('tip'),
      season: opt('season'),
      highlightPoi: opt('highlight_poi'),
      disciplineNote: opt('discipline_note'),
      corridorNote: opt('corridor_note'),
      shortPitch: opt('short_pitch') ?? opt('notes'),
      thumbnailUrl: opt('thumbnail_url') ?? heroAssetForSeedId((m['id'] as String?) ?? ''),
      bakedGeometry: baked,
      geometryEngine: opt('geometry_engine'),
    );
  }

  /// Bike Knowledge / Premium-Pass tour object (array item in
  /// `p0-rhein-neckar-60min-premium-v1.json`). IDs stay as shipped (rn-1/2/3).
  factory NaeheSeedRoute.fromPremiumBikeKnowledge(Map<String, dynamic> m) {
    final start = m['start_area'];
    double lat = 49.41;
    double lng = 8.68;
    String? corridor;
    if (start is Map) {
      final sa = Map<String, dynamic>.from(start);
      lat = (sa['lat'] as num?)?.toDouble() ?? lat;
      lng = (sa['lng'] as num?)?.toDouble() ?? lng;
      final c = sa['corridor_note'];
      if (c is String && c.trim().isNotEmpty) corridor = c.trim();
    }
    final sport = (m['sport'] as String?)?.trim();
    final tags = <String>[if (sport != null && sport.isNotEmpty) sport];
    final pois = <NaeheSeedPoi>[];
    final rawPois = m['pois'] ?? m['poi_stops'];
    if (rawPois is List) {
      for (final p in rawPois) {
        if (p is Map) {
          pois.add(NaeheSeedPoi.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    Map<String, dynamic>? mix;
    String? mixText;
    final rawMix = m['surface_mix'];
    if (rawMix is Map) {
      mix = Map<String, dynamic>.from(rawMix);
    } else if (rawMix is String && rawMix.trim().isNotEmpty) {
      mixText = rawMix.trim();
    }
    String? opt(String key) {
      final v = m[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final duration = (m['duration_min'] as num?)?.round() ?? 0;
    // Parity with Nähe fromJson: is_loop | loop | closed.
    final isLoop = m['loop'] == true ||
        m['is_loop'] == true ||
        m['closed'] == true;
    final baked = parseSeedGeometryLngLat(
      m['geometry'] ?? m['track'] ?? m['coordinates'],
    );
    return NaeheSeedRoute(
      id: (m['id'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
      ascentM: (m['ascent_m'] as num?)?.round() ?? 0,
      durationMin: duration,
      effortLabel: (m['effort_label'] as String?) ??
          (sport == 'gravel' ? 'Mittel' : 'Leicht'),
      sportTags: tags,
      centerLat: lat,
      centerLng: lng,
      isLoop: isLoop,
      durationBand: duration >= 45 && duration <= 75
          ? '60'
          : (m['duration_band'] as String?),
      poiStops: pois,
      surfaceMix: mix,
      surfaceMixText: mixText,
      type: (m['type'] as String?) ?? 'route',
      tip: opt('tip'),
      season: opt('season'),
      highlightPoi: opt('highlight_poi'),
      disciplineNote: opt('discipline_note'),
      corridorNote: corridor ?? opt('corridor_note'),
      shortPitch: opt('short_pitch') ?? opt('notes'),
      thumbnailUrl: opt('thumbnail_url') ??
          heroAssetForSeedId((m['id'] as String?) ?? ''),
      bakedGeometry: baked,
      geometryEngine: opt('geometry_engine'),
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

  /// Surface-Tag aus surface_mix (größter Anteil) oder Premium-Text.
  /// Kanonisch via [TourFilters] — gleiches Mapping wie Discover-Filter.
  String get surfaceTag {
    final text = surfaceMixText?.trim();
    if (text != null && text.isNotEmpty) {
      return TourFilters.normalizeStoredSurface(text);
    }
    final mix = surfaceMix;
    if (mix == null || mix.isEmpty) {
      return TourFilters.canonicalSurfaceTag(TourSurfaceKey.mixed);
    }
    String best = 'asphalt';
    num bestV = -1;
    mix.forEach((k, v) {
      final n = v is num ? v : 0;
      if (n > bestV) {
        bestV = n;
        best = k;
      }
    });
    return TourFilters.normalizeStoredSurface(best);
  }

  /// Geschlossene Polyline [[lng,lat],…] — bevorzugt gebackene Straßen-
  /// Geometrie aus dem Seed-JSON; sonst organische Offline-Näherung
  /// (kein perfekter Kreis).
  List<List<double>>? get trackLngLat {
    if (hasBakedGeometry) return bakedGeometry;
    if (!isLoop || distanceKm < 1) return null;
    return organicLoopLngLat(
      lat: centerLat,
      lng: centerLng,
      distanceKm: distanceKm,
      seedKey: id,
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
      isLoop: isLoop,
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
    'ebike' || 'e-bike' => BikeCategory.etrekking,
    'touring' || 'trekking' || 'etrekking' => BikeCategory.etrekking,
    'emtb' => BikeCategory.emtb,
    _ => null,
  };
}

/// Bundled hero assets for Discover photo cards (S25 — never blank sheet).
String? heroAssetForSeedId(String id) {
  if (id.isEmpty) return null;
  const map = <String, String>{
    'seed-dach-60-rn-1-heidelberg-neckarwiese':
        'assets/seeds/heroes/rn-heidelberg.jpg',
    'seed-dach-60-rn-2-mannheim-schloss-waldpark':
        'assets/seeds/heroes/rn-mannheim.jpg',
    'seed-dach-60-rn-3-heidelberg-boxberg-gaisberg':
        'assets/seeds/heroes/rn-boxberg.jpg',
    'seed-loop-heidelberg-neckar-60': 'assets/seeds/heroes/rn-heidelberg.jpg',
    'seed-loop-mannheim-rhein-60': 'assets/seeds/heroes/rn-mannheim.jpg',
    'seed-loop-heidelberg-boxberg-gravel-60':
        'assets/seeds/heroes/rn-boxberg.jpg',
    'seed-loop-tempelhofer-60': 'assets/seeds/heroes/berlin-tempelhofer.jpg',
    'seed-loop-spree-feierabend-60': 'assets/seeds/heroes/berlin-spree.jpg',
    'seed-loop-grunewald-kurz-60': 'assets/seeds/heroes/berlin-grunewald.jpg',
    // Karlsruhe / Hardtwald (Wiesloch-Nähe ≤35 km) — reuse RN heroes.
    'seed-loop-karlsruhe-hardtwald-60':
        'assets/seeds/heroes/rn-heidelberg.jpg',
    'seed-loop-karlsruhe-hardt-mtb-60':
        'assets/seeds/heroes/rn-boxberg.jpg',
  };
  return map[id];
}

/// Parse GeoJSON-ähnliche Seed-Geometrie → [[lng, lat], …].
List<List<double>>? parseSeedGeometryLngLat(dynamic raw) {
  if (raw == null) return null;
  List? coords;
  if (raw is Map) {
    final g = raw['coordinates'] ?? raw['geometry'];
    if (g is Map) {
      coords = g['coordinates'] as List?;
    } else if (g is List) {
      coords = g;
    }
  } else if (raw is List) {
    coords = raw;
  }
  if (coords == null || coords.length < 4) return null;
  final out = <List<double>>[];
  for (final c in coords) {
    if (c is List && c.length >= 2) {
      final a = (c[0] as num).toDouble();
      final b = (c[1] as num).toDouble();
      // GeoJSON: [lng, lat]. Swap only when clearly [lat, lng].
      if (a.abs() <= 90 &&
          b.abs() <= 180 &&
          a.abs() > b.abs() &&
          b.abs() <= 90) {
        out.add([b, a]);
      } else {
        out.add([a, b]);
      }
    } else if (c is Map) {
      final lat = (c['lat'] as num?)?.toDouble();
      final lng =
          (c['lng'] as num?)?.toDouble() ?? (c['lon'] as num?)?.toDouble();
      if (lat != null && lng != null) out.add([lng, lat]);
    }
  }
  if (out.length < 4) return null;
  // Close if nearly closed but not exact.
  final first = out.first;
  final last = out.last;
  final dLat = (first[1] - last[1]).abs();
  final dLng = (first[0] - last[0]).abs();
  if (dLat > 1e-5 || dLng > 1e-5) {
    out.add([first[0], first[1]]);
  }
  return out;
}

/// Synthetischer Rundkurs (geschlossen) um [lat]/[lng] mit ~[distanceKm] Umfang.
///
/// Legacy helper — prefer [organicLoopLngLat] / baked seed `geometry`.
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

/// Offline-Fallback: unregelmäßiger geschlossener Korridor (kein perfekter
/// Kreis). Optisch näher an echten Park-/Ufer-Loops wenn kein Bake/Routing.
List<List<double>> organicLoopLngLat({
  required double lat,
  required double lng,
  required double distanceKm,
  String seedKey = '',
  int points = 48,
}) {
  final radiusKm = math.max(0.8, distanceKm / (2 * math.pi));
  var h = 0;
  for (final cu in seedKey.codeUnits) {
    h = (h * 31 + cu) & 0xffff;
  }
  final phase = (h % 12) * math.pi / 12;
  final rx = radiusKm * (1.08 + (h % 5) * 0.02);
  final ry = radiusKm * (0.86 + (h % 7) * 0.02);
  final cosLat = math.cos(lat * math.pi / 180).abs().clamp(0.2, 1.0);
  final dLat = ry / 111.0;
  final dLng = rx / (111.0 * cosLat);
  final out = <List<double>>[];
  for (var i = 0; i <= points; i++) {
    final t = i / points;
    final a = phase + 2 * math.pi * t;
    // Harmonics break the circular silhouette.
    final wobble = 0.78 +
        0.16 * math.sin(3 * a + phase) +
        0.10 * math.cos(5 * a - phase * 0.5) +
        0.06 * math.sin(2 * a + (h % 7));
    out.add([
      lng + dLng * math.cos(a) * wobble,
      lat + dLat * math.sin(a) * wobble,
    ]);
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

  /// Non-Berlin DACH P0 60-min loops + MTB trails (DE/AT/CH Städte & Regionen).
  static const dachAssetPath =
      'assets/seeds/p0-dach-60min-naehe-v1.json';

  /// Rhein-Neckar Premium-Pass (Bike Knowledge array; IDs rn-1/2/3).
  /// Base curated `p0-rhein-neckar-60min-v1.json` stays untouched (#22).
  static const rheinNeckarAssetPath =
      'assets/seeds/p0-rhein-neckar-60min-premium-v1.json';

  /// Nähe-schema RN loops — loaded as fallback if Premium yields <3 loops.
  static const rheinNeckarNaeheFallbackPath =
      'assets/seeds/p0-rhein-neckar-60min-naehe-v1.json';

  /// France ~60-Min Rundkurse (Paris, Lyon, Strasbourg, Bordeaux, Nice, …).
  static const franceAssetPath =
      'assets/seeds/p0-france-60min-naehe-v1.json';

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

  /// Loads Berlin Nähe seeds + DACH + Rhein-Neckar Premium-Pass, concatenated
  /// and deduped by id (Berlin wins on collision — Tempelhof enrich lives in
  /// the Berlin asset).
  static Future<NaeheSeedsBundle> load({
    String path = assetPath,
    String? dachPath = dachAssetPath,
    String? rheinNeckarPath = rheinNeckarAssetPath,
    String? francePath = franceAssetPath,
  }) async {
    final raw = await rootBundle.loadString(path);
    var bundle = parse(raw);
    if (dachPath != null && dachPath.isNotEmpty) {
      try {
        final dachRaw = await rootBundle.loadString(dachPath);
        bundle = merge(bundle, parse(dachRaw));
      } catch (_) {
        // DACH asset optional at runtime (tests / older builds).
      }
    }
    if (rheinNeckarPath != null && rheinNeckarPath.isNotEmpty) {
      try {
        final rnRaw = await rootBundle.loadString(rheinNeckarPath);
        bundle = merge(bundle, parse(rnRaw));
      } catch (_) {
        // Rhein-Neckar asset optional at runtime (tests / older builds).
      }
    }
    if (francePath != null && francePath.isNotEmpty) {
      try {
        final frRaw = await rootBundle.loadString(francePath);
        bundle = merge(bundle, parse(frRaw));
      } catch (_) {
        // France asset optional at runtime (tests / older builds).
      }
    }
    // S25: Wiesloch must never see a dead empty sheet — if Premium missing
    // or <3 loops, merge Nähe RN schema (different ids, same region).
    final rnLoops = bundle.loops
        .where(
          (r) =>
              r.id.contains('heidelberg') ||
              r.id.contains('mannheim') ||
              r.id.contains('-rn-'),
        )
        .length;
    if (rnLoops < 3) {
      try {
        final fb = await rootBundle.loadString(rheinNeckarNaeheFallbackPath);
        bundle = merge(bundle, parse(fb));
      } catch (_) {}
    }
    return bundle;
  }

  /// Concatenate [primary] then [extra], dropping extra routes whose id already
  /// exists in primary.
  static NaeheSeedsBundle merge(
    NaeheSeedsBundle primary,
    NaeheSeedsBundle extra,
  ) {
    final seen = <String>{for (final r in primary.routes) r.id};
    final routes = <NaeheSeedRoute>[
      ...primary.routes,
      for (final r in extra.routes)
        if (r.id.isNotEmpty && !seen.contains(r.id)) r,
    ];
    return NaeheSeedsBundle(
      routes: routes,
      labelWithoutLocation: primary.labelWithoutLocation,
      labelWithLocation: primary.labelWithLocation,
      defaultCenterLat: primary.defaultCenterLat,
      defaultCenterLng: primary.defaultCenterLng,
    );
  }

  /// Pure parse (unit-testable without Flutter binding).
  ///
  /// Accepts Nähe envelope `{ seeds: [...] }` **or** Premium Bike Knowledge
  /// top-level array `[ {...tour ... }]` (Rhein-Neckar premium file).
  static NaeheSeedsBundle parse(String raw) {
    final data = jsonDecode(raw);
    if (data is List) {
      return _parsePremiumArray(data);
    }
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

  static NaeheSeedsBundle _parsePremiumArray(List<dynamic> data) {
    final routes = <NaeheSeedRoute>[];
    double lat = 49.41;
    double lng = 8.68;
    for (final s in data) {
      if (s is! Map) continue;
      final route = NaeheSeedRoute.fromPremiumBikeKnowledge(
        Map<String, dynamic>.from(s),
      );
      if (route.id.isEmpty || !route.isRoute) continue;
      routes.add(route);
    }
    if (routes.isNotEmpty) {
      lat = routes.first.centerLat;
      lng = routes.first.centerLng;
    }
    return NaeheSeedsBundle(
      routes: routes,
      labelWithoutLocation: '~60 Min in deiner Region',
      labelWithLocation: '~60 Min um dich',
      defaultCenterLat: lat,
      defaultCenterLng: lng,
    );
  }
}
