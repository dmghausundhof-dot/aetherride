/**
 * npx tsx src/lib/setup/werkstattCoach.test.ts
 */
import { planWerkstattCoach, showsFahrwerkCoach } from "./werkstattCoach";
import type { Bike } from "../../types/garage";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const now = new Date().toISOString();
function bike(partial: Partial<Bike> & Pick<Bike, "category" | "name">): Bike {
  return {
    id: partial.id ?? "b1",
    type: "all_mountain",
    isActive: true,
    isEbike: false,
    createdAt: now,
    updatedAt: now,
    components: [],
    setups: [],
    totalOdometerKm: 0,
    totalHours: 0,
    ...partial,
  };
}

const fully = bike({
  name: "Luna",
  category: "mtb_am",
  travelFrontMm: 150,
  travelRearMm: 150,
  weightKg: 15,
});
const ht = bike({
  name: "Hard",
  category: "mtb_trail",
  travelFrontMm: 130,
  weightKg: 13,
});
const gravel = bike({ name: "Kora", category: "gravel" });
const gravelFork = bike({
  name: "Kora",
  category: "gravel",
  components: [
    {
      id: "f",
      bikeId: "b1",
      slot: "fork",
      installedAt: now,
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
});
const city = bike({ name: "City", category: "urban" });
const emtb = bike({
  name: "Volt",
  category: "emtb",
  isEbike: true,
  travelFrontMm: 160,
  travelRearMm: 160,
  weightKg: 24,
});

assert(showsFahrwerkCoach(fully), "fully fahrwerk");
assert(showsFahrwerkCoach(ht), "hardtail fahrwerk");
assert(!showsFahrwerkCoach(gravel), "gravel without fork: no sag");
assert(showsFahrwerkCoach(gravelFork), "gravel with fork: sag");
assert(!showsFahrwerkCoach(city), "city no sag");

const cFully = planWerkstattCoach({ bike: fully, riderWeightKg: 78 });
assert(cFully.hasRearShock, "fully shock");
assert(cFully.sag?.shock != null, "fully shock coach");
assert((cFully.sag?.fork.sagMm ?? 0) > 0, "fork sag mm");
assert(cFully.tires?.unit === "psi", "mtb psi");

const cHt = planWerkstattCoach({ bike: ht, riderWeightKg: 78 });
assert(cHt.forkOnly && !cHt.hasRearShock, "hardtail fork only");
assert(cHt.sag?.shock === undefined, "no shock numbers");

const cGravel = planWerkstattCoach({ bike: gravel, riderWeightKg: 78 });
assert(cGravel.sag === undefined, "gravel pressure first");
assert(cGravel.tires?.unit === "bar", "gravel bar");
assert((cGravel.tires?.front ?? 0) > 1 && (cGravel.tires?.front ?? 0) < 5, "gravel bar range");

const cE = planWerkstattCoach({ bike: emtb, riderWeightKg: 78 });
const cELight = planWerkstattCoach({
  bike: { ...emtb, weightKg: 15 },
  riderWeightKg: 78,
});
assert(
  (cE.sag?.shock?.psiTarget ?? 0) > (cELight.sag?.shock?.psiTarget ?? 0),
  "emtb extra mass"
);

const cargo = planWerkstattCoach({
  bike: bike({ name: "Last", category: "cargo" }),
  riderWeightKg: 78,
});
assert(cargo.tires != null && cargo.tires.rear > cargo.tires.front, "cargo rear higher");

console.log("werkstattCoach.test.ts OK");
