import 'dart:math' as math;

import 'route_shape.dart';

/// Where Losfahren / Navigation gets its polyline for a selected tour.
///
/// Policy (D-60 / Rundkurs-Nav): the **selected** tour geometry wins.
/// Live street re-routing must not silently replace a curated loop with an
/// open A→B (or a different ring) at start.
enum TourNavGeometrySource {
  /// Prefill / previously accepted routed points for this tour id.
  cache,

  /// Seed bake, organic loop, or catalog/OSM track on the suggestion.
  track,

  /// No track yet — only then attempt a closed live ring.
  liveClosed,

  /// Nothing usable.
  none,
}

/// Pure choice: cache → selected track → live closed loop.
///
/// [trackUsable] false = track exists but is a ruler / fallback (few points
/// or near-colinear) — skip it and attempt a live closed ring instead.
TourNavGeometrySource chooseTourNavGeometry({
  required bool hasCache,
  required bool hasTrack,
  required bool isLoop,
  bool trackUsable = true,
}) {
  if (hasCache) return TourNavGeometrySource.cache;
  if (hasTrack && trackUsable) return TourNavGeometrySource.track;
  if (isLoop) return TourNavGeometrySource.liveClosed;
  // Pin / idea without track: still try a live ring around the pin.
  return TourNavGeometrySource.liveClosed;
}

/// True when a polyline is only a "ruler" (A→B, demo triangle, failed
/// routing fallback) and must not be shown as a finished street route.
///
/// Heuristics (DACH Discover map honesty):
/// - fewer than 4 vertices
/// - open track with chord ≈ path (colinear)
/// - closed but too coarse (≤6 verts) or one leg dominates
bool isDegenerateTrack(List<List<double>>? trackLngLat) {
  if (trackLngLat == null || trackLngLat.length < 2) return true;
  if (trackLngLat.length < 4) return true;

  var pathKm = 0.0;
  var maxSegKm = 0.0;
  for (var i = 1; i < trackLngLat.length; i++) {
    final a = trackLngLat[i - 1];
    final b = trackLngLat[i];
    if (a.length < 2 || b.length < 2) return true;
    final d = _haversineKm(a[1], a[0], b[1], b[0]);
    pathKm += d;
    if (d > maxSegKm) maxSegKm = d;
  }
  if (pathKm < 0.05) return true;

  final chordKm = _haversineKm(
    trackLngLat.first[1],
    trackLngLat.first[0],
    trackLngLat.last[1],
    trackLngLat.last[0],
  );
  final closed = chordKm < math.max(0.30, pathKm * 0.05);
  if (!closed) {
    final straightness = chordKm / pathKm;
    if (straightness > 0.92) return true;
    if (trackLngLat.length <= 6 && straightness > 0.85) return true;
    return false;
  }
  // Closed: real street loops need density; coarse polygons read as rulers.
  if (trackLngLat.length <= 6) return true;
  if (maxSegKm / pathKm > 0.45) return true;
  return false;
}

/// Inverse of [isDegenerateTrack] — safe to paint as a map tour line.
bool isUsableMapTrack(List<List<double>>? trackLngLat) =>
    !isDegenerateTrack(trackLngLat);

/// Discover ribbon (Komoot-Linie) only for a real street/trail polyline.
bool shouldPaintDiscoverRibbon(List<List<double>>? trackLngLat) =>
    isUsableMapTrack(trackLngLat);

/// Active `_computed` line on Discover — not a GPS heading rubber-band.
///
/// Heading-A→B (Richtung Norden/…) and demo/approx overlays stay off the map.
/// When approach is already painted cyan, do not re-paint the same prefix
/// in tour-green (that reads as a green leash from the puck).
bool shouldPaintActiveComputedRibbon({
  required List<List<double>>? trackLngLat,
  required bool isHeadingOrDemoOverlay,
  required bool approachPaintedSeparately,
}) {
  if (isHeadingOrDemoOverlay) return false;
  if (approachPaintedSeparately) return false;
  return shouldPaintDiscoverRibbon(trackLngLat);
}

/// Trailforks „TF“ pins are attribution points (center + URL).
/// No mirrored geometry → no map pin and no ribbon.
bool shouldDrawTrailforksMapPin({List<List<double>>? trackLngLat}) =>
    isUsableMapTrack(trackLngLat);

