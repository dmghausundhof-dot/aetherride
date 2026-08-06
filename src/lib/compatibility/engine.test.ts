/**
 * Leichte Regressionschecks für Kompat-Engine & Bracketing (ohne Test-Runner).
 * Ausführen: npx tsx src/lib/compatibility/engine.test.ts
 */
import { checkBikeCompatibility, aggregateVerdict } from "./engine";
import { evaluateBracketingSeries, blindTestIdenticalSetups } from "@/lib/setup/bracketing";
import type { Bike, BracketingRun } from "@/types";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const bike: Bike = {
  id: "b1",
  name: "Test",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  totalOdometerKm: 0,
  totalHours: 0,
  setups: [],
  components: [
    {
      id: "c1",
      bikeId: "b1",
      slot: "frame",
      componentModelId: "cm-transition-spire-frame",
      installedAt: new Date().toISOString(),
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
    {
      id: "c2",
      bikeId: "b1",
      slot: "rear_hub",
      componentModelId: "cm-dt-350-boost-rear-xd",
      installedAt: new Date().toISOString(),
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
    {
      id: "c3",
      bikeId: "b1",
      slot: "cassette",
      componentModelId: "cm-shimano-xt-cassette-ms",
      installedAt: new Date().toISOString(),
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};

const results = checkBikeCompatibility(bike);
const drv = results.find((r) => r.ruleCode === "RL-DRV-011");
assert(!!drv, "RL-DRV-011 sollte greifen");
assert(drv!.verdict === "INCOMPATIBLE", "XD-Nabe + MicroSpline-Kassette = INCOMPATIBLE");
assert(aggregateVerdict(results) === "INCOMPATIBLE", "Aggregat INCOMPATIBLE");

const mk = (v: number, i: number): BracketingRun => ({
  id: `${v}-${i}`,
  configValue: v,
  runIndex: i,
  segmentTimeSec: 100 + (Math.random() - 0.5) * 0.2,
  flowScore: 75 + (Math.random() - 0.5) * 0.3,
  impactHardness: 3,
  subjectiveRating: 3,
  matchQuality: 0.9,
  createdAt: new Date().toISOString(),
});

let blindOk = 0;
for (let t = 0; t < 20; t++) {
  if (
    blindTestIdenticalSetups(
      [mk(6, 1), mk(6, 2)],
      [mk(8, 1), mk(8, 2)]
    )
  )
    blindOk++;
}
assert(blindOk >= 18, `Blindtest ≥90% erwartet, got ${blindOk}/20`);

const seriesEval = evaluateBracketingSeries({
  id: "s",
  bikeId: "b1",
  setupId: "s1",
  parameter: "fork.rebound",
  unit: "clicks",
  rangeFrom: 6,
  rangeTo: 8,
  step: 2,
  referenceSegmentLabel: "x",
  status: "open",
  createdAt: new Date().toISOString(),
  runs: [mk(6, 1), mk(6, 2), mk(8, 1)],
});
assert(!seriesEval.ready, "Mit fehlendem 2. Run nicht ready");

console.log("OK: compatibility + bracketing checks passed");
