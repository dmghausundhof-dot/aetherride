/**
 * npx tsx src/lib/library/simpleAddRoute.test.ts
 */
import assert from "node:assert/strict";
import { defaultRouteName, simpleNamedRoute } from "./simpleAddRoute";

const now = new Date(2026, 7, 12, 18);
assert.equal(defaultRouteName(now), "Route 12.8.");

const named = simpleNamedRoute({
  name: "  Neckar Feierabend  ",
  start: [8.69, 49.41],
  now,
  id: "library-test",
});
assert.equal(named.id, "library-test");
assert.equal(named.name, "Neckar Feierabend");
assert.equal(named.distanceKm, 0);
assert.equal(named.geometry, null);
assert.equal(named.waypoints?.length, 1);
assert.equal(named.waypoints?.[0].role, "start");
assert.deepEqual(named.waypoints?.[0].lngLat, [8.69, 49.41]);

const emptyName = simpleNamedRoute({ name: "  ", now });
assert.equal(emptyName.name, "Route 12.8.");
assert.equal(emptyName.geometry, null);

const noStart = simpleNamedRoute({ name: "Ohne Pin", now });
assert.equal(noStart.waypoints, undefined);

console.log("simpleAddRoute.test.ts OK");
