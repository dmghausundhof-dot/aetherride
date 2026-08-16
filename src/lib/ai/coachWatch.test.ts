/**
 * Coach-Watch + Inbox + Tool-Routing.
 * npx tsx src/lib/ai/coachWatch.test.ts
 */
import { detectTool, numericGuard, buildChatRecommendation } from "./chat";
import { buildCoachWatch, formulateCoachWatch } from "./coachWatch";
import { mergeCoachInbox, snoozeMeta, unreadCoachCount } from "./coachInbox";
import { normalizeBike, normalizeRide } from "./normalize";
import type { Bike, MaintenanceInterval, Ride, RiderProfile } from "@/types";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const profile: RiderProfile = {
  style: "flow",
  skillLevel: 3,
  preferences: {
    preferSteep: false,
    preferTechnical: true,
    preferFlow: true,
    eBikeAssistPreference: "tour",
  },
  fitnessIndicators: { avgRideDurationMin: 90, weeklyDistanceKm: 40 },
  riderWeightKg: 78,
};

const bike: Bike = {
  id: "b1",
  name: "Spire",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  createdAt: "2026-01-01T00:00:00.000Z",
  updatedAt: "2026-01-01T00:00:00.000Z",
  totalOdometerKm: 2500,
  totalHours: 90,
  setups: [],
  components: [
    {
      id: "c1",
      bikeId: "b1",
      slot: "chain",
      componentModelId: "x",
      installedAt: "2025-01-01T00:00:00.000Z",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};

const interval: MaintenanceInterval = {
  id: "iv1",
  bikeId: "b1",
  slot: "chain",
  label: "Kettenverschleiß prüfen",
  intervalKm: 1000,
  lastDoneOdometerKm: 0,
  sourceLabel: "Park Tool",
  overriddenByUser: false,
};

const ride: Ride = {
  id: "r1",
  bikeId: "b1",
  sportType: "enduro",
  startTime: new Date().toISOString(),
  distanceM: 20000,
  elevationGainM: 800,
  durationSec: 7200,
  summaryMetrics: {
    gForcePeak: 4.2,
    gForceRms: 1.4,
    leanAngleMax: 40,
    impactCount: 80,
    flowScore: 48,
  },
};

assert(detectTool("Was steht an?") === "watch", "watch routing");
assert(detectTool("Sag mir die Reichweite") === "range", "sag mir ≠ setup");
assert(detectTool("Welche Reichweite habe ich") === "range", "range");

const notices = buildCoachWatch({
  bikes: [bike],
  rides: [ride],
  intervals: [interval],
  profile,
});
assert(notices.length >= 1, "mindestens ein Hinweis");
assert(
  notices.some((n) => n.kind === "maintenance" || n.kind === "wear"),
  "Wartung oder Verschleiß"
);

const empty = buildCoachWatch({
  bikes: [],
  rides: [],
  profile,
});
assert(empty.length === 0, "leere Garage → keine Hinweise");

const text = formulateCoachWatch(notices);
assert(text.length > 10, "Formulierung");
const set = buildChatRecommendation("watch", "Was steht an?", {
  bikes: [bike],
  rides: [ride],
  profile,
  intervals: [interval],
  notices,
});
const guard = numericGuard(text, set);
assert(guard.ok || guard.usedFallback, "Guard läuft");

const items = mergeCoachInbox(notices, {});
assert(unreadCoachCount(items) === items.length, "neu = ungelesen");
const snoozed = snoozeMeta({}, notices[0]);
const after = mergeCoachInbox(notices, snoozed);
assert(
  after.every((i) => i.id !== notices[0].id),
  "Snooze blendet aus"
);

const partial = normalizeBike({
  id: "m",
  name: "App-Rad",
  category: "emtb",
  type: "e_mtb",
  isActive: true,
  isEbike: false,
  createdAt: "",
  updatedAt: "",
  totalOdometerKm: undefined as unknown as number,
  totalHours: 0,
  components: undefined as unknown as Bike["components"],
  setups: undefined as unknown as Bike["setups"],
} as Bike);
assert(partial?.isEbike === true, "E-Kategorie → isEbike");
assert(Array.isArray(partial?.components), "components Array");

const thinRide = normalizeRide({
  id: "x",
  bikeId: "m",
  sportType: "e_mtb",
  startTime: "2026-01-01T00:00:00.000Z",
  distanceM: undefined as unknown as number,
  elevationGainM: 0,
  durationSec: 0,
  summaryMetrics: {
    gForcePeak: 0,
    gForceRms: 0,
    leanAngleMax: 0,
    impactCount: 0,
    flowScore: 0,
  },
  ...( { distanceKm: 12.5 } as object ),
} as Ride);
assert(thinRide?.distanceM === 12500, "distanceKm → distanceM");

const stats = buildChatRecommendation("ride_stats", "Kilometer", {
  bikes: [bike],
  rides: [{ ...(ride as Ride), distanceM: undefined as unknown as number, ...( { distanceKm: 20 } as object ) } as Ride],
  profile,
});
assert(stats.rawAnswer.includes("20.0 km") || stats.rawAnswer.includes("20 km"), stats.rawAnswer);

console.log("coachWatch.test.ts OK", {
  tools: { watch: detectTool("Was steht an?"), range: detectTool("Sag mir die Reichweite") },
  notices: notices.map((n) => n.kind),
  unread: unreadCoachCount(items),
});
