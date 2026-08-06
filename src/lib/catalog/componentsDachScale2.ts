/**
 * G-4 Katalog-Skalierung Round 2 — DE-Marken + Aftermarket-Tiefe.
 */

import type { ComponentModel, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-06T00:00:00.000Z";

function attr(
  key: string,
  opts: {
    text?: string;
    num?: number;
    enum?: string;
    unit?: string;
  }
): TypedAttribute {
  return {
    key,
    valueText: opts.text,
    valueNum: opts.num,
    valueEnum: opts.enum ?? opts.text,
    unit: opts.unit,
    source: "manufacturer_doc",
    verifiedAt: VERIFIED,
  };
}

function frameEnduro(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant?: string;
  year: number;
  shockEye: number;
  shockStroke: number;
  shockMount: "trunnion" | "standard";
  seatpostMm: number;
  url: string;
}): ComponentModel {
  return {
    id: opts.id,
    slot: "frame",
    manufacturer: opts.manufacturer,
    model: opts.model,
    variant: opts.variant,
    modelYear: opts.year,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("shock_eye_to_eye_mm", { num: opts.shockEye, unit: "mm" }),
      attr("shock_stroke_mm", { num: opts.shockStroke, unit: "mm" }),
      attr("shock_mount_type", { enum: opts.shockMount }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" }),
      attr("max_seatpost_insertion_mm", { num: 250, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 203, unit: "mm" }),
      attr("max_tire_width_mm", { num: 66, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: opts.url,
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  };
}

export const COMPONENT_CATALOG_DACH_SCALE2: ComponentModel[] = [
  frameEnduro({
    id: "cm-focus-sam-frame",
    manufacturer: "Focus",
    model: "SAM",
    variant: "2.0",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.focus-bikes.com/",
  }),
  frameEnduro({
    id: "cm-ghost-riot-en-frame",
    manufacturer: "Ghost",
    model: "Riot EN",
    variant: "Essential",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.ghost-bikes.com/",
  }),
  frameEnduro({
    id: "cm-lapierre-spicy-frame",
    manufacturer: "Lapierre",
    model: "Spicy",
    variant: "CF 8.9",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.lapierrebikes.com/",
  }),
  frameEnduro({
    id: "cm-radon-swoop-frame",
    manufacturer: "Radon",
    model: "Swoop",
    variant: "10.0",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 30.9,
    url: "https://www.radon-bikes.de/",
  }),
  frameEnduro({
    id: "cm-norco-range-frame",
    manufacturer: "Norco",
    model: "Range",
    variant: "C2",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.norco.com/",
  }),
  frameEnduro({
    id: "cm-ibis-ripmo-frame",
    manufacturer: "Ibis",
    model: "Ripmo",
    variant: "V2S",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.ibiscycles.com/",
  }),

  {
    id: "cm-rockshox-pike-150",
    slot: "fork",
    manufacturer: "RockShox",
    model: "Pike Ultimate",
    variant: "150mm 29",
    modelYear: 2024,
    attributes: [
      attr("travel_mm", { num: 150, unit: "mm" }),
      attr("steerer_type", { enum: "tapered_1.5" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("max_rotor_mm", { num: 220, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/en/rockshox",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-marzocchi-z1-170",
    slot: "fork",
    manufacturer: "Marzocchi",
    model: "Z1",
    variant: "170mm 29",
    modelYear: 2024,
    attributes: [
      attr("travel_mm", { num: 170, unit: "mm" }),
      attr("steerer_type", { enum: "tapered_1.5" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("max_rotor_mm", { num: 220, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.ridefox.com/marzocchi",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  // FLOAT X 210×55: bereits in componentsDach.ts (cm-fox-float-x-21055)
  {
    id: "cm-raceface-turbine-stem",
    slot: "stem",
    manufacturer: "Race Face",
    model: "Turbine R",
    variant: "35×40mm",
    attributes: [
      attr("stem_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.raceface.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-raceface-next-r-bar",
    slot: "handlebar",
    manufacturer: "Race Face",
    model: "Next R",
    variant: "35×800mm",
    attributes: [
      attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("width_mm", { num: 800, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.raceface.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-dt-ex511-rim-front",
    slot: "front_rim",
    manufacturer: "DT Swiss",
    model: "EX 511",
    variant: "29 Front",
    attributes: [
      attr("internal_rim_width_mm", { num: 30, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.dtswiss.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-dt-ex511-rim-rear",
    slot: "rear_rim",
    manufacturer: "DT Swiss",
    model: "EX 511",
    variant: "29 Rear",
    attributes: [
      attr("internal_rim_width_mm", { num: 30, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.dtswiss.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-sram-code-pads",
    slot: "brake_pads_front",
    manufacturer: "SRAM",
    model: "Code Organic",
    variant: "Front",
    attributes: [attr("pad_compound", { enum: "organic" })],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-magura-7p-pads",
    slot: "brake_pads_rear",
    manufacturer: "Magura",
    model: "7.P Performance",
    variant: "Rear",
    attributes: [attr("pad_compound", { enum: "organic" })],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.magura.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
];
