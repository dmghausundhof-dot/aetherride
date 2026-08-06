/**
 * Route-Follow Off-Route
 */
import {
  distanceToPolylineM,
  evaluateRouteFollow,
} from "./routeFollow";
import type { PlannedRoute } from "./rideHandoff";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const planned: PlannedRoute = {
  id: "t",
  name: "Test",
  profile: "MTB_TRAIL",
  source: "discover_suggestion",
  distanceM: 5000,
  elevationGainM: 200,
  durationMin: 40,
  geometryLngLat: [
    [12.15, 47.45],
    [12.16, 47.45],
    [12.17, 47.46],
  ],
};

const onRoute = { lat: 47.45, lng: 12.155 };
const dOn = distanceToPolylineM(onRoute, planned.geometryLngLat);
assert(dOn < 45, `on route dist ${dOn}`);

const off = { lat: 47.48, lng: 12.2 };
const dOff = distanceToPolylineM(off, planned.geometryLngLat);
assert(dOff > 45, `off route dist ${dOff}`);

const st = evaluateRouteFollow(planned, off, 0.2);
assert(st != null && st.offRoute === true, "off flag");
assert(st!.hintDe?.includes("Abseits") === true, "hint");

const st2 = evaluateRouteFollow(planned, onRoute, 0.97);
assert(st2 != null && st2.offRoute === false, "on flag");

console.log("routeFollow.test OK", { dOn: Math.round(dOn), dOff: Math.round(dOff) });
