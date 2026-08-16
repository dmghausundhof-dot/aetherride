/**
 * Smoke: npx tsx src/lib/export/gpx.test.ts
 */
import assert from "node:assert/strict";
import { rideHasExportableTrack, rideToGpx } from "./gpx";
import type { Ride } from "@/types";

const empty = {
  id: "r1",
  bikeId: "b1",
  startTime: "2026-04-01T10:00:00.000Z",
  durationSec: 3600,
  distanceM: 12000,
  elevationGainM: 400,
  sportType: "all_mountain",
  track: [],
  summaryMetrics: {
    gForcePeak: 0,
    gForceRms: 0,
    leanAngleMax: 0,
    impactCount: 0,
    flowScore: 0,
  },
} as Ride;

const emptyGpx = rideToGpx(empty);
assert.ok(emptyGpx.includes("<gpx"));
assert.equal(emptyGpx.includes("47.45"), false);
assert.equal(emptyGpx.includes("12.15"), false);
assert.ok(emptyGpx.includes("kein GPS-Track"));
assert.equal(rideHasExportableTrack(empty), false);

const withTrack = {
  ...empty,
  track: [
    { lat: 47.99, lng: 7.85, elev: 280, time: 0 },
    { lat: 48.0, lng: 7.86, elev: 300, time: 60 },
  ],
} as Ride;
const gpx = rideToGpx(withTrack, "Demo");
assert.ok(gpx.includes("47.99"));
assert.ok(gpx.includes("7.85"));
assert.equal(rideHasExportableTrack(withTrack), true);
assert.equal(gpx.includes("<gpxtpx:hr>"), false);

const withHr = {
  ...empty,
  track: [
    { lat: 47.99, lng: 7.85, elev: 280, time: 0, hr: 132, cad: 78 },
    { lat: 48.0, lng: 7.86, elev: 300, time: 60, hr: 140 },
  ],
} as Ride;
const gpxHr = rideToGpx(withHr, "Demo");
assert.ok(gpxHr.includes("<gpxtpx:hr>132</gpxtpx:hr>"));
assert.ok(gpxHr.includes("<gpxtpx:cad>78</gpxtpx:cad>"));
assert.ok(gpxHr.includes("<gpxtpx:hr>140</gpxtpx:hr>"));

console.log("gpx export honesty ok");
