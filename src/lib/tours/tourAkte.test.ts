/**
 * npx tsx src/lib/tours/tourAkte.test.ts
 */
import assert from "node:assert/strict";
import {
  buildHofTafel,
  catalogTourIdOf,
  formatMappeDay,
  formatTourCount,
  joinMappeCaption,
  lastRideForSavedRoute,
  latestConditionTag,
  resolveAkteSavedRoute,
  ridesForSavedRoute,
  stimmeInboxTitle,
  stimmeInboxShowsBody,
} from "./tourAkte";
import type { Ride } from "../../types";
import type { SavedRoute } from "../../types/route";
import type { TourReview } from "../community/types";

const saved: SavedRoute = {
  id: "r-bodensee-road",
  name: "Bodensee",
  distanceKm: 40,
  elevationM: 200,
  durationMin: 120,
  savedAt: new Date().toISOString(),
  source: "suggestion",
};

assert.equal(catalogTourIdOf(saved), "r-bodensee-road");
assert.equal(
  catalogTourIdOf({ id: "gpx-1", catalogTourId: "r-bodensee-road" }),
  "r-bodensee-road"
);
assert.equal(catalogTourIdOf({ id: "gpx-1", source: "import" } as SavedRoute), null);

const rides: Ride[] = [
  {
    id: "ride-1",
    bikeId: "b1",
    savedRouteId: "r-bodensee-road",
    sportType: "road",
    startTime: new Date().toISOString(),
    distanceM: 12000,
    elevationGainM: 80,
    durationSec: 2400,
    summaryMetrics: {
      gForcePeak: 0,
      gForceRms: 0,
      leanAngleMax: 0,
      impactCount: 0,
      flowScore: 70,
    },
  },
];
assert.equal(ridesForSavedRoute(rides, saved).length, 1);
assert.equal(ridesForSavedRoute(rides, { id: "other" }).length, 0);
assert.equal(lastRideForSavedRoute(rides, saved), null);
const finished: Ride = { ...rides[0], endTime: new Date().toISOString() };
assert.equal(lastRideForSavedRoute([finished], saved)?.id, "ride-1");
assert.equal(joinMappeCaption(["gefahren mit Aeroad", "zuletzt 12.8."]), "gefahren mit Aeroad · zuletzt 12.8.");
assert.equal(joinMappeCaption([null, "  "]), undefined);
assert.ok(formatMappeDay("2026-08-12T10:00:00.000Z").includes("."));

const review: TourReview = {
  id: "ur-1",
  tourId: "r-bodensee-road",
  authorLabel: "Du",
  rating: 4,
  body: "Schöner Belag am See.",
  createdAt: new Date().toISOString(),
  status: "pending",
};
const tafel = buildHofTafel({
  care: { text: "Kette — am Rad", href: "/garage?tab=maintenance" },
  savedRoutes: [saved],
  myReviews: [review],
});
assert.equal(tafel.length, 3);
assert.equal(tafel[0].kind, "care");
assert.equal(tafel[1].kind, "stimmen");
assert.equal(tafel[2].kind, "mappe");
assert.ok(tafel[1].href.includes("akte="));
assert.equal(formatTourCount(1, "in der Mappe"), "1 Tour in der Mappe");
assert.equal(formatTourCount(2, "in der Mappe"), "2 Touren in der Mappe");
assert.equal(resolveAkteSavedRoute("r-bodensee-road", [saved])?.id, "r-bodensee-road");
assert.equal(
  resolveAkteSavedRoute("r-bodensee-road", [
    { id: "gpx-1", catalogTourId: "r-bodensee-road" },
  ])?.id,
  "gpx-1"
);
assert.equal(resolveAkteSavedRoute("missing", [saved]), null);

const tafelOhneStimme = buildHofTafel({
  care: { text: "Kette — am Rad", href: "/garage?tab=maintenance" },
  savedRoutes: [saved],
  myReviews: [],
});
assert.equal(
  tafelOhneStimme.some((x) => x.kind === "stimmen"),
  false,
  "Tafel zeigt keine Stimmen-Zeile ohne echte Review"
);

const gpxOnly: SavedRoute = {
  id: "gpx-1",
  name: "Import",
  distanceKm: 12,
  elevationM: 40,
  durationMin: 40,
  savedAt: new Date().toISOString(),
  source: "import",
};
const tafelGpx = buildHofTafel({
  savedRoutes: [gpxOnly],
  myReviews: [],
});
assert.equal(tafelGpx.length, 1);
assert.equal(tafelGpx[0].kind, "mappe");

const tafelGroup = buildHofTafel({
  savedRoutes: [saved],
  myReviews: [],
  group: { text: "Gruppe vor dem Tor · Freitag", href: "/library" },
});
assert.equal(tafelGroup[0].kind, "gruppe");
assert.equal(tafelGroup[1].kind, "mappe");

const tafelListing = buildHofTafel({
  care: { text: "Kette — am Rad", href: "/garage?tab=maintenance" },
  listing: {
    text: "Neckar wartet auf Bestätigung (1/3).",
    href: "/library?akte=gpx-1",
  },
  savedRoutes: [saved],
  myReviews: [review],
  group: { text: "Gruppe vor dem Tor · Freitag", href: "/library" },
});
assert.equal(tafelListing[0].kind, "care");
assert.equal(tafelListing[1].kind, "listing");
assert.equal(tafelListing[2].kind, "gruppe");

assert.equal(
  latestConditionTag(
    [
      {
        tourId: saved.id,
        createdAt: "2026-08-10T00:00:00.000Z",
        tags: ["top"],
      },
      {
        tourId: saved.id,
        createdAt: "2026-08-12T00:00:00.000Z",
        tags: ["nass", "unknown"],
      },
    ],
    saved.id,
  ),
  "nass",
);
assert.equal(
  latestConditionTag(
    [{ tourId: saved.id, createdAt: "2026-08-12T00:00:00.000Z", tags: [] }],
    saved.id,
  ),
  undefined,
);
assert.equal(latestConditionTag([review], "other"), undefined);

assert.equal(stimmeInboxTitle("Neckar", "nass am See", "Stimme"), "Neckar");
assert.equal(
  stimmeInboxTitle(undefined, "Nasser Belag am See.\nRest", "Stimme"),
  "Nasser Belag am See.",
);
assert.equal(stimmeInboxTitle("  ", "", "Stimme"), "Stimme");
assert.equal(
  stimmeInboxShowsBody("Nasser Belag am See.", "Nasser Belag am See.\nRest"),
  false,
);
assert.equal(stimmeInboxShowsBody("Neckar", "nass am See"), true);

console.log("tourAkte.test.ts OK");
