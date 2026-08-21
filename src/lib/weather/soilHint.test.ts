/**
 * npx tsx src/lib/weather/soilHint.test.ts
 */
import assert from "node:assert/strict";
import {
  computeSoilTrailHint,
  soilClassForProfile,
  soilTauHours,
  trailHintFromInstantPrecip,
  trailHintFromWeightedMm,
  weightedPrecipMm,
} from "./soilHint";

assert.equal(soilClassForProfile("road"), "asphalt");
assert.equal(soilClassForProfile("urban"), "asphalt");
assert.equal(soilClassForProfile("mtb_enduro"), "earth");
assert.equal(soilClassForProfile("mtb_am"), "earth");
assert.equal(soilClassForProfile("emtb"), "earth");
assert.equal(soilClassForProfile("gravel"), "mixed");
assert.equal(soilClassForProfile("ebike"), "mixed");
assert.equal(soilClassForProfile(undefined), "mixed");

assert.equal(soilTauHours("asphalt"), 16);
assert.equal(soilTauHours("earth"), 48);
assert.equal(soilTauHours("mixed"), 32);

assert.equal(trailHintFromInstantPrecip(0), "dry_likely");
assert.equal(trailHintFromInstantPrecip(1), "damp_possible");
assert.equal(trailHintFromInstantPrecip(5), "wet_likely");
assert.equal(trailHintFromWeightedMm(0), "dry_likely");
assert.equal(trailHintFromWeightedMm(2), "damp_possible");
assert.equal(trailHintFromWeightedMm(8), "wet_likely");

const now = new Date("2026-08-20T18:00:00.000Z");
function hourAgo(h: number, mm: number) {
  const t = new Date(now.getTime() - h * 3600_000);
  return { time: t.toISOString(), precipitation: mm };
}

// 40 mm 48 h ago, nothing since — earth still wet, asphalt mostly drained.
const burst48 = Array.from({ length: 72 }, (_, i) =>
  hourAgo(i, i === 48 ? 40 : 0)
);
const earthW = weightedPrecipMm(burst48, now, soilTauHours("earth"));
const asphaltW = weightedPrecipMm(burst48, now, soilTauHours("asphalt"));
assert.ok(earthW >= 8, `earth 40mm/48h weighted ${earthW}`);
assert.ok(asphaltW < 8, `asphalt 40mm/48h weighted ${asphaltW}`);

const earthHint = computeSoilTrailHint({
  hourly: burst48,
  now,
  profile: "mtb_allmountain",
});
assert.equal(earthHint.trailHint, "wet_likely");
assert.equal(earthHint.source, "soil_72h");
assert.ok((earthHint.precip72hMm ?? 0) >= 8);

const asphaltHint = computeSoilTrailHint({
  hourly: burst48,
  now,
  profile: "road",
});
assert.ok(
  asphaltHint.trailHint === "damp_possible" ||
    asphaltHint.trailHint === "dry_likely",
  asphaltHint.trailHint
);
assert.equal(asphaltHint.source, "soil_72h");

const mixedHint = computeSoilTrailHint({
  hourly: burst48,
  now,
  profile: "gravel",
});
assert.equal(mixedHint.trailHint, "wet_likely");

const dryNow = computeSoilTrailHint({
  hourly: Array.from({ length: 72 }, (_, i) => hourAgo(i, 0)),
  now,
  profile: "gravel",
});
assert.equal(dryNow.trailHint, "dry_likely");

const fallbackCurrent = computeSoilTrailHint({
  hourly: [],
  currentPrecipMm: 6,
  dailyPrecipMm: 0,
});
assert.equal(fallbackCurrent.trailHint, "wet_likely");
assert.equal(fallbackCurrent.source, "current_precip");
assert.equal(fallbackCurrent.precip72hMm, null);

const fallbackDaily = computeSoilTrailHint({
  hourly: null,
  currentPrecipMm: 0,
  dailyPrecipMm: 3,
});
assert.equal(fallbackDaily.trailHint, "damp_possible");
assert.equal(fallbackDaily.source, "daily_sum");

const allowed: Set<string> = new Set([
  "dry_likely",
  "damp_possible",
  "wet_likely",
]);
assert.ok(allowed.has(earthHint.trailHint));
assert.ok(allowed.has(asphaltHint.trailHint));

console.log("soilHint.test.ts OK");
