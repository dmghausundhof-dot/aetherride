/**
 * npx tsx src/lib/routing/graphhopperHints.test.ts
 */
import assert from "node:assert/strict";
import {
  HONESTY_CYCLEWAY_DE,
  HONESTY_FARM_MID_DE,
  HONESTY_FARM_TAIL_DE,
  HONESTY_ROAD_DE,
  cityCyclewaySnapWanted,
  detailShares,
  graphhopperSurfaceWarnings,
  shouldRetryOrsForFarmGraphhopper,
  shouldTrimFarmTrackTail,
  trimFarmTrackHead,
  trimFarmTrackTail,
  urbanFarmTrackShareTooHigh,
} from "./graphhopperHints";

const schauinsland = detailShares([
  [0, 79, "secondary"],
  [79, 89, "path"],
  [89, 96, "track"],
  [96, 100, "residential"],
]);
assert.ok((schauinsland.secondary ?? 0) > 0.7);
assert.ok(
  graphhopperSurfaceWarnings("mtb_allmountain", schauinsland).length > 0,
  "MTB on a road climb should warn"
);
assert.equal(
  graphhopperSurfaceWarnings("road", schauinsland).length,
  0,
  "road profile on secondary is fine"
);
assert.ok(
  graphhopperSurfaceWarnings("urban", schauinsland).length > 0,
  "city profile on a road climb should mention missing cycleway"
);

const odenwald = detailShares([
  [0, 83, "track"],
  [83, 91, "residential"],
  [91, 96, "service"],
  [96, 100, "secondary"],
]);
assert.equal(
  graphhopperSurfaceWarnings("gravel", odenwald).length,
  0,
  "gravel on tracks is honest"
);

const isar = detailShares([
  [0, 71, "path"],
  [71, 95, "cycleway"],
  [95, 100, "service"],
]);
assert.equal(graphhopperSurfaceWarnings("urban", isar).length, 0);
assert.equal(graphhopperSurfaceWarnings("ebike", isar).length, 0);

const cityRoad = detailShares([
  [0, 80, "secondary"],
  [80, 95, "primary"],
  [95, 100, "residential"],
]);
assert.ok(
  graphhopperSurfaceWarnings("urban", cityRoad).length > 0,
  "city route without cycleway should mention the missing bike path"
);

const koenigstuhlCity = detailShares([
  [0, 65, "tertiary"],
  [65, 80, "residential"],
  [80, 88, "service"],
  [88, 100, "path"],
]);
assert.ok(
  cityCyclewaySnapWanted(koenigstuhlCity),
  "tertiary climb without cycleway should gate a city snap"
);
assert.ok(
  graphhopperSurfaceWarnings("urban", koenigstuhlCity).length > 0,
  "city warning must count tertiary as carriageway"
);
assert.equal(
  graphhopperSurfaceWarnings("mtb_allmountain", koenigstuhlCity).length,
  0,
  "MTB does not treat tertiary-only as a busy-road miss"
);

const residentialOnly = detailShares([
  [0, 90, "residential"],
  [90, 100, "service"],
]);
assert.equal(
  cityCyclewaySnapWanted(residentialOnly),
  false,
  "residential (bike lane on the same way) is not a snap candidate"
);

assert.equal(cityCyclewaySnapWanted(isar), false);

const mtbWarn = graphhopperSurfaceWarnings("mtb_allmountain", schauinsland);
assert.equal(mtbWarn[0], HONESTY_ROAD_DE);
const cityWarn = graphhopperSurfaceWarnings("urban", cityRoad);
assert.equal(cityWarn[0], HONESTY_CYCLEWAY_DE);
assert.equal(shouldTrimFarmTrackTail("urban"), true);
assert.equal(shouldTrimFarmTrackTail("road"), true);
assert.equal(shouldTrimFarmTrackTail("ebike"), true);
assert.equal(shouldTrimFarmTrackTail("gravel"), false);
assert.equal(shouldTrimFarmTrackTail("mtb_allmountain"), false);

