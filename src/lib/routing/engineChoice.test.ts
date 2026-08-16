/**
 * Engine picker vs costing: GraphHopper / ORS translate the same profile.
 * Gravity approach is auto/hiking — never downhill bicycle — on both engines.
 * Run: npx tsx src/lib/routing/engineChoice.test.ts
 */
import assert from "node:assert/strict";
import {
  engineIsConfigured,
  graphhopperProfile,
  nativeCostingFor,
  parseRoutingEngineParam,
  resolveRouteEngine,
  SELECTABLE_ROUTING_ENGINES,
} from "./engine";
import { approachCostingForBike, sessionCostingForBike } from "./profiles";
import { orsPreferredForGraphhopperBasic, orsProfileFor } from "./openRouteService";

assert.deepEqual(SELECTABLE_ROUTING_ENGINES, [
  "graphhopper",
  "openrouteservice",
]);

assert.equal(parseRoutingEngineParam("graphhopper"), "graphhopper");
assert.equal(parseRoutingEngineParam("gh"), "graphhopper");
assert.equal(parseRoutingEngineParam("openrouteservice"), "openrouteservice");
assert.equal(parseRoutingEngineParam("ors"), "openrouteservice");
assert.equal(parseRoutingEngineParam("hybrid"), undefined);
assert.equal(parseRoutingEngineParam("auto"), undefined);
assert.equal(parseRoutingEngineParam(""), undefined);

assert.equal(orsPreferredForGraphhopperBasic("auto"), false);
assert.equal(orsPreferredForGraphhopperBasic("hiking"), false);

const prev = {
  GRAPHHOPPER_API_KEY: process.env.GRAPHHOPPER_API_KEY,
  OPENROUTESERVICE_API_KEY: process.env.OPENROUTESERVICE_API_KEY,
  GRAPHHOPPER_ALLOW_EXTENDED_PROFILES:
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES,
  ROUTING_ENGINE: process.env.ROUTING_ENGINE,
};

function restoreEnv() {
  for (const [k, v] of Object.entries(prev)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
}

try {
  delete process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES;
  delete process.env.ROUTING_ENGINE;
  process.env.GRAPHHOPPER_API_KEY = "test-gh";
  process.env.OPENROUTESERVICE_API_KEY = "test-ors";

  assert.equal(engineIsConfigured("graphhopper"), true);
  assert.equal(engineIsConfigured("openrouteservice"), true);

  assert.equal(nativeCostingFor("auto", "graphhopper"), "car");
  assert.equal(nativeCostingFor("auto", "openrouteservice"), "driving-car");
  assert.equal(nativeCostingFor("auto", "valhalla"), "auto");
  assert.equal(nativeCostingFor("auto", "osrm"), "driving");

  assert.equal(nativeCostingFor("hiking", "graphhopper"), "foot");
  assert.equal(nativeCostingFor("hiking", "openrouteservice"), "foot-hiking");
  assert.equal(nativeCostingFor("hiking", "valhalla"), "pedestrian");
  assert.equal(nativeCostingFor("hiking", "osrm"), "foot");

  assert.equal(nativeCostingFor("mtb_allmountain", "graphhopper"), "bike");
  assert.equal(
    nativeCostingFor("mtb_allmountain", "openrouteservice"),
    "cycling-mountain"
  );

  // If someone still sends downhill A→B, both engines bicycle-cost it —
  // gravity approach must not choose that profile.
  assert.equal(nativeCostingFor("downhill", "graphhopper"), "bike");
  assert.equal(nativeCostingFor("downhill", "openrouteservice"), "cycling-mountain");
  assert.equal(approachCostingForBike("dh", "auto"), "auto");
  assert.equal(approachCostingForBike("dh", "walk"), "hiking");
  assert.notEqual(approachCostingForBike("dh", "auto"), "downhill");
  assert.equal(sessionCostingForBike("dh", "mtb_allmountain"), "auto");
  assert.equal(graphhopperProfile("auto"), "car");
  assert.equal(orsProfileFor("auto"), "driving-car");

  const pickedGh = resolveRouteEngine("mtb_enduro", "graphhopper");
  assert.equal(pickedGh.kind, "graphhopper");
  assert.equal(pickedGh.fallback, false);
  assert.equal(nativeCostingFor("mtb_enduro", pickedGh.kind), "bike");

  const pickedOrs = resolveRouteEngine("auto", "openrouteservice");
  assert.equal(pickedOrs.kind, "openrouteservice");
  assert.equal(nativeCostingFor("auto", pickedOrs.kind), "driving-car");

  const hybridMtb = resolveRouteEngine("mtb_enduro");
  assert.equal(hybridMtb.kind, "openrouteservice");

  const hybridAuto = resolveRouteEngine("auto");
  assert.equal(hybridAuto.kind, "graphhopper");
  assert.equal(nativeCostingFor("auto", hybridAuto.kind), "car");

  delete process.env.GRAPHHOPPER_API_KEY;
  const missingGh = resolveRouteEngine("auto", "graphhopper");
  assert.equal(missingGh.fallback, true);
  assert.equal(missingGh.requested, "graphhopper");
  assert.notEqual(missingGh.kind, "demo");
} finally {
  restoreEnv();
}

console.log("engineChoice.test.ts OK");
