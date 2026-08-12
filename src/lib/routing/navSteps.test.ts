/**
 * Smoke: Engine-Steps + NavCues.
 * npx tsx src/lib/routing/navSteps.test.ts
 */
import assert from "node:assert/strict";
import {
  stepsFromDemoGeometry,
  stepsFromOsrmLegs,
  nextEngineStep,
  pickAnnounce,
  announceDistancesForSpeed,
} from "./navSteps";
import { resolveNavCues, nextCue } from "./navCues";

const coords: [number, number][] = [
  [8.4, 48.6],
  [8.41, 48.6],
  [8.42, 48.61],
  [8.43, 48.62],
];
const steps = stepsFromDemoGeometry(coords);
assert.ok(steps.length >= 2);
assert.equal(steps[0].type, "start");
assert.equal(steps[steps.length - 1].type, "arrive");

const osrm = stepsFromOsrmLegs([
  {
    steps: [
      {
        distance: 100,
        maneuver: { type: "depart", location: [8.4, 48.6] },
      },
      {
        distance: 200,
        name: "Trail",
        maneuver: {
          type: "turn",
          modifier: "left",
          location: [8.41, 48.61],
        },
      },
      {
        distance: 0,
        maneuver: { type: "arrive", location: [8.42, 48.62] },
      },
    ],
  },
]);
assert.ok(osrm.some((s) => s.instruction.includes("Links")));
assert.equal(osrm.find((s) => s.streetName)?.streetName, "Trail");

const cues = resolveNavCues({ steps });
assert.ok(cues.length >= 1);
const nxt = nextEngineStep(steps, 0);
assert.ok(nxt);

const spoken = new Set<string>();
const ann = pickAnnounce(nxt!.step, 380, 20, spoken);
assert.ok(ann == null || ann.length > 0);
assert.deepEqual(announceDistancesForSpeed(20), [400, 150, 30]);
assert.ok(announceDistancesForSpeed(40)[0] > 50);

const cue = nextCue(cues, 0);
assert.ok(cue);

console.log("navSteps.test.ts: ok");
