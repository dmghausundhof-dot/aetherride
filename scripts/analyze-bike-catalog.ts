/**
 * One-shot catalog completeness report (JSON to stdout).
 */
import { BIKE_CATALOG } from "../src/lib/catalog/bikes";
import { COMPONENT_CATALOG, getComponentModel } from "../src/lib/catalog/components";
import { requiredSlotsForCategory } from "../src/lib/catalog/slots";
import type { ComponentSlot } from "../src/types/garage";

const FRAME_ATTR_KEYS = [
  "rear_spacing",
  "axle_rear",
  "shock_eye_to_eye_mm",
  "shock_stroke_mm",
  "shock_mount_type",
  "headset_top",
  "headset_bottom",
  "bb_standard",
  "seatpost_diameter_mm",
  "max_seatpost_insertion_mm",
  "brake_mount_rear",
  "max_rotor_rear_mm",
  "max_tire_width_mm",
  "motor_interface",
  "wheel_size_rear",
] as const;

const bikes = BIKE_CATALOG.flatMap((m) =>
  m.bikes.map((b) => ({ manufacturer: m.name, manufacturerId: m.id, ...b }))
);

const byCategory: Record<string, number> = {};
const byYear: Record<string, number> = {};
for (const b of bikes) {
  byCategory[b.category] = (byCategory[b.category] ?? 0) + 1;
  byYear[String(b.year)] = (byYear[String(b.year)] ?? 0) + 1;
}

const fieldCoverage = {
  travelFrontMm: bikes.filter((b) => b.travelFrontMm != null).length,
  travelRearMm: bikes.filter((b) => b.travelRearMm != null).length,
  weightKgApprox: bikes.filter((b) => b.weightKgApprox != null).length,
  sourceUrl: bikes.filter((b) => !!b.sourceUrl).length,
  frameSizeOptions: bikes.filter((b) => (b.frameSizeOptions?.length ?? 0) > 0).length,
  geometryBySize: bikes.filter((b) => (b.geometryBySize?.length ?? 0) > 0).length,
  frameAttributesNonEmpty: bikes.filter((b) => (b.frameAttributes?.length ?? 0) > 0).length,
  dedicatedFrame: bikes.filter((b) => !!b.oemComponents?.frame).length,
  isEbike: bikes.filter((b) => b.isEbike).length,
};

type BikeGap = {
  id: string;
  manufacturer: string;
  name: string;
  category: string;
  year: number;
  isEbike: boolean;
  weightKgApprox: number | null;
  travelFrontMm: number | null;
  travelRearMm: number | null;
  oemFilled: number;
  oemRequired: number;
  coveragePct: number;
  missingRequired: string[];
  hasFrame: boolean;
  frameAttrCount: number;
  frameMissingKeys: string[];
  kitHint: string;
};

const bikeGaps: BikeGap[] = [];
const missingSlotCounts: Record<string, number> = {};

for (const b of bikes) {
  const required = requiredSlotsForCategory(b.category);
  const oem = b.oemComponents ?? {};
  const filled = Object.entries(oem).filter(([, v]) => !!v).map(([k]) => k);
  const missing = required.filter((s) => !oem[s]);
  for (const s of missing) missingSlotCounts[s] = (missingSlotCounts[s] ?? 0) + 1;

  const frame = oem.frame ? getComponentModel(oem.frame) : undefined;
  const frameKeys = new Set((frame?.attributes ?? []).map((a) => a.key));
  const needsShock = required.includes("rear_shock");
  const frameMissing = FRAME_ATTR_KEYS.filter((k) => {
    if (!needsShock && (k.startsWith("shock_") || k === "shock_mount_type")) return false;
    if (!b.isEbike && k === "motor_interface") return false;
    return !frameKeys.has(k);
  });

  const kitHint =
    filled.length <= 8
      ? "sparse_kit"
      : !oem.frame
        ? "no_frame"
        : missing.length === 0
          ? "complete"
          : "partial";

  bikeGaps.push({
    id: b.id,
    manufacturer: b.manufacturer,
    name: b.name,
    category: b.category,
    year: b.year,
    isEbike: b.isEbike,
    weightKgApprox: b.weightKgApprox ?? null,
    travelFrontMm: b.travelFrontMm ?? null,
    travelRearMm: b.travelRearMm ?? null,
    oemFilled: filled.length,
    oemRequired: required.length,
    coveragePct: Math.round((filled.filter((s) => required.includes(s as ComponentSlot)).length / required.length) * 100),
    missingRequired: missing,
    hasFrame: !!oem.frame,
    frameAttrCount: frame?.attributes.length ?? 0,
    frameMissingKeys: frame ? frameMissing : FRAME_ATTR_KEYS.slice() as unknown as string[],
    kitHint,
  });
}

