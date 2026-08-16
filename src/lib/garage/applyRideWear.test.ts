/**
 * npx tsx src/lib/garage/applyRideWear.test.ts
 */
import assert from "node:assert/strict";
import {
  applyRideWearToBike,
  componentWearSinceInstall,
  honestRideDistanceM,
  shouldAssignRideWear,
} from "./applyRideWear";
import type { Bike, BikeComponent } from "../../types/garage";

assert.equal(honestRideDistanceM({ recordedM: 0, trackM: 0 }), 0);
assert.equal(honestRideDistanceM({ recordedM: 1200, trackM: 800 }), 1200);
assert.equal(honestRideDistanceM({ recordedM: 100, trackM: 140 }), 140);
assert.equal(honestRideDistanceM({ recordedM: undefined, trackM: NaN }), 0);

assert.equal(
  shouldAssignRideWear({ bikeId: "unknown", distanceM: 5000, durationSec: 600 }),
  false
);
assert.equal(
  shouldAssignRideWear({ bikeId: "", distanceM: 5000, durationSec: 600 }),
  false
);
assert.equal(
  shouldAssignRideWear({ bikeId: "b1", distanceM: 0, durationSec: 0 }),
  false
);
assert.equal(
  shouldAssignRideWear({ bikeId: "b1", distanceM: 800, durationSec: 0 }),
  true
);

const now = new Date().toISOString();
const bike: Bike = {
  id: "b1",
  name: "Luna",
  category: "mtb_am",
  type: "all_mountain",
  isActive: true,
  isEbike: false,
  createdAt: now,
  updatedAt: now,
  components: [],
  setups: [],
  totalOdometerKm: 1000,
  totalHours: 40,
};

const worn = applyRideWearToBike(bike, { distanceM: 12500, durationSec: 3600 });
assert.equal(worn.totalOdometerKm, 1012.5);
assert.equal(worn.totalHours, 41);
assert.equal(bike.totalOdometerKm, 1000, "input bike stays");

const skipped = applyRideWearToBike(bike, { distanceM: 0, durationSec: 0 });
assert.equal(skipped.totalOdometerKm, 1000);

const chain: BikeComponent = {
  id: "c1",
  bikeId: "b1",
  slot: "chain",
  installedAt: now,
  odometerKmAtInstall: 1000,
  hoursAtInstall: 40,
  attributes: [],
  currentSettings: {},
};
const wear = componentWearSinceInstall(worn, chain);
assert.equal(wear.km, 12.5);
assert.equal(wear.hours, 1);

console.log("applyRideWear.test.ts OK");
