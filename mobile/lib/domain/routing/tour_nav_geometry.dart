import 'dart:math' as math;

import 'osm_surface_label.dart';
import 'route_progress.dart';
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

/// Pin sofort, Route wie Web erst nach kurzer Ruhe.
const Duration kMapPinRouteCommitDelay = Duration(milliseconds: 450);

/// Join painted endpoints to pins when the engine stopped a few metres off.
const kPlanLinePinJoinMaxM = 35.0;

/// Komoot: the ribbon meets the pin. Never a long crow-flies cut through a field.
List<List<double>> joinPlanLineToPins({
  required List<List<double>> lineLngLat,
  double? startLat,
  double? startLng,
  double? endLat,
  double? endLng,
  double maxJoinM = kPlanLinePinJoinMaxM,
}) {
  if (lineLngLat.length < 2) return lineLngLat;
  final out = [
    for (final p in lineLngLat) <double>[p[0], p[1]]
  ];
  if (startLat != null && startLng != null) {
    final a = out.first;
    final gap = haversineM(startLat, startLng, a[1], a[0]);
    if (gap > 1.5 && gap <= maxJoinM) {
      out[0] = [startLng, startLat];
    }
  }
  if (endLat != null && endLng != null) {
    final b = out.last;
    final gap = haversineM(endLat, endLng, b[1], b[0]);
    if (gap > 1.5 && gap <= maxJoinM) {
      out[out.length - 1] = [endLng, endLat];
    }
  }
  return out;
}

const kPlanStreetSnapMinM = 40.0;
const kPlanStreetSnapMaxM = 1200.0;

bool routeHasFarmTrimWarning(Iterable<String> warnings) {
  for (final w in warnings) {
    if (w.startsWith('Kein Weg bis zum Pin')) return true;
  }
  return false;
}

({double lat, double lng})? snapPlanPinToStreetLine({
  required double pinLat,
  required double pinLng,
  required double streetLat,
  required double streetLng,
  double minM = kPlanStreetSnapMinM,
  double maxM = kPlanStreetSnapMaxM,
}) {
  final d = haversineM(pinLat, pinLng, streetLat, streetLng);
  if (d < minM || d > maxM) return null;
  return (lat: streetLat, lng: streetLng);
}

({
  double startLat,
  double startLng,
  double endLat,
  double endLng,
  bool snappedStart,
  bool snappedEnd,
}) applyFarmTrimPinSnap({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  required List<List<double>> lineLngLat,
  Iterable<String> warnings = const [],
  bool startIsGps = false,
}) {
  if (!routeHasFarmTrimWarning(warnings) || lineLngLat.length < 2) {
    return (
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      snappedStart: false,
      snappedEnd: false,
    );
  }
  final first = lineLngLat.first;
  final last = lineLngLat.last;
  var slat = startLat;
  var slng = startLng;
  var elat = endLat;
  var elng = endLng;
  var snappedStart = false;
  var snappedEnd = false;
  if (!startIsGps) {
    final s = snapPlanPinToStreetLine(
      pinLat: startLat,
      pinLng: startLng,
      streetLat: first[1],
      streetLng: first[0],
    );
    if (s != null) {
      slat = s.lat;
      slng = s.lng;
      snappedStart = true;
    }
  }
  final e = snapPlanPinToStreetLine(
    pinLat: endLat,
    pinLng: endLng,
    streetLat: last[1],
    streetLng: last[0],
  );
  if (e != null) {
    elat = e.lat;
    elng = e.lng;
    snappedEnd = true;
  }
  return (
    startLat: slat,
    startLng: slng,
    endLat: elat,
    endLng: elng,
    snappedStart: snappedStart,
    snappedEnd: snappedEnd,
  );
}

const Duration kPlanLineCoachRetry = Duration(days: 14);

bool planLineCoachShouldShow({
  required Object? stored,
  DateTime? now,
}) {
  if (stored == null) return true;
  if (stored == true || stored == '1') return false;
  final t = stored is num ? stored.toInt() : int.tryParse('$stored');
  if (t == null) return false;
  final at = now ?? DateTime.now();
  return at.millisecondsSinceEpoch - t >= kPlanLineCoachRetry.inMilliseconds;
}

/// Finger-hoch nach Pan/Zoom ist kein Ziel-Tipp.
const Duration kMapTapAfterCameraQuiet = Duration(milliseconds: 280);

/// Doppel-Feuer / Nachzittern direkt nach dem letzten Pin.
const Duration kMapTapAfterPinQuiet = Duration(milliseconds: 350);

/// Pan/zoom finger-up (or in-flight camera) is not a destination tap.
bool mapTapLooksLikeCameraGesture({
  required DateTime now,
  required bool cameraMoving,
  DateTime? cameraMovedAt,
  Duration quiet = kMapTapAfterCameraQuiet,
}) {
  if (cameraMoving) return true;
  if (cameraMovedAt == null) return false;
  return now.difference(cameraMovedAt) < quiet;
}

bool mapTapTooSoonAfterLastPin({
  required DateTime now,
  DateTime? lastPinAt,
  Duration quiet = kMapTapAfterPinQuiet,
}) {
  if (lastPinAt == null) return false;
  return now.difference(lastPinAt) < quiet;
}

/// A/B/Via nur bei echtem Tipp, nicht nach Schieben oder Bounce.
/// Long-press and explicit pick-mode use this. Short browse taps do not.
bool mapTapMayPlaceRoutePin({
  required bool addressFieldFocused,
  required bool startSet,
  required bool endSet,
  required bool explicitlyPicking,
  required bool cameraMoving,
  DateTime? cameraMovedAt,
  DateTime? lastPinAt,
  required DateTime now,
}) {
  if (!mapTapMaySetAbPoint(
    addressFieldFocused: addressFieldFocused,
    startSet: startSet,
    endSet: endSet,
    explicitlyPicking: explicitlyPicking,
  )) {
    return false;
  }
  if (mapTapLooksLikeCameraGesture(
    now: now,
    cameraMoving: cameraMoving,
    cameraMovedAt: cameraMovedAt,
  )) {
    return false;
  }
  if (mapTapTooSoonAfterLastPin(now: now, lastPinAt: lastPinAt)) {
    return false;
  }
  return true;
}

/// Plan editor: the map is the tool. Explore browse stays inspect-only
/// (see [mapShortTapPlacesRoutePin]).
bool mapPlanEditorTapPlacesPin({
  required bool editorActive,
  required bool addressFieldFocused,
  required bool cameraMoving,
  DateTime? cameraMovedAt,
  DateTime? lastPinAt,
  required DateTime now,
  bool placingVia = false,
}) {
  if (!editorActive) return false;
  if (addressFieldFocused && !placingVia) return false;
  if (mapTapLooksLikeCameraGesture(
    now: now,
    cameraMoving: cameraMoving,
    cameraMovedAt: cameraMovedAt,
  )) {
    return false;
  }
  if (placingVia) return true;
  return !mapTapTooSoonAfterLastPin(now: now, lastPinAt: lastPinAt);
}

/// Short tap commits a routing pin only in explicit pick mode
/// („Start auf Karte“ / „Ziel auf Karte“). Browse and an open plan
/// sheet without pick mode stay inspect/select — Komoot/Google.
bool mapShortTapPlacesRoutePin({
  required bool explicitlyPicking,
  required bool planSurface,
  required bool addressFieldFocused,
  required bool startSet,
  required bool endSet,
  required bool cameraMoving,
  DateTime? cameraMovedAt,
  DateTime? lastPinAt,
  required DateTime now,
}) {
  if (!explicitlyPicking || !planSurface) return false;
  return mapTapMayPlaceRoutePin(
    addressFieldFocused: addressFieldFocused,
    startSet: startSet,
    endSet: endSet,
    explicitlyPicking: true,
    cameraMoving: cameraMoving,
    cameraMovedAt: cameraMovedAt,
    lastPinAt: lastPinAt,
    now: now,
  );
}

/// Seed / catalog preview on Discover — not a live A→B the rider just asked for.
bool isTourPreviewLine(String? engine) {
  final e = (engine ?? '').toLowerCase();
  if (e.isEmpty) return false;
  return e == 'seed-loop' ||
      e == 'seed-loop-routed' ||
      e == 'tour-routed' ||
      e == 'tour-adopt' ||
      e == 'tour-pin' ||
      e == 'tour-track' ||
      e == 'tour' ||
      e == 'osm-trail' ||
      e == 'osm-trail-last-mile' ||
      e.endsWith('+tour') ||
      e.contains('seed-loop');
}

/// A new routing pin after a tour preview must drop that leftover line.
/// Also when start is already set (GPS→tour, then a new destination pin).
bool mapPinClearsTourPreview({
  required String? computedEngine,
  required String? selectedTourId,
}) {
  if (selectedTourId != null && selectedTourId.isNotEmpty) return true;
  return isTourPreviewLine(computedEngine);
}

/// Tour leftover vanishes immediately (half-old-tour bug).
/// Live street A–B stays until the engine returns (Komoot / AllTrails).
bool mapPinClearsLeftoverRoute({
  required String? computedEngine,
  required String? selectedTourId,
  required bool hasComputedLine,
}) {
  final _ = hasComputedLine;
  return mapPinClearsTourPreview(
    computedEngine: computedEngine,
    selectedTourId: selectedTourId,
  );
}

/// Hit slop for tapping the painted A–B ribbon (Komoot / AllTrails).
const double kDiscoverRouteTapMaxM = 64;

bool isAdoptedTourLine(String? engine) =>
    (engine ?? '').toLowerCase() == 'tour-adopt';

/// Live A–B or an adopted catalog track the rider is customizing.
bool isPlanCustomizableLine({
  required String? engine,
  required int coordinateCount,
}) {
  if (coordinateCount < 2) return false;
  if (isAdoptedTourLine(engine)) return true;
  return !isTourPreviewLine(engine);
}

bool isLiveStreetDiscoverLine({
  required String? engine,
  required int coordinateCount,
}) =>
    isPlanCustomizableLine(engine: engine, coordinateCount: coordinateCount);

/// Catalog leftover wipes on the first dest pin — not after A+B in the editor.
bool planLeftoverTourWipesOnTap({
  required bool leftover,
  required bool hasStart,
  required bool hasEnd,
  bool pickingVia = false,
}) {
  if (!leftover || pickingVia) return false;
  if (hasStart && hasEnd) return false;
  return true;
}

/// Orange last-mile overlay is the current dest. Via / reshape drops it
/// so a leftover trail does not sit on the new street line.
bool planPaintsTrailLastMileOverlay({
  required bool hasVias,
  required bool reshaping,
}) =>
    !hasVias && !reshaping;

/// While the engine is in flight, far taps stay vias — dest only via pick/hold.
bool planBusyBlocksDestReplace({
  required bool routingBusy,
  required bool hasStart,
  required bool hasEnd,
  bool pickingStart = false,
  bool pickingEnd = false,
  bool forceEnd = false,
}) {
  if (!routingBusy || forceEnd || pickingStart || pickingEnd) return false;
  return hasStart && hasEnd;
}

