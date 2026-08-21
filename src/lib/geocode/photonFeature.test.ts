/**
 * npx tsx src/lib/geocode/photonFeature.test.ts
 */
import assert from "node:assert/strict";
import {
  isPlaceholderPlanLabel,
  looksLikeCoordinateLabel,
  photonHitFromFeature,
} from "./photonFeature";

const hit = photonHitFromFeature({
  geometry: { coordinates: [8.694, 49.41] },
  properties: {
    name: "Bismarckplatz",
    city: "Heidelberg",
    country: "Germany",
    type: "locality",
  },
});
assert.ok(hit);
assert.equal(hit.lat, 49.41);
assert.equal(hit.lng, 8.694);
assert.ok(hit.label.includes("Bismarckplatz"));
assert.ok(hit.label.includes("Heidelberg"));
assert.equal(hit.name, "Bismarckplatz");

assert.equal(photonHitFromFeature({}), null);
assert.equal(looksLikeCoordinateLabel("49.4100, 8.6940"), true);
assert.equal(looksLikeCoordinateLabel("Heidelberg"), false);
assert.equal(
  isPlaceholderPlanLabel("Ziel (Karte)", ["Ziel (Karte)", "Start (Karte)"]),
  true
);
assert.equal(isPlaceholderPlanLabel("Via 2", []), true);
assert.equal(isPlaceholderPlanLabel("Alte Brücke", ["Ziel (Karte)"]), false);

console.log("photonFeature.test.ts OK");
