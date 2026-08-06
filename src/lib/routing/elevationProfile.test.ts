/**
 * Elevation profile from planned / route
 */
import {
  buildElevationProfileFromPlanned,
  pointAtDistanceAlongPlanned,
} from "./elevationProfile";
import type { PlannedRoute } from "./rideHandoff";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const planned: PlannedRoute = {
  id: "p1",
  name: "Profil",
  profile: "MTB_TRAIL",
  source: "discover_suggestion",
  distanceM: 10000,
  elevationGainM: 400,
  durationMin: 60,
  geometryLngLat: Array.from({ length: 30 }, (_, i) => [
    12.1 + i * 0.003,
    47.4 + i * 0.001,
  ]),
  mtbScale: "S2",
};

const elev = buildElevationProfileFromPlanned(planned);
assert(elev.points.length >= 10, "points");
assert(elev.gapKm > 0, "honest gap");
assert(elev.points.some((p) => p.elevM == null), "null elev in gap");
const pt = pointAtDistanceAlongPlanned(planned, 2);
assert(pt != null && Number.isFinite(pt.lat), "point along");

console.log("elevationProfile.test OK", {
  climb: elev.totalClimbM,
  gap: elev.gapKm,
});
