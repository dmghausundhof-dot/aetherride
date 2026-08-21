/// Eine Fahrt, drei Zustände — nicht drei Einstiege.
enum RideActivityKind { freeride, liveTour, following }

/// Freeride / live gezeichnet / vorhandener Tour gefolgt.
RideActivityKind rideActivityKind({
  required String? routeId,
  bool liveTour = false,
}) {
  if (liveTour) return RideActivityKind.liveTour;
  final id = routeId?.trim() ?? '';
  if (id.startsWith('recorded-')) return RideActivityKind.liveTour;
  if (id.isNotEmpty) return RideActivityKind.following;
  return RideActivityKind.freeride;
}

bool rideActivityCanDrawTour({required String? activeRouteId}) {
  final id = activeRouteId?.trim() ?? '';
  return id.isEmpty;
}

/// A–B from Navigieren (`engine-<ts>`), not a catalog tour.
bool rideIsEngineNav(String? routeId) {
  final id = routeId?.trim() ?? '';
  return id.startsWith('engine-');
}

/// Standing / indoor session — no honest pace or track recap.
bool rideIsShortSession({
  required double distanceKm,
  required int trackPoints,
}) {
  return distanceKm < 0.15 || trackPoints < 2;
}
