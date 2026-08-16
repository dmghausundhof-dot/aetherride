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
assert(!city.chips.some((c) => !c.known), "city chips are known facts");
assert(!city.sentence.toLowerCase().includes("nicht"), "city sentence not a deficit");

const cargoBike: Bike = { ...cityBike, id: "cargo1", name: "Lasten", category: "cargo" };
const cargo = planDieBox({ bike: cargoBike });
assert(cargo.kind === "urban", "cargo lives in city box");
assert(!cargo.sentence.toLowerCase().includes("sag"), "cargo no sag");
assert(cargo.addableSlots.includes("light"), "cargo can add light");

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
assert(!eplan.chips.some((c) => c.label === "CSC"), "unpaired csc not a chip");

const jam2Parts: Bike["components"] = [
  {
    id: "p-tire",
    bikeId: "j1",
    slot: "tire_front",
    componentModelId: "cm-tire",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
  {
    id: "p-headset",
    bikeId: "j1",
    slot: "headset",
    componentModelId: "cm-headset",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
  {
    id: "p-lock",
    bikeId: "j1",
    slot: "lock",
    freeText: "Abus",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
];
const jam2: Bike = {
  ...cityBike,
  id: "j1",
  name: "JAM² 6.9",
  category: "emtb",
  type: "e_mtb",
  isEbike: true,
  catalogBikeId: "cat-focus-jam2-2024",
  travelFrontMm: 150,
  travelRearMm: 150,
  wheelSizeFront: "29",
  wheelSizeRear: "29",
  components: jam2Parts,
};
const jamPlan = planDieBox({ bike: jam2 });
assert(jamPlan.onBike.some((c) => c.slot === "tire_front"), "jam2 core tire");
assert(!jamPlan.onBike.some((c) => c.slot === "headset"), "jam2 no oem dump");
assert(jamPlan.onBike.some((c) => c.slot === "lock"), "jam2 explicit lock");
assert(jamPlan.sentence.includes("150/150"), "jam2 travel in sentence");
assert(jamPlan.sentence.includes("E-Antrieb"), "jam2 assist named honestly");
assert(!jamPlan.chips.some((c) => c.label === "Bosch CX"), "no invented motor sku");
assert(!jamPlan.chips.some((c) => c.label === "800 Wh"), "no invented battery");
assert(!jamPlan.addableSlots.includes("headset"), "headset not addable");

const hike = planDieBox({
  bike: {
    ...cityBike,
    id: "h1",
    name: "Tour-Kit",
    category: "hiking",
    type: "hiking",
  },
});
assert(
  hike.addableSlots.every((s) => s.startsWith("hiking_")),
  "hiking only kit slots"
);
assert(!hike.addableSlots.includes("fork"), "hiking no fork");

console.log("garageUx.test.ts OK");
