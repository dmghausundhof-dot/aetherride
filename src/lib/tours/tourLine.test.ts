/**
 * npx tsx src/lib/tours/tourLine.test.ts
 */
import assert from "node:assert/strict";
import { downsampleLngLats, fitTourLine } from "./tourLine";

assert.equal(fitTourLine([]), null);
assert.equal(fitTourLine([[8.6, 49.4]]), null);

const line = fitTourLine([
  [8.6, 49.4],
  [8.7, 49.5],
]);
assert.ok(line);
assert.ok(line.d.startsWith("M"));
assert.ok(line.d.includes(" L"));
assert.equal(line.loop, false);
assert.equal(line.pointCount, 2);
assert.ok(line.start.x >= 8 && line.start.x <= 56);
assert.ok(line.end.y >= 8 && line.end.y <= 56);

const loop = fitTourLine([
  [8.68, 49.4],
  [8.7, 49.41],
  [8.72, 49.4],
  [8.7, 49.39],
  [8.68, 49.4],
]);
assert.ok(loop);
assert.equal(loop.loop, true);
assert.equal(loop.pointCount, 5);

const many: [number, number][] = [];
for (let i = 0; i < 400; i++) {
  many.push([8.6 + i * 0.001, 49.4 + Math.sin(i / 12) * 0.01]);
}
const sampled = downsampleLngLats(many, 64);
assert.equal(sampled.length, 64);
assert.deepEqual(sampled[0], many[0]);
assert.deepEqual(sampled[63], many[399]);

const ns = fitTourLine([
  [8.7, 49.3],
  [8.7, 49.5],
]);
const ew = fitTourLine([
  [8.6, 49.4],
  [8.9, 49.4],
]);
assert.ok(ns && ew);
assert.ok(Math.abs(ns.start.x - ns.end.x) < 1, "north-south stays centered in x");
assert.ok(Math.abs(ew.start.y - ew.end.y) < 1, "east-west stays centered in y");
assert.ok(Math.abs(ns.end.y - ns.start.y) > 20);
assert.ok(Math.abs(ew.end.x - ew.start.x) > 20);

const wide = fitTourLine(
  [
    [8.6, 49.4],
    [8.8, 49.45],
    [8.7, 49.5],
  ],
  128,
  64,
);
assert.ok(wide);
assert.ok(wide.start.x >= 8 && wide.start.x <= 120);
assert.ok(wide.start.y >= 7 && wide.start.y <= 57);

console.log("tourLine.test.ts ok");
