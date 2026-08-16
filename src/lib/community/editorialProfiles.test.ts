/**
 * Run: npx tsx src/lib/community/editorialProfiles.test.ts
 */
import assert from "node:assert/strict";
import { EDITORIAL_REVIEWS } from "./seed";
import { getPublicTour } from "../catalog/publicTours";
import { getRegion } from "../catalog/regions";
import {
  getEditorialProfile,
  listEditorialHandles,
  listEditorialProfilesForRegion,
} from "./editorialProfiles";

function testHandlesMatchReviews() {
  const reviewHandles = new Set(
    EDITORIAL_REVIEWS.map((r) => r.authorHandle).filter(Boolean),
  );
  for (const handle of listEditorialHandles()) {
    assert.ok(reviewHandles.has(handle), `no stimme for @${handle}`);
    assert.ok(getEditorialProfile(handle));
  }
  assert.equal(getEditorialProfile("nobody"), null);
}

function testReviewToursExist() {
  for (const review of EDITORIAL_REVIEWS) {
    assert.ok(
      getPublicTour(review.tourId),
      `missing catalog tour ${review.tourId}`,
    );
  }
}

function testRegionSlugsExist() {
  for (const handle of listEditorialHandles()) {
    const profile = getEditorialProfile(handle);
    assert.ok(profile);
    assert.ok(getRegion(profile.regionSlug), profile.regionSlug);
  }
  assert.ok(listEditorialProfilesForRegion("rhein-neckar").length >= 2);
  assert.equal(listEditorialProfilesForRegion("nowhere").length, 0);
}

testHandlesMatchReviews();
testReviewToursExist();
testRegionSlugsExist();
console.log("editorialProfiles.test.ts OK");
