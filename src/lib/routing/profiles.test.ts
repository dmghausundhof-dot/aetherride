/**
 * RideProfile SSOT — Akzeptanzkriterien.
 * Ausführen: npx tsx src/lib/routing/profiles.test.ts
 */
import assert from "node:assert/strict";
import {
  DEFAULT_DISCOVER_PROFILE,
  RIDE_PROFILES,
  DISCOVER_PROFILE_CHIPS,
  accessCostingForRideProfile,
  approachCostingForBike,
  discoverNavProfile,
  discoverNavProfileChipVisible,
  discoverProfileMenuForSports,
  sessionCostingForBike,
  suggestedApproachKind,
  trailFitsBikeCategory,
  buildValhallaCosting,
  difficultiesFromTrailLabel,
  getProfile,
  graphhopperCustomModel,
  graphhopperCustomModelShouldSend,
  isGraphhopperCustomModelRejected,
  isLabeledTrailSuitable,
  isRoutingProfile,
  isTrailSuitable,
  listBikeProfiles,
  listProfiles,
  navSessionForBike,
  overlayScaleLabels,
  overlayScaleMatchValues,
  prefersUnratedTrails,
  routeCostingProfile,
  trailFilterExpression,
  type RideProfileId,
} from "./profiles";

const dh = getProfile("downhill");
assert.equal(dh.id, "downhill");
assert.equal(dh.label, "Downhill");
assert.equal(dh.shortLabel, "DH");
assert.equal(dh.category, "mtb");
assert.equal(dh.costing, "bicycle");
assert.deepEqual(dh.preferredDifficulties, ["s1", "s2", "s3plus"]);
assert.equal(dh.maxMtbScale, 6);
assert.equal(dh.bicycleOptions?.use_hills, 1.0);
assert.ok((dh.bicycleOptions?.use_roads ?? 1) <= 0.05);

assert.equal(isTrailSuitable("downhill", { mtb_scale: 2 }), true);
assert.equal(isTrailSuitable("downhill", { mtb_scale: "S2" }), true);
assert.equal(isTrailSuitable("downhill", { mtb_scale: 0 }), false);
assert.equal(isTrailSuitable("road", { mtb_scale: 2 }), false);
assert.equal(isTrailSuitable("mtb_enduro", { mtb_scale: 3 }), true);
assert.equal(isTrailSuitable("mtb_allmountain", { mtb_scale: 0 }), true);
assert.equal(isTrailSuitable("gravel", { mtb_scale: 3 }), false);

const costing = buildValhallaCosting("downhill");
assert.equal(costing.costing, "bicycle");
assert.equal(costing.costing_options.bicycle?.bicycle_type, "mountain");
assert.equal(costing.costing_options.bicycle?.use_hills, 1.0);
assert.equal(costing.costing_options.bicycle?.use_roads, 0.05);

const hikeCosting = buildValhallaCosting("hiking");
assert.equal(hikeCosting.costing, "pedestrian");
assert.equal(hikeCosting.costing_options.pedestrian?.walking_speed, 4.5);

const ids: RideProfileId[] = [
  "mtb_allmountain",
  "mtb_enduro",
  "gravel",
  "road",
  "ebike",
  "emtb",
  "downhill",
  "hiking",
];
assert.equal(listProfiles().length, 8);
assert.deepEqual(
  listProfiles()
    .map((p) => p.id)
    .sort(),
  [...ids].sort()
);
assert.equal(listBikeProfiles().length, 7);
assert.ok(!listBikeProfiles().some((p) => p.id === "hiking"));
for (const id of ids) {
  const p = RIDE_PROFILES[id];
  assert.equal(p.id, id);
  assert.ok(p.label.length > 0);
  assert.ok(p.routeColor.startsWith("#"));
  const c = buildValhallaCosting(id);
  assert.ok(c.costing === "bicycle" || c.costing === "pedestrian");
}

assert.deepEqual(overlayScaleLabels("downhill"), ["S1", "S2", "S3+"]);
assert.equal(prefersUnratedTrails("downhill"), false);
assert.equal(prefersUnratedTrails("mtb_allmountain"), true);
assert.deepEqual(overlayScaleLabels("road"), []);
const dhScaleValues = overlayScaleMatchValues("downhill");
assert.ok(dhScaleValues.includes("S1"));
assert.ok(dhScaleValues.includes("S3"));
assert.ok(dhScaleValues.includes("S3+"));
assert.ok(dhScaleValues.includes("3"));
assert.ok(!dhScaleValues.includes("S0"));
assert.ok(!dhScaleValues.includes("0"));

assert.deepEqual(difficultiesFromTrailLabel("S1–S2"), ["s1", "s2"]);
assert.equal(isLabeledTrailSuitable("downhill", "S2"), true);
assert.equal(isLabeledTrailSuitable("downhill", "S0"), false);
assert.equal(isLabeledTrailSuitable("road", "S1"), false);

const dhFilter = trailFilterExpression("downhill");
assert.ok(Array.isArray(dhFilter));
assert.ok(dhFilter.length > 0);

