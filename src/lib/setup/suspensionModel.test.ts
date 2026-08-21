/**
 * npx tsx src/lib/setup/suspensionModel.test.ts
 */
import {
  END_BIAS,
  REFERENCE_BIKE_KG,
  equivalentRiderKg,
  estimateAirPsiFromLoad,
  estimateTravelUsage,
  remainingTravelExcessG,
  targetSagMm,
} from "./suspensionModel";
import { estimateAirPsi } from "./sagGuide";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(targetSagMm(150, 22) === 33, "150 mm · 22 % = 33 mm");
assert(targetSagMm(160, 30) === 48, "160 mm · 30 % = 48 mm");
assert(targetSagMm(0, 22) === 0, "no travel");

const riderOnly = equivalentRiderKg({
  riderWeightKg: 78,
  gearWeightKg: 5,
  end: "fork",
});
assert(riderOnly === 83, `no bike extra: ${riderOnly}`);

const trail = equivalentRiderKg({
  riderWeightKg: 78,
  gearWeightKg: 5,
  bikeWeightKg: 15,
  end: "shock",
});
assert(
  Math.abs(trail - (83 + 1 * END_BIAS.shock)) < 1e-9,
  "15 kg bike: 1 kg over reference on shock bias"
);

const emtbShock = equivalentRiderKg({
  riderWeightKg: 78,
  gearWeightKg: 5,
  bikeWeightKg: 24,
  end: "shock",
});
const emtbFork = equivalentRiderKg({
  riderWeightKg: 78,
  gearWeightKg: 5,
  bikeWeightKg: 24,
  end: "fork",
});
assert(
  Math.abs(emtbShock - (83 + 10 * 0.6)) < 1e-9,
  `emtb shock load ${emtbShock}`
);
assert(
  Math.abs(emtbFork - (83 + 10 * 0.4)) < 1e-9,
  `emtb fork load ${emtbFork}`
);
assert(emtbShock > emtbFork, "motor mass sits more on the shock");

const light = equivalentRiderKg({
  riderWeightKg: 78,
  bikeWeightKg: 9,
  end: "fork",
});
assert(light === 78, "road bike under reference adds nothing");

assert(Math.abs(remainingTravelExcessG(25) - 3) < 1e-9, "25 % sag → 3 g excess");
assert(Math.abs(remainingTravelExcessG(20) - 4) < 1e-9, "20 % sag → 4 g excess");

const rest = estimateTravelUsage({
  gForcePeak: 1.0,
  sagPct: 25,
  travelMm: 150,
});
assert(rest !== null && rest.usagePct === 25 && rest.usageMm === 38, "at rest = sag");

const full = estimateTravelUsage({
  gForcePeak: 4.0,
  sagPct: 25,
  travelMm: 150,
});
assert(full !== null && full.usagePct === 100 && full.usageMm === 150, "4 g uses travel");

const mid = estimateTravelUsage({
  gForcePeak: 2.5,
  sagPct: 25,
  travelMm: 150,
});
assert(mid !== null && mid.usagePct === 63, `mid usage ${mid?.usagePct}`);

assert(
  estimateTravelUsage({ gForcePeak: 2, sagPct: 25, travelMm: 0 }) === null,
  "no travel"
);

const psiTrail = estimateAirPsiFromLoad({
  riderWeightKg: 78,
  gearWeightKg: 5,
  bikeWeightKg: 15,
  category: "emtb",
  end: "shock",
  travelMm: 150,
});
const psiEmtb = estimateAirPsiFromLoad({
  riderWeightKg: 78,
  gearWeightKg: 5,
  bikeWeightKg: 24,
  category: "emtb",
  end: "shock",
  travelMm: 150,
});
assert(psiEmtb.psiTarget > psiTrail.psiTarget, "heavier bike → more shock psi");
assert(psiTrail.sagMm === targetSagMm(150, psiTrail.sag.target), "sag mm matches");

const legacy = estimateAirPsi({
  riderWeightKg: 78,
  gearWeightKg: 5,
  category: "mtb_am",
  end: "fork",
  travelMm: 150,
});
const viaModel = estimateAirPsiFromLoad({
  riderWeightKg: 78,
  gearWeightKg: 5,
  category: "mtb_am",
  end: "fork",
  travelMm: 150,
});
assert(legacy.psiTarget === viaModel.psiTarget, "sagGuide wraps the load model");
assert(REFERENCE_BIKE_KG === 14, "reference bike");

console.log("suspensionModel.test.ts OK");
