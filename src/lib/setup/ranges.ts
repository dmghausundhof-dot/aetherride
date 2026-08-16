import { getComponentModel } from "@/lib/catalog/components";
import type {
  Bike,
  BikeCategory,
  Setup,
  SetupCondition,
  SetupValue,
} from "@/types/garage";

/**
 * SAG-Richtwerte aus Magazin-/OEM-Praxis (Simplon, Dirt MTB, Enduro MTB Mag):
 * XC 20–25 %, AM/Trail 25–30 %, Enduro 25–35 %, Freeride/DH 30–40 %.
 * Gabel typisch etwas weniger SAG als Dämpfer (~20–25 % vs. 25–30 %).
 */

export function recommendedSagPct(
  category: BikeCategory,
  end: "fork" | "shock"
): { min: number; max: number; target: number } {
  const table: Record<
    BikeCategory,
    { fork: [number, number]; shock: [number, number] }
  > = {
    mtb_trail: { fork: [20, 25], shock: [25, 30] },
    mtb_am: { fork: [20, 25], shock: [25, 30] },
    mtb_enduro: { fork: [20, 26], shock: [27, 35] },
    dh: { fork: [25, 30], shock: [30, 40] },
    gravel: { fork: [15, 20], shock: [20, 25] },
    road: { fork: [15, 20], shock: [15, 20] },
    urban: { fork: [15, 20], shock: [15, 20] },
    cargo: { fork: [15, 20], shock: [15, 20] },
    folding: { fork: [15, 20], shock: [15, 20] },
    kids: { fork: [15, 20], shock: [15, 20] },
    emtb: { fork: [20, 26], shock: [27, 35] },
    etrekking: { fork: [20, 25], shock: [25, 30] },
    cargo: { fork: [15, 20], shock: [15, 20] },
    folding: { fork: [15, 20], shock: [15, 20] },
    kids: { fork: [15, 20], shock: [15, 20] },
    hiking: { fork: [0, 0], shock: [0, 0] },
  };
  const [min, max] = table[category][end];
  return { min, max, target: Math.round((min + max) / 2) };
}

export function isOutOfSpec(
  modelId: string | undefined,
  adjusterKey: string,
  value: number
): boolean {
  if (!modelId) return false;
  const model = getComponentModel(modelId);
  const adj = model?.adjusters.find((a) => a.key === adjusterKey);
  if (!adj) return false;
  if (adj.min !== undefined && value < adj.min) return true;
  if (adj.max !== undefined && value > adj.max) return true;
  if (adj.totalClicks !== undefined && (value < 0 || value > adj.totalClicks))
    return true;
  return false;
}

export function buildSetupValuesFromBike(
  bike: Bike,
  overrides: Record<string, number> = {}
): SetupValue[] {
  const values: SetupValue[] = [];
  for (const comp of bike.components.filter((c) => !c.removedAt)) {
    const model = comp.componentModelId
      ? getComponentModel(comp.componentModelId)
      : undefined;
    const adjusters = model?.adjusters ?? [];
    for (const adj of adjusters) {
      const overrideKey = `${comp.slot}.${adj.key}`;
      const fromSettings = comp.currentSettings[adj.key];
      const num =
        overrides[overrideKey] ??
        (typeof fromSettings === "number"
          ? fromSettings
          : typeof fromSettings === "string" && !Number.isNaN(Number(fromSettings))
            ? Number(fromSettings)
            : adj.min ?? 0);
      values.push({
        bikeComponentId: comp.id,
        slot: comp.slot,
        adjusterKey: adj.key,
        valueNum: num,
        unit: adj.unit,
        outOfSpec: isOutOfSpec(comp.componentModelId, adj.key, num),
      });
    }
  }
  return values;
}

export function nextSetupVersion(existing: Setup[]): number {
  if (existing.length === 0) return 1;
  return Math.max(...existing.map((s) => s.version)) + 1;
}

export function createImmutableSetup(input: {
  bike: Bike;
  label: string;
  conditions: SetupCondition;
  description?: string;
  riderWeightKg?: number;
  parentSetupId?: string;
  values?: SetupValue[];
  createdBy?: Setup["createdBy"];
  id: string;
}): Setup {
  const parent = input.parentSetupId
    ? input.bike.setups.find((s) => s.id === input.parentSetupId)
    : input.bike.setups.find((s) => s.isCurrent);

  return {
    id: input.id,
    bikeId: input.bike.id,
    version: nextSetupVersion(input.bike.setups),
    parentSetupId: parent?.id,
    label: input.label,
    conditions: input.conditions,
    description: input.description,
    riderWeightKg: input.riderWeightKg,
    values: input.values ?? buildSetupValuesFromBike(input.bike),
    createdAt: new Date().toISOString(),
    createdBy: input.createdBy ?? "user",
    isCurrent: true,
  };
}

export function setupFingerprint(setup: Setup): string {
  return setup.values
    .slice()
    .sort((a, b) =>
      `${a.slot}.${a.adjusterKey}`.localeCompare(`${b.slot}.${b.adjusterKey}`)
    )
    .map((v) => `${v.slot}.${v.adjusterKey}=${v.valueNum}${v.unit}`)
    .join("|");
}
