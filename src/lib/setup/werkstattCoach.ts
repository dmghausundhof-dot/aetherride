import type { Bike, BikeCategory } from "@/types/garage";
import { pressureUnitLabel, psiToBar } from "@/lib/garage/pressureUnit";
import { estimateAirPsiFromLoad } from "@/lib/setup/suspensionModel";

export type CoachEnd = {
  targetPct: number;
  sagMm: number | null;
  psiTarget: number;
  psiMin: number;
  psiMax: number;
};

export type WerkstattCoach = {
  hasRearShock: boolean;
  forkOnly: boolean;
  sag?: { fork: CoachEnd; shock?: CoachEnd };
  tires?: { unit: "bar" | "psi"; front: number; rear: number };
};

function hasRearShockOn(bike: Bike): boolean {
  const travelR = bike.travelRearMm ?? 0;
  if (travelR > 0) return true;
  return bike.components.some((c) => !c.removedAt && c.slot === "rear_shock");
}

function hasForkOn(bike: Bike): boolean {
  const travelF = bike.travelFrontMm ?? 0;
  if (travelF > 0) return true;
  return bike.components.some((c) => !c.removedAt && c.slot === "fork");
}

/** Gabel-SAG-UI: MTB-Familie, oder Gravel mit wirklich verbauter Gabel. */
export function showsFahrwerkCoach(bike: Bike): boolean {
  const cat = bike.category;
  const mtb =
    cat === "mtb_trail" ||
    cat === "mtb_am" ||
    cat === "mtb_enduro" ||
    cat === "dh" ||
    cat === "emtb";
  if (mtb) return hasForkOn(bike) || hasRearShockOn(bike);
  if (cat === "gravel") return hasForkOn(bike);
  return false;
}

function tireBasePsi(category: BikeCategory): { front: number; rear: number } {
  switch (category) {
    case "gravel":
      return { front: 36, rear: 38 };
    case "road":
      return { front: 72, rear: 76 };
    case "urban":
    case "etrekking":
      return { front: 55, rear: 58 };
    case "cargo":
      return { front: 50, rear: 62 };
    case "folding":
      return { front: 60, rear: 62 };
    case "kids":
      return { front: 35, rear: 38 };
    case "mtb_trail":
    case "mtb_am":
    case "mtb_enduro":
    case "emtb":
      return { front: 22, rear: 24 };
    case "dh":
      return { front: 26, rear: 28 };
    default:
      return { front: 45, rear: 48 };
  }
}

function scaleTirePsi(
  base: { front: number; rear: number },
  riderWeightKg: number,
  bikeWeightKg?: number
): { front: number; rear: number } {
  const load = riderWeightKg + Math.max(0, (bikeWeightKg ?? 14) - 14) * 0.3;
  const scale = Math.min(1.25, Math.max(0.8, load / 78));
  return {
    front: Math.round(base.front * scale),
    rear: Math.round(base.rear * scale),
  };
}

function toCoachEnd(
  end: ReturnType<typeof estimateAirPsiFromLoad>
): CoachEnd {
  return {
    targetPct: end.sag.target,
    sagMm: end.sagMm,
    psiTarget: end.psiTarget,
    psiMin: end.psiMin,
    psiMax: end.psiMax,
  };
}

export function planWerkstattCoach(input: {
  bike: Bike;
  riderWeightKg: number;
  gearWeightKg?: number;
}): WerkstattCoach {
  const { bike } = input;
  const rear = hasRearShockOn(bike);
  const forkOnly = !rear;
  const load = {
    riderWeightKg: input.riderWeightKg,
    gearWeightKg: input.gearWeightKg ?? 5,
    bikeWeightKg: bike.weightKg,
    category: bike.category,
  };

  const sag = showsFahrwerkCoach(bike)
    ? {
        fork: toCoachEnd(
          estimateAirPsiFromLoad({
            ...load,
            end: "fork",
            travelMm: bike.travelFrontMm,
          })
        ),
        shock: rear
          ? toCoachEnd(
              estimateAirPsiFromLoad({
                ...load,
                end: "shock",
                travelMm: bike.travelRearMm,
              })
            )
          : undefined,
      }
    : undefined;

  const psi = scaleTirePsi(
    tireBasePsi(bike.category),
    input.riderWeightKg,
    bike.weightKg
  );
  const unit = pressureUnitLabel(bike.category);
  const tires =
    bike.category === "hiking"
      ? undefined
      : {
          unit,
          front: unit === "bar" ? psiToBar(psi.front) : psi.front,
          rear: unit === "bar" ? psiToBar(psi.rear) : psi.rear,
        };

  return { hasRearShock: rear, forkOnly, sag, tires };
}
