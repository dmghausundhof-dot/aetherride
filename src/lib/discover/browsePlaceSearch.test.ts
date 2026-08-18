/**
 * Run: npx tsx src/lib/discover/browsePlaceSearch.test.ts
 */
import assert from "node:assert/strict";
import {
  geocodeHitFromCoordinates,
  shouldFlyToPlace,
  shouldOfferPlaceHits,
} from "./browsePlaceSearch";

const tours = ["Wiesloch Feierabend", "Schwetzingen Schloss–Rhein"];

assert.equal(
  shouldFlyToPlace({ query: "Berlin", visibleTourNames: tours }),
  true
);
assert.equal(
  shouldFlyToPlace({ query: "Wiesloch", visibleTourNames: tours }),
  false,
  "Wiesloch-Prefix bleibt Tour-Filter"
);
assert.equal(
  shouldFlyToPlace({ query: "  ", visibleTourNames: tours }),
  false
);
assert.equal(
  shouldFlyToPlace({
    query: "52.52, 13.40",
    visibleTourNames: tours,
  }),
  true,
  "Koordinaten immer anfliegen"
);

assert.equal(shouldOfferPlaceHits("Be"), false);
assert.equal(shouldOfferPlaceHits("Ber"), true);
assert.equal(shouldOfferPlaceHits("49.291, 8.664"), false);

const latLng = geocodeHitFromCoordinates("49.398, 8.715");
assert.ok(latLng);
assert.equal(latLng.lat, 49.398);
assert.equal(latLng.lng, 8.715);

const lngLat = geocodeHitFromCoordinates("8.715, 49.398");
assert.ok(lngLat);
assert.equal(lngLat.lat, 49.398);
assert.equal(lngLat.lng, 8.715);

console.log("browsePlaceSearch.test.ts OK");
