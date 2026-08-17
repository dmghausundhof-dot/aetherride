/**
 * Honesty: Scale-Farbe nur bei echten OSM-Tags; sac_scale ≠ S0–S3.
 * npx tsx src/lib/routing/bikeOverlayClass.test.ts
 */
import assert from "node:assert/strict";
import {
  classifyBikeWay,
  overlayFamilyForBike,
  overlayClassesForFamily,
  parseOsmMtbScale,
  bikeOverlaySurfaceKind,
} from "./bikeOverlayClass";

function testParseScale() {
  assert.equal(parseOsmMtbScale("2"), "S2");
  assert.equal(parseOsmMtbScale("S1"), "S1");
  assert.equal(parseOsmMtbScale("0+"), "S0");
  assert.equal(parseOsmMtbScale(undefined, "1"), "S1");
  assert.equal(parseOsmMtbScale("4"), "S3+");
  assert.equal(parseOsmMtbScale("S3"), "S3+");
  assert.equal(parseOsmMtbScale(""), null);
  assert.equal(parseOsmMtbScale(undefined, undefined), null);
}

function testMtbTagged() {
  const r = classifyBikeWay({
    highway: "path",
    "mtb:scale": "2",
  });
  assert.equal(r.bikeClass, "mtb");
  assert.equal(r.mtbScale, "S2");
}

function testImbaTagged() {
  const r = classifyBikeWay({
    highway: "track",
    "mtb:scale:imba": "0",
  });
  assert.equal(r.bikeClass, "mtb");
  assert.equal(r.mtbScale, "S0");
}

function testUnratedPathNotS2() {
  const r = classifyBikeWay({ highway: "path", surface: "ground" });
  assert.equal(r.bikeClass, "mtb_unrated");
  assert.equal(r.mtbScale, null);
}

function testSacScaleNotMapped() {
  const r = classifyBikeWay({
    highway: "path",
    sac_scale: "mountain_hiking",
    trail_visibility: "bad",
  });
  assert.equal(r.bikeClass, "mtb_unrated");
  assert.equal(r.mtbScale, null);
  assert.notEqual(r.mtbScale, "S2");
}

function testHiddenBicycleNo() {
  const r = classifyBikeWay({
    highway: "path",
    "mtb:scale": "1",
    bicycle: "no",
  });
  assert.equal(r.bikeClass, "hidden");
  assert.equal(r.mtbScale, null);
}

function testHiddenMtbNo() {
  const r = classifyBikeWay({ highway: "track", mtb: "no", surface: "ground" });
  assert.equal(r.bikeClass, "hidden");
}

function testGravelTrack() {
  const r = classifyBikeWay({
    highway: "track",
    tracktype: "grade3",
    surface: "compacted",
  });
  assert.equal(r.bikeClass, "gravel");
  assert.equal(r.mtbScale, null);
}

function testRoadCycleway() {
  const r = classifyBikeWay({
    highway: "cycleway",
    surface: "asphalt",
    bicycle: "designated",
  });
  assert.equal(r.bikeClass, "road");
}

function testUrbanLivingStreet() {
  const r = classifyBikeWay({ highway: "living_street" });
  assert.equal(r.bikeClass, "urban");
}

function testUrbanCycleLane() {
  const r = classifyBikeWay({
    highway: "residential",
    cycleway: "lane",
  });
  assert.equal(r.bikeClass, "urban");
}

function testFamilyDefaults() {
  assert.deepEqual(overlayClassesForFamily(overlayFamilyForBike("mtb_am")), [
    "mtb",
    "mtb_unrated",
  ]);
  assert.deepEqual(overlayClassesForFamily(overlayFamilyForBike("gravel")), [
    "gravel",
    "road",
  ]);
  assert.deepEqual(overlayClassesForFamily(overlayFamilyForBike("road")), [
    "road",
    "urban",
  ]);
  assert.deepEqual(overlayClassesForFamily(overlayFamilyForBike("urban")), [
    "urban",
    "road",
  ]);
  assert.equal(overlayFamilyForBike("emtb"), "mtb");
  assert.equal(overlayFamilyForBike("downhill"), "mtb");
  assert.equal(overlayFamilyForBike("dh"), "mtb");
}

function testSurfaceKindRideability() {
  assert.equal(bikeOverlaySurfaceKind("asphalt"), "paved");
  assert.equal(bikeOverlaySurfaceKind("concrete"), "paved");
  assert.equal(bikeOverlaySurfaceKind("compacted"), "gravel");
  assert.equal(bikeOverlaySurfaceKind("fine_gravel"), "gravel");
  assert.equal(bikeOverlaySurfaceKind("dirt"), "dirt");
  assert.equal(bikeOverlaySurfaceKind("ground"), "dirt");
  assert.equal(bikeOverlaySurfaceKind("unpaved"), "dirt");
  assert.equal(bikeOverlaySurfaceKind(""), "unknown");
  assert.equal(bikeOverlaySurfaceKind(undefined), "unknown");
  assert.equal(bikeOverlaySurfaceKind("woodchips"), "unknown");
}

testParseScale();
testMtbTagged();
testImbaTagged();
testUnratedPathNotS2();
testSacScaleNotMapped();
testHiddenBicycleNo();
testHiddenMtbNo();
testGravelTrack();
testRoadCycleway();
testUrbanLivingStreet();
testUrbanCycleLane();
testFamilyDefaults();
testSurfaceKindRideability();
console.log("bikeOverlayClass.test.ts: ok");
