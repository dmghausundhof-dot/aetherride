/**
 * npx tsx src/lib/community/placeOnTrack.test.ts
 */
import assert from "node:assert/strict";
import { parseTrackSamples, snapPlaceOntoTrack } from "./placeOnTrack";

const line: [number, number][] = [
  [8.67, 49.4],
  [8.68, 49.4],
  [8.69, 49.4],
];

const on = snapPlaceOntoTrack(49.4002, 8.68, line);
assert.ok(on);
assert.ok(Math.abs(on.lat - 49.4) < 0.001);

const far = snapPlaceOntoTrack(49.5, 8.68, line);
assert.equal(far, null);

assert.equal(snapPlaceOntoTrack(49.4, 8.68, [[8.67, 49.4]]), null);

const parsed = parseTrackSamples([
  [8.67, 49.4],
  ["nope"],
  [8.68, 49.4],
]);
assert.equal(parsed.length, 2);

const long = Array.from({ length: 80 }, (_, i) => [8.67 + i * 0.001, 49.4]);
const sampled = parseTrackSamples(long, 40);
assert.ok(sampled.length <= 40);
assert.deepEqual(sampled[0], long[0]);
assert.deepEqual(sampled[sampled.length - 1], long[long.length - 1]);

console.log("placeOnTrack.test.ts OK");
