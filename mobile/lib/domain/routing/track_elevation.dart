import 'route_progress.dart';

/// Gemessene Höhe — nie interpoliert, nie aus km/hm erfunden.
class TrackElevSample {
  const TrackElevSample({
    required this.elev,
    this.lat,
    this.lng,
    this.distKm,
  });

  final double elev;
  final double? lat;
  final double? lng;
  final double? distKm;
}

bool elevationSourceIsDemo(String? source) {
  final s = source?.trim().toLowerCase() ?? '';
  return s == 'demo';
}

bool trackHasRealElev(List<List<double>> trackLngLat) {
  for (final p in trackLngLat) {
    if (p.length >= 3 && p[2].isFinite) return true;
  }
  return false;
}

List<TrackElevSample> trackElevSamplesFromMaps(
  List<Map<String, dynamic>> points,
) {
  final out = <TrackElevSample>[];
  for (final m in points) {
    final raw = m['elevM'] ?? m['elev'] ?? m['elevation'] ?? m['ele'] ?? m['z'];
    if (raw is! num) continue;
    final elev = raw.toDouble();
    if (!elev.isFinite) continue;
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num? ?? m['lon'] as num?)?.toDouble();
    final dist = (m['distKm'] as num? ?? m['dist_km'] as num?)?.toDouble();
    out.add(
      TrackElevSample(
        elev: elev,
        lat: lat != null && lat.isFinite ? lat : null,
        lng: lng != null && lng.isFinite ? lng : null,
        distKm: dist != null && dist.isFinite ? dist : null,
      ),
    );
  }
  return out;
}

/// Setzt echte Samples auf die nächste Spur-Vertex. Lücken bleiben 2D.
List<List<double>> attachRealElevToTrack({
  required List<List<double>> trackLngLat,
  required List<TrackElevSample> samples,
  double maxMatchM = 80,
  String? source,
}) {
  if (elevationSourceIsDemo(source) ||
      trackLngLat.length < 2 ||
      samples.isEmpty) {
    return trackLngLat;
  }
  final out = <List<double>>[
    for (final p in trackLngLat) [for (final v in p) v],
  ];
  final withGeo = <TrackElevSample>[
    for (final s in samples)
      if (s.lat != null && s.lng != null) s,
  ];
  if (withGeo.isNotEmpty) {
    _placeByLngLat(out, withGeo, maxMatchM);
    return out;
  }
  final withKm = <TrackElevSample>[
    for (final s in samples)
      if (s.distKm != null) s,
  ];
  if (withKm.length == samples.length) {
    _placeByDistKm(out, withKm, maxMatchM);
    return out;
  }
  if (samples.length == trackLngLat.length) {
    for (var i = 0; i < out.length; i++) {
      if (out[i].length >= 3 && out[i][2].isFinite) continue;
      out[i] = [out[i][0], out[i][1], samples[i].elev];
    }
  }
  return out;
}

void _placeByLngLat(
  List<List<double>> out,
  List<TrackElevSample> samples,
  double maxMatchM,
) {
  for (final s in samples) {
    var bestI = -1;
    var bestM = maxMatchM;
    for (var i = 0; i < out.length; i++) {
      final d = haversineM(s.lat!, s.lng!, out[i][1], out[i][0]);
      if (d <= bestM) {
        bestM = d;
        bestI = i;
      }
    }
    if (bestI < 0) continue;
    if (out[bestI].length >= 3 && out[bestI][2].isFinite) continue;
    out[bestI] = [out[bestI][0], out[bestI][1], s.elev];
  }
}

void _placeByDistKm(
  List<List<double>> out,
  List<TrackElevSample> samples,
  double maxMatchM,
) {
  final along = List<double>.filled(out.length, 0);
  for (var i = 1; i < out.length; i++) {
    along[i] = along[i - 1] +
        haversineM(out[i - 1][1], out[i - 1][0], out[i][1], out[i][0]);
  }
  for (final s in samples) {
    final targetM = s.distKm! * 1000;
    var bestI = -1;
    var bestM = maxMatchM;
    for (var i = 0; i < along.length; i++) {
      final d = (along[i] - targetM).abs();
      if (d <= bestM) {
        bestM = d;
        bestI = i;
      }
    }
    if (bestI < 0) continue;
    if (out[bestI].length >= 3 && out[bestI][2].isFinite) continue;
    out[bestI] = [out[bestI][0], out[bestI][1], s.elev];
  }
}
