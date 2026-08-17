import '../routing/route_progress.dart';

class FilmstripShot {
  const FilmstripShot({
    required this.id,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.source,
    this.attribution,
  });

  final String id;
  final String imageUrl;
  final double lat;
  final double lng;
  final String source;
  final String? attribution;
}

List<FilmstripShot> filmstripAlongLine({
  required List<FilmstripShot> shots,
  required List<List<double>> line,
  double maxOffM = 150,
  int limit = 6,
}) {
  if (line.length < 2) {
    return shots.where((s) => s.imageUrl.isNotEmpty).take(limit).toList();
  }
  final seen = <String>{};
  final out = <FilmstripShot>[];
  for (final s in shots) {
    if (s.imageUrl.isEmpty || !seen.add(s.id)) continue;
    if (s.source == 'demo') continue;
    final off = projectOntoRoute(
      coordinates: line,
      lat: s.lat,
      lng: s.lng,
    ).crossTrackM;
    if (off > maxOffM) continue;
    out.add(s);
    if (out.length >= limit) break;
  }
  return out;
}
