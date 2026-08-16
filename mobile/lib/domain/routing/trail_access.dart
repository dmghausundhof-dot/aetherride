import 'dart:math' as math;

/// Trailhead orientation: gravity uses elevation (top = start), else nearest end.
class OrientedTrail {
  const OrientedTrail({
    required this.geometry,
    required this.entryLat,
    required this.entryLng,
    required this.exitLat,
    required this.exitLng,
    required this.reversed,
    required this.usedElevation,
  });

  /// [lng, lat] pairs, downhill / ride direction.
  final List<List<double>> geometry;
  final double entryLat;
  final double entryLng;
  final double exitLat;
  final double exitLng;
  final bool reversed;
  final bool usedElevation;
}

/// Minimum drop before elevation wins over GPS-nearest.
const double kTrailElevDecideMinM = 8;

double trailAccessHaversineKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
}

double _rad(double deg) => deg * math.pi / 180;

OrientedTrail orientTrail({
  required List<List<double>> geometry,
  required double fromLat,
  required double fromLng,
  double? startElevM,
  double? endElevM,
  required bool preferDownhill,
}) {
  if (geometry.length < 2) {
    final p = geometry.isEmpty ? <double>[0, 0] : geometry.first;
    return OrientedTrail(
      geometry: geometry,
      entryLat: p.length > 1 ? p[1] : fromLat,
      entryLng: p.isNotEmpty ? p[0] : fromLng,
      exitLat: p.length > 1 ? p[1] : fromLat,
      exitLng: p.isNotEmpty ? p[0] : fromLng,
      reversed: false,
      usedElevation: false,
    );
  }

  final first = geometry.first;
  final last = geometry.last;
  final startLng = first[0];
  final startLat = first[1];
  final endLng = last[0];
  final endLat = last[1];

  var reverse = false;
  var usedElevation = false;

  final startE = startElevM;
  final endE = endElevM;
  if (preferDownhill &&
      startE != null &&
      endE != null &&
      startE.isFinite &&
      endE.isFinite &&
      (startE - endE).abs() >= kTrailElevDecideMinM) {
    usedElevation = true;
    reverse = startE < endE;
  } else {
    final dFirst = trailAccessHaversineKm(fromLat, fromLng, startLat, startLng);
    final dLast = trailAccessHaversineKm(fromLat, fromLng, endLat, endLng);
    reverse = dLast < dFirst;
  }

  final geo = reverse ? geometry.reversed.toList() : geometry;
  return OrientedTrail(
    geometry: geo,
    entryLat: geo.first[1],
    entryLng: geo.first[0],
    exitLat: geo.last[1],
    exitLng: geo.last[0],
    reversed: reverse,
    usedElevation: usedElevation,
  );
}