/// Tap/drag the painted route inserts a via. Empty-map long-press stays dest.
bool shouldInsertViaOnDiscoverRouteTap({
  required bool hasStart,
  required bool hasEnd,
  required bool hasLiveStreetLine,
  required bool leftoverTourOnMap,
  bool pickingStart = false,
}) {
  if (pickingStart) return false;
  if (!hasStart || !hasEnd) return false;
  if (!hasLiveStreetLine) return false;
  if (leftoverTourOnMap) return false;
  return true;
}

/// Keep the last honest street line while a reshape is in flight.
bool shouldKeepStaleDiscoverLine({
  required bool hasLiveStreetLine,
  required bool leftoverTourOnMap,
}) =>
    hasLiveStreetLine && !leftoverTourOnMap;

bool tapHitsDiscoverRouteLine({
  required List<List<double>> coordinates,
  required double tapLat,
  required double tapLng,
  double maxM = kDiscoverRouteTapMaxM,
}) {
  if (coordinates.length < 2) return false;
  final p = projectOntoRoute(
    coordinates: coordinates,
    lat: tapLat,
    lng: tapLng,
  );
  return p.crossTrackM <= maxM;
}

/// Project the tap onto the painted polyline (via sits on the old line).
({double lat, double lng}) snapTapOntoDiscoverRoute({
  required List<List<double>> coordinates,
  required double tapLat,
  required double tapLng,
}) {
  if (coordinates.length < 2) return (lat: tapLat, lng: tapLng);
  final p = projectOntoRoute(
    coordinates: coordinates,
    lat: tapLat,
    lng: tapLng,
  );
  final pt = pointAlongRoute(coordinates, p.distanceAlongM);
  return (lat: pt[1], lng: pt[0]);
}

/// Catalog/seed ribbons stay off while A–B is the map story.
/// A destination pin hides leftovers immediately — also dest-only
/// (GPS not yet adopted) and after leaving Navigieren with A+B.
bool shouldHideDiscoverTourRibbons({
  required bool navigateMode,
  required bool hasStart,
  required bool hasEnd,
}) {
  if (hasEnd) return true;
  return navigateMode && hasStart;
}

/// Farm-track overlay: hide while Navigieren / loading / GPS→pin ghost.
/// Leftover dest on Explore must not blank the trail net.
bool shouldHideFarmTracksOnBrowse({
  required bool navigateMode,
  required bool loading,
  required bool hasPendingAbHint,
}) =>
    navigateMode || loading || hasPendingAbHint;

/// 3D plates of the selected tour. Catalog ovals can hide in A–B;
/// plates stay on a tour preview/adopt line, never on a rider-asked A–B.
bool shouldShowDiscoverTourPois({
  required bool hideRibbons,
  required bool hasSelectedTour,
  required String? computedEngine,
}) {
  if (!hasSelectedTour) return false;
  if (!hideRibbons) return true;
  return isTourPreviewLine(computedEngine);
}

/// GPS / explicit start — never the panned map center (browse anchor).
({double lat, double lng})? routingOriginPreferGps({
  double? userLat,
  double? userLng,
  double? startLat,
  double? startLng,
}) {
  if (userLat != null && userLng != null) {
    return (lat: userLat, lng: userLng);
  }
  if (startLat != null && startLng != null) {
    return (lat: startLat, lng: startLng);
  }
  return null;
}

/// Pin after viewing a tour: destination, GPS is start.
/// Also when adopt already filled start with the tour’s first point.
bool mapPinAfterTourPreviewIsDestination({
  required bool tourPreviewOnMap,
  required bool hasGps,
}) =>
    tourPreviewOnMap && hasGps;

/// Browse long-press is destination. Via only via „Via auf Karte“.
bool mapLongPressAddsVia({required bool explicitlyPickingVia}) =>
    explicitlyPickingVia;

/// Browse long-press / new pin: destination, never a start in a field.
/// Start is GPS when we have a fix — otherwise dest only until GPS arrives.
/// After a leftover tour or A–B line, reset A to GPS so the old start
/// does not keep the line in the previous tour.
/// A second pin after A+B replaces B. Via only via „Via auf Karte“.
bool mapPinIsGpsDestination({
  required bool tourPreviewOnMap,
  required bool hasGps,
  required bool startSet,
  required bool endSet,
  required bool pickingStart,
  bool leftoverRoute = false,
}) {
  if (pickingStart) return false;
  final _ = (tourPreviewOnMap, hasGps, startSet, endSet, leftoverRoute);
  return true;
}

/// Status after a browse dest pin — never „Start gesetzt“ for a field pin.
enum DiscoverBrowsePinCue { computing, waitingGpsForStart, pickStart }

DiscoverBrowsePinCue discoverBrowsePinCue({
  required bool hasStart,
  required bool hasEnd,
  required bool hasGps,
}) {
  if (hasStart && hasEnd) return DiscoverBrowsePinCue.computing;
  if (hasEnd && !hasStart) return DiscoverBrowsePinCue.waitingGpsForStart;
  if (hasStart && !hasEnd) return DiscoverBrowsePinCue.pickStart;
  return hasGps
      ? DiscoverBrowsePinCue.computing
      : DiscoverBrowsePinCue.waitingGpsForStart;
}

/// GPS→pin without a live street line — hide farm tracks, never paint crow-flies.
bool waitingForLiveDiscoverAb({
  required bool hasFrom,
  required bool hasEnd,
  required bool hasLiveLine,
}) =>
    hasFrom && hasEnd && !hasLiveLine;

/// Crow-flies through fields looks like the route. Do not paint it.
bool shouldPaintPendingAbHint({
  required bool hasFrom,
  required bool hasEnd,
  required bool hasLiveLine,
}) {
  if (!waitingForLiveDiscoverAb(
    hasFrom: hasFrom,
    hasEnd: hasEnd,
    hasLiveLine: hasLiveLine,
  )) {
    return false;
  }
  return false;
}

/// km/min/hm only after a real street line — not a 2-point ghost.
bool shouldShowLiveRouteStats({
  required bool hasLiveLine,
  required String? engine,
  required int coordinateCount,
}) {
  if (!hasLiveLine || coordinateCount < 3) return false;
  final e = (engine ?? '').toLowerCase();
  if (e.contains('fallback') || e.contains('approx') || e.contains('demo')) {
    return false;
  }
  return !isTourPreviewLine(engine);
}

/// Pin-only „Route berechnen“: A→B from GPS/start to the pin.
/// Never invent a geometric destination in a field NE of the pin.
({double startLat, double startLng, double endLat, double endLng})?
    pinOnlyAbEndpoints({
  required double pinLat,
  required double pinLng,
  double? startLat,
  double? startLng,
  double? userLat,
  double? userLng,
  bool preferGps = false,
}) {
  final sLat = preferGps ? (userLat ?? startLat) : (startLat ?? userLat);
  final sLng = preferGps ? (userLng ?? startLng) : (startLng ?? userLng);
  if (sLat == null || sLng == null) return null;
  return (
    startLat: sLat,
    startLng: sLng,
    endLat: pinLat,
    endLng: pinLng,
  );
}

/// A–B plan: live ORS/GraphHopper with net. Pack Dijkstra without net
/// (A–B or via-leg chain on the covering pack).
///
/// With net, the client may still Dijkstra *after* ORS fails — if a pack
/// on disk covers the trip. Alps + Schwarzwald must not sneak in first.
({
  bool preferOffline,
  bool allowOfflineFirst,
  bool allowOnline,
  bool allowOfflineFallback,
}) discoverAbEngineChoice({
  required bool online,
  bool viasEmpty = true,
}) {
  final graph = !online;
  return (
    preferOffline: graph,
    allowOfflineFirst: graph,
    allowOnline: online,
    allowOfflineFallback: true,
  );
}

/// Discover browse pin A–B: streets from the live engine only.
/// Pack Dijkstra draws field-scale lines and must not run — also not
/// after a live fail. Offline → fail honestly, no graph fallback.
({
  bool preferOffline,
  bool allowOfflineFirst,
  bool allowOnline,
  bool allowOfflineFallback,
}) discoverBrowseAbEngineChoice({required bool online}) {
  return (
    preferOffline: false,
    allowOfflineFirst: false,
    allowOnline: online,
    allowOfflineFallback: false,
  );
}

/// Explore long-press pin stays live streets. Planned Navigieren (CTA,
/// vias, drag, line tap) uses [discoverAbEngineChoice].
bool planCalcUsesLiveStreetsOnly({
  required bool fromBrowsePin,
  required bool viasEmpty,
}) =>
    fromBrowsePin && viasEmpty;

/// Komoot/AllTrails: tap the computed ribbon to drop a stop — not empty map.
bool planLineTapInsertsVia({
  required bool editorActive,
  required bool hasStart,
  required bool hasEnd,
  required bool hasLiveLine,
  required bool pickingStartOrEnd,
}) {
  if (!editorActive || !hasStart || !hasEnd) return false;
  if (!hasLiveLine) return false;
  return !pickingStartOrEnd;
}

/// Finger radius in metres — tighter when zoomed in.
double plannedRouteTapRadiusM(double zoom) {
  final z = zoom.clamp(9.0, 18.0);
  return (140 * math.pow(2, 14 - z)).toDouble().clamp(64.0, 420.0);
}

/// Snap a map tap onto the live line when it is close enough.
({double lat, double lng, double alongM})? plannedRouteTapSnap({
  required List<List<double>> lineLngLat,
  required double tapLat,
  required double tapLng,
  required double maxOffsetM,
}) {
  if (lineLngLat.length < 2) return null;
  final p = projectOntoRoute(
    coordinates: lineLngLat,
    lat: tapLat,
    lng: tapLng,
  );
  if (!p.crossTrackM.isFinite || p.crossTrackM > maxOffsetM) return null;
  final pt = pointAlongRoute(lineLngLat, p.distanceAlongM);
  return (lat: pt[1], lng: pt[0], alongM: p.distanceAlongM);
}

bool plannedRouteViaIsDuplicate({
  required Iterable<({double lat, double lng})> vias,
  required double lat,
  required double lng,
  double minSeparationM = 40,
}) {
  for (final v in vias) {
    if (haversineM(v.lat, v.lng, lat, lng) < minSeparationM) return true;
  }
  return false;
}

/// Drag preview: km already along the live line.
String planDragAlongLabelKm(double alongM) {
  if (!alongM.isFinite || alongM <= 0) return '0';
  final km = alongM / 1000;
  if (km < 0.1) return '0';
  if (km < 10) return km.toStringAsFixed(1);
  return km.round().toString();
}

List<List<double>> _planRubberKeepSlice(
  List<List<double>> lineLngLat,
  double fromM,
  double toM,
) {
  if (lineLngLat.length < 2) return const [];
  return planLineSlice(lineLngLat, fromM, toM);
}

