/**
 * npx tsx src/lib/routing/tourGeometry.test.ts
 */
import assert from "node:assert/strict";
import {
  waypointsForTour,
  routingProfileForTour,
  tourGeometrySource,
  computeTourGeometry,
} from "./tourGeometry";
import { getPublicTour, listPublicTours } from "@/lib/catalog/publicTours";
import { getP0SeedById } from "@/lib/discover/berlinLoops";

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

assert.equal(tourGeometrySource("r-freiburg-city"), "catalog");
assert.equal(tourGeometrySource("seed-loop-tempelhofer-60"), "p0-seed");
assert.equal(tourGeometrySource("seed-loop-heidelberg-neckar-60"), "p0-seed");
assert.equal(tourGeometrySource("seed-loop-titisee-feldberg-mtb-60"), "p0-seed");
assert.equal(tourGeometrySource("no-such-tour"), null);

computeTourGeometry("seed-loop-titisee-feldberg-mtb-60")
  .then((titisee) => {
    assert.ok(titisee);
    assert.ok(
      (titisee.geometry.coordinates?.length ?? 0) >= 2,
      "stored Titisee track is returned, not a live fill"
    );
    assert.equal(titisee.engine, "editorial");
    const stored = getP0SeedById("seed-loop-titisee-feldberg-mtb-60")?.geometry;
    assert.equal(titisee.geometry.coordinates.length, stored?.length);
    console.log("tourGeometry.test.ts OK");
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
