/// Track für POST /api/community/places: inkl. letztem Punkt, max. 40 Samples.
List<List<double>> parseTrackSamples(Object? raw, {int max = 40}) {
  if (raw is! List) return const [];
  final all = <List<double>>[];
  for (final p in raw) {
    if (p is! List || p.length < 2) continue;
    final lng = (p[0] as num?)?.toDouble();
    final lat = (p[1] as num?)?.toDouble();
    if (lng == null || lat == null) continue;
    if (!lng.isFinite || !lat.isFinite) continue;
    if (lat.abs() > 90 || lng.abs() > 180) continue;
    all.add([lng, lat]);
  }
  return sampleTrackLngLat(all, max: max);
}

List<List<double>> sampleTrackLngLat(
  List<List<double>> coords, {
  int max = 40,
}) {
  if (coords.length <= max) return List<List<double>>.from(coords);
  final out = <List<double>>[];
  for (var i = 0; i < max; i++) {
    final idx = i == max - 1
        ? coords.length - 1
        : ((i * (coords.length - 1)) / (max - 1)).round();
    final pt = coords[idx];
    if (out.isNotEmpty && out.last[0] == pt[0] && out.last[1] == pt[1]) {
      continue;
    }
    out.add(pt);
  }
  return out;
}

List<List<double>> trackMapsToLngLat(List<Map<String, dynamic>> track) {
  return [
    for (final p in track)
      if (p['lat'] is num && p['lng'] is num)
        [
          (p['lng'] as num).toDouble(),
          (p['lat'] as num).toDouble(),
        ],
  ];
}