List<List<double>> _planRubberJoin({
  required List<List<double>> keep,
  required List<double> fallback,
  required List<double> finger,
  required List<List<double>> tail,
  required List<double> tailFallback,
}) {
  return [
    if (keep.length >= 2) ...keep else fallback,
    finger,
    if (tail.length >= 2) ...tail else tailFallback,
  ];
}

/// Komoot rubber-band: geometry before the previous anchor and after the next
/// stays on the live line. Only the edited span is a straight ghost through
/// the finger. [syncPendingAbOverlay] paints it.
List<List<double>> planRubberBandLngLat({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  required Iterable<({double lat, double lng})> vias,
  required double fingerLat,
  required double fingerLng,
  required List<List<double>> lineLngLat,
  bool draggingStart = false,
  bool draggingEnd = false,
  int? draggingViaIndex,
}) {
  final stops = vias.toList();
  final lineLen = lineLngLat.length >= 2 ? routeLengthM(lineLngLat) : 0.0;
  if (draggingStart) {
    final next = stops.isNotEmpty ? stops.first : (lat: endLat, lng: endLng);
    if (lineLen > 4) {
      final nextAlong = projectOntoRoute(
        coordinates: lineLngLat,
        lat: next.lat,
        lng: next.lng,
      ).distanceAlongM;
      final tail = _planRubberKeepSlice(lineLngLat, nextAlong, lineLen);
      return [
        [fingerLng, fingerLat],
        if (tail.length >= 2) ...tail else [next.lng, next.lat],
      ];
    }
    return [
      [fingerLng, fingerLat],
      [next.lng, next.lat],
    ];
  }
  if (draggingEnd) {
    final prev = stops.isNotEmpty ? stops.last : (lat: startLat, lng: startLng);
    if (lineLen > 4) {
      final prevAlong = projectOntoRoute(
        coordinates: lineLngLat,
        lat: prev.lat,
        lng: prev.lng,
      ).distanceAlongM;
      final head = _planRubberKeepSlice(lineLngLat, 0, prevAlong);
      return [
        if (head.length >= 2) ...head else [prev.lng, prev.lat],
        [fingerLng, fingerLat],
      ];
    }
    return [
      [prev.lng, prev.lat],
      [fingerLng, fingerLat],
    ];
  }
  var prev = (lat: startLat, lng: startLng);
  var next = (lat: endLat, lng: endLng);
  var prevAlong = 0.0;
  var nextAlong = lineLen > 0 ? lineLen : double.infinity;
  if (lineLngLat.length >= 2) {
    final along = projectOntoRoute(
      coordinates: lineLngLat,
      lat: fingerLat,
      lng: fingerLng,
    ).distanceAlongM;
    for (var i = 0; i < stops.length; i++) {
      if (draggingViaIndex != null && i == draggingViaIndex) continue;
      final v = stops[i];
      final a = projectOntoRoute(
        coordinates: lineLngLat,
        lat: v.lat,
        lng: v.lng,
      ).distanceAlongM;
      if (a <= along && a >= prevAlong) {
        prevAlong = a;
        prev = v;
      } else if (a > along && a < nextAlong) {
        nextAlong = a;
        next = v;
      }
    }
  } else if (draggingViaIndex != null &&
      draggingViaIndex >= 0 &&
      draggingViaIndex < stops.length) {
    prev = draggingViaIndex == 0
        ? (lat: startLat, lng: startLng)
        : stops[draggingViaIndex - 1];
    next = draggingViaIndex == stops.length - 1
        ? (lat: endLat, lng: endLng)
        : stops[draggingViaIndex + 1];
  }
  if (lineLen > 4) {
    final cap = nextAlong.isFinite ? math.min(nextAlong, lineLen) : lineLen;
    return _planRubberJoin(
      keep: _planRubberKeepSlice(lineLngLat, 0, prevAlong),
      fallback: [prev.lng, prev.lat],
      finger: [fingerLng, fingerLat],
      tail: _planRubberKeepSlice(lineLngLat, cap, lineLen),
      tailFallback: [next.lng, next.lat],
    );
  }
  return [
    [prev.lng, prev.lat],
    [fingerLng, fingerLat],
    [next.lng, next.lat],
  ];
}

/// Navigieren-Sheet or plan surface — Explore leftover A–B stays inspect-only.
bool planEditorIsActive({
  required bool navigateMode,
  required bool planSurface,
}) =>
    navigateMode || planSurface;

/// While the rubber-band is up, the editor sheet recedes so the map is the editor.
double planEditorSheetHeightFraction({
  required bool shaping,
  required bool ideaPin,
}) {
  if (shaping) return 0;
  return ideaPin ? 0.58 : 0.52;
}

/// Floor for the plan panel clamp. Zero while shaping so 0-fraction is not
/// forced back up to 220 px.
double planEditorSheetMinPx({required bool shaping}) => shaping ? 0 : 220;

/// Rubber-band *and* the following recalc: map stays the editor.
bool planEditorSheetRecedes({
  required bool rubberBand,
  required bool adapting,
}) =>
    rubberBand || adapting;

/// Brief “stop set” chip at the new via — not while waiting/reshaping.
bool planMapStopHintVisible({
  required bool hasStopAt,
  required bool waitHintOnMap,
  required bool rubberBand,
}) =>
    hasStopAt && !waitHintOnMap && !rubberBand;

const Duration kPlanStopHint = Duration(milliseconds: 3200);

const double kPlanMapChromeFabColPx = 56;

const double kPlanFingerHintBelowGap = 16;
const double kPlanFingerHintAboveGap = 12;
const double kPlanFingerHintPad = 8;

/// Place the adapting chip near the finger without covering locate/undo.
({double left, double top}) planFingerHintPlacement({
  required double fingerX,
  required double fingerY,
  required double mapW,
  required double mapH,
  required double chipW,
  required double chipH,
  double avoidRight = 0,
  double avoidTop = 0,
  double avoidBottom = 0,
  double pad = kPlanFingerHintPad,
  bool preferAbove = false,
}) {
  final minLeft = pad;
  final maxLeft = math.max(minLeft, mapW - chipW - pad - avoidRight);
  final left = (fingerX - chipW / 2).clamp(minLeft, maxLeft);
  final minTop = pad + avoidTop;
  final maxTop = math.max(minTop, mapH - chipH - pad - avoidBottom);
  final below = fingerY + kPlanFingerHintBelowGap;
  final above = fingerY - chipH - kPlanFingerHintAboveGap;
  var top = preferAbove ? above : below;
  if (!preferAbove && top + chipH > mapH - pad - avoidBottom) {
    top = above;
  } else if (preferAbove && top < minTop) {
    top = below;
  }
  if (maxTop < minTop) {
    return (left: left, top: minTop);
  }
  return (left: left, top: top.clamp(minTop, maxTop));
}

/// Dest pin in the editor keeps start + vias (Komoot). Browse leftover
/// tour still starts a fresh GPS→pin A–B.
bool planDestPinKeepsSession({
  required bool editorActive,
  required bool startSet,
  required bool leftoverTour,
  required bool pickingStart,
}) {
  if (!editorActive || pickingStart || leftoverTour) return false;
  return startSet;
}

/// Discs stay off until the rider has a stop or dismisses the line coach.
/// Returning users (coach already gone) can drag the ribbon immediately.
bool planReshapeHandlesReady({
  required bool hasVia,
  required bool coachVisible,
}) =>
    hasVia || !coachVisible;

/// Spacing between grab discs — denser when zoomed in (Komoot beads).
double planReshapeHandleStepM({double zoom = 14}) {
  if (zoom >= 16) return 600;
  if (zoom >= 15) return 800;
  if (zoom >= 14) return 1100;
  if (zoom >= 13) return 1800;
  return 2800;
}

int planReshapeHandleMax({double zoom = 14}) {
  if (zoom >= 16) return 10;
  if (zoom >= 15) return 8;
  if (zoom >= 14) return 6;
  return 4;
}

/// Where grab discs sit — every few hundred metres, capped by zoom.
List<double> planReshapeHandleFracs(double lenM, {double zoom = 14}) {
  if (!(lenM > 0)) return const [0.5];
  final step = planReshapeHandleStepM(zoom: zoom);
  final max = planReshapeHandleMax(zoom: zoom);
  final out = <double>[];
  for (var a = step; a < lenM && out.length < max; a += step) {
    out.add(a / lenM);
  }
  return out.isEmpty ? const [0.5] : out;
}

/// Translucent discs on the live ribbon — drag off-path like AllTrails.
List<({double lat, double lng, double alongM})> planReshapeHandles({
  required List<List<double>> lineLngLat,
  required Iterable<({double lat, double lng})> vias,
  int? maxHandles,
  double minFromEndM = 180,
  double minFromViaM = 140,
  Iterable<double> avoidAlongM = const [],
  double avoidM = 160,
  double zoom = 14,
}) {
  final len = routeLengthM(lineLngLat);
  if (len < 280) return const [];
  final cap = maxHandles ?? planReshapeHandleMax(zoom: zoom);
  final fracs = planReshapeHandleFracs(len, zoom: zoom);
  final out = <({double lat, double lng, double alongM})>[];
  for (final f in fracs) {
    if (out.length >= cap) break;
    final along = len * f;
    if (along < minFromEndM || (len - along) < minFromEndM) continue;
    var blocked = false;
    for (final a in avoidAlongM) {
      if ((a - along).abs() < avoidM) {
        blocked = true;
        break;
      }
    }
    if (blocked) continue;
    final pt = pointAlongRoute(lineLngLat, along);
    final lat = pt[1];
    final lng = pt[0];
    var nearVia = false;
    for (final v in vias) {
      if (haversineM(v.lat, v.lng, lat, lng) < minFromViaM) {
        nearVia = true;
        break;
      }
    }
    if (nearVia) continue;
    out.add((lat: lat, lng: lng, alongM: along));
  }
  if (out.isEmpty && len >= 280) {
    final along = len * 0.5;
    final pt = pointAlongRoute(lineLngLat, along);
    final lat = pt[1];
    final lng = pt[0];
    var nearVia = false;
    for (final v in vias) {
      if (haversineM(v.lat, v.lng, lat, lng) < minFromViaM) {
        nearVia = true;
        break;
      }
    }
    if (!nearVia) {
      out.add((lat: lat, lng: lng, alongM: along));
    }
  }
  return out;
}

/// Long tours keep km-ticks for a closer zoom so the overview stays clean.
double planDistanceTicksMinZoom(double distanceM) =>
    distanceM >= 25000 ? 13 : 12;

/// km-Ticks erst lokal (Komoot: Distanz auf der Linie, nicht in der Übersicht).
bool planDistanceTicksVisible(double zoom, {double minZoom = 12}) =>
    zoom >= minZoom;

/// Spacing for km ticks: denser only when zoomed in (Komoot).
double planDistanceTickStepM(double zoom) {
  if (zoom >= 16) return 1000;
  if (zoom >= 14.5) return 2000;
  if (zoom >= 13) return 2500;
  return 5000;
}

int planDistanceTickMax(double zoom) {
  if (zoom >= 16) return 10;
  if (zoom >= 14.5) return 8;
  if (zoom >= 13) return 6;
  return 4;
}