/// Live ring is acceptable only when honestly closed and length-plausible
/// vs the curated distance (same gates as Discover seed upgrade).
bool isAcceptableLiveLoop({
  required List<List<double>> trackLngLat,
  required double expectedDistanceKm,
  double maxGapKm = 0.45,
}) {
  if (trackLngLat.length < 4) return false;
  if (routeShapeOf(trackLngLat) != RouteShape.loop) return false;

  final gapKm = _haversineKm(
    trackLngLat.first[1],
    trackLngLat.first[0],
    trackLngLat.last[1],
    trackLngLat.last[0],
  );
  if (gapKm > maxGapKm) return false;

  var lenKm = 0.0;
  for (var i = 1; i < trackLngLat.length; i++) {
    lenKm += _haversineKm(
      trackLngLat[i - 1][1],
      trackLngLat[i - 1][0],
      trackLngLat[i][1],
      trackLngLat[i][0],
    );
  }
  if (expectedDistanceKm > 0) {
    if (lenKm > expectedDistanceKm * 2.8 + 5) return false;
    if (lenKm < expectedDistanceKm * 0.25) return false;
  }
  return true;
}

/// Whether [navLngLat] (what Ride will actually draw) is a closed loop.
bool navGeometryIsLoop(List<List<double>>? navLngLat) =>
    routeShapeOf(navLngLat) == RouteShape.loop;

/// Map tap in Navigieren must not steal B while typing or after A+B exist.
bool mapTapMaySetAbPoint({
  required bool addressFieldFocused,
  required bool startSet,
  required bool endSet,
  required bool explicitlyPicking,
}) {
  if (addressFieldFocused) return false;
  if (!explicitlyPicking && startSet && endSet) return false;
  return true;
}

/// A→B that wanders far beyond the crow-flies (stale cache, coarse offline
/// graph, or a superseded in-flight calc). Loops (start≈end) are not judged.
///
/// Frauenweiler → Wiesloch is ~2.6 km crow / ~3.4 km GraphHopper bike.
/// A 16 km triangle via Sandhausen must not win over the live engine.
bool isImplausibleAbDetour({
  required double distanceM,
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
  List<({double lat, double lng})> vias = const [],
}) {
  var crowM = 0.0;
  var plat = fromLat;
  var plng = fromLng;
  for (final v in vias) {
    crowM += _haversineKm(plat, plng, v.lat, v.lng) * 1000;
    plat = v.lat;
    plng = v.lng;
  }
  crowM += _haversineKm(plat, plng, toLat, toLng) * 1000;
  if (crowM < 400) return false;
  return distanceM > crowM * 2.4 && distanceM > crowM + 2500;
}

/// GPS farther than this from the tour polyline → Losfahren must compute
/// an approach (current position → join), not only load the curated track.
const double kTourApproachThresholdM = 200;

/// True when the rider is not already on the selected tour.
bool tourNeedsApproachFromGps(
  double crossTrackM, {
  double thresholdM = kTourApproachThresholdM,
}) =>
    crossTrackM.isFinite && crossTrackM > thresholdM;

/// Catalog pins are often metadata-only (no polyline, sometimes a default
/// city center). A bundled Nähe-seed with the same place can supply the
/// street loop Losfahren needs — without a live pentagon that times out.
const _kCatalogSeedPlaceStopwords = {
  'allee',
  'bike',
  'city',
  'gravel',
  'idea',
  'idee',
  'loop',
  'mtb',
  'park',
  'rad',
  'road',
  'route',
  'runde',
  'rundkurs',
  'the',
  'tour',
  'touren',
  'trail',
  'urban',
};

String _catalogSeedNorm(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
}

Set<String> catalogSeedPlaceTokens(String name) {
  final norm = _catalogSeedNorm(name).replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  return {
    for (final t in norm.split(' '))
      if (t.length >= 5 && !_kCatalogSeedPlaceStopwords.contains(t)) t,
  };
}

bool _placeTokensAlign(String a, String b) {
  if (a == b) return true;
  if (a.length >= 6 && b.length >= 6) {
    return a.startsWith(b) || b.startsWith(a);
  }
  return false;
}

