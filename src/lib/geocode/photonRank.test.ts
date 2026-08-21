/**
 * npx tsx src/lib/geocode/photonRank.test.ts
 */
import assert from "node:assert/strict";
import {
  cinemaPlaceQuery,
  geocodeHitScore,
  isCinemaQuery,
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

assert.equal(isCinemaQuery("Walldorf Kino"), true);
assert.equal(cinemaPlaceQuery("Walldorf Kino"), "Walldorf");

const nearLuxor = rankGeocodeHits(
  "Walldorf Kino",
  [
    {
      label:
        "Lichtblick - Walldorfer Kinotreff, Mörfelder Straße, 20, 64546, Walldorf, Hessen, Deutschland",
      lat: 49.9998755,
      lng: 8.5708116,
      kind: "house",
      name: "Lichtblick - Walldorfer Kinotreff",
    },
    {
      label:
        "Luxor Filmpalast Walldorf-Wiesloch, Impexstraße, 1, 69190, Wiesloch, Baden-Württemberg, Deutschland",
      lat: 49.2927126,
      lng: 8.664038,
      kind: "house",
      name: "Luxor Filmpalast Walldorf-Wiesloch",
    },
  ],
  { lat: 49.27968, lng: 8.67009 }
);
assert.ok(
  nearLuxor[0].name?.includes("Luxor"),
  "nearby cinema must beat Hessen Walldorf"
);

console.log("photonRank.test.ts OK");