/// Along-metres of pins on the live line — keep ticks off vias / handles.
List<double> planPinAlongMeters({
  required List<List<double>> lineLngLat,
  required Iterable<({double lat, double lng})> pins,
}) {
  if (lineLngLat.length < 2) return const [];
  return [
    for (final p in pins)
      projectOntoRoute(
        coordinates: lineLngLat,
        lat: p.lat,
        lng: p.lng,
      ).distanceAlongM,
  ];
}

/// Named via under the number. Skip generic “on map” / “Stop 1” placeholders.
String? planViaMapCaption(
  String? label, {
  Iterable<String> placeholders = const [],
}) {
  final t = label?.trim() ?? '';
  if (t.isEmpty) return null;
  final lower = t.toLowerCase();
  for (final p in placeholders) {
    final q = p.trim().toLowerCase();
    if (q.isNotEmpty && lower == q) return null;
  }
  if (RegExp(
    r'^(punkt auf der karte|point on the map|point sur la carte|'
    r'punto sulla mappa|punt op de kaart)$',
    caseSensitive: false,
  ).hasMatch(t)) {
    return null;
  }
  if (RegExp(
    r'^(zwischenstopp|stopp|stop|via|waypoint)\s*\d*$',
    caseSensitive: false,
  ).hasMatch(t)) {
    return null;
  }
  if (RegExp(r'^\d{1,2}$').hasMatch(t)) return null;
  if (t.length > 22) return '${t.substring(0, 20)}…';
  return t;
}

double planChevronStepM(double zoom) {
  if (zoom >= 16.5) return 220;
  if (zoom >= 15.5) return 320;
  if (zoom >= 14.5) return 480;
  if (zoom >= 13.5) return 700;
  return 1100;
}

int planChevronMax(double zoom) {
  if (zoom >= 16.5) return 24;
  if (zoom >= 15.5) return 20;
  if (zoom >= 14.5) return 16;
  return 12;
}

/// Bearing of the segment at [alongM], degrees clockwise from north.
double planBearingDegAt(List<List<double>> lineLngLat, double alongM) {
  if (lineLngLat.length < 2) return 0;
  final a = pointAlongRoute(lineLngLat, alongM);
  final b = pointAlongRoute(lineLngLat, alongM + 18);
  final lat1 = a[1] * math.pi / 180;
  final lat2 = b[1] * math.pi / 180;
  final dLng = (b[0] - a[0]) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Direction chevrons on the live ribbon (App — Web uses a symbol line layer).
List<({double lat, double lng, double bearingDeg, double alongM})>
    planDirectionChevrons({
  required List<List<double>> lineLngLat,
  double zoom = 14,
  double minZoom = 12,
  int? maxChevrons,
  double minFromEndM = 280,
  Iterable<double> avoidAlongM = const [],
  double avoidM = 140,
}) {
  if (!planDistanceTicksVisible(zoom, minZoom: minZoom)) return const [];
  final step = planChevronStepM(zoom);
  final cap = maxChevrons ?? planChevronMax(zoom);
  final len = routeLengthM(lineLngLat);
  if (len < step + minFromEndM) return const [];
  final out = <({double lat, double lng, double bearingDeg, double alongM})>[];
  var along = step;
  while (along <= len - minFromEndM && out.length < cap) {
    if (along >= minFromEndM) {
      var blocked = false;
      for (final a in avoidAlongM) {
        if ((a - along).abs() < avoidM) {
          blocked = true;
          break;
        }
      }
      if (!blocked) {
        final pt = pointAlongRoute(lineLngLat, along);
        out.add((
          lat: pt[1],
          lng: pt[0],
          bearingDeg: planBearingDegAt(lineLngLat, along),
          alongM: along,
        ));
      }
    }
    along += step;
  }
  return out;
}

/// Sparse km labels on the live ribbon (Komoot distance ticks).
List<({double lat, double lng, String km, double alongM})> planDistanceTicks({
  required List<List<double>> lineLngLat,
  double? everyM,
  int? maxTicks,
  double minFromEndM = 1200,
  Iterable<double> avoidAlongM = const [],
  double avoidM = 180,
  double zoom = 14,
  double minZoom = 12,
}) {
  if (!planDistanceTicksVisible(zoom, minZoom: minZoom)) return const [];
  final step = everyM ?? planDistanceTickStepM(zoom);
  final cap = maxTicks ?? planDistanceTickMax(zoom);
  final len = routeLengthM(lineLngLat);
  if (len < step + minFromEndM) return const [];
  final out = <({double lat, double lng, String km, double alongM})>[];
  var along = step;
  while (along <= len - minFromEndM && out.length < cap) {
    if (along >= minFromEndM) {
      var blocked = false;
      for (final a in avoidAlongM) {
        if ((a - along).abs() < avoidM) {
          blocked = true;
          break;
        }
      }
      if (!blocked) {
        final pt = pointAlongRoute(lineLngLat, along);
        out.add((
          lat: pt[1],
          lng: pt[0],
          km: planDragAlongLabelKm(along),
          alongM: along,
        ));
      }
    }
    along += step;
  }
  return out;
}

/// Komoot Höhenfarbe on the live ribbon (climb heat / descent cool).
enum PlanGradeKind { steepUp, up, roll, down, steepDown }

PlanGradeKind planGradeKind({
  required double fromM,
  required double toM,
  required double distM,
}) {
  if (!(distM > 1)) return PlanGradeKind.roll;
  final pct = ((toM - fromM) / distM) * 100;
  if (pct > 8) return PlanGradeKind.steepUp;
  if (pct > 3) return PlanGradeKind.up;
  if (pct >= -3) return PlanGradeKind.roll;
  if (pct >= -8) return PlanGradeKind.down;
  return PlanGradeKind.steepDown;
}

String planGradeColorHex(PlanGradeKind kind) => switch (kind) {
      PlanGradeKind.steepUp => '#C2410C',
      PlanGradeKind.up => '#E85D04',
      PlanGradeKind.roll => '#FF6A00',
      PlanGradeKind.down => '#5B8C9A',
      PlanGradeKind.steepDown => '#3D6B8A',
    };

int planGradeColorArgb(PlanGradeKind kind) => switch (kind) {
      PlanGradeKind.steepUp => 0xFFC2410C,
      PlanGradeKind.up => 0xFFE85D04,
      PlanGradeKind.roll => 0xFFFF6A00,
      PlanGradeKind.down => 0xFF5B8C9A,
      PlanGradeKind.steepDown => 0xFF3D6B8A,
    };

class PlanGradeSlice {
  const PlanGradeSlice({required this.coords, required this.kind});
  final List<List<double>> coords;
  final PlanGradeKind kind;
}

/// Grade between two elevation samples. Matches the web Höhenprofil (>8 %).
bool planElevSegmentSteep({
  required double fromM,
  required double toM,
  required double distM,
  double steepPct = 8,
}) {
  final kind = planGradeKind(fromM: fromM, toM: toM, distM: distM);
  if (steepPct <= 8) {
    return kind == PlanGradeKind.steepUp || kind == PlanGradeKind.steepDown;
  }
  if (!(distM > 1)) return false;
  final grade = ((toM - fromM) / distM) * 100;
  return grade.abs() > steepPct;
}

const _planUnpavedSurfaces = {
  'gravel',
  'fine_gravel',
  'pebblestone',
  'compacted',
  'unpaved',
  'dirt',
  'ground',
  'earth',
  'grass',
  'sand',
  'path',
  'track',
  'trail',
  'wood',
  'woodchips',
  'mud',
  'rock',
  'stones',
};

bool planSurfaceIsUnpaved(String? surface) {
  final s = surface?.trim().toLowerCase() ?? '';
  return _planUnpavedSurfaces.contains(s);
}

OsmSurfaceGroup? planSurfaceKind(String? surface) => osmSurfaceGroup(surface);

/// Same-kind surface bands merge across short unknown OSM gaps.
const kPlanSurfaceMergeGapM = 80.0;

/// Chart / map share one cursor: along-metres → 0..1 on the live line.
double? planElevScrubT({required double alongM, required double lineLenM}) {
  if (!(lineLenM > 0) || !alongM.isFinite) return null;
  return (alongM / lineLenM).clamp(0.0, 1.0);
}

class PlanSurfaceSlice {
  const PlanSurfaceSlice({required this.kind, required this.coords});
  final OsmSurfaceGroup kind;
  final List<List<double>> coords;
}

/// Merge short non-flag gaps so steep bands stay continuous.
void fillShortFlagGaps({
  required List<bool> flags,
  required List<double> along,
  required double mergeGapM,
}) {
  if (!(mergeGapM > 0) || flags.isEmpty || along.length < flags.length + 1) {
    return;
  }
  var i = 0;
  while (i < flags.length) {
    if (!flags[i]) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < flags.length) {
      if (flags[j + 1]) {
        j++;
        continue;
      }
      var g = j + 1;
      var gapM = 0.0;
      while (g < flags.length && !flags[g]) {
        gapM += along[g + 1] - along[g];
        g++;
      }
      if (g < flags.length && flags[g] && gapM <= mergeGapM) {
        for (var k = j + 1; k < g; k++) {
          flags[k] = true;
        }
        j = g;
        continue;
      }
      break;
    }
    i = j + 1;
  }
}

/// Inclusive slice of a polyline between two along-track metres.
List<List<double>> planLineSlice(
  List<List<double>> lineLngLat,
  double fromM,
  double toM,
) {
  if (lineLngLat.length < 2) return const [];
  final lo = math.min(fromM, toM);
  final hi = math.max(fromM, toM);
  if (!(hi > lo + 4)) return const [];
  final rem = sliceRouteAtAlongM(lineLngLat, lo).remaining;
  if (rem.length < 2) {
    return [
      pointAlongRoute(lineLngLat, lo),
      pointAlongRoute(lineLngLat, hi),
    ];
  }
  final take = (hi - lo).clamp(0.0, routeLengthM(rem));
  final traveled = sliceRouteAtAlongM(rem, take).traveled;
  if (traveled.length >= 2) return traveled;
  return [rem.first, pointAlongRoute(rem, take)];
}

double _elevAlongSamples(
  List<double> elevM,
  double alongM,
  double lineLenM,
  List<double>? distKm,
) {
  if (elevM.length < 2 || !(lineLenM > 0)) return elevM.first;
  if (distKm != null && distKm.length == elevM.length && distKm.last > 0) {
    final km = (alongM / 1000).clamp(0.0, distKm.last);
    for (var i = 1; i < distKm.length; i++) {
      if (km <= distKm[i]) {
        final span = distKm[i] - distKm[i - 1];
        final f = span < 1e-6 ? 1.0 : (km - distKm[i - 1]) / span;
        return elevM[i - 1] * (1 - f) + elevM[i] * f;
      }
    }
    return elevM.last;
  }
  final t = (alongM / lineLenM).clamp(0.0, 1.0);
  final x = t * (elevM.length - 1);
  final i = x.floor().clamp(0, elevM.length - 2);
  final f = x - i;
  return elevM[i] * (1 - f) + elevM[i + 1] * f;
}

