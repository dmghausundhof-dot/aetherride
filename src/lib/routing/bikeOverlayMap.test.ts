/**
 * MapLibre overlay filters from RideProfile.
 * Ausführen: npx tsx src/lib/routing/bikeOverlayMap.test.ts
 */
import assert from "node:assert/strict";
import { overlayFamilyForBike } from "./bikeOverlayClass";
import {
  bikeOverlayLayerFilter,
  overlayClassesOn,
} from "./bikeOverlayMap";

function testDownhillFiltersS1ToS3() {
  const mtb = bikeOverlayLayerFilter("mtb", "downhill");
  assert.notEqual(mtb, false);
  const json = JSON.stringify(mtb);
  assert.ok(json.includes("S1"), "DH includes S1");
  assert.ok(json.includes("S2"), "DH includes S2");
  assert.ok(json.includes("S3"), "DH includes S3");
  assert.ok(json.includes("S3+"), "DH matches OSM/API S3+");
  assert.ok(!json.includes('"S0"'), "DH excludes S0");

  assert.equal(bikeOverlayLayerFilter("mtb_unrated", "downhill"), false);

  const on = overlayClassesOn({
    family: "mtb",
    visible: true,
    rideProfileId: "downhill",
  });
  assert.ok(on.has("mtb"));
  assert.ok(!on.has("mtb_unrated"));
}

function testAllmountainKeepsS0AndOpen() {
  const mtb = bikeOverlayLayerFilter("mtb", "mtb_allmountain");
  const json = JSON.stringify(mtb);
  assert.ok(json.includes("S0"));
  assert.ok(json.includes("S2"));
  assert.notEqual(bikeOverlayLayerFilter("mtb_unrated", "mtb_allmountain"), false);

  const on = overlayClassesOn({
    family: "mtb",
    visible: true,
    rideProfileId: "mtb_allmountain",
  });
  assert.ok(on.has("mtb_unrated"));
}

function testOverlayFamilyFollowsRideProfile() {
  assert.equal(overlayFamilyForBike("downhill"), "mtb");
  assert.equal(overlayFamilyForBike("road"), "road");
  const dh = overlayClassesOn({
    family: overlayFamilyForBike("downhill"),
    visible: true,
    rideProfileId: "downhill",
  });
  assert.ok(dh.has("mtb"));
  assert.ok(!dh.has("mtb_unrated"));
  assert.ok(!dh.has("road"));
  const road = overlayClassesOn({
    family: overlayFamilyForBike("road"),
    visible: true,
    rideProfileId: "road",
  });
  assert.ok(road.has("road"));
  assert.ok(road.has("urban"));
  assert.ok(!road.has("mtb"));
}

function testRoadHidesMtb() {
  assert.equal(bikeOverlayLayerFilter("mtb", "road"), false);
  const on = overlayClassesOn({
    family: "road",
    visible: true,
    rideProfileId: "road",
  });
  assert.ok(on.has("road"));
  assert.ok(on.has("urban"));
  assert.ok(!on.has("mtb"));
}

function testGravelKeepsS0S1() {
  const mtb = bikeOverlayLayerFilter("mtb", "gravel");
  const json = JSON.stringify(mtb);
  assert.ok(json.includes("S0"));
  assert.ok(json.includes("S1"));
  assert.ok(!json.includes('"S2"'));
  const on = overlayClassesOn({
    family: "gravel",
    visible: true,
    rideProfileId: "gravel",
  });
  assert.ok(on.has("gravel"));
  assert.ok(on.has("mtb"));
  assert.ok(on.has("road"));
}

testDownhillFiltersS1ToS3();
testAllmountainKeepsS0AndOpen();
testOverlayFamilyFollowsRideProfile();
testRoadHidesMtb();
testGravelKeepsS0S1();
console.log("bikeOverlayMap.test.ts OK");
