// Thin upcoming peek under next-turn (N-07).

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

/// Build a single glance line: next turn after current, or next POI, or climb stub.
UpcomingRailItem? buildUpcomingRail({
  required String? nextNextTurnInstruction,
  required double? nextNextTurnRemainingM,
  required RoutePoiStop? nextPoi,
  required double? remainingClimbM,
}) {
  // Prefer next turn after the current one when close enough to plan.
  if (nextNextTurnInstruction != null &&
      nextNextTurnInstruction.trim().isNotEmpty &&
      nextNextTurnRemainingM != null &&
      nextNextTurnRemainingM > 40 &&
      nextNextTurnRemainingM < 2500) {
    final dist = nextNextTurnRemainingM < 1000
        ? '${nextNextTurnRemainingM.round()} m'
        : '${(nextNextTurnRemainingM / 1000).toStringAsFixed(1)} km';
    return UpcomingRailItem(
      kind: 'turn',
      label: nextNextTurnInstruction,
      detail: dist,
    );
  }
  if (nextPoi != null && nextPoi.title.trim().isNotEmpty) {
    return UpcomingRailItem(
      kind: 'poi',
      label: nextPoi.title,
      detail: 'in ~${nextPoi.atMin} min',
    );
  }
  if (remainingClimbM != null && remainingClimbM >= 25) {
    return UpcomingRailItem(
      kind: 'climb',
      label: 'Anstieg',
      detail: 'noch ~${remainingClimbM.round()} hm',
    );
  }
  return null;
}