/// Full-line grade coloring (Komoot Höhenfarbe). Consecutive same-kind
/// segments merge so MapLibre stays at a handful of polylines.
List<PlanGradeSlice> planGradeLineSlices({
  required List<List<double>> lineLngLat,
  required List<double> elevM,
  List<double>? distKm,
  double minSegM = 18,
  int maxSlices = 28,
}) {
  if (lineLngLat.length < 2 || elevM.length < 2) return const [];
  final n = lineLngLat.length;
  final along = List<double>.filled(n, 0);
  for (var i = 1; i < n; i++) {
    along[i] = along[i - 1] +
        haversineM(
          lineLngLat[i - 1][1],
          lineLngLat[i - 1][0],
          lineLngLat[i][1],
          lineLngLat[i][0],
        );
  }
  final len = along.last;
  if (len < minSegM * 2) return const [];

  double elevAtAlong(double m) => _elevAlongSamples(elevM, m, len, distKm);

  final kinds = <PlanGradeKind>[];
  for (var i = 1; i < n; i++) {
    final dist = along[i] - along[i - 1];
    if (dist < minSegM) {
      kinds.add(kinds.isEmpty ? PlanGradeKind.roll : kinds.last);
      continue;
    }
    kinds.add(
      planGradeKind(
        fromM: elevAtAlong(along[i - 1]),
        toM: elevAtAlong(along[i]),
        distM: dist,
      ),
    );
  }

  var slices = <PlanGradeSlice>[];
  List<List<double>>? cur;
  PlanGradeKind? curKind;
  for (var i = 0; i < kinds.length; i++) {
    final k = kinds[i];
    if (cur == null || curKind != k) {
      if (cur != null && curKind != null) {
        slices.add(PlanGradeSlice(coords: cur, kind: curKind));
      }
      cur = [lineLngLat[i], lineLngLat[i + 1]];
      curKind = k;
    } else {
      cur.add(lineLngLat[i + 1]);
    }
  }
  if (cur != null && curKind != null) {
    slices.add(PlanGradeSlice(coords: cur, kind: curKind));
  }
  while (slices.length > maxSlices && slices.length >= 2) {
    var shortest = 0;
    var shortestLen = routeLengthM(slices.first.coords);
    for (var i = 1; i < slices.length; i++) {
      final l = routeLengthM(slices[i].coords);
      if (l < shortestLen) {
        shortestLen = l;
        shortest = i;
      }
    }
    final into = shortest == 0 ? 1 : shortest - 1;
    final keep = slices[into];
    final drop = slices[shortest];
    final mergedCoords = shortest < into
        ? [...drop.coords, ...keep.coords.skip(1)]
        : [...keep.coords, ...drop.coords.skip(1)];
    final merged = PlanGradeSlice(coords: mergedCoords, kind: keep.kind);
    final next = <PlanGradeSlice>[];
    for (var i = 0; i < slices.length; i++) {
      if (i == shortest || i == into) continue;
      next.add(slices[i]);
    }
    final insertAt = math.min(shortest, into).clamp(0, next.length);
    next.insert(insertAt, merged);
    slices = next;
  }
  return slices;
}

/// Steep climbs/descents as merged polylines for the live map ribbon.
/// Elevation samples are stretched along the line (Komoot Höhenfarbe).
List<List<List<double>>> planSteepLineSlices({
  required List<List<double>> lineLngLat,
  required List<double> elevM,
  List<double>? distKm,
  double steepPct = 8,
  double minSegM = 50,
  double mergeGapM = 80,
  int maxSlices = 18,
}) {
  if (lineLngLat.length < 2 || elevM.length < 2) return const [];
  final n = lineLngLat.length;
  final along = List<double>.filled(n, 0);
  for (var i = 1; i < n; i++) {
    along[i] = along[i - 1] +
        haversineM(
          lineLngLat[i - 1][1],
          lineLngLat[i - 1][0],
          lineLngLat[i][1],
          lineLngLat[i][0],
        );
  }
  final len = along.last;
  if (len < minSegM * 2) return const [];
  final steep = <bool>[];
  for (var i = 1; i < n; i++) {
    final dist = along[i] - along[i - 1];
    if (dist < minSegM) {
      steep.add(steep.isEmpty ? false : steep.last);
      continue;
    }
    steep.add(
      planElevSegmentSteep(
        fromM: _elevAlongSamples(elevM, along[i - 1], len, distKm),
        toM: _elevAlongSamples(elevM, along[i], len, distKm),
        distM: dist,
        steepPct: steepPct,
      ),
    );
  }
  fillShortFlagGaps(flags: steep, along: along, mergeGapM: mergeGapM);
  final slices = <List<List<double>>>[];
  List<List<double>>? cur;
  for (var i = 0; i < steep.length; i++) {
    if (!steep[i]) {
      if (cur != null) {
        slices.add(cur);
        cur = null;
      }
      continue;
    }
    if (cur == null) {
      cur = [lineLngLat[i], lineLngLat[i + 1]];
    } else {
      cur.add(lineLngLat[i + 1]);
    }
  }
  if (cur != null) slices.add(cur);
  if (slices.length <= maxSlices) return slices;
  final ranked = [...slices]
    ..sort((a, b) => routeLengthM(b).compareTo(routeLengthM(a)));
  return ranked.take(maxSlices).toList();
}

/// Whole-ribbon surface tint — asphalt / gravel / trail.
List<PlanSurfaceSlice> planSurfaceLineSlices({
  required List<List<double>> lineLngLat,
  required List<({double fromKm, double toKm, String? surface})> bands,
  double minSegM = 50,
  int maxSlices = 24,
  double mergeGapM = kPlanSurfaceMergeGapM,
}) {
  final merged = <({OsmSurfaceGroup kind, double fromM, double toM})>[];
  final sorted = [...bands]..sort((a, b) => a.fromKm.compareTo(b.fromKm));
  for (final b in sorted) {
    final kind = planSurfaceKind(b.surface);
    if (kind == null) continue;
    final fromM = b.fromKm * 1000;
    final toM = b.toKm * 1000;
    if (!(toM - fromM >= minSegM)) continue;
    if (merged.isNotEmpty &&
        merged.last.kind == kind &&
        fromM <= merged.last.toM + mergeGapM) {
      final last = merged.removeLast();
      merged.add((
        kind: last.kind,
        fromM: last.fromM,
        toM: math.max(last.toM, toM),
      ));
    } else {
      merged.add((kind: kind, fromM: fromM, toM: toM));
    }
  }
  final out = <PlanSurfaceSlice>[];
  for (final m in merged) {
    final slice = planLineSlice(lineLngLat, m.fromM, m.toM);
    if (slice.length >= 2) {
      out.add(PlanSurfaceSlice(kind: m.kind, coords: slice));
    }
  }
  if (out.length <= maxSlices) return out;
  final ranked = [...out]..sort(
      (a, b) => routeLengthM(b.coords).compareTo(routeLengthM(a.coords)),
    );
  return ranked.take(maxSlices).toList();
}

/// Unpaved / gravel stretches on the live ribbon (AllTrails surface tint).
List<List<List<double>>> planUnpavedLineSlices({
  required List<List<double>> lineLngLat,
  required List<({double fromKm, double toKm, String? surface})> bands,
  int maxSlices = 18,
}) {
  return [
    for (final s in planSurfaceLineSlices(
      lineLngLat: lineLngLat,
      bands: bands,
      maxSlices: maxSlices,
    ))
      if (s.kind == OsmSurfaceGroup.gravel || s.kind == OsmSurfaceGroup.trail)
        s.coords,
  ];
}

/// Browse style poll. Plan uses [kPlanOnlineProbeTtl] so airplane-mode
/// after a cached-online flag does not wait the full ORS timeout.
const kBrowseOnlineProbeTtl = Duration(seconds: 12);
const kPlanOnlineProbeTtl = Duration(seconds: 4);

