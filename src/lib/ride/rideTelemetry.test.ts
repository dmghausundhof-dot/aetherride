/**
 * Run: npx tsx src/lib/ride/rideTelemetry.test.ts
 */
import assert from "node:assert/strict";
import {
  buildRideTelemetry,
  gradeBand,
  gradeMapLayers,
  GRADE_COLORS,
  haversineM,
  honestClimbM,
  nearestSample,
} from "./rideTelemetry";
import { terrainCaption } from "./terrainCaption";

function testEmpty() {
  assert.equal(buildRideTelemetry([]).samples.length, 0);
  assert.equal(buildRideTelemetry(null).channels.elev, false);
  assert.equal(buildRideTelemetry([{ lat: 48, lng: 8 }]).totalDistKm, 0);
}

function testClimbAndGrade() {
  const start = { lat: 48.0, lng: 8.0, elev: 200, time: 1_700_000_000_000 };
  const endLat = 48.0 + 1000 / 111_320;
  const end = {
    lat: endLat,
    lng: 8.0,
    elev: 300,
    time: 1_700_000_000_000 + 240_000,
  };
  const hop = haversineM(start.lat, start.lng, end.lat, end.lng);
  assert.ok(hop > 900 && hop < 1100, `hop ${hop}`);

  const t = buildRideTelemetry([start, end]);
  assert.equal(t.channels.elev, true);
  assert.equal(t.elevSource, "gps");
  assert.ok(t.climbM >= 90 && t.climbM <= 110, `climb ${t.climbM}`);
  assert.equal(t.descentM, 0);
  const g = t.samples[1].gradePct;
  assert.ok(g != null && g > 8 && g < 12, `grade ${g}`);
  assert.equal(t.samples[1].band, "steep_up");
  assert.ok(t.maxSpeedKmh != null && t.maxSpeedKmh > 10 && t.maxSpeedKmh < 20);
}

function testDescent() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 400 },
    { lat: 48.0 + 800 / 111_320, lng: 8.0, elev: 280 },
  ]);
  assert.ok(t.descentM >= 110 && t.descentM <= 130, `descent ${t.descentM}`);
  assert.equal(t.climbM, 0);
  assert.equal(t.samples[1].band, "steep_down");
}

function testElevGap() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 400 / 111_320, lng: 8.0 },
    { lat: 48.0 + 800 / 111_320, lng: 8.0, elev: 240 },
  ]);
  assert.ok(t.gapKm > 0.2, `gap ${t.gapKm}`);
  assert.equal(t.samples[1].elevM, null);
  assert.equal(t.samples[1].band, "gap");
}

function testNoFakeGradeOnJitter() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 2 / 111_320, lng: 8.0, elev: 212 },
  ]);
  assert.equal(t.samples[1].gradePct, null);
  assert.equal(t.samples[1].band, "gap");
}

function testSensorsOptional() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200, hr: 132, cad: 78, power: 190, lean: 8, g: 1.4 },
    {
      lat: 48.0 + 500 / 111_320,
      lng: 8.0,
      elev: 210,
      hr: 148,
      cad: 82,
      power: 210,
      lean: 12,
      g: 2.1,
      impact: 1,
    },
  ]);
  assert.equal(t.channels.hr, true);
  assert.equal(t.channels.cad, true);
  assert.equal(t.channels.power, true);
  assert.equal(t.channels.lean, true);
  assert.equal(t.channels.g, true);
  assert.equal(t.channels.impact, true);
  assert.equal(t.impactCount, 1);
  assert.ok((t.avgHr ?? 0) > 130);
  assert.ok((t.maxLean ?? 0) >= 12);

  const bare = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 500 / 111_320, lng: 8.0, elev: 210 },
  ]);
  assert.equal(bare.channels.hr, false);
  assert.equal(bare.channels.impact, false);
}

function testGradeBandsAndLayers() {
  assert.equal(gradeBand(9), "steep_up");
  assert.equal(gradeBand(4), "up");
  assert.equal(gradeBand(0), "roll");
  assert.equal(gradeBand(-5), "down");
  assert.equal(gradeBand(-12), "steep_down");
  assert.equal(gradeBand(null), "gap");

  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 600 / 111_320, lng: 8.0, elev: 260 },
    { lat: 48.0 + 1200 / 111_320, lng: 8.0, elev: 250 },
  ]);
  const layers = gradeMapLayers(t);
  assert.ok(layers.length >= 1);
  assert.ok(layers.every((l) => l.coordinates.length >= 2));
  assert.equal(layers[0].color, GRADE_COLORS[layers[0].band]);
}

function testNearest() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 400 / 111_320, lng: 8.0, elev: 220 },
    { lat: 48.0 + 800 / 111_320, lng: 8.0, elev: 240 },
  ]);
  const hit = nearestSample(t, t.totalDistKm / 2);
  assert.ok(hit);
  assert.ok(hit!.distKm > 0);
}

function testHonestClimbPrefersTelemetry() {
  const track = [
    { lat: 48.0, lng: 8.0, elev: 200, time: 0 },
    { lat: 48.0 + 1000 / 111_320, lng: 8.0, elev: 300, time: 240 },
  ];
  const climb = honestClimbM(track, 800);
  assert.ok(climb >= 90 && climb <= 110, `honest climb ${climb}`);
  assert.equal(honestClimbM([], 120), 120);
  assert.equal(honestClimbM(null, 0), 0);
  const flat = [
    { lat: 48.0, lng: 8.0, elev: 200, time: 0 },
    { lat: 48.0 + 800 / 111_320, lng: 8.0, elev: 201, time: 180 },
  ];
  assert.equal(honestClimbM(flat, 800), 0, "GPS elev wins even when climb is 0");
}

testEmpty();
testClimbAndGrade();
testDescent();
testElevGap();
testNoFakeGradeOnJitter();
testSensorsOptional();
testGradeBandsAndLayers();
testNearest();
function testTerrainCaption() {
  const t = buildRideTelemetry([
    { lat: 48.0, lng: 8.0, elev: 200 },
    { lat: 48.0 + 1000 / 111_320, lng: 8.0, elev: 300 },
  ]);
  const cap = terrainCaption(t, "hm");
  assert.ok(cap && cap.includes("hm"), cap);
  assert.equal(terrainCaption(buildRideTelemetry([]), "hm"), undefined);
}

testHonestClimbPrefersTelemetry();
testTerrainCaption();
console.log("rideTelemetry.test.ts OK");
