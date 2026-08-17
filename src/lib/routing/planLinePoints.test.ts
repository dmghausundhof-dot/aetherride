/**
 * npx tsx src/lib/routing/planLinePoints.test.ts
 */
import assert from "node:assert/strict";
import { maxElevAlong, sampleAlongLine } from "./planLinePoints";

const line: [number, number][] = [
  [8.67, 49.4],
  [8.68, 49.41],
  [8.69, 49.42],
];
const elev = [
  { distKm: 0, elevM: 110 },
  { distKm: 1.2, elevM: 180 },
  { distKm: 2.4, elevM: 140 },
];
const summit = maxElevAlong(line, elev);
assert.ok(summit);
assert.equal(summit.elevM, 180);
assert.ok(Math.abs(summit.lng - 8.68) < 0.03);

assert.equal(sampleAlongLine(line, 2).length, 2);
console.log("planLinePoints.test.ts OK");
