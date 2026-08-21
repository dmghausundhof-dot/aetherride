/**
 * npx tsx src/lib/routing/lastPlanDest.test.ts
 */
import assert from "node:assert/strict";
import {
  lastPlanDestChipName,
  lastPlanDestCoordsMatch,
  lastPlanDestIsNearby,
  lastPlanDestShouldOffer,
  lastPlanDestWorthRemembering,
  parseLastPlanDest,
} from "./lastPlanDest";

assert.equal(parseLastPlanDest(null), null);
assert.equal(parseLastPlanDest({ lat: 91, lng: 8 }), null);
const dest = parseLastPlanDest({ lat: 49.4, lng: 8.7, label: " Kino " });
assert.ok(dest);
assert.equal(dest.label, "Kino");

assert.equal(
  lastPlanDestCoordsMatch(dest, { lat: 49.4, lng: 8.7 }),
  true,
);
assert.equal(
  lastPlanDestCoordsMatch(dest, { lat: 49.294, lng: 8.698 }),
  false,
);

assert.equal(
  lastPlanDestWorthRemembering({
    destLat: 49.294,
    destLng: 8.698,
    originLat: 49.294,
    originLng: 8.698,
  }),
  false,
  "dest on GPS is not worth remembering",
);
assert.equal(
  lastPlanDestWorthRemembering({
    destLat: 49.4,
    destLng: 8.7,
    originLat: 49.294,
    originLng: 8.698,
  }),
  true,
);

assert.equal(
  lastPlanDestIsNearby({
    destLat: 49.4,
    destLng: 8.7,
    gpsLat: 49.294,
    gpsLng: 8.698,
    viewLat: 49.294,
    viewLng: 8.698,
  }),
  true,
);
assert.equal(
  lastPlanDestIsNearby({
    destLat: 52.5,
    destLng: 13.4,
    gpsLat: 49.294,
    gpsLng: 8.698,
    viewLat: 49.294,
    viewLng: 8.698,
  }),
  false,
  "Berlin dest while GPS is Wiesloch",
);

assert.equal(lastPlanDestChipName(null), "");
assert.equal(lastPlanDestChipName("Kino"), "Kino");
assert.equal(lastPlanDestChipName("abcdefghijklmnopqrstuvwxyzABCD", 12).length, 12);

assert.equal(
  lastPlanDestShouldOffer({
    saved: dest,
    dismissed: dest,
    hasEnd: false,
    gpsLat: 49.294,
    gpsLng: 8.698,
    viewLat: 49.294,
    viewLng: 8.698,
  }),
  null,
  "dismissed dest stays hidden",
);
assert.ok(
  lastPlanDestShouldOffer({
    saved: dest,
    dismissed: null,
    hasEnd: false,
    gpsLat: 49.294,
    gpsLng: 8.698,
    viewLat: 49.294,
    viewLng: 8.698,
  }),
);
assert.equal(
  lastPlanDestShouldOffer({
    saved: dest,
    dismissed: null,
    hasEnd: true,
    gpsLat: 49.294,
    gpsLng: 8.698,
    viewLat: 49.294,
    viewLng: 8.698,
  }),
  null,
);

console.log("lastPlanDest.test.ts OK");
