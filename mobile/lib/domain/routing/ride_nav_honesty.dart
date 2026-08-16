import 'dart:math' as math;

/// Hide next-turn / upcoming while the body is not on the active line.
/// 80 m is past off-route enter (35 m) so a brief dodge still shows TBT.
const double kTbtHideCrossTrackM = 80;

/// Next-turn is honest only while cross-track is small (or not yet measured).
bool showTurnByTurn({required double crossTrackM}) {
  if (!crossTrackM.isFinite) return true;
  return crossTrackM <= kTbtHideCrossTrackM;
}

enum RideRestHudMode {
  /// On the tour line: one remaining figure + ETA.
  alongRoute,

  /// Approach or far off-route: distance to join vs rest of the loop.
  splitToJoin,
}

class RideRestSplit {
  const RideRestSplit.alongRoute({required this.restKm})
      : untilJoinKm = null,
        restLoopKm = null,
        mode = RideRestHudMode.alongRoute;

  const RideRestSplit.split({
    required this.untilJoinKm,
    required this.restLoopKm,
  })  : restKm = null,
        mode = RideRestHudMode.splitToJoin;

  final RideRestHudMode mode;
  final double? restKm;
  final double? untilJoinKm;
  final double? restLoopKm;
}

/// Glanceable km: one decimal under 100 km so 14.8 km is not "6.1 rest".
String formatHudKm(double km) {
  final n = km < 0 || !km.isFinite ? 0.0 : km;
  if (n < 100) return n.toStringAsFixed(1);
  return n.toStringAsFixed(0);
}

/// Split remaining distance so seed-rest is never shown as "almost there"
/// while the rider is still 15 km from the line.
RideRestSplit rideRestSplit({
  required double routeDistanceKm,
  required double alongRouteM,
  required double joinAlongM,
  required double crossTrackM,
}) {
  final restAlong = math.max(0.0, routeDistanceKm - alongRouteM / 1000);
  final loopAfterJoin = joinAlongM > 8
      ? math.max(0.0, routeDistanceKm - joinAlongM / 1000)
      : restAlong;
  final farOff = !showTurnByTurn(crossTrackM: crossTrackM);
  final beforeJoin = joinAlongM > 8 && alongRouteM < joinAlongM - 8;

  if (farOff) {
    final until = crossTrackM.isFinite ? math.max(0.0, crossTrackM / 1000) : 0.0;
    return RideRestSplit.split(untilJoinKm: until, restLoopKm: loopAfterJoin);
  }
  if (beforeJoin) {
    return RideRestSplit.split(
      untilJoinKm: math.max(0.0, (joinAlongM - alongRouteM) / 1000),
      restLoopKm: loopAfterJoin,
    );
  }
  return RideRestSplit.alongRoute(restKm: restAlong);
}
