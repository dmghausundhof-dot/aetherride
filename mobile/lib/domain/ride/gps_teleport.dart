/// Emulator teleports and dual native+Geolocator streams invent kilometres.
/// Cycling never holds 144 km/h; treat those segments as a gap, not odometer.
bool isGpsTeleport({
  required double distanceM,
  required double dtSec,
  double accuracyM = 0,
}) {
  if (distanceM < 25) return false;
  if (accuracyM >= 80 && distanceM > 80) return true;
  if (dtSec <= 0.08) return distanceM > 40;
  return distanceM / dtSec > 40;
}
