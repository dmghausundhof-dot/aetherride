import 'route_progress.dart';

/// Highest sample on the line. Prefers lat/lng on the sample, else distKm.
({double lat, double lng, double elevM})? maxElevAlong({
  required List<List<double>> line,
  required List<Map<String, dynamic>> points,
}) {
  Map<String, dynamic>? best;
  var bestE = double.negativeInfinity;
  for (final m in points) {
    final raw = m['elevM'] ?? m['elev'] ?? m['elevation'];
    if (raw is! num) continue;
    final e = raw.toDouble();
    if (e <= bestE) continue;
    bestE = e;
    best = m;
  }
  if (best == null) return null;
  final lat = (best['lat'] as num?)?.toDouble();
  final lng = (best['lng'] as num? ?? best['lon'] as num?)?.toDouble();
  if (lat != null && lng != null) {
    return (lat: lat, lng: lng, elevM: bestE);
  }
  final distKm = (best['distKm'] as num?)?.toDouble();
  if (distKm != null && line.length >= 2) {
    final pt = pointAlongRoute(line, distKm * 1000);
    return (lat: pt[1], lng: pt[0], elevM: bestE);
  }
  return null;
}

List<List<double>> sampleAlongLine(List<List<double>> coords, [int count = 4]) {
  if (coords.isEmpty) return const [];
  if (coords.length <= count) return coords;
  final last = coords.length - 1;
  return [
    for (var i = 0; i < count; i++)
      coords[((i / (count - 1)) * last).round()],
  ];
}