assert.equal(getProfile("downhill").edgeFactor("path", 2, "dirt"), 0.7);
assert.equal(getProfile("downhill").edgeFactor("motorway", 2, "asphalt"), null);
assert.equal(getProfile("road").acceptsHighway("path"), false);
assert.equal(getProfile("road").acceptsHighway("motorway"), false);
assert.equal(getProfile("road").edgeFactor("cycleway", null, "asphalt"), 0.72);
assert.equal(getProfile("road").edgeFactor("cycleway", null, ""), 0.72);
assert.ok(
  (getProfile("road").edgeFactor("cycleway", null, "asphalt") ?? 9) <
    (getProfile("road").edgeFactor("primary", null, "asphalt") ?? 0)
);
assert.equal(getProfile("gravel").edgeFactor("track", null, "gravel"), 0.75);
assert.equal(getProfile("gravel").edgeFactor("cycleway", null, "asphalt"), 0.9);
assert.ok(
  (getProfile("gravel").edgeFactor("track", null, "gravel") ?? 9) <
    (getProfile("gravel").edgeFactor("primary", null, "asphalt") ?? 0)
);
assert.equal(getProfile("ebike").edgeFactor("cycleway", null, "asphalt"), 0.8);

assert.equal(DEFAULT_DISCOVER_PROFILE, "urban");
assert.equal(graphhopperCustomModel("hiking"), null);
assert.ok(
  graphhopperCustomModel("urban")?.priority.some((r) =>
    r.if.includes("CYCLEWAY")
  )
);
assert.ok(
  graphhopperCustomModel("urban")?.priority.some(
    (r) => r.if.includes("TRACK") && r.multiply_by < 1
  ),
  "urban A–B must not prefer farm tracks"
);
assert.ok(
  graphhopperCustomModel("urban")?.priority.some(
    (r) => r.if.includes("PATH") && r.if.includes("GRASS") && r.multiply_by < 1
  ),
  "urban A–B must not prefer grass paths"
);
assert.ok(
  graphhopperCustomModel("gravel")?.priority.some((r) => r.if.includes("TRACK"))
);
assert.ok(
  graphhopperCustomModel("gravel")?.priority.some(
    (r) => r.if.includes("GRASS") && r.multiply_by < 1
  ),
  "grass farm tracks stay off gravel A–B"
);
assert.ok(
  graphhopperCustomModel("mtb_enduro")?.priority.some((r) =>
    r.if.includes("PATH")
  )
);

assert.equal(graphhopperCustomModel("auto"), null);
assert.equal(graphhopperCustomModelShouldSend({}), true);
assert.equal(graphhopperCustomModelShouldSend({ env: "0" }), false);
assert.equal(
  graphhopperCustomModelShouldSend({ rejectedThisProcess: true }),
  false,
);
assert.equal(
  isGraphhopperCustomModelRejected("Cannot use custom_model on this package"),
  true,
);
assert.equal(isGraphhopperCustomModelRejected("rate limit"), false);
assert.equal(isRoutingProfile("auto"), true);
assert.equal(navSessionForBike("dh"), "gravity");
assert.equal(navSessionForBike("mtb_am"), "pedal");
assert.equal(routeCostingProfile("dh"), "auto");
assert.equal(accessCostingForRideProfile("downhill"), "auto");
assert.equal(accessCostingForRideProfile("mtb_allmountain"), "mtb_allmountain");
assert.equal(discoverNavProfile("downhill"), "mtb_allmountain");
assert.equal(discoverNavProfile("mtb_enduro"), "mtb_allmountain");
assert.ok(!DISCOVER_PROFILE_CHIPS.includes("downhill"));
assert.ok(!DISCOVER_PROFILE_CHIPS.includes("auto"));
assert.equal(
  discoverNavProfileChipVisible(discoverProfileMenuForSports({ primary: "road" })),
  false,
  "ein Sport → kein Navi-Chip",
);
assert.equal(
  discoverNavProfileChipVisible(
    discoverProfileMenuForSports({
      primary: "road",
      sports: ["road", "gravel"],
    }),
  ),
  true,
  "zwei Sportarten → ein Chip, keine Rainbow-Leiste",
);
assert.equal(
  discoverProfileMenuForSports({
    primary: "mtb_enduro",
    sports: ["mtb_trail"],
  }).length,
  1,
  "Enduro+Trail fallen auf ein Navi-Profil",
);
assert.equal(discoverProfileMenuForSports().length, DISCOVER_PROFILE_CHIPS.length);
assert.ok(discoverNavProfileChipVisible(discoverProfileMenuForSports()));
assert.equal(sessionCostingForBike("dh", "mtb_allmountain"), "auto");
assert.equal(sessionCostingForBike("mtb_am", "mtb_allmountain"), "mtb_allmountain");
assert.equal(approachCostingForBike("dh", "auto"), "auto");
assert.equal(approachCostingForBike("dh", "walk"), "hiking");
assert.equal(approachCostingForBike("dh", "bicycle"), "mtb_allmountain");
assert.equal(
  suggestedApproachKind({ session: "gravity", distanceKm: 12 }),
  "auto"
);
assert.equal(
  suggestedApproachKind({ session: "gravity", distanceKm: 0.4 }),
  "walk"
);
assert.equal(
  suggestedApproachKind({ session: "pedal", distanceKm: 12 }),
  "bicycle"
);
assert.equal(trailFitsBikeCategory("road", "S3"), false);
assert.equal(trailFitsBikeCategory("dh", "S3"), true);
assert.equal(trailFitsBikeCategory("road", "offen"), true);

console.log("profiles.test.ts OK");
