/**
 * npx tsx src/lib/routing/tourGeometry.test.ts
 */
import assert from "node:assert/strict";
import { waypointsForTour, routingProfileForTour } from "./tourGeometry";
import { getPublicTour, listPublicTours } from "@/lib/catalog/publicTours";

const tours = listPublicTours();
assert.ok(tours.length > 5, "public tours exist");

const loop = getPublicTour("r-bodensee-road");
// bodensee is not loop - use freiburg city
const city = getPublicTour("r-freiburg-city");
assert.ok(city);
const wp = waypointsForTour(city!);
assert.equal(wp.shape, "loop");
assert.equal(wp.from[0], wp.to[0]);
assert.ok(wp.vias.length >= 2);

const road = getPublicTour("r-rhein-radweg");
assert.ok(road);
const wp2 = waypointsForTour(road!);
assert.equal(wp2.shape, "point_to_point");
assert.ok(wp2.vias.length >= 1);

assert.equal(routingProfileForTour(city!), "urban");
assert.equal(routingProfileForTour(road!), "road");

console.log("tourGeometry.test.ts OK");
