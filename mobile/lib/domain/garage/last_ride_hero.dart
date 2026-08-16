import '../ride.dart';

/// Hero-Zeile: nur echte Fahrten, keine erfundenen Kilometer.
String? lastRideHeroLine(RideRecord? ride) {
  if (ride == null) return null;
  if (ride.distanceKm >= 0.05) {
    return 'Zuletzt ${ride.distanceKm.toStringAsFixed(1)} km';
  }
  return 'Zuletzt unterwegs — ohne GPS-Strecke';
}

RideRecord? lastEndedRideForBike(List<RideRecord> rides, String bikeId) {
  RideRecord? best;
  for (final r in rides) {
    if (r.bikeId != bikeId) continue;
    if (r.endedAt == null) continue;
    if (best == null || r.startedAt.isAfter(best.startedAt)) best = r;
  }
  return best;
}
