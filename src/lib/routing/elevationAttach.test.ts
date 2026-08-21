/**
 * npx tsx src/lib/routing/elevationAttach.test.ts
 */
import assert from "node:assert/strict";
import {
  attachRealElevToTrack,
  elevationSourceIsDemo,
  trackHasRealElev,
  trackElevSamplesFromPoints,
} from "./elevationAttach";
import { mappeElevSpark } from "@/lib/tours/mappeList";

const line = [
  [8.6, 49.4],
  [8.61, 49.4],
  [8.62, 49.4],
  [8.63, 49.4],
];

const zipped = attachRealElevToTrack(line, [
  { elev: 100 },
  { elev: 110 },
  { elev: 140 },
  { elev: 130 },
]);
assert.deepEqual(
  zipped.map((p) => p[2]),
  [100, 110, 140, 130],
);
assert.ok(mappeElevSpark(zipped).length > 0);

const placed = attachRealElevToTrack(line, [
  { elev: 90, lat: 49.4, lng: 8.6 },
  { elev: 160, lat: 49.4, lng: 8.63 },
]);
assert.equal(placed[0]![2], 90);
assert.equal(placed[1]!.length, 2);
assert.equal(placed[3]![2], 160);

const keep = attachRealElevToTrack(
  [
    [8.6, 49.4, 42],
    [8.61, 49.4],
    [8.62, 49.4],
    [8.63, 49.4],
  ],
  [
    { elev: 90, lat: 49.4, lng: 8.6 },
    { elev: 160, lat: 49.4, lng: 8.61 },
  ],
);
assert.equal(keep[0]![2], 42);
assert.equal(keep[1]![2], 160);

const demo = attachRealElevToTrack(
  line,
  [
    { elev: 100 },
    { elev: 200 },
    { elev: 300 },
    { elev: 400 },
  ],
  { source: "demo" },
);
assert.ok(demo.every((p) => p.length === 2));
assert.equal(elevationSourceIsDemo("demo"), true);
assert.equal(trackHasRealElev(line), false);
assert.equal(trackHasRealElev([[8.6, 49.4, 120], [8.7, 49.5]]), true);

const samples = trackElevSamplesFromPoints([
  { lat: 49.4, lng: 8.6, elevM: 110, distKm: 0 },
  { lat: 49.4, lng: 8.61, elevM: null, distKm: 0.8 },
]);
assert.equal(samples.length, 1);
assert.equal(samples[0]?.elev, 110);

console.log("elevationAttach.test.ts ok");
