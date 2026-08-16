/**
 * Unit tests for getMaintenanceSummary (T-WA-00).
 * Run: npx tsx src/lib/maintenance/summary.test.ts
 */
import {
  getFleetMaintenanceDueCount,
  getMaintenanceSummary,
  lastRideForBike,
} from "./summary";
import type { Bike, MaintenanceInterval, Ride } from "@/types";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const bike = {
  id: "b1",
  name: "Spire",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  createdAt: "",
  updatedAt: "",
  components: [],
  setups: [],
  totalOdometerKm: 820,
  totalHours: 40,
} as Bike;

const chainInterval: MaintenanceInterval = {
  id: "i-chain",
  bikeId: "b1",
  slot: "chain",
  label: "Kettenverschleiß prüfen",
  intervalKm: 1000,
  lastDoneOdometerKm: 0,
  sourceLabel: "test",
  overriddenByUser: false,
};

const forkInterval: MaintenanceInterval = {
  id: "i-fork",
  bikeId: "b1",
  slot: "fork",
  label: "Gabel Lower-Leg Service",
  intervalHours: 50,
  lastDoneHours: 0,
  sourceLabel: "test",
  overriddenByUser: false,
};

// Empty
const empty = getMaintenanceSummary(null, []);
assert(empty.status === "empty", "empty status");
assert(empty.headline.includes("Werkstatt"), "empty headline");
assert(empty.href.includes("wizard"), "empty href wizard");

// Ok — low km
const ok = getMaintenanceSummary(
  { ...bike, totalOdometerKm: 100, totalHours: 5 },
  [chainInterval, forkInterval],
  { lastRideAt: "2026-08-01T10:00:00.000Z", lastRideDistanceKm: 32 }
);
assert(ok.status === "ok", `ok status got ${ok.status}`);
assert(ok.dueCount === 0, "ok dueCount");
assert(ok.headline.startsWith("Alles ok"), "ok headline");
assert(ok.headline.includes("letzte Fahrt"), "ok headline last ride");
assert(ok.href.includes("tab=maintenance"), "ok href");

// Due soon — 820/1000 = 82% on chain
const soon = getMaintenanceSummary(bike, [chainInterval, forkInterval]);
assert(soon.status === "due_soon", `due_soon got ${soon.status}`);
assert(soon.dueCount >= 1, "due soon count");
assert(soon.topItem?.shortLabel === "Kette", "top is chain");
assert(soon.headline.includes("bald checken"), `headline ${soon.headline}`);
assert(soon.headline.includes("Kette"), "headline has Kette");
assert(soon.shopHref?.includes("bike=b1"), `shopHref bike ${soon.shopHref}`);
assert(soon.shopHref?.includes("slot=chain"), `shopHref slot ${soon.shopHref}`);
assert(soon.shopHref?.includes("fit=bike"), "shopHref fit");
assert(soon.shopHref?.includes("door=parts"), "shopHref door");
assert(!soon.shopHref?.includes("sp-"), "no snapshot sku");

// Overdue — past interval
const overdue = getMaintenanceSummary(
  { ...bike, totalOdometerKm: 1500, totalHours: 60 },
  [chainInterval, forkInterval]
);
assert(overdue.status === "overdue", `overdue got ${overdue.status}`);
assert(overdue.overdueCount >= 1, "overdue count");
assert(overdue.headline.includes("überfällig") || overdue.headline.includes("checken"),
  `overdue headline ${overdue.headline}`);

// Fleet badge
const fleet = getFleetMaintenanceDueCount(
  [{ ...bike, totalOdometerKm: 1500, totalHours: 60 }],
  [chainInterval, forkInterval]
);
assert(fleet.dueTotal >= 1, "fleet due");
assert(fleet.overdue >= 1, "fleet overdue");

// lastRideForBike
const rides = [
  {
    id: "r1",
    bikeId: "b1",
    startTime: "2026-07-01T00:00:00.000Z",
    distanceM: 10000,
  },
  {
    id: "r2",
    bikeId: "b1",
    startTime: "2026-08-05T00:00:00.000Z",
    distanceM: 25000,
  },
  {
    id: "r3",
    bikeId: "other",
    startTime: "2026-08-10T00:00:00.000Z",
    distanceM: 5000,
  },
] as Ride[];
const last = lastRideForBike(rides, "b1");
assert(last?.id === "r2", "newest ride");

console.log("summary.test.ts OK", {
  empty: empty.status,
  ok: ok.headline,
  soon: soon.headline,
  overdue: overdue.headline,
  fleet,
});
