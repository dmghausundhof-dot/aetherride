/**
 * Run: npx tsx src/lib/tours/mapPins.test.ts
 */
import assert from "node:assert/strict";
import { lineEndpoints, pointsAreClose, sportKeysOnTours, sportPinColor } from "./mapPins";

assert.equal(sportPinColor("gravel"), "#C4A574");
assert.equal(sportPinColor("unknown"), "#FF6A00");

const loop = lineEndpoints(
  [
    [8.69, 49.41],
    [8.7, 49.42],
    [8.69, 49.41],
  ],
  false,
);
assert.equal(loop.loop, true);
assert.equal(loop.end, null);

const stage = lineEndpoints(
  [
    [8.69, 49.41],
    [8.8, 49.5],
  ],
  false,
);
assert.equal(stage.loop, false);
assert.ok(stage.end);
assert.ok(pointsAreClose(stage.start!, [8.69, 49.41]));

assert.deepEqual(
  sportKeysOnTours([
    { primaryCategory: "road" },
    { primaryCategory: "gravel" },
    { primaryCategory: "road" },
  ]),
  ["road", "gravel"],
);

console.log("mapPins.test.ts OK");
