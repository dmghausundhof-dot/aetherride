/**
 * OSM round-trip helpers — no network.
 * Run: npx tsx src/lib/routing/osmRoundTrip.test.ts
 */
import assert from "node:assert/strict";
import { orsDirectionsOptions, orsRoundTripRequestBody } from "./openRouteService";
import {
  defaultLoopSpeedKmh,
  loopOsmHonesty,
  normalizeRoundTripSeed,
  profileAllowsOsmRoundTrip,
  riderFacingLoopWarnings,
  roundTripLengthFromInput,
  roundTripLengthM,
  roundTripWaypointCount,
} from "./osmRoundTrip";

assert.equal(profileAllowsOsmRoundTrip("gravel"), true);
assert.equal(profileAllowsOsmRoundTrip("road"), true);
assert.equal(profileAllowsOsmRoundTrip("urban"), true);
assert.equal(profileAllowsOsmRoundTrip("ebike"), true);
assert.equal(profileAllowsOsmRoundTrip("mtb_allmountain"), false);
assert.equal(profileAllowsOsmRoundTrip("mtb_enduro"), false);
assert.equal(profileAllowsOsmRoundTrip("downhill"), false);
assert.equal(profileAllowsOsmRoundTrip("emtb"), false);
assert.equal(profileAllowsOsmRoundTrip("hiking"), false);
assert.equal(profileAllowsOsmRoundTrip("auto"), false);

assert.equal(defaultLoopSpeedKmh("gravel"), 18);
assert.equal(defaultLoopSpeedKmh("road"), 25.2);
assert.equal(defaultLoopSpeedKmh("urban"), 21.6);
assert.equal(defaultLoopSpeedKmh("ebike"), 21.6);

assert.equal(roundTripLengthM("gravel", 0), roundTripLengthM("gravel", 60));
assert.equal(roundTripLengthM("gravel", 60), 18_000);
assert.equal(roundTripLengthM("road", 60), 25_200);
assert.ok(roundTripLengthM("gravel", 1) >= 5_000);
assert.ok(roundTripLengthM("road", 600) <= 120_000);

assert.equal(roundTripLengthFromInput({ profile: "gravel", lengthKm: 25 }), 25_000);
assert.equal(
  roundTripLengthFromInput({ profile: "gravel", minutes: 60 }),
  18_000
);

assert.equal(roundTripWaypointCount(10_000), 4);
assert.equal(roundTripWaypointCount(40_000), 5);
assert.equal(roundTripWaypointCount(80_000), 6);

assert.equal(normalizeRoundTripSeed(undefined), 1);
assert.equal(normalizeRoundTripSeed(0), 1);
assert.equal(normalizeRoundTripSeed(3), 3);

const body = orsRoundTripRequestBody({
  profile: "gravel",
  start: [8.59, 49.3],
  lengthM: 18_000,
  seed: 2,
});
assert.deepEqual(body.coordinates, [[8.59, 49.3]]);
const options = body.options as {
  round_trip: { length: number; points: number; seed: number };
};
assert.equal(options.round_trip.length, 18_000);
assert.equal(options.round_trip.points, 4);
assert.equal(options.round_trip.seed, 2);
const gravelOpts = orsDirectionsOptions("gravel") as Record<string, unknown>;
assert.ok(JSON.stringify(options).includes("green"));
assert.ok(gravelOpts.avoid_features);

assert.equal(
  loopOsmHonesty("de"),
  "Rundkurs auf OSM-Wegen — kein Trailforks-Trail"
);
const rider = riderFacingLoopWarnings(
  [
    "ORS Oberfläche überwiegend Asphalt",
    "OpenRouteService Fallback: GraphHopper",
    "Wenig Track/Schotter auf dieser Linie — OSM-Wege antippen und anhängen.",
  ],
  "de"
);
assert.equal(rider[0], loopOsmHonesty("de"));
assert.ok(rider.some((w) => w.includes("Asphalt")));
assert.ok(rider.some((w) => /Track|Schotter/.test(w)));
for (const w of rider) {
  const lower = w.toLowerCase();
  assert.ok(!lower.includes("openrouteservice"), w);
  assert.ok(!lower.includes("graphhopper"), w);
  assert.ok(!/\bors\b/.test(lower), w);
}

console.log("osmRoundTrip.test.ts OK");
