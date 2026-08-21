import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../l10n/app_locale.dart';
import '../../domain/bike.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/live_engine.dart';
import '../../domain/routing/nav_policy.dart';
import '../../domain/routing/nav_cues.dart';
import '../../domain/routing/route_variant.dart';
import '../../domain/routing/street_from_instruction.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../native/routing_core_ffi.dart';
import '../local/ride_prefs.dart';
import 'offline_pack_dirs.dart';
import 'offline_tiles.dart';

enum RoutingProfile {
  mtbTrail,
  mtbEnduro,
  downhill,
  gravel,
  road,
  urban,
  ebikeTour,
  emtb,
  hiking,

  /// Access-only (DH Anfahrt). Nie Discover-Chip / Overlay.
  driving,
}

extension RoutingProfileApi on RoutingProfile {
  String get apiId => switch (this) {
        RoutingProfile.mtbTrail => 'mtb_allmountain',
        RoutingProfile.mtbEnduro => 'mtb_enduro',
        RoutingProfile.downhill => 'downhill',
        RoutingProfile.gravel => 'gravel',
        RoutingProfile.road => 'road',
        RoutingProfile.urban => 'urban',
        RoutingProfile.ebikeTour => 'ebike',
        RoutingProfile.emtb => 'emtb',
        RoutingProfile.hiking => 'hiking',
        RoutingProfile.driving => 'auto',
      };

  /// Multi-Sport UI-Labels (alle Disziplinen gleichwertig).
  String get label => switch (this) {
        RoutingProfile.mtbTrail => 'MTB',
        RoutingProfile.mtbEnduro => 'Enduro',
        RoutingProfile.downhill => 'Downhill',
        RoutingProfile.gravel => 'Gravel',
        RoutingProfile.road => 'Rennrad',
        RoutingProfile.urban => 'City',
        RoutingProfile.ebikeTour => 'E-Trekking',
        RoutingProfile.emtb => 'E-MTB',
        RoutingProfile.hiking => 'Zu Fuß',
        RoutingProfile.driving => 'Auto',
      };

  bool get isAccessOnly => this == RoutingProfile.driving;
}

/// ORS mountain costing is forest road, not a Trailforks trail.
bool profileAllowsOsmRoundTrip(RoutingProfile profile) {
  switch (profile) {
    case RoutingProfile.gravel:
    case RoutingProfile.road:
    case RoutingProfile.urban:
    case RoutingProfile.ebikeTour:
      return true;
    case RoutingProfile.mtbTrail:
    case RoutingProfile.mtbEnduro:
    case RoutingProfile.downhill:
    case RoutingProfile.emtb:
    case RoutingProfile.hiking:
    case RoutingProfile.driving:
      return false;
  }
}

RoutingProfile routingProfileForBike(BikeCategory category) =>
    switch (category) {
      BikeCategory.mtbTrail || BikeCategory.mtbAm => RoutingProfile.mtbTrail,
      BikeCategory.dh => RoutingProfile.downhill,
      BikeCategory.mtbEnduro => RoutingProfile.mtbEnduro,
      BikeCategory.gravel => RoutingProfile.gravel,
      BikeCategory.road => RoutingProfile.road,
      BikeCategory.urban => RoutingProfile.urban,
      BikeCategory.cargo ||
      BikeCategory.folding ||
      BikeCategory.kids =>
        RoutingProfile.urban,
      BikeCategory.emtb => RoutingProfile.emtb,
      BikeCategory.etrekking => RoutingProfile.ebikeTour,
      BikeCategory.hiking => RoutingProfile.hiking,
    };

/// Discover-Chip/Menü: Enduro/DH-Garage ist MTB-Wege, nicht Auto- oder DH-Costing.
/// GraphHopper Basic mappt sowieso alle Bike-Profile auf `bike`.
RoutingProfile discoverNavProfile(RoutingProfile profile) {
  if (profile == RoutingProfile.mtbEnduro ||
      profile == RoutingProfile.downhill) {
    return RoutingProfile.mtbTrail;
  }
  if (profile == RoutingProfile.driving) return RoutingProfile.urban;
  return profile;
}

/// Overlay-Familie folgt dem Discover-Chip, nicht dem Garagen-Rad.
BikeOverlayFamily overlayFamilyForProfile(RoutingProfile profile) =>
    switch (discoverNavProfile(profile)) {
      RoutingProfile.mtbTrail ||
      RoutingProfile.emtb ||
      RoutingProfile.hiking ||
      RoutingProfile.downhill ||
      RoutingProfile.mtbEnduro =>
        BikeOverlayFamily.mtb,
      RoutingProfile.gravel ||
      RoutingProfile.ebikeTour =>
        BikeOverlayFamily.gravel,
      RoutingProfile.urban || RoutingProfile.driving => BikeOverlayFamily.urban,
      RoutingProfile.road => BikeOverlayFamily.road,
    };

