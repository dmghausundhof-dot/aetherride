/// Whether rejoin can run without live ORS/GraphHopper.
///
/// No approach needed (already close): splice the remaining track.
/// Otherwise the local graph must cover GPS and the rejoin point.
bool canOfflineRejoin({
  required bool needApproach,
  required bool graphReady,
  required bool routeCovered,
}) {
  if (!needApproach) return true;
  return graphReady && routeCovered;
}
