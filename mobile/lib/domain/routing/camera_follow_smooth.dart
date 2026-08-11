import 'dart:math' as math;

/// Smoothed heading-up camera follow (N-06) — pure helpers, unit-testable.
///
/// Reduces jank from noisy GPS bearings while keeping pan-pause behavior
/// (caller still owns user-gesture pause).

/// Shortest-path lerp of bearings in degrees [0, 360).
double lerpBearingDeg(double from, double to, double t) {
  final a = t.clamp(0.0, 1.0);
  final d = shortestBearingDeltaDeg(from, to);
  return (from + d * a + 360) % 360;
}

/// Signed delta from [from] to [to] in (-180, 180].
double shortestBearingDeltaDeg(double from, double to) {
  return ((to - from + 540) % 360) - 180;
}

/// Low-pass bearing with [alpha] in (0,1]; higher = snappier.
double smoothBearingDeg({
  required double previous,
  required double measured,
  double alpha = 0.28,
}) {
  return lerpBearingDeg(previous, measured, alpha.clamp(0.05, 1.0));
}

/// Whether a camera update is worth issuing (position or heading moved enough).
bool shouldUpdateFollowCamera({
  required double? lastLat,
  required double? lastLng,
  required double nextLat,
  required double nextLng,
  required double lastBearing,
  required double nextBearing,
  required DateTime? lastUpdateAt,
  required DateTime now,
  double minMoveM = 4.0,
  double minBearingDeg = 6.0,
  Duration minInterval = const Duration(milliseconds: 700),
}) {
  if (lastLat == null || lastLng == null || lastUpdateAt == null) {
    return true;
  }
  if (now.difference(lastUpdateAt) < minInterval) {
    // Still allow large heading snaps after a stall.
    final dBrg = shortestBearingDeltaDeg(lastBearing, nextBearing).abs();
    if (dBrg < 25) return false;
  }
  final moved = _haversineM(lastLat, lastLng, nextLat, nextLng);
  final dBrg = shortestBearingDeltaDeg(lastBearing, nextBearing).abs();
  return moved >= minMoveM || dBrg >= minBearingDeg;
}

double _haversineM(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}
