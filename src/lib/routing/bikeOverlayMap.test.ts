/**
 * MapLibre overlay filters from RideProfile.
 * Ausführen: npx tsx src/lib/routing/bikeOverlayMap.test.ts
 */
import assert from "node:assert/strict";
import { overlayFamilyForBike } from "./bikeOverlayClass";
import {
  bikeOverlayExcludeFarmTracks,
  bikeOverlayLayerFilter,
  bikeOverlaySurfaceLineColor,
  overlayClassesOn,
} from "./bikeOverlayMap";
import { BIKE_OVERLAY_COLORS } from "./bikeOverlayClass";

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
  assert.ok(on.has("road"), "gravel touring also sees signed cycle routes");
}

function testSurfaceLineColorReadyWithoutField() {
  const expr = bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.road);
  const json = JSON.stringify(expr);
  assert.equal(expr[0], "case");
  assert.ok(json.includes('["has","surface"]'), "old tiles without field keep class color");
  assert.ok(json.includes('["coalesce",["get","surface"],""]'));
  assert.ok(
    json.includes('"any"') && json.includes('""'),
    "empty tippecanoe surface keeps class color"
  );
  assert.ok(json.includes("asphalt"));
  assert.ok(json.includes("compacted"));
  assert.ok(json.includes("fine_gravel"));
  assert.ok(json.includes("dirt"));
  assert.ok(json.includes("unpaved"));
  assert.ok(json.includes(BIKE_OVERLAY_COLORS.road));
  assert.ok(json.includes(BIKE_OVERLAY_COLORS.gravel));
  assert.ok(json.includes(BIKE_OVERLAY_COLORS.dirt));
  assert.ok(json.includes(BIKE_OVERLAY_COLORS.unrated));
  assert.ok(!json.includes("france-latest"));
}

/** Empty `surface: ""` must hit class fallback, not the muted unrated branch. */
function testSurfaceEmptyUsesClassFallbackNotGrey() {
  const expr = bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.urban);
  assert.equal(expr[0], "case");
  const when = expr[1] as unknown[];
  assert.equal(when[0], "any");
  assert.equal(expr[2], BIKE_OVERLAY_COLORS.urban, "empty/missing → class color");
  const matchArm = expr[3] as unknown[];
  assert.equal(matchArm[0], "match");
  assert.equal(
    matchArm[matchArm.length - 1],
    BIKE_OVERLAY_COLORS.unrated,
    "unknown non-empty surfaces still muted"
  );
}

testDownhillFiltersS1ToS3();
testAllmountainKeepsS0AndOpen();
testOverlayFamilyFollowsRideProfile();
testRoadHidesMtb();
testGravelKeepsS0S1();
testSurfaceLineColorReadyWithoutField();
testSurfaceEmptyUsesClassFallbackNotGrey();

function testFarmTracksFilterDropsHighwayTrack() {
  const base = bikeOverlayLayerFilter("gravel");
  assert.notEqual(base, false);
  const filtered = bikeOverlayExcludeFarmTracks(base);
  assert.notEqual(filtered, false);
  const json = JSON.stringify(filtered);
  assert.ok(json.includes("highway"), "farm-track filter reads OSM highway");
  assert.ok(json.includes("track"), "farm-track filter drops highway=track");
  assert.equal(bikeOverlayExcludeFarmTracks(false), false);
}

testFarmTracksFilterDropsHighwayTrack();
console.log("bikeOverlayMap.test.ts OK");
