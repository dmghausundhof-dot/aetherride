/**
 * Garage-UX Helpers — Ausführen: npx tsx src/lib/garage/garageUx.test.ts
 */
import { estimateAirPsi } from "../setup/sagGuide";
import { setupConditionLabel } from "../setup/conditionLabels";
import { weeklyRideKm, verdictSummaryDe } from "./readiness";
import { resolveGaragePrimaryAction } from "./primaryCta";
import { planDieBox } from "./dieBox";
import type { Bike } from "../../types/garage";

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

assert(
  resolveGaragePrimaryAction({ isActive: true, dueCount: 1, partsCount: 0 }) ===
    "viewMaintenance",
  "cta maintenance"
);
assert(
  resolveGaragePrimaryAction({ isActive: false, dueCount: 0, partsCount: 0 }) ===
    "addPart",
  "cta add part"
);
assert(
  resolveGaragePrimaryAction({ isActive: false, dueCount: 0, partsCount: 2 }) ===
    "setActive",
  "cta set active"
);
assert(
  resolveGaragePrimaryAction({ isActive: true, dueCount: 0, partsCount: 2 }) ===
    "openSetup",
  "legacy mehr-tab cta"
);

const cityBike: Bike = {
  id: "c1",
  name: "City",
  category: "urban",
  type: "road",
  isActive: true,
  isEbike: false,
  createdAt: now,
  updatedAt: now,
  components: [],
  setups: [],
  totalOdometerKm: 0,
  totalHours: 0,
};
const city = planDieBox({ bike: cityBike });
assert(!city.sentence.toLowerCase().includes("sag"), "city no sag");
assert(city.addableSlots.includes("light"), "city can add light");
assert(!city.addableSlots.includes("fork"), "city no ghost fork");
assert(city.today.some((t) => t.id === "lightsMissing"), "city lights today");

const dhBike: Bike = {
  ...cityBike,
  id: "d1",
  name: "Spicy",
  category: "dh",
  type: "enduro",
  travelFrontMm: 200,
  travelRearMm: 200,
};
const dh = planDieBox({ bike: dhBike });
assert(!dh.chips.some((c) => c.label === "Licht"), "dh no lights chip");
assert(!dh.addableSlots.includes("light"), "dh no light slot");
assert(dh.primary?.cta !== "Zum Setup", "box primary not zum setup");

const emtb: Bike = {
  ...cityBike,
  id: "e1",
  name: "Cargo",
  category: "etrekking",
  isEbike: true,
};
const eplan = planDieBox({ bike: emtb, cscPaired: false });
assert(!eplan.today.some((t) => t.id === "pairCsc"), "csc not today hero");
assert(eplan.chips.some((c) => c.label === "CSC"), "ebike csc chip");

console.log("garageUx.test.ts OK");