/// Chip-Familie: Enduro/DH → mtb. Kein Fake-GH-Profil, kein Auto-Chip.
String discoverChipFamilyId(RoutingProfile profile) =>
    switch (discoverNavProfile(profile)) {
      RoutingProfile.mtbTrail ||
      RoutingProfile.emtb ||
      RoutingProfile.downhill ||
      RoutingProfile.mtbEnduro =>
        'mtb',
      RoutingProfile.gravel => 'gravel',
      RoutingProfile.road => 'road',
      RoutingProfile.urban || RoutingProfile.driving => 'urban',
      RoutingProfile.ebikeTour => 'ebike',
      RoutingProfile.hiking => 'hiking',
    };

bool routingProfileSharesGhBasicBike(RoutingProfile profile) =>
    profile != RoutingProfile.hiking && profile != RoutingProfile.driving;

/// Anfahrt-Costing aus Garage + Bein — nie `downhill` bicycle für GPS→Trail.
RoutingProfile approachRoutingProfile(
  BikeCategory bike,
  ApproachKind kind,
) {
  switch (kind) {
    case ApproachKind.auto:
      return RoutingProfile.driving;
    case ApproachKind.walk:
    case ApproachKind.atStart:
      return RoutingProfile.hiking;
    case ApproachKind.bicycle:
      final p = routingProfileForBike(bike);
      if (p == RoutingProfile.downhill) return RoutingProfile.mtbTrail;
      return discoverNavProfile(p);
  }
}

/// Fallback, wenn keine Vorlieben gesetzt sind (inkl. Wandern, ohne DH).
/// Kein Enduro neben MTB — gleiche GH-`bike`-Route.
const kDiscoverProfileMenuFallback = <RoutingProfile>[
  RoutingProfile.urban,
  RoutingProfile.ebikeTour,
  RoutingProfile.gravel,
  RoutingProfile.road,
  RoutingProfile.mtbTrail,
  RoutingProfile.emtb,
  RoutingProfile.hiking,
];

/// Discover-Profilmenü: Haupt zuerst, dann übrige Vorlieben — nicht die
/// volle Liste inkl. Downhill/Wandern, wenn nicht gewählt.
List<RoutingProfile> discoverProfileMenuForSports({
  BikeCategory? primary,
  Iterable<BikeCategory> sports = const [],
}) {
  final ordered = <BikeCategory>[];
  if (primary != null) ordered.add(primary);
  for (final s in sports) {
    if (!ordered.contains(s)) ordered.add(s);
  }
  if (ordered.isEmpty) {
    return List<RoutingProfile>.of(kDiscoverProfileMenuFallback);
  }
  final out = <RoutingProfile>[];
  final seen = <RoutingProfile>{};
  for (final c in ordered) {
    final p = discoverNavProfile(routingProfileForBike(c));
    if (seen.add(p)) out.add(p);
  }
  return out.isEmpty
      ? List<RoutingProfile>.of(kDiscoverProfileMenuFallback)
      : out;
}

/// Ein Chip ohne Alternative ist keine Filterung — nur bei ≥2 Profilen.
bool discoverNavProfileChipVisible(List<RoutingProfile> menu) =>
    menu.length >= 2;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Native Dijkstra (`offline_graph`) or Valhalla tiles — not ORS/GraphHopper.
bool isOfflineRoutingEngine(String? engine) {
  final e = (engine ?? '').toLowerCase();
  return e == 'offline_graph' || e == 'valhalla';
}

/// After a region pack is activated, do not keep serving an older live
/// (ORS/GraphHopper) cache hit — otherwise the graph never runs.
///
/// Keep the cache when FFI is missing, vias force online, the cached line
/// is already native, or it was written *after* the pack was activated
/// (offline failed over to live).
bool skipLiveCacheForOfflinePack({
  required DateTime? cacheFetchedAt,
  required DateTime? packActivatedAt,
  required String? cachedEngine,
  required bool ffiAvailable,
  required bool viasEmpty,
  bool planned = true,
}) {
  if (!planned || !viasEmpty || !ffiAvailable) return false;
  final fetched = cacheFetchedAt;
  final activated = packActivatedAt;
  if (fetched == null || activated == null) return false;
  if (!fetched.isBefore(activated)) return false;
  return !isOfflineRoutingEngine(cachedEngine);
}

