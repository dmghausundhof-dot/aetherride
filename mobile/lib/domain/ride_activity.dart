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