bikeGaps.sort((a, b) => a.coveragePct - b.coveragePct);

const slotCoverage: Record<string, { filled: number; requiredOn: number; pct: number }> = {};
const allSlots = new Set<string>();
for (const b of bikes) {
  for (const s of requiredSlotsForCategory(b.category)) allSlots.add(s);
}
for (const slot of allSlots) {
  let requiredOn = 0;
  let filled = 0;
  for (const b of bikes) {
    const req = requiredSlotsForCategory(b.category);
    if (!req.includes(slot as ComponentSlot)) continue;
    requiredOn += 1;
    if (b.oemComponents?.[slot as ComponentSlot]) filled += 1;
  }
  slotCoverage[slot] = {
    filled,
    requiredOn,
    pct: requiredOn ? Math.round((filled / requiredOn) * 100) : 0,
  };
}

const componentsBySlot: Record<string, number> = {};
const componentsThin: { id: string; slot: string; manufacturer: string; model: string; attrCount: number; hasAdjusters: boolean; hasTorque: boolean; weightG: boolean }[] = [];
for (const c of COMPONENT_CATALOG) {
  componentsBySlot[c.slot] = (componentsBySlot[c.slot] ?? 0) + 1;
  if (c.attributes.length < 3 || (!c.weightG && c.slot !== "frame" && c.attributes.length < 6)) {
    componentsThin.push({
      id: c.id,
      slot: c.slot,
      manufacturer: c.manufacturer,
      model: c.model,
      attrCount: c.attributes.length,
      hasAdjusters: c.adjusters.length > 0,
      hasTorque: c.torqueSpecs.length > 0,
      weightG: c.weightG != null,
    });
  }
}

const mfrs = BIKE_CATALOG.map((m) => ({
  id: m.id,
  name: m.name,
  bikeCount: m.bikes.length,
  categories: [...new Set(m.bikes.map((b) => b.category))],
  avgCoverage: Math.round(
    bikeGaps.filter((g) => g.manufacturer === m.name).reduce((s, g) => s + g.coveragePct, 0) /
      m.bikes.length
  ),
}));

const coverageBuckets = {
  complete_100: bikeGaps.filter((g) => g.coveragePct === 100).length,
  high_80_99: bikeGaps.filter((g) => g.coveragePct >= 80 && g.coveragePct < 100).length,
  mid_50_79: bikeGaps.filter((g) => g.coveragePct >= 50 && g.coveragePct < 80).length,
  low_25_49: bikeGaps.filter((g) => g.coveragePct >= 25 && g.coveragePct < 50).length,
  sparse_0_24: bikeGaps.filter((g) => g.coveragePct < 25).length,
};

console.log(
  JSON.stringify(
    {
      totals: {
        manufacturers: BIKE_CATALOG.length,
        bikes: bikes.length,
        components: COMPONENT_CATALOG.length,
        oemRefs: bikes.reduce((n, b) => n + Object.keys(b.oemComponents ?? {}).length, 0),
      },
      byCategory,
      byYear,
      fieldCoverage,
      coverageBuckets,
      meanCoveragePct: Math.round(bikeGaps.reduce((s, g) => s + g.coveragePct, 0) / bikeGaps.length),
      slotCoverage: Object.entries(slotCoverage)
        .sort((a, b) => a[1].pct - b[1].pct)
        .map(([slot, v]) => ({ slot, ...v })),
      missingSlotCounts: Object.entries(missingSlotCounts)
        .sort((a, b) => b[1] - a[1])
        .map(([slot, n]) => ({ slot, bikesMissing: n })),
      worstBikes: bikeGaps.slice(0, 25),
      bestBikes: [...bikeGaps].sort((a, b) => b.coveragePct - a.coveragePct).slice(0, 8),
      manufacturers: mfrs.sort((a, b) => a.avgCoverage - b.avgCoverage),
      componentsBySlot,
      componentsThin: componentsThin.slice(0, 40),
      kitHints: {
        sparse_kit: bikeGaps.filter((g) => g.kitHint === "sparse_kit").length,
        no_frame: bikeGaps.filter((g) => g.kitHint === "no_frame").length,
        partial: bikeGaps.filter((g) => g.kitHint === "partial").length,
        complete: bikeGaps.filter((g) => g.kitHint === "complete").length,
      },
    },
    null,
    2
  )
);
