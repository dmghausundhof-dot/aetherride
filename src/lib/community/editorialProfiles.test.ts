/**
 * Run: npx tsx src/lib/community/editorialProfiles.test.ts
 */
import assert from "node:assert/strict";
import { EDITORIAL_REVIEWS } from "./seed";
import { getPublicTour } from "../catalog/publicTours";
import {
  getEditorialProfile,
  listEditorialHandles,
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

testHandlesMatchReviews();
testReviewToursExist();
console.log("editorialProfiles.test.ts OK");
