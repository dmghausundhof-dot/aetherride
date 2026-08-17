/**
 * npx tsx src/lib/tours/mappeList.test.ts
 */
import assert from "node:assert/strict";
import {
  filterMappeQuery,
  mappeCardStats,
  savedRouteHasTrack,
  sortMappe,
} from "./mappeList";
import type { SavedRoute } from "@/types/route";

function route(
  id: string,
  name: string,
  savedAt: string,
  km: number,
  coords: [number, number][] = [],
): SavedRoute {
  return {
    id,
    name,
    distanceKm: km,
    elevationM: 120,
    durationMin: 40,
    savedAt,
    source: "engine",
    geometry:
      coords.length >= 2
        ? { type: "LineString", coordinates: coords }
        : undefined,
  };
}

const a = route("a", "Neckar", "2026-08-10T00:00:00.000Z", 16, [
  [8.6, 49.4],
  [8.7, 49.5],
]);
const b = route("b", "Alpenpass", "2026-08-16T00:00:00.000Z", 42);

assert.deepEqual(
  sortMappe([a, b], "recent").map((r) => r.id),
  ["b", "a"],
);
assert.deepEqual(
  sortMappe([a, b], "distance").map((r) => r.id),
  ["b", "a"],
);
assert.deepEqual(
  sortMappe([a, b], "name").map((r) => r.id),
  ["b", "a"],
);
assert.equal(filterMappeQuery([a, b], "neck").length, 1);
assert.equal(mappeCardStats(a), "16 km · 120 hm · 40 min");
assert.equal(mappeCardStats(b), "");
assert.equal(savedRouteHasTrack(a), true);
assert.equal(savedRouteHasTrack(b), false);

console.log("mappeList.test.ts ok");