/// Mid-ride without net: do not serve an ORS/GraphHopper cache hit.
bool skipLiveCacheWhenOffline({
  required bool allowOnline,
  required String? cachedEngine,
}) {
  return !allowOnline && !isOfflineRoutingEngine(cachedEngine);
}

/// Native Dijkstra only when A–B sits in an activated pack, or we just
/// switched to a downloaded pack that covers the trip.
///
/// [preferOffline] must not skip that check — a Schwarzwald graph must
/// not swallow a plan in the Alps.
bool shouldAttemptOfflineGraphFirst({
  required bool planned,
  required bool viasEmpty,
  required bool activePackCovers,
  required bool switchedToCoveringPack,
  bool allowOfflineFirst = true,
}) {
  if (!allowOfflineFirst) return false;
  if (!planned || !viasEmpty) return false;
  return activePackCovers || switchedToCoveringPack;
}

/// After ORS/GraphHopper fail: Dijkstra only if a pack on disk covers A–B.
/// Alps + Schwarzwald graph must not sneak in here.
bool shouldFallbackOfflineAfterOnlineFail({
  required bool planned,
  required bool viasEmpty,
  required bool packCoversOrSwitched,
  bool allowOfflineFallback = true,
}) {
  if (!allowOfflineFallback) return false;
  return planned && viasEmpty && packCoversOrSwitched;
}

const kOnlineRouteTimeout = Duration(seconds: 28);
const kOnlineRouteTimeoutWithOfflineFallback = Duration(seconds: 10);
const kBrowseLiveRouteTimeout = Duration(seconds: 12);

/// A–B with a covering pack: fail over to Dijkstra sooner than live/via trips.
/// Browse pin A–B has no Dijkstra — fail the live call sooner than 28 s.
Duration onlineRouteTimeout({
  required bool planned,
  required bool viasEmpty,
  required bool allowOfflineFallback,
  bool packMayCover = false,
}) {
  if (planned && viasEmpty && allowOfflineFallback && packMayCover) {
    return kOnlineRouteTimeoutWithOfflineFallback;
  }
  if (planned && !allowOfflineFallback) {
    return kBrowseLiveRouteTimeout;
  }
  return kOnlineRouteTimeout;
}

bool isOfflineNoRouteError(Object error) =>
    error.toString().contains('offline-no-route');

bool isOfflineViasNeedNetworkError(Object error) =>
    error.toString().contains('offline-vias-need-network');

bool isLoopNotClosedError(Object error) =>
    error.toString().contains('loop-not-closed');

bool isLoopProfileError(Object error) =>
    error.toString().contains('loop-profile');

bool isLoopGeneratorError(Object error) {
  final s = error.toString();
  return s.contains('loop-not-closed') ||
      s.contains('loop-profile') ||
      s.contains('loop-ors-unconfigured') ||
      s.contains('loop-offline') ||
      s.contains('Loop failed');
}

