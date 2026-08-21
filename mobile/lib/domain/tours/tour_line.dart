import 'dart:math' as math;

/// Die Linie ist das Foto — Spiegel von `src/lib/tours/tourLine.ts`.
class TourLinePoint {
  const TourLinePoint(this.x, this.y);
  final double x;
  final double y;
}

class TourLineFit {
  const TourLineFit({required this.points, required this.loop});
  final List<TourLinePoint> points;
  final bool loop;
  TourLinePoint get start => points.first;
  TourLinePoint get end => points.last;
}

const kTourLineSize = 64.0;
const kTourLinePad = 8.0;
const kTourLineMaxPoints = 64;
const kTourLineLoopPx = 3.0;

List<List<double>> downsampleLngLats(
  List<List<double>> coords, [
  int max = kTourLineMaxPoints,
]) {
  if (coords.length <= max) return coords;
  final step = (coords.length - 1) / (max - 1);
  return [
    for (var i = 0; i < max; i++) coords[(i * step).round()],
  ];
}

TourLineFit? fitTourLine(
  List<List<double>> raw, {
  double width = kTourLineSize,
  double height = kTourLineSize,
  double pad = kTourLinePad,
}) {
  final coords = [
    for (final p in raw)
      if (p.length >= 2 && p[0].isFinite && p[1].isFinite) [p[0], p[1]],
  ];
  if (coords.length < 2) return null;
  final sampled = downsampleLngLats(coords);

  var minLng = double.infinity;
  var maxLng = double.negativeInfinity;
  var minLat = double.infinity;
  var maxLat = double.negativeInfinity;
  for (final p in sampled) {
    minLng = math.min(minLng, p[0]);
    maxLng = math.max(maxLng, p[0]);
    minLat = math.min(minLat, p[1]);
    maxLat = math.max(maxLat, p[1]);
  }
  final midLat = (minLat + maxLat) / 2;
  final midLng = (minLng + maxLng) / 2;
  final cosLat = math.cos(midLat * math.pi / 180).abs().clamp(0.05, 1.0);
  final wDeg = math.max((maxLng - minLng) * cosLat, 1e-9);
  final hDeg = math.max(maxLat - minLat, 1e-9);
  final scale = math.min((width - pad * 2) / wDeg, (height - pad * 2) / hDeg);

  final points = [
    for (final p in sampled)
      TourLinePoint(
        width / 2 + (p[0] - midLng) * cosLat * scale,
        height / 2 + (midLat - p[1]) * scale,
      ),
  ];
  final start = points.first;
  final end = points.last;
  final loop = math.sqrt(
        math.pow(end.x - start.x, 2) + math.pow(end.y - start.y, 2),
      ) <
      kTourLineLoopPx;
  return TourLineFit(points: points, loop: loop);
}

List<List<double>> trackCoordsOf({
  required List<List<double>> coordinates,
  List<List<double>> tour = const [],
}) {
  if (coordinates.length >= 2) return coordinates;
  if (tour.length >= 2) return tour;
  return const [];
}
