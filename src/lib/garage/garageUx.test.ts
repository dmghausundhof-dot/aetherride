/**
 * Garage-UX Helpers — Ausführen: npx tsx src/lib/garage/garageUx.test.ts
 */
import { estimateAirPsi } from "../setup/sagGuide";
import { setupConditionLabel } from "../setup/conditionLabels";
import { weeklyRideKm, verdictSummaryDe } from "./readiness";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const e = estimateAirPsi({
  riderWeightKg: 78,
  gearWeightKg: 4,
  category: "mtb_am",
  end: "fork",
  travelMm: 150,
});
assert(e.psiTarget > 50 && e.psiTarget < 140, `psiTarget=${e.psiTarget}`);
assert(e.sag.target >= 20, "sag target");

assert(setupConditionLabel("bikepark") === "Bikepark", "label bikepark");
assert(setupConditionLabel("wet") === "Nass", "label wet");

const now = new Date().toISOString();
const old = new Date(Date.now() - 10 * 86400000).toISOString();
assert(
  weeklyRideKm(
    [
      { startTime: now, distanceM: 20000, bikeId: "a" },
      { startTime: old, distanceM: 50000, bikeId: "a" },
    ],
    "a"
  ) === 20,
  "weekly km"
);

assert(verdictSummaryDe("COMPATIBLE") === "Kompatibel", "verdict");

console.log("garageUx.test.ts OK");
