import 'dart:math' as math;

/// Projektion GPS → Route-Polyline (lng/lat-Paare wie GeoJSON).
class RouteProgress {
  const RouteProgress({
    required this.distanceAlongM,
    required this.crossTrackM,
    required this.segmentIndex,
  });

  final double distanceAlongM;
  final double crossTrackM;
  final int segmentIndex;
}

double haversineM(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * R * math.asin(math.min(1.0, math.sqrt(a)));
}

double _toRad(double d) => d * math.pi / 180;

/// Nächster Punkt auf der Polyline + Distanz entlang der Route + Cross-Track.
RouteProgress projectOntoRoute({
  required List<List<double>> coordinates,
  required double lat,
  required double lng,
}) {
  if (coordinates.isEmpty) {
    return const RouteProgress(
      distanceAlongM: 0,
      crossTrackM: double.infinity,
      segmentIndex: 0,
    );
  }
  if (coordinates.length == 1) {
    final c = coordinates.first;
    return RouteProgress(
      distanceAlongM: 0,
      crossTrackM: haversineM(lat, lng, c[1], c[0]),
      segmentIndex: 0,
    );
  }

  var bestDist = double.infinity;
  var bestAlong = 0.0;
  var bestSeg = 0;
  var alongBefore = 0.0;

  for (var i = 1; i < coordinates.length; i++) {
    final a = coordinates[i - 1];
    final b = coordinates[i];
    final ax = a[0];
    final ay = a[1];
    final bx = b[0];
    final by = b[1];
    final segLen = haversineM(ay, ax, by, bx);
    if (segLen < 0.01) {
      alongBefore += segLen;
      continue;
    }

    // Lokale ENU-Näherung für Segment-Projektion
    final latRad = _toRad(ay);
    final dx = (lng - ax) * math.cos(latRad) * 111320;
    final dy = (lat - ay) * 110540;
    final sx = (bx - ax) * math.cos(latRad) * 111320;
    final sy = (by - ay) * 110540;
    final seg2 = sx * sx + sy * sy;
    final t = ((dx * sx + dy * sy) / seg2).clamp(0.0, 1.0);
    final px = ax + (bx - ax) * t;
    final py = ay + (by - ay) * t;
    final d = haversineM(lat, lng, py, px);
    if (d < bestDist) {
      bestDist = d;
      bestAlong = alongBefore + segLen * t;
      bestSeg = i - 1;
    }
    alongBefore += segLen;
  }

  return RouteProgress(
    distanceAlongM: bestAlong,
    crossTrackM: bestDist,
    segmentIndex: bestSeg,
  );
}

/// Off-Route mit Hysterese: enter ≥ [enterM], clear ≤ [clearM].
bool updateOffRouteState({
  required bool currentlyOff,
  required double crossTrackM,
  double enterM = 40,
  double clearM = 25,
}) {
  if (currentlyOff) {
    return crossTrackM > clearM;
  }
  return crossTrackM >= enterM;
}
