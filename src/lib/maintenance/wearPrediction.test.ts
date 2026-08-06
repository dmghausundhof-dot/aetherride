/**
 * Regressionschecks F-GAR-005 P1 — immer Spanne, nie Punktwert.
 * Ausführen: npx tsx src/lib/maintenance/wearPrediction.test.ts
 */
import { forecastWear } from "./wearPrediction";
import type { Bike, Ride } from "@/types";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const bike: Bike = {
  id: "b1",
  name: "Test Enduro",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  createdAt: "2026-01-01T00:00:00.000Z",
  updatedAt: "2026-01-01T00:00:00.000Z",
  totalOdometerKm: 1200,
  totalHours: 40,
  setups: [],
  components: [
    {
      id: "c-chain",
      bikeId: "b1",
      slot: "chain",
      componentModelId: "cm-sram-xx-chain",
      installedAt: "2026-01-01T00:00:00.000Z",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
    {
      id: "c-pad",
      bikeId: "b1",
      slot: "brake_pads_front",
      componentModelId: "cm-shimano-pad",
      installedAt: "2026-01-01T00:00:00.000Z",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};

const rides: Ride[] = [
  {
    id: "r1",
    bikeId: "b1",
    sportType: "enduro",
    startTime: "2026-02-01T10:00:00.000Z",
    distanceM: 28000,
    elevationGainM: 1100,
    durationSec: 7200,
    summaryMetrics: {
      gForcePeak: 4,
      gForceRms: 1.2,
      leanAngleMax: 28,
      impactCount: 40,
      flowScore: 72,
    },
    notes: "nass roots",
  },
  {
    id: "r2",
    bikeId: "b1",
    sportType: "enduro",
    startTime: "2026-03-01T10:00:00.000Z",
    distanceM: 22000,
    elevationGainM: 900,
    durationSec: 6000,
    summaryMetrics: {
      gForcePeak: 3.5,
      gForceRms: 1.1,
      leanAngleMax: 25,
      impactCount: 30,
      flowScore: 70,
    },
  },
];

const forecasts = forecastWear(bike, rides);
assert(forecasts.length >= 2, "erwartet Kette + Beläge");
for (const f of forecasts) {
  assert(f.remainingKmLow <= f.remainingKmHigh, "Spanne low≤high");
  assert(f.label.includes("–") || f.label.includes("-"), "Label enthält Spanne");
  assert(!/in \d+ km$/.test(f.label.replace(/–/g, "-")), "kein reiner Punktwert");
  assert(f.sourceLabel.length > 0, "Quelle angegeben");
  assert(f.reasoning.includes("Spanne") || f.reasoning.length > 40, "Begründung");
}

console.log("wearPrediction.test.ts OK", forecasts.map((f) => f.label));
