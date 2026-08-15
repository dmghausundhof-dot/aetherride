/**
 * Public catalog must cover every editorial region with a real pin.
 * Run: npx tsx src/lib/catalog/publicTours.regions.test.ts
 */
import assert from "node:assert/strict";
import {
  featuredPublicTours,
  FEATURED_TOUR_IDS,
  getPublicTour,
  listToursByRegion,
} from "./publicTours";
import { listRegions, neighborRegions, REGION_NEIGHBORS } from "./regions";

function testEveryRegionHasTours() {
  const empty = listRegions().filter(
    (r) => listToursByRegion(r.slug).length === 0,
  );
  assert.equal(
    empty.length,
    0,
    `empty regions: ${empty.map((r) => r.slug).join(",")}`,
  );
}

function testFeaturedToursResolve() {
  assert.equal(FEATURED_TOUR_IDS.length, 4);
  assert.equal(featuredPublicTours().length, FEATURED_TOUR_IDS.length);
  for (const id of FEATURED_TOUR_IDS) {
    assert.ok(getPublicTour(id), `missing featured ${id}`);
  }
}

function testDachPins() {
  assert.equal(getPublicTour("r-hamburg-alster")?.regionSlug, "norddeutschland");
  assert.equal(getPublicTour("r-berlin-tempelhof")?.regionSlug, "berlin-brandenburg");
  assert.equal(getPublicTour("r-koeln-urban")?.regionSlug, "nrw");
  assert.equal(getPublicTour("r-innsbruck-road")?.regionSlug, "oesterreich");
  assert.equal(getPublicTour("r-geneve-urban")?.regionSlug, "schweiz");
}

function testNeighborsExist() {
  const slugs = new Set(listRegions().map((r) => r.slug));
  for (const [from, to] of Object.entries(REGION_NEIGHBORS)) {
    assert.ok(slugs.has(from), `unknown neighbor key ${from}`);
    assert.equal(neighborRegions(from).length, to.length);
    for (const slug of to) {
      assert.ok(slugs.has(slug), `${from} → missing ${slug}`);
    }
  }
}

testEveryRegionHasTours();
testFeaturedToursResolve();
testDachPins();
testNeighborsExist();
console.log("publicTours.regions.test.ts OK");