RouteResult routeResultFromJson(
  Map<String, dynamic> data, {
  GeoPoint? fallbackFrom,
  GeoPoint? fallbackTo,
}) {
  final coords = <GeoPoint>[];
  final geom = data['geometry'];
  if (geom is Map && geom['coordinates'] is List) {
    for (final c in geom['coordinates'] as List) {
      if (c is List && c.length >= 2) {
        coords.add(
          GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        );
      }
    }
  } else if (geom is List) {
    for (final c in geom) {
      if (c is List && c.length >= 2) {
        coords.add(
          GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        );
      } else if (c is Map) {
        coords.add(
          GeoPoint(
            (c['lat'] as num).toDouble(),
            (c['lng'] as num? ?? c['lon'] as num).toDouble(),
          ),
        );
      }
    }
  }
  final usedFallback = coords.isEmpty;
  if (usedFallback && fallbackFrom != null && fallbackTo != null) {
    coords.addAll([fallbackFrom, fallbackTo]);
  }

  final rawSteps = data['steps'];
  final steps = <RouteStep>[];
  if (rawSteps is List) {
    for (final s in rawSteps) {
      if (s is! Map) continue;
      final instruction =
          '${s['instruction'] ?? (AppLocaleBinding.isEnglish ? 'Continue' : 'Weiter')}';
      final streetRaw = s['streetName'] ?? s['street'] ?? s['name'];
      final streetFromField =
          streetRaw is String && streetRaw.trim().isNotEmpty
              ? streetRaw.trim()
              : null;
      final coord = s['coordinate'];
      double? lat;
      double? lng;
      if (coord is Map) {
        lat = (coord['lat'] as num?)?.toDouble();
        lng = (coord['lng'] as num? ?? coord['lon'] as num?)?.toDouble();
      }
      steps.add(
        RouteStep(
          id: '${s['id']}',
          instruction: instruction,
          distanceAlongM: (s['distanceAlongM'] as num?)?.toDouble() ?? 0,
          streetName: streetFromField ??
              extractStreetNameFromInstruction(instruction),
          lat: lat,
          lng: lng,
        ),
      );
    }
  }

  final rawWarnings = data['warnings'];
  final warnings = <String>[];
  if (rawWarnings is List) {
    for (final w in rawWarnings) {
      if (w is String && w.trim().isNotEmpty) warnings.add(w.trim());
    }
  }

  return RouteResult(
    coordinates: coords,
    distanceM: (data['distance'] as num?)?.toDouble() ??
        (data['distanceM'] as num?)?.toDouble() ??
        0,
    durationS: (data['duration'] as num?)?.toDouble() ??
        (data['durationS'] as num?)?.toDouble() ??
        0,
    engine: usedFallback ? 'fallback-line' : data['engine'] as String?,
    steps: steps.isNotEmpty ? steps : stepsFromCoordinates(coords),
    warnings: warnings,
    variant: parseRouteVariant(data['variant'] as String? ?? 'planned'),
    variantApplied: data['variantApplied'] == true,
  );
}

class RouteResult {
  const RouteResult({
    required this.coordinates,
    required this.distanceM,
    required this.durationS,
    this.engine,
    this.steps = const [],
    this.warnings = const [],
    this.variant = RouteVariant.planned,
    this.variantApplied = false,
  });

  final List<GeoPoint> coordinates;
  final double distanceM;
  final double durationS;
  final String? engine;
  final List<RouteStep> steps;
  final List<String> warnings;
  final RouteVariant variant;
  final bool variantApplied;

  /// First rider-facing warning (skips GraphHopper Basic / engine debug).
  String? get riderWarning {
    for (final w in warnings) {
      if (w.startsWith('GraphHopper-Account')) continue;
      if (w.contains('GRAPHHOPPER_ALLOW_EXTENDED')) continue;
      if (w.startsWith('OpenRouteService Fallback')) continue;
      if (w.startsWith('Live-Routing')) continue;
      if (w.startsWith('Öffentliches OSRM')) continue;
      return w;
    }
    return null;
  }
}

class RouteStep {
  const RouteStep({
    required this.id,
    required this.instruction,
    required this.distanceAlongM,
    this.streetName,
    this.lat,
    this.lng,
  });

  final String id;
  final String instruction;
  final double distanceAlongM;
  final String? streetName;
  final double? lat;
  final double? lng;
}

List<RouteStep> stepsFromCoordinates(List<GeoPoint> coords) {
  final raw = navStepsFromPolyline([
    for (final p in coords) (lat: p.lat, lng: p.lng),
  ]);
  return [
    for (final s in raw)
      RouteStep(
        id: s.id,
        instruction: s.instruction,
        distanceAlongM: s.distanceAlongM,
      ),
  ];
}

/// Online `/api/route` + offline `routing_core` FFI (Spec §5.4).
class RoutingClient {
  RoutingClient({
    http.Client? httpClient,
    RoutingCoreFfi? ffi,
  })  : _http = httpClient ?? http.Client(),
        _ffi = ffi ?? RoutingCoreFfi();

  final http.Client _http;
  final RoutingCoreFfi _ffi;

  /// Native `routing_core` loaded — graph routes can run on this device.
  bool get nativeOfflineAvailable => _ffi.available;

