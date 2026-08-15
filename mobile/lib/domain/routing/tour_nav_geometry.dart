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
