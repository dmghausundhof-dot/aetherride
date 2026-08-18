/**
 * Run: npx tsx src/lib/tours/tourFunctions.test.ts
 */
import assert from "node:assert/strict";
import { getPublicTour, listPublicTours } from "../catalog/publicTours";
import { COMMUNITY_EVENTS } from "../community/seed";
import {
  REFERENCE_TOUR_ID,
  TOUR_FUNCTION_IDS,
  clubsForTour,
  eventsForRegion,
  eventsForTour,
  tourFunctionStates,
  tourHrefForEvent,
  tourMatchesSport,
} from "./tourFunctions";

function testReferenceTourHasFullKit() {
  const tour = getPublicTour(REFERENCE_TOUR_ID);
  assert.ok(tour, `missing ${REFERENCE_TOUR_ID}`);
  assert.equal(tour!.regionSlug, "rhein-neckar");
  assert.ok(tour!.loop);
  assert.ok(
    Math.abs(tour!.center[0] - 8.693) < 0.01 &&
      Math.abs(tour!.center[1] - 49.412) < 0.01,
    `reference pin ${tour!.center}`,
  );
  const events = eventsForTour(REFERENCE_TOUR_ID);
  assert.equal(events.length, 1);
  assert.equal(events[0]?.id, "ev-neckar-voll");
  const clubs = clubsForTour(tour!);
  assert.ok(clubs.some((c) => c.id === "cl-rn-allround"));
  const states = tourFunctionStates(tour!);
  assert.equal(states.length, TOUR_FUNCTION_IDS.length);
  assert.ok(states.every((s) => s.available), "reference tour must expose all functions");
}

function testEventsAttachToCatalogTours() {
  for (const event of COMMUNITY_EVENTS) {
    assert.ok(event.catalogTourId, `${event.id} missing catalogTourId`);
    assert.ok(
      getPublicTour(event.catalogTourId!),
      `${event.id} → missing tour ${event.catalogTourId}`,
    );
    assert.equal(tourHrefForEvent(event), `/tours/${event.catalogTourId}`);
  }
  assert.ok(eventsForTour("r-heidelberg-city").some((e) => e.id === "ev-city-hd"));
  assert.equal(eventsForTour("unknown-tour").length, 0);
  assert.ok(eventsForRegion("rhein-neckar").length >= 2);
}

function testSportMatch() {
  const tour = getPublicTour(REFERENCE_TOUR_ID)!;
  assert.equal(tourMatchesSport(tour, "gravel"), true);
  assert.equal(tourMatchesSport(tour, "road"), true);
  assert.equal(tourMatchesSport(tour, "urban"), true);
  assert.equal(tourMatchesSport(tour, "hiking"), false);
  assert.equal(tourMatchesSport(tour, "mtb"), false);
}

function testCatalogStillDense() {
  assert.ok(listPublicTours().length >= 90, "catalog should include the reference tour");
}

testReferenceTourHasFullKit();
testEventsAttachToCatalogTours();
testSportMatch();
testCatalogStillDense();
console.log("tourFunctions.test.ts OK");