/// Trust a recent *online* probe so plan skips DNS. A cached *offline*
/// must not skip ORS — that plus pack Dijkstra draws field lines.
bool trustCachedOnlineProbe({
  required bool cachedOnline,
  required DateTime? cachedAt,
  DateTime? now,
  Duration ttl = kBrowseOnlineProbeTtl,
}) {
  if (!cachedOnline || cachedAt == null) return false;
  return (now ?? DateTime.now()).difference(cachedAt) < ttl;
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

/// Remembered Navigieren dest — restore only if still near GPS/viewport.
const kLastPlanDestMaxKm = 80.0;

bool lastPlanDestWorthRemembering({
  required double destLat,
  required double destLng,
  double? originLat,
  double? originLng,
}) {
  if (destLat.abs() > 90 || destLng.abs() > 180) return false;
  if (originLat == null || originLng == null) return true;
  return _haversineKm(destLat, destLng, originLat, originLng) >= 0.04;
}

bool lastPlanDestIsNearby({
  required double destLat,
  required double destLng,
  double? gpsLat,
  double? gpsLng,
  double? viewLat,
  double? viewLng,
  double maxKm = kLastPlanDestMaxKm,
}) {
  if (destLat.abs() > 90 || destLng.abs() > 180) return false;
  bool near(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    final km = _haversineKm(destLat, destLng, lat, lng);
    return km >= 0.04 && km <= maxKm;
  }

  final gpsNear = near(gpsLat, gpsLng);
  final viewNear = near(viewLat, viewLng);
  if (gpsLat != null &&
      gpsLng != null &&
      viewLat != null &&
      viewLng != null &&
      _haversineKm(gpsLat, gpsLng, viewLat, viewLng) > 40) {
    return viewNear;
  }
  return gpsNear || viewNear;
}

String lastPlanDestChipLabel({
  required String? savedLabel,
  required String generic,
  int maxNameChars = 28,
}) {
  final raw = savedLabel?.trim() ?? '';
  if (raw.isEmpty) return generic;
  if (raw.length <= maxNameChars) return raw;
  return '${raw.substring(0, maxNameChars - 1)}…';
}

bool lastPlanDestCoordsMatch({
  required double aLat,
  required double aLng,
  required double bLat,
  required double bLng,
}) =>
    (aLat - bLat).abs() < 1e-5 && (aLng - bLng).abs() < 1e-5;

/// Chip „Letztes Ziel“ — never auto-restore, only after dest is empty.
bool planLastDestShouldOffer({
  required bool hasEnd,
  required bool nearby,
  required bool dismissed,
}) {
  if (hasEnd || dismissed || !nearby) return false;
  return true;
}

/// Live-ribbon opacity while the rubber-band is up.
/// Whisper-faint so the solid pull reads as the editor, not a second route.
double planRibbonDimOpacity(double base, {required bool dimmed}) {
  if (!dimmed) return base.clamp(0.0, 1.0);
  return (base * 0.045).clamp(0.028, 0.07);
}

/// Grab discs recede with the ribbon but stay visible as hit targets.
double planGrabHandleOpacity(double base, {required bool dimmed}) {
  if (!dimmed) return base.clamp(0.0, 1.0);
  return (base * 0.28).clamp(0.14, 0.36);
}

/// Compact legend keys from OSM bands + optional steep flag.
/// Unknown OSM (orange core showing through) only when the gap is real, not a 20 m hole.
const kPlanRibbonUnknownMinKm = 0.08;

Set<String> planRibbonLegendKinds({
  Iterable<({double fromKm, double toKm, String? surface})> bands = const [],
  bool hasSteep = false,
  double unknownMinKm = kPlanRibbonUnknownMinKm,
}) {
  final kinds = <String>{};
  var unknownKm = 0.0;
  for (final b in bands) {
    final k = planSurfaceKind(b.surface);
    if (k != null) {
      kinds.add(k.name);
    } else {
      final span = b.toKm - b.fromKm;
      if (span > 0) unknownKm += span;
    }
  }
  if (unknownKm >= unknownMinKm) kinds.add('unknown');
  if (hasSteep) kinds.add('steep');
  return kinds;
}

/// Fat halo under the orange core — MapLibre lines are otherwise too thin to grab.
const kPlanRibbonGrabHaloWidth = 36.0;

/// MapLibre zoom 0 = 256 px world width.
const kPlanMapTileSize = 256.0;

/// Hold on the ribbon → new dest (matches web canvas hold).
const Duration kPlanLineHold = Duration(milliseconds: 450);

/// Finger must move this far before the rubber-band starts (web uses 8 px).
const double kPlanLineGrabMovePx = 8;

/// Any slip past this cancels hold→dest (before exclusive rubber).
const double kPlanLineHoldCancelPx = 6;

/// Second finger = pinch/rotate, not a via. Yield the line grab.
bool planLineGrabYieldsToPinch({required int pointerCount}) =>
    pointerCount >= 2;

/// One finger past the slop becomes an exclusive line pull (map pan off).
bool planLineGrabBecomesExclusive({
  required int pointerCount,
  required double movePx,
  double thresholdPx = kPlanLineGrabMovePx,
}) =>
    pointerCount == 1 && movePx >= thresholdPx;

/// Finger left the “still” zone — do not fire hold→new dest.
bool planLineHoldCancelsOnMove({
  required double movePx,
  double thresholdPx = kPlanLineHoldCancelPx,
}) =>
    movePx >= thresholdPx;

const double kPlanLineCoachCompactHeight = 700;
const double kPlanLineCoachXCompactHeight = 640;

bool planLineCoachIsCompact(double height) =>
    height < kPlanLineCoachCompactHeight;

bool planLineCoachIsXCompact(double height) =>
    height < kPlanLineCoachXCompactHeight;

/// Adopted catalog tour: teach “merken, dann formen”. Short screens: one line.
String planLineCoachCopy({
  required bool adopting,
  required bool compact,
  required String full,
  required String short,
  required String adopt,
}) {
  if (adopting) return adopt;
  return compact ? short : full;
}

const double kPlanRibbonLegendCompactWidth = 420;

bool planRibbonLegendCompact(double width) =>
    width < kPlanRibbonLegendCompactWidth;

const Duration kPlanChevronFresh = Duration(milliseconds: 1400);

double planChevronIconOpacity({
  required bool dimmed,
  required bool fresh,
}) {
  if (dimmed) return 0;
  return fresh ? 0.96 : 0.88;
}

bool planRibbonAllowsGrab({
  required bool editorActive,
  required bool hasLiveStreetLine,
  required bool approx,
}) =>
    editorActive && hasLiveStreetLine && !approx;

double planMapMetersPerPixel({
  required double lat,
  required double zoom,
  double tileSize = kPlanMapTileSize,
}) {
  final z = tileSize * math.pow(2, zoom);
  if (!(z > 0)) return 0;
  return math.cos(lat * math.pi / 180).abs() * 2 * math.pi * 6378137 / z;
}

/// MapLibre default vertical FOV (~36.87°). Pitch uses the same camera.
const kPlanMapFovRad = 0.6435011087932844;

({double lng, double lat})? planMapScreenToLngLat({
  required double localX,
  required double localY,
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  double bearingDeg = 0,
  double tiltDeg = 0,
  double tileSize = kPlanMapTileSize,
}) {
  if (width <= 4 || height <= 4) return null;
  if (tiltDeg.abs() > 1) {
    return _planMapScreenToLngLatPitched(
      localX: localX,
      localY: localY,
      width: width,
      height: height,
      centerLng: centerLng,
      centerLat: centerLat,
      zoom: zoom,
      bearingDeg: bearingDeg,
      tiltDeg: tiltDeg,
      tileSize: tileSize,
    );
  }
  var dx = localX - width / 2;
  var dy = localY - height / 2;
  if (bearingDeg.abs() > 0.01) {
    final rad = -bearingDeg * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    final rdx = dx * c - dy * s;
    final rdy = dx * s + dy * c;
    dx = rdx;
    dy = rdy;
  }
  final world = tileSize * math.pow(2, zoom);
  final cx = (centerLng + 180) / 360 * world;
  final sinLat = math.sin(centerLat.clamp(-85.0, 85.0) * math.pi / 180);
  final cy =
      (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * world;
  final lng = ((cx + dx) / world) * 360 - 180;
  final n = math.pi - 2 * math.pi * (cy + dy) / world;
  final lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  if (!lng.isFinite || !lat.isFinite) return null;
  return (lng: lng, lat: lat.clamp(-85.0, 85.0));
}

({double x, double y})? planMapLngLatToScreen({
  required double lng,
  required double lat,
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  double bearingDeg = 0,
  double tiltDeg = 0,
  double tileSize = kPlanMapTileSize,
}) {
  if (width <= 4 || height <= 4) return null;
  if (tiltDeg.abs() > 1) {
    return _planMapLngLatToScreenPitched(
      lng: lng,
      lat: lat,
      width: width,
      height: height,
      centerLng: centerLng,
      centerLat: centerLat,
      zoom: zoom,
      bearingDeg: bearingDeg,
      tiltDeg: tiltDeg,
      tileSize: tileSize,
    );
  }
  final world = tileSize * math.pow(2, zoom);
  double mercX(double lo) => (lo + 180) / 360 * world;
  double mercY(double la) {
    final s = math.sin(la.clamp(-85.0, 85.0) * math.pi / 180);
    return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * world;
  }

  var dx = mercX(lng) - mercX(centerLng);
  var dy = mercY(lat) - mercY(centerLat);
  if (bearingDeg.abs() > 0.01) {
    final rad = bearingDeg * math.pi / 180;
    final c = math.cos(rad);
    final s = math.sin(rad);
    final rdx = dx * c - dy * s;
    final rdy = dx * s + dy * c;
    dx = rdx;
    dy = rdy;
  }
  return (x: width / 2 + dx, y: height / 2 + dy);
}

/// True when the pointer is on the live ribbon and not on a pin/disc.
bool planMapPointerHitsRibbon({
  required double localX,
  required double localY,
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  double bearingDeg = 0,
  double tiltDeg = 0,
  required List<List<double>> lineLngLat,
  Iterable<List<double>> pinLngLat = const [],
  double pinAvoidPx = 28,
  double hitPx = 36,
}) {
  if (lineLngLat.length < 2) return false;
  final ll = planMapScreenToLngLat(
    localX: localX,
    localY: localY,
    width: width,
    height: height,
    centerLng: centerLng,
    centerLat: centerLat,
    zoom: zoom,
    bearingDeg: bearingDeg,
    tiltDeg: tiltDeg,
  );
  if (ll == null) return false;
  for (final p in pinLngLat) {
    if (p.length < 2) continue;
    final s = planMapLngLatToScreen(
      lng: p[0],
      lat: p[1],
      width: width,
      height: height,
      centerLng: centerLng,
      centerLat: centerLat,
      zoom: zoom,
      bearingDeg: bearingDeg,
      tiltDeg: tiltDeg,
    );
    if (s == null) continue;
    final dx = s.x - localX;
    final dy = s.y - localY;
    if (dx * dx + dy * dy <= pinAvoidPx * pinAvoidPx) return false;
  }
  final mPerPx = planMapMetersPerPixel(lat: centerLat, zoom: zoom);
  final maxM = math.min(
    plannedRouteTapRadiusM(zoom),
    math.max(28, hitPx * mPerPx),
  );
  return plannedRouteTapSnap(
        lineLngLat: lineLngLat,
        tapLat: ll.lat,
        tapLng: ll.lng,
        maxOffsetM: maxM.toDouble(),
      ) !=
      null;
}

const kPlanGrabScreenMaxPts = 120;

/// Spacing for the native screen-sample of the live ribbon (far / uniform).
double planGrabScreenSampleStepM({
  required double zoom,
  required double lat,
}) {
  final mPerPx = planMapMetersPerPixel(lat: lat, zoom: zoom);
  return math.max(12, mPerPx * 10);
}

/// Denser step inside the viewport — serpentine hits under tilt.
double planGrabScreenSampleDenseStepM({
  required double zoom,
  required double lat,
}) {
  final mPerPx = planMapMetersPerPixel(lat: lat, zoom: zoom);
  return math.max(8, mPerPx * 4);
}

bool planGrabSampleInViewport({
  required double lng,
  required double lat,
  required double centerLng,
  required double centerLat,
  required double zoom,
  required double mapW,
  required double mapH,
  double bearingDeg = 0,
  double tiltDeg = 0,
  double padPx = 56,
}) {
  if (!(mapW > 8) || !(mapH > 8)) return false;
  final s = planMapLngLatToScreen(
    lng: lng,
    lat: lat,
    width: mapW,
    height: mapH,
    centerLng: centerLng,
    centerLat: centerLat,
    zoom: zoom,
    bearingDeg: bearingDeg,
    tiltDeg: tiltDeg,
  );
  if (s == null) return false;
  return s.x >= -padPx &&
      s.x <= mapW + padPx &&
      s.y >= -padPx &&
      s.y <= mapH + padPx;
}

List<List<double>> _planGrabThinAlong(
  List<List<double>> pts, {
  required int budget,
}) {
  if (pts.length <= budget) return pts;
  if (budget <= 2) return [pts.first, pts.last];
  final out = <List<double>>[pts.first];
  final inner = budget - 2;
  for (var i = 1; i <= inner; i++) {
    final t = i / (inner + 1);
    final idx = (t * (pts.length - 1)).round().clamp(1, pts.length - 2);
    final p = pts[idx];
    if (out.last[0] != p[0] || out.last[1] != p[1]) out.add(p);
  }
  out.add(pts.last);
  return out;
}

List<List<double>> _planGrabUniformSample(
  List<List<double>> lineLngLat, {
  required double totalM,
  required double stepM,
  required int maxPts,
}) {
  var step = stepM;
  if (totalM / step > maxPts - 1) {
    step = totalM / (maxPts - 1);
  }
  final out = <List<double>>[lineLngLat.first];
  var along = step;
  while (along < totalM - 1 && out.length < maxPts - 1) {
    out.add(pointAlongRoute(lineLngLat, along));
    along += step;
  }
  out.add(lineLngLat.last);
  return out;
}

/// Thin the live line so [toScreenLocationBatch] stays cheap.
/// With viewport args, spend most samples on the visible ribbon.
List<List<double>> planGrabScreenSample(
  List<List<double>> lineLngLat, {
  required double zoom,
  required double lat,
  int maxPts = kPlanGrabScreenMaxPts,
  double? centerLng,
  double? centerLat,
  double? mapW,
  double? mapH,
  double bearingDeg = 0,
  double tiltDeg = 0,
}) {
  if (lineLngLat.length < 2) return lineLngLat;
  if (lineLngLat.length <= maxPts) return lineLngLat;
  final total = routeLengthM(lineLngLat);
  if (total <= 0) return [lineLngLat.first, lineLngLat.last];

  final sparse = planGrabScreenSampleStepM(zoom: zoom, lat: lat);
  final useView = centerLng != null &&
      centerLat != null &&
      mapW != null &&
      mapH != null &&
      mapW! > 8 &&
      mapH! > 8;

  if (!useView) {
    return _planGrabUniformSample(
      lineLngLat,
      totalM: total,
      stepM: sparse,
      maxPts: maxPts,
    );
  }

  final dense = planGrabScreenSampleDenseStepM(zoom: zoom, lat: lat);
  // Index-tagged walk keeps route order without float string keys.
  final tagged = <({List<double> p, bool near})>[];
  var along = 0.0;
  var nextFar = 0.0;
  while (along < total - 1e-6) {
    final p = pointAlongRoute(lineLngLat, along);
    final near = planGrabSampleInViewport(
      lng: p[0],
      lat: p[1],
      centerLng: centerLng!,
      centerLat: centerLat!,
      zoom: zoom,
      mapW: mapW!,
      mapH: mapH!,
      bearingDeg: bearingDeg,
      tiltDeg: tiltDeg,
    );
    if (near) {
      tagged.add((p: p, near: true));
    } else if (along + 1e-6 >= nextFar) {
      tagged.add((p: p, near: false));
      nextFar = along + sparse;
    }
    along += dense;
  }
  final last = lineLngLat.last;
  if (tagged.isEmpty ||
      tagged.last.p[0] != last[0] ||
      tagged.last.p[1] != last[1]) {
    tagged.add((p: last, near: false));
  }

  final nearIdx = <int>[];
  final farIdx = <int>[];
  for (var i = 0; i < tagged.length; i++) {
    if (tagged[i].near) {
      nearIdx.add(i);
    } else {
      farIdx.add(i);
    }
  }

  final nearBudget = math.min(
    nearIdx.length,
    math.max(24, (maxPts * 0.78).floor()),
  ).toInt();
  final farBudget = math.min(
    farIdx.length,
    math.max(2, maxPts - math.max(nearBudget, 1)),
  ).toInt();

  List<int> thinIdx(List<int> src, int budget) {
    if (src.length <= budget) return src;
    if (budget <= 0) return const [];
    if (budget == 1) return [src.first];
    final out = <int>[src.first];
    final inner = budget - 2;
    for (var i = 1; i <= inner; i++) {
      final t = i / (inner + 1);
      final j =
          (t * (src.length - 1)).round().clamp(1, src.length - 2).toInt();
      out.add(src[j]);
    }
    out.add(src.last);
    return out;
  }

  final keep = <int>{
    ...thinIdx(nearIdx, nearBudget),
    ...thinIdx(farIdx, farBudget),
    0,
    tagged.length - 1,
  };
  final out = <List<double>>[
    for (var i = 0; i < tagged.length; i++)
      if (keep.contains(i)) tagged[i].p,
  ];
  if (out.length < 2) {
    return _planGrabUniformSample(
      lineLngLat,
      totalM: total,
      stepM: sparse,
      maxPts: maxPts,
    );
  }
  if (out.length <= maxPts) return out;
  return _planGrabThinAlong(out, budget: maxPts);
}

class PlanGrabScreenCache {
  const PlanGrabScreenCache({
    required this.lineScreen,
    required this.lineLngLat,
    this.pinScreen = const [],
  });

  final List<({double x, double y})> lineScreen;
  final List<List<double>> lineLngLat;
  final List<({double x, double y})> pinScreen;

  bool get usable =>
      lineScreen.length >= 2 && lineScreen.length == lineLngLat.length;
}

double _planScreenDist2ToSeg(
  double px,
  double py,
  ({double x, double y}) a,
  ({double x, double y}) b,
) {
  final abx = b.x - a.x;
  final aby = b.y - a.y;
  final apx = px - a.x;
  final apy = py - a.y;
  final ab2 = abx * abx + aby * aby;
  if (ab2 < 1e-9) return apx * apx + apy * apy;
  var t = (apx * abx + apy * aby) / ab2;
  if (t < 0) t = 0;
  if (t > 1) t = 1;
  final dx = apx - abx * t;
  final dy = apy - aby * t;
  return dx * dx + dy * dy;
}

/// Hit-test against a native-projected ribbon (tilt-accurate).
bool planMapPointerHitsScreenRibbon({
  required double localX,
  required double localY,
  required List<({double x, double y})> lineScreen,
  List<({double x, double y})> pinScreen = const [],
  double pinAvoidPx = 28,
  double hitPx = 36,
}) {
  if (lineScreen.length < 2) return false;
  final avoid2 = pinAvoidPx * pinAvoidPx;
  for (final p in pinScreen) {
    final dx = p.x - localX;
    final dy = p.y - localY;
    if (dx * dx + dy * dy <= avoid2) return false;
  }
  final max2 = hitPx * hitPx;
  for (var i = 1; i < lineScreen.length; i++) {
    if (_planScreenDist2ToSeg(
          localX,
          localY,
          lineScreen[i - 1],
          lineScreen[i],
        ) <=
        max2) {
      return true;
    }
  }
  return false;
}

/// Closest point on the sampled ribbon, in lng/lat.
({double lng, double lat})? planLngLatAtScreenRibbon({
  required double localX,
  required double localY,
  required List<({double x, double y})> lineScreen,
  required List<List<double>> lineLngLat,
}) {
  if (lineScreen.length < 2 || lineScreen.length != lineLngLat.length) {
    return null;
  }
  var best = double.infinity;
  var bestI = 0;
  var bestT = 0.0;
  for (var i = 1; i < lineScreen.length; i++) {
    final a = lineScreen[i - 1];
    final b = lineScreen[i];
    final abx = b.x - a.x;
    final aby = b.y - a.y;
    final apx = localX - a.x;
    final apy = localY - a.y;
    final ab2 = abx * abx + aby * aby;
    var t = ab2 < 1e-9 ? 0.0 : (apx * abx + apy * aby) / ab2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    final dx = apx - abx * t;
    final dy = apy - aby * t;
    final d2 = dx * dx + dy * dy;
    if (d2 < best) {
      best = d2;
      bestI = i;
      bestT = t;
    }
  }
  final a = lineLngLat[bestI - 1];
  final b = lineLngLat[bestI];
  if (a.length < 2 || b.length < 2) return null;
  return (
    lng: a[0] + (b[0] - a[0]) * bestT,
    lat: a[1] + (b[1] - a[1]) * bestT,
  );
}

/// Map chip while A+B exist and the engine is in flight — not a 1.6 s flash.
bool planMapShowsRoutingWait({
  required bool editorActive,
  required bool routingBusy,
  required bool hasStart,
  required bool hasEnd,
}) =>
    editorActive && routingBusy && hasStart && hasEnd;

/// History FABs stay off while a map chip owns Undo (stop / wait / adapting)
/// or the fallback routing-wait banner is up. Redo lives only on the FABs.
bool planMapHistoryFabsVisible({
  required bool editorActive,
  required bool hasHistory,
  required bool mapHintOnMap,
  required bool rubberBand,
  required bool coachVisible,
  bool routingWaitBanner = false,
}) =>
    editorActive &&
    hasHistory &&
    !mapHintOnMap &&
    !rubberBand &&
    !coachVisible &&
    !routingWaitBanner;

/// Planned A→B "Losfahren" / web "In App starten" persists the draft first so
/// the ride (or bridge) carries a library id — never a bare `engine-*` ghost.
bool planStartRidePersistsDraft({
  required bool hasComputed,
  required bool fromCatalogSuggestion,
}) =>
    hasComputed && !fromCatalogSuggestion;

/// Library ids hand off to ride; ephemeral engine ids do not count as saved.
String? planRideHandoffId(String? savedId) {
  if (savedId == null || savedId.startsWith('engine-')) return null;
  return savedId;
}

/// Stable fingerprint of a planned line so Save + Losfahren reuse one library id.
String? planDraftGeometryKey({
  required List<List<double>>? coordinates,
  int viaCount = 0,
  double? distanceM,
}) {
  final c = coordinates;
  if (c == null || c.length < 2) return null;
  final a = c.first;
  final b = c.last;
  final mid = c[c.length ~/ 2];
  if (a.length < 2 || b.length < 2 || mid.length < 2) return null;
  String r(double n) => n.toStringAsFixed(5);
  return [
    '${c.length}',
    '$viaCount',
    if (distanceM != null) '${distanceM.round()}' else '',
    r(a[0]),
    r(a[1]),
    r(mid[0]),
    r(mid[1]),
    r(b[0]),
    r(b[1]),
  ].join('|');
}

/// Reuse last save when the live line still matches that fingerprint.
String? planReuseSavedHandoffId({
  required String? lastSavedId,
  required String? lastSavedGeomKey,
  required String? currentGeomKey,
}) {
  if (currentGeomKey == null || lastSavedGeomKey == null) return null;
  if (currentGeomKey != lastSavedGeomKey) return null;
  return planRideHandoffId(lastSavedId);
}

/// Finger-chip while the engine reshapes an existing line (not the first A–B).
bool planMapAdaptingHintOnMap({
  required bool routingBusy,
  required bool hasLiveLine,
  required bool hasFinger,
}) =>
    routingBusy && hasLiveLine && hasFinger;

/// Parked reshape finger lasts only while that reshape is in flight — otherwise
/// the next edit parks the wait chip on a stale point (Web: `planShaped`).
bool planParkedFingerClearsWhenIdle({required bool routingBusy}) =>
    !routingBusy;

/// Dest/stop wait pin wins over a parked reshape finger (undo mid-recalc).
({double lng, double lat})? planMapHintAnchorLngLat({
  ({double lng, double lat})? adaptingAt,
  ({double lng, double lat})? parkedFinger,
}) =>
    adaptingAt ?? parkedFinger;

/// First A→B (or dest confirm / GPS wait): chip at the dest pin.
/// Once a live line exists, the 1.6 s dest flash does not return to the chip.
bool planMapDestWaitHintOnMap({
  required bool editorActive,
  required bool routingBusy,
  required bool hasStart,
  required bool hasEnd,
  required bool fingerHint,
  bool destConfirm = false,
  bool hasLiveLine = false,
}) {
  if (fingerHint || !editorActive || !hasEnd) return false;
  if (routingBusy && hasStart) return true;
  if (!hasStart) return true;
  if (!destConfirm) return false;
  return !hasLiveLine;
}

enum PlanMapDestWaitCopy { adapting, firstAb, waitingGps }

PlanMapDestWaitCopy planMapDestWaitCopy({
  required bool hasStart,
  required bool hasLiveLine,
}) {
  if (!hasStart) return PlanMapDestWaitCopy.waitingGps;
  if (!hasLiveLine) return PlanMapDestWaitCopy.firstAb;
  return PlanMapDestWaitCopy.adapting;
}

double planFingerHintChipW({
  required bool undo,
  required bool firstAb,
}) {
  if (firstAb) return undo ? 280 : 244;
  return undo ? 228 : 176;
}

/// Native unproject during a line pull — only for commit / sync-miss, not
/// mid-drag preview (avoids rubber-band jump when the Future lands late).
bool planGrabNativeDrivesPreview({required bool hasSyncPreview}) =>
    !hasSyncPreview;

const _kPlanHorizonDeg = 89.25;

({double lng, double lat})? _planMapScreenToLngLatPitched({
  required double localX,
  required double localY,
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  required double bearingDeg,
  required double tiltDeg,
  required double tileSize,
}) {
  if (tiltDeg.abs() > 80) return null;
  final pixel = _planMapPixelMatrix(
    width: width,
    height: height,
    centerLng: centerLng,
    centerLat: centerLat,
    zoom: zoom,
    bearingDeg: bearingDeg,
    tiltDeg: tiltDeg,
    tileSize: tileSize,
  );
  if (pixel == null) return null;
  final inv = _m4Invert(pixel);
  if (inv == null) return null;
  final a = _m4Vec4(inv, localX, localY, 0, 1);
  final b = _m4Vec4(inv, localX, localY, 1, 1);
  if (a[3].abs() < 1e-12 || b[3].abs() < 1e-12) return null;
  final x0 = a[0] / a[3], y0 = a[1] / a[3], z0 = a[2] / a[3];
  final x1 = b[0] / b[3], y1 = b[1] / b[3], z1 = b[2] / b[3];
  final dz = z1 - z0;
  if (dz.abs() < 1e-12) return null;
  final t = (0 - z0) / dz;
  if (!t.isFinite) return null;
  final world = tileSize * math.pow(2, zoom);
  return _planMapWorldToLngLat(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, world);
}

({double x, double y})? _planMapLngLatToScreenPitched({
  required double lng,
  required double lat,
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  required double bearingDeg,
  required double tiltDeg,
  required double tileSize,
}) {
  if (tiltDeg.abs() > 80) return null;
  final pixel = _planMapPixelMatrix(
    width: width,
    height: height,
    centerLng: centerLng,
    centerLat: centerLat,
    zoom: zoom,
    bearingDeg: bearingDeg,
    tiltDeg: tiltDeg,
    tileSize: tileSize,
  );
  if (pixel == null) return null;
  final world = tileSize * math.pow(2, zoom);
  final merc = _planMapLngLatToWorld(lng, lat, world);
  final p = _m4Vec4(pixel, merc.x, merc.y, 0, 1);
  if (p[3] <= 1e-8) return null;
  final x = p[0] / p[3];
  final y = p[1] / p[3];
  if (!x.isFinite || !y.isFinite) return null;
  return (x: x, y: y);
}

({double x, double y}) _planMapLngLatToWorld(
  double lng,
  double lat,
  num world,
) {
  final w = world.toDouble();
  final s = math.sin(lat.clamp(-85.0, 85.0) * math.pi / 180);
  return (
    x: (lng + 180) / 360 * w,
    y: (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * w,
  );
}

({double lng, double lat})? _planMapWorldToLngLat(
  double x,
  double y,
  num world,
) {
  final w = world.toDouble();
  if (!(w > 0)) return null;
  final lng = (x / w) * 360 - 180;
  final n = math.pi - 2 * math.pi * y / w;
  final lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  if (!lng.isFinite || !lat.isFinite) return null;
  return (lng: lng, lat: lat.clamp(-85.0, 85.0));
}

double _planMapCameraToCenter(double height) =>
    0.5 / math.tan(kPlanMapFovRad / 2) * height;

double _planMapFarZ({required double height, required double pitchRad}) {
  final d = _planMapCameraToCenter(height);
  final limited = math.min(pitchRad.abs(), _kPlanHorizonDeg * math.pi / 180);
  const groundBase = math.pi / 2;
  final groundAngle = groundBase + pitchRad;
  final fovAbove = kPlanMapFovRad * 0.5;
  double surface(double angle) {
    final denom = math.sin(
      (math.pi - groundAngle - angle).clamp(0.01, math.pi - 0.01),
    );
    return math.sin(angle) * d / denom;
  }

  final topHalf = surface(fovAbove);
  final horizon = d *
      math.tan(
        ((_kPlanHorizonDeg * math.pi / 180) - pitchRad)
            .clamp(0.01, math.pi / 2),
      );
  final horizonAngle = math.atan(horizon / d);
  final minFov = (90 - _kPlanHorizonDeg) * math.pi / 180;
  final fovHorizon = horizonAngle > minFov ? horizonAngle : minFov;
  final topMin = math.min(topHalf, surface(fovHorizon));
  return (math.cos(groundBase - limited) * topMin + d) * 1.01;
}

List<double>? _planMapPixelMatrix({
  required double width,
  required double height,
  required double centerLng,
  required double centerLat,
  required double zoom,
  required double bearingDeg,
  required double tiltDeg,
  required double tileSize,
}) {
  final world = tileSize * math.pow(2, zoom);
  final merc = _planMapLngLatToWorld(centerLng, centerLat, world);
  final pitch = tiltDeg * math.pi / 180;
  final bearing = bearingDeg * math.pi / 180;
  final cam = _planMapCameraToCenter(height);
  final nearZ = height / 50;
  final farZ = _planMapFarZ(height: height, pitchRad: pitch);
  if (!(farZ > nearZ) || !(cam > 0)) return null;
  var m = _m4Perspective(kPlanMapFovRad, width / height, nearZ, farZ);
  m = _m4Scale(m, 1, -1, 1);
  m = _m4Translate(m, 0, 0, -cam);
  m = _m4RotateX(m, pitch);
  m = _m4RotateZ(m, -bearing);
  m = _m4Translate(m, -merc.x, -merc.y, 0);
  var clip = _m4Scale(_m4I(), width / 2, -height / 2, 1);
  clip = _m4Translate(clip, 1, -1, 0);
  return _m4Mul(clip, m);
}

List<double> _m4I() => <double>[
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    ];

List<double> _m4Mul(List<double> a, List<double> b) {
  final o = List<double>.filled(16, 0);
  for (var col = 0; col < 4; col++) {
    for (var row = 0; row < 4; row++) {
      var s = 0.0;
      for (var k = 0; k < 4; k++) {
        s += a[k * 4 + row] * b[col * 4 + k];
      }
      o[col * 4 + row] = s;
    }
  }
  return o;
}

List<double> _m4Translate(List<double> a, double x, double y, double z) =>
    _m4Mul(a, <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1]);

List<double> _m4Scale(List<double> a, double x, double y, double z) =>
    _m4Mul(a, <double>[x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1]);

List<double> _m4RotateX(List<double> a, double rad) {
  final c = math.cos(rad);
  final s = math.sin(rad);
  return _m4Mul(a, <double>[
    1,
    0,
    0,
    0,
    0,
    c,
    s,
    0,
    0,
    -s,
    c,
    0,
    0,
    0,
    0,
    1,
  ]);
}

List<double> _m4RotateZ(List<double> a, double rad) {
  final c = math.cos(rad);
  final s = math.sin(rad);
  return _m4Mul(a, <double>[
    c,
    s,
    0,
    0,
    -s,
    c,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);
}

List<double> _m4Perspective(
  double fovy,
  double aspect,
  double near,
  double far,
) {
  final f = 1 / math.tan(fovy / 2);
  final nf = 1 / (near - far);
  return <double>[
    f / aspect,
    0,
    0,
    0,
    0,
    f,
    0,
    0,
    0,
    0,
    (far + near) * nf,
    -1,
    0,
    0,
    2 * far * near * nf,
    0,
  ];
}

List<double> _m4Vec4(List<double> m, double x, double y, double z, double w) =>
    <double>[
      m[0] * x + m[4] * y + m[8] * z + m[12] * w,
      m[1] * x + m[5] * y + m[9] * z + m[13] * w,
      m[2] * x + m[6] * y + m[10] * z + m[14] * w,
      m[3] * x + m[7] * y + m[11] * z + m[15] * w,
    ];

List<double>? _m4Invert(List<double> a) {
  final a00 = a[0], a01 = a[1], a02 = a[2], a03 = a[3];
  final a10 = a[4], a11 = a[5], a12 = a[6], a13 = a[7];
  final a20 = a[8], a21 = a[9], a22 = a[10], a23 = a[11];
  final a30 = a[12], a31 = a[13], a32 = a[14], a33 = a[15];
  final b00 = a00 * a11 - a01 * a10;
  final b01 = a00 * a12 - a02 * a10;
  final b02 = a00 * a13 - a03 * a10;
  final b03 = a01 * a12 - a02 * a11;
  final b04 = a01 * a13 - a03 * a11;
  final b05 = a02 * a13 - a03 * a12;
  final b06 = a20 * a31 - a21 * a30;
  final b07 = a20 * a32 - a22 * a30;
  final b08 = a20 * a33 - a23 * a30;
  final b09 = a21 * a32 - a22 * a31;
  final b10 = a21 * a33 - a23 * a31;
  final b11 = a22 * a33 - a23 * a32;
  var det =
      b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
  if (det.abs() < 1e-20) return null;
  det = 1.0 / det;
  return <double>[
    (a11 * b11 - a12 * b10 + a13 * b09) * det,
    (a02 * b10 - a01 * b11 - a03 * b09) * det,
    (a31 * b05 - a32 * b04 + a33 * b03) * det,
    (a22 * b04 - a21 * b05 - a23 * b03) * det,
    (a12 * b08 - a10 * b11 - a13 * b07) * det,
    (a00 * b11 - a02 * b08 + a03 * b07) * det,
    (a32 * b02 - a30 * b05 - a33 * b01) * det,
    (a20 * b05 - a22 * b02 + a23 * b01) * det,
    (a10 * b10 - a11 * b08 + a13 * b06) * det,
    (a01 * b08 - a00 * b10 - a03 * b06) * det,
    (a30 * b04 - a31 * b02 + a33 * b00) * det,
    (a21 * b02 - a20 * b04 - a23 * b00) * det,
    (a11 * b07 - a10 * b09 - a12 * b06) * det,
    (a00 * b09 - a01 * b07 + a02 * b06) * det,
    (a31 * b01 - a30 * b03 - a32 * b00) * det,
    (a20 * b03 - a21 * b01 + a22 * b00) * det,
  ];
}
