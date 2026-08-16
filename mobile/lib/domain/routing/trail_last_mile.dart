import 'dart:math' as math;

import 'route_progress.dart';

/// Last mile on an OSM trail when B is a tap on/near that trail.
///
/// Approach stays an efficient A→B (GraphHopper `bike` / hiking `foot`).
/// The trail is followed only from a nearby join to the tap — never the
/// whole way, never past the destination, never a loop join.
class TrailLastMile {
  const TrailLastMile({
    required this.geometry,
    required this.joinLat,
    required this.joinLng,
    required this.destLat,
    required this.destLng,
    required this.lastMileM,
    required this.destOffM,
  });

  /// `[lng, lat]` from join → destination (inclusive).
  final List<List<double>> geometry;
  final double joinLat;
  final double joinLng;
  final double destLat;
  final double destLng;
  final double lastMileM;
  final double destOffM;
}

const double kTrailDestMaxOffM = 90;
const double kTrailLastMileMaxM = 2000;

/// True when [to] sits on/near the trail (S-grade overlay tap, map B).
bool destLiesOnTrail(
  List<List<double>> trailLngLat, {
  required double toLat,
  required double toLng,
  double maxOffM = kTrailDestMaxOffM,
}) {
  if (trailLngLat.length < 2) return false;
  return projectOntoRoute(
        coordinates: trailLngLat,
        lat: toLat,
        lng: toLng,
      ).crossTrackM <=
      maxOffM;
}

/// Clip [trailLngLat] to join → dest. Null when dest is not on the trail.
TrailLastMile? clipTrailLastMile({
  required List<List<double>> trailLngLat,
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
  double maxDestOffM = kTrailDestMaxOffM,
  double maxLastMileM = kTrailLastMileMaxM,
}) {
  if (trailLngLat.length < 2) return null;
  final destP = projectOntoRoute(
    coordinates: trailLngLat,
    lat: toLat,
    lng: toLng,
  );
  if (destP.crossTrackM > maxDestOffM) return null;

  final len = routeLengthM(trailLngLat);
  final destAlong = destP.distanceAlongM.clamp(0.0, len);
  final fromP = projectOntoRoute(
    coordinates: trailLngLat,
    lat: fromLat,
    lng: fromLng,
  );
  final dStart = haversineM(
    fromLat,
    fromLng,
    trailLngLat.first[1],
    trailLngLat.first[0],
  );
  final dEnd = haversineM(
    fromLat,
    fromLng,
    trailLngLat.last[1],
    trailLngLat.last[0],
  );
  final fromStartSide = fromP.crossTrackM < 120
      ? fromP.distanceAlongM <= destAlong
      : dStart <= dEnd;

  double joinAlong;
  double endAlong;
  if (fromStartSide) {
    endAlong = destAlong;
    joinAlong = math.max(0.0, destAlong - maxLastMileM);
    if (fromP.crossTrackM < 250 &&
        fromP.distanceAlongM >= joinAlong &&
        fromP.distanceAlongM <= destAlong) {
      joinAlong = fromP.distanceAlongM;
    } else {
      joinAlong = _closestAlongInWindow(
        trailLngLat,
        fromLat,
        fromLng,
        joinAlong,
        destAlong,
      );
    }
  } else {
    joinAlong = destAlong;
    endAlong = math.min(len, destAlong + maxLastMileM);
    if (fromP.crossTrackM < 250 &&
        fromP.distanceAlongM >= destAlong &&
        fromP.distanceAlongM <= endAlong) {
      endAlong = fromP.distanceAlongM;
    } else {
      endAlong = _closestAlongInWindow(
        trailLngLat,
        fromLat,
        fromLng,
        destAlong,
        endAlong,
      );
    }
  }

  var geom = _sliceBetween(trailLngLat, joinAlong, endAlong);
  if (joinAlong > endAlong) {
    geom = geom.reversed.toList();
  }
  if (geom.length < 2) {
    final dest = pointAlongRoute(trailLngLat, destAlong);
    geom = [
      dest,
      dest,
    ];
  }
  final join = geom.first;
  final dest = geom.last;
  return TrailLastMile(
    geometry: geom,
    joinLat: join[1],
    joinLng: join[0],
    destLat: dest[1],
    destLng: dest[0],
    lastMileM: routeLengthM(geom),
    destOffM: destP.crossTrackM,
  );
}

/// First trail whose dest projection is on-line, else the closest off-track.
TrailLastMile? lastMileTowardDestination({
  required Iterable<List<List<double>>> trails,
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  TrailLastMile? best;
  for (final g in trails) {
    final mile = clipTrailLastMile(
      trailLngLat: g,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (mile == null) continue;
    if (best == null || mile.destOffM < best.destOffM) best = mile;
  }
  return best;
}

/// Nudge the GH target off a hard trail toward the rider so `bike` does not
/// enter at a distant trailhead and follow the whole S-grade line.
({double lat, double lng}) nudgeJoinTowardRider({
  required double joinLat,
  required double joinLng,
  required double fromLat,
  required double fromLng,
  double nudgeM = 140,
}) {
  final d = haversineM(fromLat, fromLng, joinLat, joinLng);
  if (d < nudgeM + 40) {
    return (lat: joinLat, lng: joinLng);
  }
  final f = nudgeM / d;
  return (
    lat: joinLat + (fromLat - joinLat) * f,
    lng: joinLng + (fromLng - joinLng) * f,
  );
}

double _closestAlongInWindow(
  List<List<double>> coords,
  double lat,
  double lng,
  double aM,
  double bM,
) {
  final lo = math.min(aM, bM);
  final hi = math.max(aM, bM);
  var bestAlong = lo;
  var bestD = double.infinity;
  const step = 40.0;
  for (var m = lo; m <= hi; m += step) {
    final p = pointAlongRoute(coords, m);
    final d = haversineM(lat, lng, p[1], p[0]);
    if (d < bestD) {
      bestD = d;
      bestAlong = m;
    }
  }
  final end = pointAlongRoute(coords, hi);
  final dEnd = haversineM(lat, lng, end[1], end[0]);
  if (dEnd < bestD) bestAlong = hi;
  return bestAlong;
}

List<List<double>> _sliceBetween(
  List<List<double>> coordinates,
  double startM,
  double endM,
) {
  final lo = math.min(startM, endM);
  final hi = math.max(startM, endM);
  final tail = sliceRouteAtAlongM(coordinates, lo).remaining;
  if (tail.length < 2) {
    final p = pointAlongRoute(coordinates, hi);
    return [pointAlongRoute(coordinates, lo), p];
  }
  final take = (hi - lo).clamp(0.0, routeLengthM(tail));
  final traveled = sliceRouteAtAlongM(tail, take).traveled;
  if (traveled.length >= 2) return traveled;
  return [tail.first, pointAlongRoute(tail, take)];
}
