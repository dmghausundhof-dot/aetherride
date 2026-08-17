/**
 * npx tsx src/lib/catalog/tourGeometryOverrides.test.ts
 */
import assert from "node:assert/strict";
import {
  getTourGeometryOverride,
  listBuiltinOverrideIds,
} from "./tourGeometryOverrides";
import { listPublicTourIds } from "./publicTours";

const ids = listBuiltinOverrideIds();
assert.ok(ids.length >= 25, `expected many overrides, got ${ids.length}`);

const wiesloch = getTourGeometryOverride("r-wiesloch-feierabend");
assert.ok(wiesloch, "Wiesloch Feierabend needs a line");
assert.ok(
  (wiesloch?.coordinates.length ?? 0) >= 8,
  "Wiesloch line must be dense enough for Discover"
);

for (const id of listPublicTourIds()) {
  const o = getTourGeometryOverride(id);
  assert.ok(o, `override missing for ${id}`);
  assert.ok(
    o!.coordinates.length >= 8,
    `${id} needs enough points (got ${o!.coordinates.length})`
  );
}

console.log("tourGeometryOverrides.test.ts OK", {
  overrides: ids.length,
  tours: listPublicTourIds().length,
});
