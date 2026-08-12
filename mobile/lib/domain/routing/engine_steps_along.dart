import '../../data/routing/routing_client.dart';
import 'route_progress.dart';

/// Stützpunkte entlang eines Tracks für die Routing-Engine (from + vias + to).
List<GeoPoint> sampleTrackWaypoints(
  List<GeoPoint> pts, {
  int maxPoints = 8,
}) {
  if (pts.length < 2) return pts;
  final n = maxPoints.clamp(2, 12);
  if (pts.length <= n) return List<GeoPoint>.from(pts);

  final cum = <double>[0];
  for (var i = 1; i < pts.length; i++) {
    cum.add(
      cum.last +
          haversineM(pts[i - 1].lat, pts[i - 1].lng, pts[i].lat, pts[i].lng),
    );
  }
  final total = cum.last;
  if (total < 40) return [pts.first, pts.last];

  final out = <GeoPoint>[];
  for (var k = 0; k < n; k++) {
    final target = total * k / (n - 1);
    var i = 0;
    while (i < cum.length - 1 && cum[i + 1] < target) {
      i++;
    }
    final p = pts[i];
    if (out.isEmpty ||
        haversineM(out.last.lat, out.last.lng, p.lat, p.lng) > 25) {
      out.add(p);
    }
  }
  if (out.isEmpty) return [pts.first, pts.last];
  if (haversineM(out.last.lat, out.last.lng, pts.last.lat, pts.last.lng) > 25) {
    if (out.length >= n) {
      out[out.length - 1] = pts.last;
    } else {
      out.add(pts.last);
    }
  }
  if (out.length > n) {
    final first = out.first;
    final last = out.last;
    final mid = out.sublist(1, out.length - 1);
    final need = n - 2;
    final kept = <GeoPoint>[first];
    if (need > 0 && mid.isNotEmpty) {
      for (var k = 0; k < need; k++) {
        final idx = ((k + 0.5) * mid.length / need).floor().clamp(0, mid.length - 1);
        kept.add(mid[idx]);
      }
    }
    kept.add(last);
    return kept;
  }
  return out;
}

/// Engine-Steps auf die Original-Polyline legen (Honesty: Track bleibt).
List<RouteStep> remapEngineStepsOntoTrack(
  List<RouteStep> steps,
  List<List<double>> trackLngLat,
) {
  if (steps.isEmpty || trackLngLat.length < 2) return steps;
  var origLen = 0.0;
  for (var i = 1; i < trackLngLat.length; i++) {
    origLen += haversineM(
      trackLngLat[i - 1][1],
      trackLngLat[i - 1][0],
      trackLngLat[i][1],
      trackLngLat[i][0],
    );
  }
  final engLen = steps.last.distanceAlongM;
  return [
    for (final s in steps)
      RouteStep(
        id: s.id,
        instruction: s.instruction,
        streetName: s.streetName,
        lat: s.lat,
        lng: s.lng,
        distanceAlongM: s.lat != null && s.lng != null
            ? projectOntoRoute(
                coordinates: trackLngLat,
                lat: s.lat!,
                lng: s.lng!,
              ).distanceAlongM
            : (engLen > 0 ? s.distanceAlongM * (origLen / engLen) : s.distanceAlongM),
      ),
  ];
}

bool engineStepsUseful(List<RouteStep> steps) {
  if (steps.length < 3) return false;
  final named = steps.where((s) {
    final street = s.streetName?.trim() ?? '';
    if (street.isNotEmpty) return true;
    final t = s.instruction.toLowerCase();
    return t.contains(' auf ') || t.contains(' onto ');
  }).length;
  return named >= 1 || steps.length >= 5;
}
