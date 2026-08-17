/**
 * npx tsx src/lib/routing/routeVariant.test.ts
 */
import assert from "node:assert/strict";
import { buildValhallaCosting, getProfile, isTrailSuitable } from "./profiles";
import {
  applyRouteVariant,
  parseRouteVariant,
  variantNeedsValhalla,
} from "./routeVariant";

assert.equal(parseRouteVariant("flatter"), "flatter");
assert.equal(parseRouteVariant("UNPAVED"), "unpaved");
assert.equal(parseRouteVariant("nope"), "planned");

const planned = buildValhallaCosting("mtb_allmountain");
const bike = planned.costing_options.bicycle!;
const flatter = applyRouteVariant(planned, "flatter");
const unpaved = applyRouteVariant(planned, "unpaved");

assert.ok(
  (flatter.costing_options.bicycle?.use_hills ?? 1) < bike.use_hills,
  "flatter lowers use_hills"
);
assert.equal(bike.use_hills, 0.75, "original costing not mutated");
assert.ok(
  (unpaved.costing_options.bicycle?.avoid_bad_surfaces ?? 1) <
    bike.avoid_bad_surfaces,
  "unpaved lowers avoid_bad_surfaces"
);
assert.ok(
  (unpaved.costing_options.bicycle?.use_roads ?? 1) < bike.use_roads,
  "unpaved lowers use_roads"
);

const profile = getProfile("mtb_allmountain");
assert.equal(profile.maxMtbScale, 3);
assert.equal(isTrailSuitable("mtb_allmountain", { mtb_scale: 2 }), true);
assert.equal(isTrailSuitable("mtb_allmountain", { mtb_scale: 4 }), false);

assert.equal(variantNeedsValhalla("planned"), false);
assert.equal(variantNeedsValhalla("flatter"), true);

const hike = applyRouteVariant(buildValhallaCosting("hiking"), "flatter");
assert.ok(
  (hike.costing_options.pedestrian?.use_hills ?? 1) < 0.6,
  "hiking flatter lowers pedestrian use_hills"
);

console.log("routeVariant.test.ts OK");
