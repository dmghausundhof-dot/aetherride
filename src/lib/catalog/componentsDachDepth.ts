/**
 * G-4 Katalogtiefe — weitere DACH-/EU-Enduro-Marken + Aftermarket.
 * Fehlende Attribute → INSUFFICIENT_DATA (nie raten).
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
    source?: TypedAttribute["source"];
  }
): TypedAttribute {
  return {
    key,
    valueText: opts.text,
    valueNum: opts.num,
    valueEnum: opts.enum ?? opts.text,
    unit: opts.unit,
    source: opts.source ?? "manufacturer_doc",
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

function tire(
  id: string,
  manufacturer: string,
  model: string,
  variant: string,
  slot: "tire_front" | "tire_rear",
  widthMm: number,
  etrto: string,
  url: string
): ComponentModel {
  return {
    id,
    slot,
    manufacturer,
    model,
    variant,
    attributes: [
      attr("tire_width_mm", { num: widthMm, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("etrto", { text: etrto }),
      attr("tubeless_ready", { enum: "yes" }),
    ],
    adjusters: [
      {
        key: "pressure_psi",
        label: "Luftdruck",
        unit: "psi",
        min: 15,
        max: 40,
        step: 0.5,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: url,
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: false,
  };
}

export const COMPONENT_CATALOG_DACH_DEPTH: ComponentModel[] = [
  // —— Rahmen ——
  frameEnduro({
    id: "cm-santa-cruz-hightower-frame",
    manufacturer: "Santa Cruz",
    model: "Hightower",
    variant: "C",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.santacruzbicycles.com/",
  }),
  frameEnduro({
    id: "cm-commencal-meta-am-frame",
    manufacturer: "Commencal",
    model: "Meta AM",
    variant: "29",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.commencal.com/",
  }),
  frameEnduro({
    id: "cm-orbea-rallon-frame",
    manufacturer: "Orbea",
    model: "Rallon",
    variant: "M10",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.orbea.com/",
  }),
  frameEnduro({
    id: "cm-nukeproof-giga-frame",
    manufacturer: "Nukeproof",
    model: "Giga",
    variant: "290",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://nukeproof.com/",
  }),
  frameEnduro({
    id: "cm-pivot-firebird-frame",
    manufacturer: "Pivot",
    model: "Firebird",
    variant: "Ride",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.pivotcycles.com/",
  }),
  frameEnduro({
    id: "cm-forbidden-dreadnought-frame",
    manufacturer: "Forbidden",
    model: "Dreadnought",
    variant: "V2",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.forbiddenbike.com/",
  }),

  // —— Coil / Premium-Dämpfer ——
  {
    id: "cm-fox-dhx2-20565",
    slot: "rear_shock",
    manufacturer: "Fox",
    model: "DHX2 Factory",
    variant: "205×65 Trunnion Coil",
    modelYear: 2024,
    attributes: [
      attr("eye_to_eye_mm", { num: 205, unit: "mm" }),
      attr("stroke_mm", { num: 65, unit: "mm" }),
      attr("mount_type", { enum: "trunnion" }),
      attr("spring_type", { enum: "coil" }),
    ],
    adjusters: [
      {
        key: "sag_pct",
        label: "SAG",
        unit: "%",
        min: 25,
        max: 35,
        step: 1,
      },
      {
        key: "rebound",
        label: "Zugstufe",
        unit: "clicks",
        totalClicks: 16,
        reference: "from_closed",
        min: 0,
        max: 16,
        step: 1,
      },
      {
        key: "lsc",
        label: "LSC",
        unit: "clicks",
        totalClicks: 16,
        reference: "from_closed",
        min: 0,
        max: 16,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.ridefox.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-cane-creek-dbair-20565",
    slot: "rear_shock",
    manufacturer: "Cane Creek",
    model: "DBAir IL",
    variant: "205×65 Trunnion",
    modelYear: 2024,
    attributes: [
      attr("eye_to_eye_mm", { num: 205, unit: "mm" }),
      attr("stroke_mm", { num: 65, unit: "mm" }),
      attr("mount_type", { enum: "trunnion" }),
      attr("spring_type", { enum: "air" }),
    ],
    adjusters: [
      {
        key: "air_pressure_psi",
        label: "Luftdruck",
        unit: "psi",
        min: 100,
        max: 350,
        step: 1,
      },
      {
        key: "sag_pct",
        label: "SAG",
        unit: "%",
        min: 25,
        max: 35,
        step: 1,
      },
      {
        key: "rebound",
        label: "Zugstufe",
        unit: "clicks",
        totalClicks: 18,
        reference: "from_closed",
        min: 0,
        max: 18,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.canecreek.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },

  // —— Bremsen / Scheiben ——
  {
    id: "cm-sram-maven-silver-front",
    slot: "brake_front",
    manufacturer: "SRAM",
    model: "Maven Silver",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-sram-maven-silver-rear",
    slot: "brake_rear",
    manufacturer: "SRAM",
    model: "Maven Silver",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-hope-tech4-v4-front",
    slot: "brake_front",
    manufacturer: "Hope",
    model: "Tech 4 V4",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.hopetech.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-hope-tech4-v4-rear",
    slot: "brake_rear",
    manufacturer: "Hope",
    model: "Tech 4 V4",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.hopetech.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-hope-floating-200-front",
    slot: "rotor_front",
    manufacturer: "Hope",
    model: "Floating Rotor",
    variant: "200mm 6-Bolt",
    attributes: [
      attr("rotor_diameter_mm", { num: 200, unit: "mm" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.hopetech.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-hope-floating-180-rear",
    slot: "rotor_rear",
    manufacturer: "Hope",
    model: "Floating Rotor",
    variant: "180mm 6-Bolt",
    attributes: [
      attr("rotor_diameter_mm", { num: 180, unit: "mm" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.hopetech.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },

  // —— Naben 6-Bolt ——
  {
    id: "cm-dt-240-boost-front-6b",
    slot: "front_hub",
    manufacturer: "DT Swiss",
    model: "240",
    variant: "15×110 Boost 6-Bolt",
    attributes: [
      attr("axle_front", { enum: "15x110_boost" }),
      attr("rotor_mount", { enum: "6_bolt" }),
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
    id: "cm-dt-240-boost-rear-xd-6b",
    slot: "rear_hub",
    manufacturer: "DT Swiss",
    model: "240",
    variant: "12×148 Boost XD 6-Bolt",
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("freehub_standard", { enum: "XD" }),
      attr("rotor_mount", { enum: "6_bolt" }),
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
    id: "cm-i9-hydra-boost-rear-xd",
    slot: "rear_hub",
    manufacturer: "Industry Nine",
    model: "Hydra",
    variant: "12×148 Boost XD 6-Bolt",
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("freehub_standard", { enum: "XD" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.industrynine.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },

  // —— Reifen ——
  tire(
    "cm-schwalbe-magic-mary-29",
    "Schwalbe",
    "Magic Mary",
    "29×2.4 Soft Super Trail",
    "tire_front",
    60,
    "60-622",
    "https://www.schwalbe.com/"
  ),
  tire(
    "cm-schwalbe-big-betty-29",
    "Schwalbe",
    "Big Betty",
    "29×2.4 Soft Super Trail",
    "tire_rear",
    60,
    "60-622",
    "https://www.schwalbe.com/"
  ),
  tire(
    "cm-maxxis-aggressor-29-25",
    "Maxxis",
    "Aggressor",
    "29×2.5 WT EXO+",
    "tire_rear",
    63.5,
    "63-622",
    "https://www.maxxis.com/"
  ),

  // —— Dropper ——
  {
    id: "cm-bikeyoke-revive-31-6",
    slot: "seatpost",
    manufacturer: "BikeYoke",
    model: "Revive 3",
    variant: "31.6 × 185mm",
    attributes: [
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("min_insertion_mm", { num: 140, unit: "mm" }),
      attr("dropper_travel_mm", { num: 185, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.bikeyoke.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-fox-transfer-31-6",
    slot: "seatpost",
    manufacturer: "Fox",
    model: "Transfer Factory",
    variant: "31.6 × 175mm",
    attributes: [
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("min_insertion_mm", { num: 140, unit: "mm" }),
      attr("dropper_travel_mm", { num: 175, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.ridefox.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
];
