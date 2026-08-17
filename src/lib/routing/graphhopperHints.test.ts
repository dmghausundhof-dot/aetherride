/**
 * npx tsx src/lib/routing/graphhopperHints.test.ts
 */
import assert from "node:assert/strict";
import {
  HONESTY_CYCLEWAY_DE,
  HONESTY_ROAD_DE,
  cityCyclewaySnapWanted,
  detailShares,
  graphhopperSurfaceWarnings,
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
for (const line of [...mtbWarn, ...cityWarn, HONESTY_ROAD_DE, HONESTY_CYCLEWAY_DE]) {
  const lower = line.toLowerCase();
  assert.ok(!lower.includes("graphhopper"), line);
  assert.ok(!lower.includes("valhalla"), line);
  assert.ok(!lower.includes("osrm"), line);
}

console.log("graphhopperHints.test.ts OK");
