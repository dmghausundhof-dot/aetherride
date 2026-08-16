/**
 * G-SCH-03 — BikeCategory → schema template + optional layers.
 * Keep in sync with mobile/lib/domain/garage/bike_schema_mapper.dart
 */

import type { BikeCategory, ComponentSlot } from "@/types/garage";
import type { BikeSchemaTemplate } from "./anchors";

export type BikeSchemaKind = BikeSchemaTemplate | "hiking";

export interface BikeSchemaPlan {
  /** Base SVG template (null for hiking — no diamond frame) */
  template: BikeSchemaTemplate | null;
  kind: BikeSchemaKind;
  /** Draw rear-shock layer on MTB template */
  showShock: boolean;
  /** Draw motor + battery blocks */
  showEbike: boolean;
  /** Slots that should appear as hotspots for this bike */
  hotspotSlots: ComponentSlot[];
}

const CORE_SLOTS: ComponentSlot[] = [
  "tire_front",
  "fork",
  "brake_front",
  "handlebar",
  "stem",
  "frame",
  "seatpost",
  "saddle",
  "crankset",
  "chain",
  "cassette",
  "tire_rear",
  "brake_rear",
];

const HIKING_SLOTS: ComponentSlot[] = [
  "hiking_shoes",
  "hiking_pack",
  "hiking_poles",
];

/**
 * Map garage category + runtime flags → drawing plan.
 * Hardtail: MTB template without shock layer.
 * Fully (AM/Enduro/DH/E-MTB or rear_shock installed): shock layer on.
 */
export function planBikeSchema(input: {
  category: BikeCategory;
  isEbike?: boolean;
  /** true if rear shock installed or category expects full suspension */
  hasRearShock?: boolean;
}): BikeSchemaPlan {
  const { category } = input;
  const isEbike =
    input.isEbike === true ||
    category === "emtb" ||
    category === "etrekking";

  if (category === "hiking") {
    return {
      template: null,
      kind: "hiking",
      showShock: false,
      showEbike: false,
      hotspotSlots: HIKING_SLOTS,
    };
  }

  let template: BikeSchemaTemplate;
  switch (category) {
    case "road":
      template = "road";
      break;
    case "gravel":
      template = "gravel";
      break;
    case "urban":
    case "etrekking":
    case "cargo":
    case "folding":
    case "kids":
      template = "city";
      break;
    case "mtb_trail":
    case "mtb_am":
    case "mtb_enduro":
    case "dh":
    case "emtb":
    default:
      template = "mtb";
      break;
  }

  const categoryFully = (
    ["mtb_am", "mtb_enduro", "dh", "emtb"] as BikeCategory[]
  ).includes(category);
  // Trail defaults hardtail unless shock installed; fully categories always show shock
  const showShock =
    template === "mtb" &&
    (categoryFully || input.hasRearShock === true);

  const hotspotSlots: ComponentSlot[] = [...CORE_SLOTS];
  if (showShock) hotspotSlots.push("rear_shock");
  if (isEbike) {
    hotspotSlots.push("motor", "battery");
  }

  return {
    template,
    kind: template,
    showShock,
    showEbike: isEbike,
    hotspotSlots,
  };
}

/** Hiking fallback anchors (viewBox 1000×500) when no SVG template. */
export const HIKING_ANCHORS: Record<
  string,
  { cx: number; cy: number; hitR: number; label_de: string }
> = {
  hiking_shoes: { cx: 280, cy: 380, hitR: 28, label_de: "Schuhe" },
  hiking_pack: { cx: 500, cy: 200, hitR: 28, label_de: "Rucksack" },
  hiking_poles: { cx: 720, cy: 280, hitR: 28, label_de: "Stöcke" },
};