  Future<RouteResult> requestRoute({
    required GeoPoint from,
    required GeoPoint to,
    RoutingProfile profile = RoutingProfile.mtbTrail,
    bool preferOffline = false,
    bool allowOnline = true,
    List<GeoPoint> vias = const [],
    LiveRoutingEngine? engine,
    bool accessLeg = false,
    RouteVariant variant = RouteVariant.planned,
    bool allowOfflineFirst = true,
    bool allowOfflineFallback = true,
  }) async {
    final viaLngLats = [
      for (final v in vias) (lng: v.lng, lat: v.lat),
    ];
    // Dijkstra is A→B only — vias without net must not look like a pack miss.
    if (!allowOnline && vias.isNotEmpty) {
      throw StateError('offline-vias-need-network');
    }
    var coversActive = false;
    var switched = false;
    if (allowOfflineFirst && variant == RouteVariant.planned && vias.isEmpty) {
      final covering = await _ensureCoveringPack(
        from: from,
        to: to,
        vias: viaLngLats,
      );
      coversActive = covering.covers;
      switched = covering.switched;
    }
    var offlineFirst = shouldAttemptOfflineGraphFirst(
      planned: variant == RouteVariant.planned,
      viasEmpty: vias.isEmpty,
      activePackCovers: coversActive,
      switchedToCoveringPack: switched,
      allowOfflineFirst: allowOfflineFirst,
    );
    // Ride without net, graph on disk, but no bbox to test — last chance.
    // A known bbox that does not cover A–B must not reach Dijkstra.
    if (!offlineFirst &&
        !allowOnline &&
        vias.isEmpty &&
        variant == RouteVariant.planned &&
        preferOffline) {
      final bbox = await OfflinePackDirs.activatedCoverageBbox();
      if (bbox == null && await OfflinePackDirs.hasLegitimateActivatedPack()) {
        offlineFirst = true;
      }
    }
    if (offlineFirst) {
      final offline = await _tryOfflineIfPlausible(from, to, profile, vias);
      if (offline != null) return offline;
    }

    if (!allowOnline) {
      throw StateError('offline-no-route');
    }

    // Live-first still needs coverage for a short ORS timeout and for
    // Dijkstra after a hang — Alps + Schwarzwald must not look covered.
    if (!coversActive &&
        !switched &&
        allowOfflineFallback &&
        variant == RouteVariant.planned &&
        vias.isEmpty) {
      final covering = await _ensureCoveringPack(
        from: from,
        to: to,
        vias: viaLngLats,
      );
      coversActive = covering.covers;
      switched = covering.switched;
    }

    try {
      return await _requestOnline(
        from,
        to,
        profile,
        vias: vias,
        engine: engine,
        accessLeg: accessLeg,
        variant: variant,
        timeout: onlineRouteTimeout(
          planned: variant == RouteVariant.planned,
          viasEmpty: vias.isEmpty,
          allowOfflineFallback: allowOfflineFallback,
          packMayCover: coversActive || switched,
        ),
      );
    } catch (_) {
      if (variant != RouteVariant.planned || vias.isNotEmpty) rethrow;
      if (!shouldFallbackOfflineAfterOnlineFail(
        planned: true,
        viasEmpty: true,
        packCoversOrSwitched: coversActive || switched,
        allowOfflineFallback: allowOfflineFallback,
      )) {
        rethrow;
      }
      final offline = await _tryOfflineIfPlausible(from, to, profile, vias);
      if (offline != null) return offline;
      rethrow;
    }
  }

  Future<({bool covers, bool switched})> _ensureCoveringPack({
    required GeoPoint from,
    required GeoPoint to,
    required List<({double lng, double lat})> vias,
  }) async {
    final covers = await OfflinePackDirs.legitimateCoversRoute(
      fromLng: from.lng,
      fromLat: from.lat,
      toLng: to.lng,
      toLat: to.lat,
      vias: vias,
    );
    if (covers) return (covers: true, switched: false);
    final switched = await OfflinePackDirs.switchToPackCovering(
      fromLng: from.lng,
      fromLat: from.lat,
      toLng: to.lng,
      toLat: to.lat,
      vias: vias,
    );
    if (switched) OfflineTilesStore.instance.clearCache();
    return (covers: false, switched: switched);
  }

  Future<RouteResult?> _tryOfflineIfPlausible(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile,
    List<GeoPoint> vias,
  ) async {
    final offline = await _tryOffline(from, to, profile);
    if (offline == null) return null;
    if (isImplausibleAbDetour(
      distanceM: offline.distanceM,
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
      vias: [
        for (final v in vias) (lat: v.lat, lng: v.lng),
      ],
    )) {
      return null;
    }
    return offline;
  }

