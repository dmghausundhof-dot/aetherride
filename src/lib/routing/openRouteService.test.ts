/**
 * OpenRouteService mapping + extras — no network.
 * Run: npx tsx src/lib/routing/openRouteService.test.ts
 */
import assert from "node:assert/strict";
import {
  orsDirectionsOptions,
  orsProfileFor,
  orsPreferredForGraphhopperBasic,
  orsTypeToNav,
  parseOrsExtras,
  pointPairInDach,
  stepsFromOrs,
} from "./openRouteService";

assert.equal(orsProfileFor("road"), "cycling-road");
assert.equal(orsProfileFor("gravel"), "cycling-regular");
assert.equal(orsProfileFor("urban"), "cycling-regular");
assert.equal(orsProfileFor("mtb_enduro"), "cycling-mountain");
assert.equal(orsProfileFor("downhill"), "cycling-mountain");
assert.equal(orsProfileFor("mtb_allmountain"), "cycling-mountain");
assert.equal(orsProfileFor("emtb"), "cycling-mountain");
assert.equal(orsProfileFor("ebike"), "cycling-electric");
assert.equal(orsProfileFor("hiking"), "foot-hiking");
assert.equal(orsProfileFor("auto"), "driving-car");

assert.equal(orsPreferredForGraphhopperBasic("gravel"), true);
assert.equal(orsPreferredForGraphhopperBasic("mtb_enduro"), true);
assert.equal(orsPreferredForGraphhopperBasic("downhill"), true);
assert.equal(orsPreferredForGraphhopperBasic("road"), false);
assert.equal(orsPreferredForGraphhopperBasic("urban"), false);

assert.equal(orsTypeToNav(11), "start");
assert.equal(orsTypeToNav(10), "arrive");
assert.equal(orsTypeToNav(0), "turn");
assert.equal(orsTypeToNav(7), "roundabout");
assert.equal(orsTypeToNav(9), "uturn");

const extras = parseOrsExtras(
  {
    surface: {
      summary: [
        { value: 3, distance: 8000 },
        { value: 9, distance: 2000 },
      ],
    },
    steepness: { summary: [{ value: 4, distance: 400 }] },
    traildifficulty: { summary: [{ value: 1, distance: 500 }] },
  },
  10000
);
assert.equal(extras.dominantSurface, "Asphalt");
assert.equal(extras.surfaces[0].label, "Asphalt");
assert.equal(extras.steepnessHint, "hügelig");
assert.equal(extras.trailDifficultyMax, 1);
assert.deepEqual(extras.waytypes, []);

assert.ok(orsDirectionsOptions("urban")?.avoid_features);
assert.ok(
  JSON.stringify(orsDirectionsOptions("mtb_enduro")).includes("highways")
);
assert.ok(
  JSON.stringify(orsDirectionsOptions("gravel")).includes("green")
);

assert.equal(pointPairInDach([[13.405, 52.52], [13.41, 52.53]]), true);
assert.equal(pointPairInDach([[0, 0], [1, 1]]), false);

const steps = stepsFromOrs(
  [
    {
      type: 11,
      instruction: "Losfahren",
      name: "Unter den Linden",
      distance: 40,
      way_points: [0, 1],
    },
    {
      type: 10,
      instruction: "Ziel erreicht",
      distance: 0,
      way_points: [1, 1],
    },
  ],
  [
    [13.4, 52.52],
    [13.41, 52.53],
  ]
);
assert.equal(steps[0].type, "start");
assert.equal(steps[0].streetName, "Unter den Linden");
assert.equal(steps[1].type, "arrive");

console.log("openRouteService.test.ts OK");
