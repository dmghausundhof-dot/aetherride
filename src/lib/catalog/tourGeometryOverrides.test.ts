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

for (const id of listPublicTourIds()) {
  const o = getTourGeometryOverride(id);
  assert.ok(o, `override missing for ${id}`);
  assert.ok(
    o!.coordinates.length >= 4,
    `${id} needs enough points`
  );
}

console.log("tourGeometryOverrides.test.ts OK", {
  overrides: ids.length,
  tours: listPublicTourIds().length,
});