  Future<RouteResult?> _tryOffline(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile,
  ) async {
    if (!_ffi.available) return null;
    final tiles = await OfflineTilesStore.instance.ensureTilesPath(
      overridePath: AppConfig.offlineTilesPath.isEmpty
          ? null
          : AppConfig.offlineTilesPath,
      bundledFallback: false,
    );
    if (tiles == null || !_ffi.tilesOk(tiles)) return null;
    try {
      final r = _ffi.tryOfflineRoute(
        fromLat: from.lat,
        fromLng: from.lng,
        toLat: to.lat,
        toLng: to.lng,
        profile: profile.apiId,
        tilesPath: tiles,
      );
      if (r == null) return null;
      final coords =
          r.coordinatesLngLat.map((c) => GeoPoint(c[1], c[0])).toList();
      return RouteResult(
        coordinates: coords,
        distanceM: r.distanceM,
        durationS: r.durationS,
        engine: r.engine,
        steps: stepsFromCoordinates(coords),
      );
    } on RoutingCoreException {
      return null;
    }
  }

  Future<RouteResult> _requestOnline(
    GeoPoint from,
    GeoPoint to,
    RoutingProfile profile, {
    List<GeoPoint> vias = const [],
    LiveRoutingEngine? engine,
    bool accessLeg = false,
    RouteVariant variant = RouteVariant.planned,
    Duration timeout = kOnlineRouteTimeout,
  }) async {
    // Web-API: from=lng,lat&to=lng,lat&via=... (Spec /api/route)
    final choice = engine ?? await RidePrefs.routingEngine();
    final qp = <String, String>{
      'from': '${from.lng},${from.lat}',
      'to': '${to.lng},${to.lat}',
      'profile': profile.apiId,
      'lang': AppLocaleBinding.chromeLanguageCode,
    };
    final engineId = choice.apiId;
    if (engineId != null) qp['engine'] = engineId;
    if (accessLeg) qp['access'] = '1';
    if (variant != RouteVariant.planned) qp['variant'] = variant.apiId;
    var url = Uri.parse('${AppConfig.apiBaseUrl}/api/route').replace(
      queryParameters: qp,
    );
    if (vias.isNotEmpty) {
      final extra = vias.map((v) => 'via=${v.lng},${v.lat}').join('&');
      url = Uri.parse('${url.toString()}&$extra');
    }
    final res = await _http
        .get(url, headers: {'Accept': 'application/json'}).timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Route failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return routeResultFromJson(
      data,
      fallbackFrom: from,
      fallbackTo: to,
    );
  }

  /// OSM round-trip around [from]. Online only — no offline graph.
  Future<RouteResult> requestLoop({
    required GeoPoint from,
    required RoutingProfile profile,
    int minutes = 60,
    int seed = 1,
    double? lengthKm,
    Duration timeout = kOnlineRouteTimeout,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/route/loop');
    final body = <String, dynamic>{
      'profile': profile.apiId,
      'from': [from.lng, from.lat],
      'minutes': minutes,
      'seed': seed,
      'lang': AppLocaleBinding.chromeLanguageCode,
      if (lengthKm != null) 'lengthKm': lengthKm,
    };
    final res = await _http
        .post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode == 422) {
      throw StateError('loop-not-closed');
    }
    if (res.statusCode == 503) {
      throw StateError('loop-ors-unconfigured');
    }
    if (res.statusCode == 400) {
      throw StateError('loop-profile');
    }
    if (res.statusCode != 200) {
      throw Exception('Loop failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result = routeResultFromJson(data);
    if (result.coordinates.length < 4) {
      throw StateError('loop-not-closed');
    }
    return result;
  }

  /// Compile GraphHopper custom_model for [near] — discard the dummy path.
  Future<void> warmupLiveRouting({
    required GeoPoint near,
    required RoutingProfile profile,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/route/warmup').replace(
      queryParameters: {
        'near': '${near.lng},${near.lat}',
        'profile': profile.apiId,
      },
    );
    try {
      await _http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 18));
    } catch (_) {}
  }
}

/// Gerade-Linie Out-and-back wenn Live-Routing fehlt / Limit (Web-Parität).
RouteResult approximateOutAndBack({
  required GeoPoint from,
  required GeoPoint to,
  required String label,
}) {
  final mid = GeoPoint((from.lat + to.lat) / 2, (from.lng + to.lng) / 2);
  final coords = [from, mid, to, mid, from];
  final deg = math.sqrt(
    math.pow(to.lat - from.lat, 2) + math.pow(to.lng - from.lng, 2),
  );
  final distM = deg * 111000 * 2 * 1.15;
  return RouteResult(
    coordinates: coords,
    distanceM: distM.roundToDouble(),
    durationS: (distM / 4.5).roundToDouble(),
    engine: 'approx',
    steps: [
      RouteStep(
        id: 'approx-out',
        instruction: 'Näherung „$label“ — Live-Routing später erneut',
        distanceAlongM: distM / 2,
      ),
    ],
  );
}
