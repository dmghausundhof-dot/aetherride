/**
 * Discover→Ride Handoff + Track-Geometrie
 * Ausführen: npx tsx src/lib/routing/rideHandoff.test.ts
 */
import {
  buildDemoGeometryForSuggestion,
  buildTrackStats,
  haversineM,
  plannedRouteFromSuggestion,
  pointAlongGeometry,
  trackDistanceM,
} from "./rideHandoff";
import type { RouteSuggestion } from "./suggestions";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const sug: RouteSuggestion = {
  id: "r-alpbach-enduro",
  name: "Enduro Alpbachtal",
  category: "mtb_enduro",
  distanceKm: 28.4,
  elevationM: 1240,
  durationMin: 150,
  mtbScale: "S2–S3",
  surface: "trail/root",
  loop: true,
  uncertainKmPct: 12,
  matchScore: 88,
  reasons: ["a", "b", "c"],
};

const geom = buildDemoGeometryForSuggestion(sug);
assert(geom.length >= 24, "geom points");
assert(geom[0].length === 2, "lnglat");

const planned = plannedRouteFromSuggestion(sug);
assert(planned.name === "Enduro Alpbachtal", "name");
assert(planned.geometryLngLat.length >= 2, "planned geom");
assert(planned.distanceM === 28400, "distance");

const start = pointAlongGeometry(planned.geometryLngLat, 0);
const mid = pointAlongGeometry(planned.geometryLngLat, 0.5);
const end = pointAlongGeometry(planned.geometryLngLat, 1);
assert(Math.abs(start.lat - planned.geometryLngLat[0][1]) < 1e-6, "start");
assert(haversineM(start, end) > 500, "route length");
assert(haversineM(start, mid) > 100, "mid progress");

const track = [
  { lat: start.lat, lng: start.lng, time: 0 },
  { lat: mid.lat, lng: mid.lng, time: 60 },
  { lat: end.lat, lng: end.lng, time: 120 },
];
const dist = trackDistanceM(track);
assert(dist > 500, `track dist ${dist}`);
const stats = buildTrackStats(track, planned);
assert(stats.distanceM > 0, "stats dist");
assert(stats.elevationGainM > 0, "stats elev");

console.log("rideHandoff.test OK", {
  geomPts: geom.length,
  trackDistM: Math.round(dist),
});
