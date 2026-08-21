/**
 * Run: npx tsx src/lib/i18n/maintDomainCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  maintIntervalLabel,
  maintRemainingLabel,
  presentWear,
  wearSlotLabel,
} from "./maintDomainCopy";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import type { Bike, Ride } from "@/types";

assert.equal(maintIntervalLabel("Kettenverschleiß prüfen", "en"), "Check chain wear");
assert.equal(
  maintIntervalLabel("Jährliche E-Bike-Inspektion", "fr"),
  "Inspection annuelle e-bike"
);
assert.equal(maintIntervalLabel("Reifen prüfen", "nl"), "Banden controleren");
assert.equal(maintRemainingLabel("Kein Intervall", "en"), "No interval");
assert.equal(maintRemainingLabel("14 Tage", "en"), "14 days");
assert.equal(maintRemainingLabel("14 Tage", "fr"), "14 j");
assert.equal(maintRemainingLabel("180 km · 12 Tage", "it"), "180 km · 12 giorni");
assert.equal(maintRemainingLabel("fällig", "en"), "due");
assert.equal(maintRemainingLabel("fällig · Bosch", "en"), "due · Bosch");
assert.equal(wearSlotLabel("chain", "en"), "Chain");

const bike: Bike = {
  id: "b1",
  name: "Test",
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
      componentModelId: "cm",
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
  },
];

const chain = forecastWear(bike, rides).find((f) => f.kind === "chain");
assert.ok(chain, "chain forecast");
const en = presentWear(chain!, "en");
assert.ok(en.label.includes("–"), "wear range");
assert.ok(en.label.toLowerCase().includes("chain"), "wear label en");
assert.ok(!en.label.includes("Kettenwechsel"), "wear not leftover DE");
assert.ok(en.reasoning.includes("range") || en.reasoning.includes("0.5"), "wear reason en");

const de = presentWear(chain!, "de");
assert.ok(de.label.includes("Kettenwechsel"), "wear DE keeps engine wording");

console.log("maintDomainCopy.test.ts OK");
