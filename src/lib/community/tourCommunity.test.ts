/**
 * npx tsx src/lib/community/tourCommunity.test.ts
 */
import assert from "node:assert/strict";
import {
  COMMUNITY_EMPTY_COPY,
  communityChipLabel,
  countsFromPayload,
  countsMapFromBatch,
  hasCommunity,
} from "./tourCommunity";

assert.ok(COMMUNITY_EMPTY_COPY.includes("Stimmen"));

const empty = countsFromPayload({
  tourId: "x",
  reviews: [],
  photos: [],
  stub: false,
});
assert.equal(empty.reviewCount, 0);
assert.equal(empty.photoCount, 0);
assert.equal(empty.averageRating, null);
assert.equal(hasCommunity(empty), false);
assert.equal(communityChipLabel(empty), null);

const live = countsFromPayload({
  tourId: "seed-loop-tempelhofer-60",
  reviewCount: 2,
  photoCount: 3,
  reviews: [
    { id: "r1", rating: 5 },
    { id: "r2", rating: 3 },
    { id: "bad", rating: 99 },
  ],
  photos: [{ url: "https://cdn.example/a.jpg" }],
});
assert.equal(live.reviewCount, 2);
assert.equal(live.photoCount, 3);
assert.equal(live.averageRating, 4);
assert.ok(communityChipLabel(live)?.includes("2"));

const noInvented = countsFromPayload({
  reviews: [{ id: "r", body: "ok" }],
  photos: [],
});
assert.equal(noInvented.reviewCount, 0);
assert.equal(noInvented.averageRating, null);

const crowd = countsFromPayload({
  reviewCount: 6,
  photoCount: 0,
  reviews: [{ rating: 4 }],
  difficulty: { n: 6, mean: 0.7, shown: true, label: "harder" },
});
assert.equal(crowd.difficulty?.shown, true);
assert.equal(crowd.difficulty?.label, "harder");

const thinCrowd = countsFromPayload({
  difficulty: { n: 2, shown: true, label: "harder" },
});
assert.equal(thinCrowd.difficulty?.shown, false);

const batch = countsMapFromBatch({
  counts: {
    a: { reviewCount: 1, photoCount: 0 },
    b: { reviewCount: 0, photoCount: 4 },
  },
});
assert.equal(batch.a.reviewCount, 1);
assert.equal(batch.b.photoCount, 4);

console.log("tourCommunity.test.ts OK");
