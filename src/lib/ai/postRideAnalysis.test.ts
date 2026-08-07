/**
 * Smoke-Tests: Post-Ride-Analyse & Home-Wartung.
 * Ausführen: npx tsx src/lib/ai/postRideAnalysis.test.ts
 */
import { analyzePostRide } from "./postRideAnalysis";
import { buildMaintenanceAlerts } from "@/lib/home/maintenanceAlerts";
import { greetingLine, timeOfDayGreeting } from "@/lib/home/greeting";
import { setupConditionHint } from "@/lib/home/setupHint";
import type { Bike, Ride, Setup } from "@/types";

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
  totalOdometerKm: 1200,
  totalHours: 80,
} as Bike;

const setup = {
  id: "s1",
  bikeId: "b1",
  version: 1,
  label: "Wet Roots",
  conditions: "wet",
  values: [
    {
      bikeComponentId: "c1",
      slot: "fork",
      adjusterKey: "fork.rebound",
      valueNum: 10,
      unit: "clicks",
      outOfSpec: false,
    },
  ],
  createdAt: new Date().toISOString(),
  createdBy: "user",
  isCurrent: true,
} as Setup;

const ride = {
  id: "r1",
  bikeId: "b1",
  setupId: "s1",
  sportType: "enduro",
  startTime: new Date().toISOString(),
  distanceM: 20000,
  elevationGainM: 800,
  durationSec: 7200,
  summaryMetrics: {
    gForcePeak: 4.2,
    gForceRms: 1.4,
    leanAngleMax: 40,
    impactCount: 55,
    flowScore: 48,
  },
} as Ride;

const analysis = analyzePostRide({
  ride,
  bike,
  setup,
  feedback: {
    rideId: "r1",
    overallFeel: 3,
    frontFeel: "too_firm",
    smallBump: "harsh",
    skipped: false,
    createdAt: new Date().toISOString(),
  },
});

if (!analysis.setupSuggestion) {
  throw new Error("expected setup suggestion for harsh front");
}
if (analysis.observations.length > 3) {
  throw new Error("max 3 observations");
}
if (!analysis.setupSuggestion.title.includes("Zugstufe")) {
  throw new Error("expected rebound suggestion");
}

const hint = setupConditionHint(setup, [setup], "dry_likely");
if (!hint) throw new Error("expected wet setup vs dry trail hint");

const g = timeOfDayGreeting(new Date("2026-08-07T09:00:00"));
if (g !== "Guten Morgen") throw new Error(`greeting ${g}`);
if (!greetingLine("Jonas").includes("Jonas")) throw new Error("name");

const alerts = buildMaintenanceAlerts({
  bike: { ...bike, totalOdometerKm: 5000, totalHours: 200 },
  rides: [ride],
  intervals: [
    {
      id: "i1",
      bikeId: "b1",
      slot: "fork",
      label: "Gabel Lower-Leg Service",
      intervalHours: 50,
      lastDoneHours: 0,
      sourceLabel: "test",
      overriddenByUser: false,
    },
  ],
  max: 2,
});
if (alerts.length === 0) throw new Error("expected maintenance alert");
if (alerts.length > 2) throw new Error("max 2 alerts");

console.log("postRideAnalysis.test.ts OK", {
  suggestion: analysis.setupSuggestion.title,
  observations: analysis.observations.length,
  alerts: alerts.map((a) => a.title),
});
