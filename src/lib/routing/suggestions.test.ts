/**
 * F-NAV-004 — jeder Vorschlag hat genau 3 Reasons.
 * Ausführen: npx tsx src/lib/routing/suggestions.test.ts
 */
import { suggestRoutes } from "./suggestions";
import type { Bike, RiderProfile } from "@/types";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const bike: Bike = {
  id: "b1",
  name: "Spire",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  travelFrontMm: 170,
  createdAt: "2026-01-01T00:00:00.000Z",
  updatedAt: "2026-01-01T00:00:00.000Z",
  totalOdometerKm: 0,
  totalHours: 0,
  setups: [],
  components: [],
};

const profile: RiderProfile = {
  style: "flow",
  skillLevel: 3,
  preferences: {
    preferSteep: true,
    preferTechnical: true,
    preferFlow: false,
    eBikeAssistPreference: "sport",
  },
  terrainShare: { s0s1: 20, s2: 40, s3plus: 30, gravelRoad: 10 },
  fitnessIndicators: { avgRideDurationMin: 120, weeklyDistanceKm: 60 },
  riderWeightKg: 78,
};

const routes = suggestRoutes({ bike, profile, availableMinutes: 150 });
assert(routes.length >= 1 && routes.length <= 5, "3–5 Vorschläge");
for (const r of routes) {
  assert(r.reasons.length === 3, `${r.name}: genau 3 Gründe`);
  assert(r.matchScore >= 0 && r.matchScore <= 99, "Score-Band");
}

console.log(
  "suggestions.test.ts OK",
  routes.map((r) => ({ name: r.name, reasons: r.reasons.length }))
);