/// How many distinctive place tokens are shared (prefix-aware).
int alignedPlaceTokenCount(String catalogName, String seedTitle) {
  final catalog = catalogSeedPlaceTokens(catalogName);
  final seed = catalogSeedPlaceTokens(seedTitle);
  var n = 0;
  for (final a in catalog) {
    if (seed.any((b) => _placeTokensAlign(a, b))) n++;
  }
  return n;
}

/// Catalog card and bundled seed describe the same loop.
bool catalogMatchesBundledSeed({
  required String catalogName,
  required double catalogLat,
  required double catalogLng,
  required double catalogDistanceKm,
  required String seedTitle,
  required double seedLat,
  required double seedLng,
  required double seedDistanceKm,
}) {
  final aligned = alignedPlaceTokenCount(catalogName, seedTitle);
  final gapKm = _haversineKm(catalogLat, catalogLng, seedLat, seedLng);
  final denom = math.max(catalogDistanceKm, seedDistanceKm);
  final kmRatio =
      denom > 0 ? (catalogDistanceKm - seedDistanceKm).abs() / denom : 1.0;
  // Strong place overlap (Baden-Baden + Lichtental) even if the catalog
  // pin still sits on a default city (Freiburg).
  if (aligned >= 2) return true;
  if (aligned >= 1 && gapKm < 25) return true;
  if (gapKm < 4.0 && kmRatio < 0.35) return true;
  return false;
}

/// Best bundled seed track for a pin-only catalog tour, or null.
({List<List<double>> trackLngLat, double lat, double lng})?
    pickBundledSeedForCatalog({
  required String catalogName,
  required double catalogLat,
  required double catalogLng,
  required double catalogDistanceKm,
  required List<
          ({
            String title,
            double lat,
            double lng,
            double distanceKm,
            List<List<double>> trackLngLat,
          })>
      seeds,
}) {
  ({List<List<double>> trackLngLat, double lat, double lng})? best;
  var bestAligned = -1;
  var bestGap = double.infinity;
  for (final s in seeds) {
    if (s.trackLngLat.length < 4) continue;
    if (!catalogMatchesBundledSeed(
      catalogName: catalogName,
      catalogLat: catalogLat,
      catalogLng: catalogLng,
      catalogDistanceKm: catalogDistanceKm,
      seedTitle: s.title,
      seedLat: s.lat,
      seedLng: s.lng,
      seedDistanceKm: s.distanceKm,
    )) {
      continue;
    }
    final aligned = alignedPlaceTokenCount(catalogName, s.title);
    final gap = _haversineKm(catalogLat, catalogLng, s.lat, s.lng);
    if (aligned > bestAligned || (aligned == bestAligned && gap < bestGap)) {
      bestAligned = aligned;
      bestGap = gap;
      best = (trackLngLat: s.trackLngLat, lat: s.lat, lng: s.lng);
    }
  }
  return best;
}

/// Prepend a street approach onto the remaining tour from [joinIndex].
({List<List<double>> coordinates, double remainM}) mergeApproachAndTour({
  required List<List<double>> approachLngLat,
  required List<List<double>> tourLngLat,
  required int joinIndex,
}) {
  if (tourLngLat.isEmpty) {
    return (coordinates: List<List<double>>.from(approachLngLat), remainM: 0);
  }
  final idx = joinIndex.clamp(0, tourLngLat.length - 1);
  final remaining = tourLngLat.sublist(idx);
  var remainM = 0.0;
  for (var i = 1; i < remaining.length; i++) {
    remainM += _haversineKm(
          remaining[i - 1][1],
          remaining[i - 1][0],
          remaining[i][1],
          remaining[i][0],
        ) *
        1000;
  }
  return (
    coordinates: [...approachLngLat, ...remaining],
    remainM: remainM,
  );
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// HUD/Plan-Titel: Zielname statt generischem „Geplante Route“.
String plannedRouteHudLabel({
  required String destinationField,
  required String plannedFallback,
  required String suggestEndPlaceholder,
}) {
  final dest = destinationField.trim();
  if (dest.isEmpty || dest == suggestEndPlaceholder) return plannedFallback;
  if (RegExp(r'^-?\d+[.,]\d+').hasMatch(dest)) return plannedFallback;
  return dest;
}