const farmTail: [number, number][] = [];
for (let i = 0; i < 10; i++) farmTail.push([8.7, 49.4 + i * 0.002]);
const trimmedFarm = trimFarmTrackTail({
  coordinates: farmTail,
  roadClass: [
    [0, 6, "residential"],
    [6, 10, "track"],
  ],
  surface: [
    [0, 6, "asphalt"],
    [6, 10, "grass"],
  ],
});
assert.equal(trimmedFarm.length, 7, "drop grass TRACK last-mile");
assert.deepEqual(trimmedFarm[trimmedFarm.length - 1], farmTail[6]);

const pavedTrack = trimFarmTrackTail({
  coordinates: farmTail,
  roadClass: [
    [0, 6, "residential"],
    [6, 10, "track"],
  ],
  surface: [
    [0, 6, "asphalt"],
    [6, 10, "paved"],
  ],
});
assert.equal(pavedTrack.length, farmTail.length, "keep paved TRACK");

const noDetails = trimFarmTrackTail({ coordinates: farmTail });
assert.equal(noDetails.length, farmTail.length, "fail-open without details");

const farmHead = trimFarmTrackHead({
  coordinates: farmTail,
  roadClass: [
    [0, 4, "track"],
    [4, 10, "residential"],
  ],
  surface: [
    [0, 4, "grass"],
    [4, 10, "asphalt"],
  ],
});
assert.equal(farmHead.length, 6, "drop grass TRACK first-mile");
assert.deepEqual(farmHead[0], farmTail[4]);

assert.equal(HONESTY_FARM_TAIL_DE.includes("Pin"), true);
assert.equal(HONESTY_FARM_TAIL_DE.toLowerCase().includes("graphhopper"), false);
assert.equal(HONESTY_FARM_MID_DE.includes("Feldwegen"), true);
assert.equal(HONESTY_FARM_MID_DE.toLowerCase().includes("graphhopper"), false);

assert.equal(
  urbanFarmTrackShareTooHigh("urban", { track: 0.2, residential: 0.8 }),
  true,
);
assert.equal(
  urbanFarmTrackShareTooHigh("urban", { TRACK: 0.2, residential: 0.8 }),
  true,
  "GH road_class case",
);
assert.equal(
  urbanFarmTrackShareTooHigh("urban", { track: 0.09, residential: 0.91 }),
  true,
);
assert.equal(
  urbanFarmTrackShareTooHigh("urban", { track: 0.05, residential: 0.95 }),
  false,
);
assert.equal(
  urbanFarmTrackShareTooHigh("gravel", { track: 0.4 }),
  false,
  "gravel may use tracks",
);
assert.equal(urbanFarmTrackShareTooHigh("urban", {}), false);

assert.equal(
  shouldRetryOrsForFarmGraphhopper({
    profile: "urban",
    engine: "graphhopper",
    roadClass: { track: 0.2 },
    viasEmpty: true,
    orsConfigured: true,
  }),
  true,
);
assert.equal(
  shouldRetryOrsForFarmGraphhopper({
    profile: "urban",
    engine: "graphhopper",
    roadClass: { track: 0.2 },
    viasEmpty: true,
    orsConfigured: false,
  }),
  false,
);
assert.equal(
  shouldRetryOrsForFarmGraphhopper({
    profile: "urban",
    engine: "graphhopper",
    roadClass: { track: 0.2 },
    viasEmpty: false,
    orsConfigured: true,
  }),
  false,
);

for (const line of [
  ...mtbWarn,
  ...cityWarn,
  HONESTY_ROAD_DE,
  HONESTY_CYCLEWAY_DE,
  HONESTY_FARM_TAIL_DE,
  HONESTY_FARM_MID_DE,
]) {
  const lower = line.toLowerCase();
  assert.ok(!lower.includes("graphhopper"), line);
  assert.ok(!lower.includes("valhalla"), line);
  assert.ok(!lower.includes("osrm"), line);
}

console.log("graphhopperHints.test.ts OK");
