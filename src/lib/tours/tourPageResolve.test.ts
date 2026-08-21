/**
 * Run: npx tsx src/lib/tours/tourPageResolve.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { hasPublicTourPage, resolveTourPage } from "./tourPageResolve";
import { getPublicTour, listPublicTourIds } from "@/lib/catalog/publicTours";

const catalog = resolveTourPage("r-heidelberg-city");
assert.equal(catalog?.kind, "catalog");
if (catalog?.kind === "catalog") {
  assert.equal(catalog.tour.id, "r-heidelberg-city");
}

const seed = resolveTourPage("seed-loop-titisee-feldberg-mtb-60");
assert.equal(seed?.kind, "seed");
if (seed?.kind === "seed") {
  assert.equal(seed.seed.suggestion.id, "seed-loop-titisee-feldberg-mtb-60");
  assert.ok((seed.seed.geometry?.length ?? 0) >= 2, "Titisee keeps stored track");
  assert.ok(getPublicTour(seed.seed.suggestion.id) == null, "seed is not a catalog row");
}

const pinOnly = resolveTourPage("seed-loop-tempelhofer-60");
assert.equal(pinOnly?.kind, "seed");

assert.equal(resolveTourPage("no-such-tour"), null);
assert.equal(hasPublicTourPage("r-heidelberg-road"), true);
assert.equal(hasPublicTourPage("seed-loop-titisee-feldberg-mtb-60"), true);
assert.equal(hasPublicTourPage("engine-loop-not-a-page"), false);

assert.ok(
  !listPublicTourIds().some((id) => id.startsWith("seed-loop-")),
  "seed ids stay off the SEO catalog list"
);

const seedPage = readFileSync("src/components/tours/SeedTourPageBody.tsx", "utf8");
assert(!seedPage.includes("TourReviews"), "seed page has no review form");
assert(!seedPage.includes("TourCommunityChip"), "seed page has no community chip");
assert(seedPage.includes("/discover?route="), "seed page links to Trail View");

const tourRoute = readFileSync("src/app/(marketing)/tours/[id]/page.tsx", "utf8");
assert(tourRoute.includes("resolveTourPage"), "tour route resolves catalog + seeds");
assert(tourRoute.includes("SeedTourPageBody"), "tour route renders seed page");

console.log("tourPageResolve.test.ts OK");
