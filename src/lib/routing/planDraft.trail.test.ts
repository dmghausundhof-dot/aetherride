/**
 * npx tsx src/lib/routing/planDraft.trail.test.ts
 */
import assert from "node:assert/strict";
import { lineLengthM } from "./planDraft";

const zig = lineLengthM([
  [8.0, 49.0],
  [8.01, 49.0],
  [8.01, 49.01],
]);
const straight = lineLengthM([
  [8.0, 49.0],
  [8.01, 49.01],
]);
assert.ok(zig > 1400 && zig < 2200, `zigzag ~1.8 km, got ${zig}`);
assert.ok(straight < zig, "polyline longer than crow-flies");
assert.equal(lineLengthM([[8, 49]]), 0);

console.log("planDraft.trail.test.ts OK");
