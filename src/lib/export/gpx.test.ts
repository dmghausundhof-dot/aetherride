/**
 * Smoke: npx tsx src/lib/export/gpx.test.ts
 */
import assert from "node:assert/strict";
import { rideHasExportableTrack, rideToGpx } from "./gpx";
import { rideWithTrimmedTrack } from "@/lib/privacy/trimRide";
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
const gpx = rideToGpx({ ...withTrack, elevationGainM: 800 }, "Demo");
assert.ok(gpx.includes("47.99"));
assert.ok(gpx.includes("7.85"));
assert.equal(gpx.includes("800 hm"), false, "export must not use stored route climb");
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

const inZone = {
  ...empty,
  track: [
    { lat: 47.45, lng: 12.15, elev: 800, time: 0 },
    { lat: 47.451, lng: 12.151, elev: 801, time: 30 },
    { lat: 47.452, lng: 12.152, elev: 802, time: 60 },
    { lat: 47.453, lng: 12.153, elev: 803, time: 90 },
    { lat: 47.454, lng: 12.154, elev: 804, time: 120 },
  ],
} as Ride;
const trimmedHome = rideWithTrimmedTrack(inZone, [
  { id: "z1", label: "Home", lat: 47.45, lng: 12.15, radiusM: 2000 },
]);
assert.equal((trimmedHome.track ?? []).length, 0);

const longSensor = {
  ...empty,
  track: Array.from({ length: 24 }, (_, i) => ({
    lat: 48 + (i * 50) / 111320,
    lng: 8.0,
    elev: 200 + i,
    time: 1_700_000_000_000 + i * 4000,
    hr: 130 + i,
    cad: 80,
    lean: 7,
    g: 1.1,
    spd: 24,
    impact: i === 12 ? 1 : undefined,
  })),
} as Ride;
const trimmedKeep = rideWithTrimmedTrack(longSensor, []);
assert.ok((trimmedKeep.track?.length ?? 0) >= 8, "end-cap trim keeps middle");
for (const p of trimmedKeep.track ?? []) {
  assert.ok(p.hr != null, "hr survives privacy trim");
  assert.ok(p.elev != null, "elev survives privacy trim");
  assert.ok(p.lean != null, "lean survives privacy trim");
  assert.ok(p.time > 1e12, "epoch ms survives privacy trim");
}

const start = "2026-04-01T10:00:00.000Z";
const t0 = Date.parse(start);
const withEpoch = {
  ...empty,
  startTime: start,
  track: [
    { lat: 47.99, lng: 7.85, elev: 280, time: t0, hr: 132 },
    { lat: 48.0, lng: 7.86, elev: 300, time: t0 + 60_000 },
  ],
} as Ride;
const gpxEpoch = rideToGpx(withEpoch);
assert.ok(gpxEpoch.includes("2026-04-01T10:00:00.000Z"));
assert.ok(gpxEpoch.includes("2026-04-01T10:01:00.000Z"));
assert.equal(gpxEpoch.includes("56000"), false);

console.log("gpx export honesty ok");
