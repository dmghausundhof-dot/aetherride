/**
 * npx tsx src/lib/tours/tourListing.test.ts
 */
import assert from "node:assert/strict";
import {
  LISTING_CONFIRM_K,
  LISTING_WINDOW_DAYS,
  beginTourShare,
  confirmationsFromReviews,
  listedForPublicExplore,
  nearbyListingTafelText,
  pickListingTafel,
  tickTourListing,
  uniqueConfirmCount,
  unpublishTour,
  type ListingSnapshot,
} from "./tourListing";

const t0 = new Date("2026-08-18T10:00:00.000Z");

function snap(partial: Partial<ListingSnapshot> = {}): ListingSnapshot {
  return {
    visibility: "private",
    listing: "none",
    candidateSince: null,
    listedAt: null,
    shareEpoch: 0,
    ...partial,
  };
}

assert.equal(LISTING_CONFIRM_K, 3);
assert.equal(LISTING_WINDOW_DAYS, 14);

const shared = beginTourShare(snap(), t0, false);
assert.equal(shared.visibility, "shared");
assert.equal(shared.listing, "candidate");
assert.equal(shared.candidateSince, t0.toISOString());
assert.equal(listedForPublicExplore(shared), false);

const catalogShare = beginTourShare(snap(), t0, true);
assert.equal(catalogShare.visibility, "shared");
assert.equal(catalogShare.listing, "none");
assert.equal(listedForPublicExplore(catalogShare), false);

const reviews = confirmationsFromReviews(
  [
    { authorLabel: "Du", createdAt: t0.toISOString(), status: "approved" },
    { authorLabel: "Ada", createdAt: t0.toISOString(), status: "approved" },
    { authorLabel: "Ada", createdAt: t0.toISOString(), status: "approved" },
    { authorLabel: "Bo", createdAt: t0.toISOString(), status: "pending" },
    {
      authorLabel: "Seed",
      createdAt: t0.toISOString(),
      status: "approved",
      editorial: true,
    },
    { authorLabel: "Cam", createdAt: t0.toISOString(), status: "approved" },
  ],
  "Du"
);
assert.equal(reviews.length, 2);
assert.equal(uniqueConfirmCount(reviews), 2);

const waiting = tickTourListing({
  ...shared,
  isCatalog: false,
  confirmations: reviews,
  now: t0,
});
assert.equal(waiting.listing, "candidate");
assert.equal(waiting.notice, "candidate");
assert.equal(waiting.confirmCount, 2);
assert.equal(waiting.changed, false);
assert.ok(waiting.expiresAt);

const three = [
  ...reviews,
  { riderId: "Bo", at: t0.toISOString(), kind: "stimme" as const },
];
const listed = tickTourListing({
  ...shared,
  isCatalog: false,
  confirmations: three,
  now: t0,
});
assert.equal(listed.listing, "listed");
assert.equal(listed.visibility, "shared");
assert.equal(listed.notice, "listed");
assert.equal(listed.changed, true);
assert.equal(listedForPublicExplore(listed), true);

const day15 = new Date(t0.getTime() + 15 * 24 * 60 * 60 * 1000);
const expired = tickTourListing({
  ...shared,
  isCatalog: false,
  confirmations: reviews,
  now: day15,
});
assert.equal(expired.visibility, "private");
assert.equal(expired.listing, "reverted");
assert.equal(expired.shareEpoch, 1);
assert.equal(expired.notice, "reverted");
assert.equal(listedForPublicExplore(expired), false);

const stayListed = tickTourListing({
  visibility: "shared",
  listing: "listed",
  candidateSince: shared.candidateSince,
  listedAt: t0.toISOString(),
  shareEpoch: 0,
  isCatalog: false,
  confirmations: [],
  now: day15,
});
assert.equal(stayListed.listing, "listed");
assert.equal(stayListed.visibility, "shared");

const unpublished = unpublishTour(listed);
assert.equal(unpublished.visibility, "private");
assert.equal(unpublished.listing, "none");
assert.equal(unpublished.shareEpoch, 1);

const migrateOldShare = tickTourListing({
  visibility: "shared",
  listing: "none",
  candidateSince: null,
  listedAt: null,
  shareEpoch: 0,
  isCatalog: false,
  confirmations: [],
  now: t0,
});
assert.equal(migrateOldShare.listing, "candidate");
assert.equal(migrateOldShare.candidateSince, t0.toISOString());

assert.equal(
  pickListingTafel({
    own: [
      { name: "Neckar", notice: "candidate", confirmCount: 1 },
      { name: "Odenwald", notice: "reverted", confirmCount: 0 },
    ],
    nearbyWaiting: 4,
  }),
  "Odenwald wieder privat — zu wenig Stimmen."
);
assert.equal(
  pickListingTafel({
    own: [{ name: "Neckar", notice: "candidate", confirmCount: 1 }],
  }),
  "Neckar wartet auf Bestätigung (1/3)."
);
assert.equal(nearbyListingTafelText(2), "2 Runden in der Nähe warten auf Bestätigung.");
assert.equal(nearbyListingTafelText(0), null);

console.log("tourListing.test.ts OK");
