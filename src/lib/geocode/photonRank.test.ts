/**
 * npx tsx src/lib/geocode/photonRank.test.ts
 */
import assert from "node:assert/strict";
import {
  geocodeHitScore,
  nameMatchesQuery,
  rankGeocodeHits,
} from "./photonRank";

assert.equal(nameMatchesQuery("Berlin", "Berlin"), true);
assert.equal(nameMatchesQuery("Berlin-Mitte", "Berlin"), true);
assert.equal(nameMatchesQuery("Berlingen", "Berlin"), false);
assert.equal(nameMatchesQuery("Berliner Straße", "Berlin"), false);

const ranked = rankGeocodeHits("Berlin", [
  {
    label: "Berlingen, Moselle, Frankreich",
    lat: 49.24,
    lng: 6.67,
    kind: "city",
  },
  {
    label: "Berliner Straße, Sandhausen",
    lat: 49.37,
    lng: 8.66,
    kind: "street",
  },
  {
    label: "Berlin, Deutschland",
    lat: 52.52,
    lng: 13.4,
    kind: "city",
  },
]);
assert.equal(ranked[0].label.startsWith("Berlin,"), true);
assert.ok(
  geocodeHitScore("Berlin", ranked[0]) >
    geocodeHitScore("Berlin", {
      label: "Berlingen, Moselle, Frankreich",
      lat: 49.24,
      lng: 6.67,
      kind: "city",
    })
);

console.log("photonRank.test.ts OK");
