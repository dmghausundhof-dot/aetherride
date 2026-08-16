// Thin upcoming peek under next-turn (N-07 / nav-hud-tokens-v1).
// Shown only when the next stop ETA is under [kUpcomingRailMaxEtaMin] minutes.
// Does not count as a fifth Clean Mode HUD stat.

/// Locked with nav-hud-tokens-v1 (`upcomingRailMaxEtaMin`).
const int kUpcomingRailMaxEtaMin = 15;

class UpcomingRailItem {
  const UpcomingRailItem({
    required this.kind,
    required this.label,
    this.detail,
  });

  /// `turn` | `poi` | `climb`
  final String kind;
  final String label;
  final String? detail;
}

class RoutePoiStop {
  const RoutePoiStop({
    required this.atMin,
    required this.title,
    this.kind = 'poi',
  });

  final int atMin;
  final String title;
  final String kind;
}

/// Next POI still ahead of [alongRouteM], using duration fraction as proxy.
RoutePoiStop? nextPoiStop({
  required List<RoutePoiStop> stops,
  required double alongRouteM,
  required double totalDistanceM,
  required int durationMin,
}) {
  if (stops.isEmpty || totalDistanceM <= 0 || durationMin <= 0) return null;
  final progressMin = (alongRouteM / totalDistanceM) * durationMin;
  RoutePoiStop? best;
  for (final s in stops) {
    if (s.atMin > progressMin + 0.4) {
      if (best == null || s.atMin < best.atMin) best = s;
    }
  }
  return best;
}

/// Remaining minutes until [poi], or null if not computable.
double? poiEtaMin({
  required RoutePoiStop poi,
  required double alongRouteM,
  required double totalDistanceM,
  required int durationMin,
}) {
  if (totalDistanceM <= 0 || durationMin <= 0) return null;
  final progressMin = (alongRouteM / totalDistanceM) * durationMin;
  final remain = poi.atMin - progressMin;
  if (remain <= 0) return null;
  return remain;
}

/// Stimme: Ort erst wenn nah (≤3 min), einmal pro Stop. Rail bleibt bis 15 min.
const double kPoiAnnounceMaxEtaMin = 3;

String? pickPoiAnnounce({
  required String title,
  required int atMin,
  required double etaMin,
  required Set<String> spoken,
}) {
  final name = title.trim();
  if (name.isEmpty) return null;
  if (etaMin <= 0 || etaMin > kPoiAnnounceMaxEtaMin) return null;
  final key = 'poi:$name@$atMin';
  if (!spoken.add(key)) return null;
  return '$name in ${etaMin.ceil()} min';
}

/// ETA minutes for a distance at [speedKmh], falling back to ~18 km/h cruise.
double etaMinForDistanceM(double distanceM, {double speedKmh = 0}) {
  final v = speedKmh > 3 ? speedKmh : 18.0;
  return (distanceM / 1000) / v * 60;
}

/// Build a single glance line when the next stop is within
/// [kUpcomingRailMaxEtaMin] minutes (nav-hud-tokens-v1).
UpcomingRailItem? buildUpcomingRail({
  required String? nextNextTurnInstruction,
  required double? nextNextTurnRemainingM,
  required double? nextNextTurnEtaMin,
  required RoutePoiStop? nextPoi,
  required double? nextPoiEtaMin,
  required double? remainingClimbM,
  int maxEtaMin = kUpcomingRailMaxEtaMin,
}) {
  // Prefer next turn after the current one when ETA is under the token gate.
  if (nextNextTurnInstruction != null &&
      nextNextTurnInstruction.trim().isNotEmpty &&
      nextNextTurnRemainingM != null &&
      nextNextTurnRemainingM > 40 &&
      nextNextTurnEtaMin != null &&
      nextNextTurnEtaMin > 0 &&
      nextNextTurnEtaMin < maxEtaMin) {
    final dist = nextNextTurnRemainingM < 1000
        ? '${nextNextTurnRemainingM.round()} m'
        : '${(nextNextTurnRemainingM / 1000).toStringAsFixed(1)} km';
    return UpcomingRailItem(
      kind: 'turn',
      label: nextNextTurnInstruction,
      detail: dist,
    );
  }
  if (nextPoi != null &&
      nextPoi.title.trim().isNotEmpty &&
      nextPoiEtaMin != null &&
      nextPoiEtaMin > 0 &&
      nextPoiEtaMin < maxEtaMin) {
    return UpcomingRailItem(
      kind: 'poi',
      label: nextPoi.title,
      detail: 'in ~${nextPoiEtaMin.ceil()} min',
    );
  }
  // Climb is not a timed "stop" — omit from Clean upcoming (token: stop <15 min).
  return null;
}
