/**
 * G-4 Katalog-Skalierung — weitere EU-Enduro-OEM + Aftermarket.
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

export const COMPONENT_CATALOG_DACH_SCALE: ComponentModel[] = [
  frameEnduro({
    id: "cm-mondraker-foxy-frame",
    manufacturer: "Mondraker",
    model: "Foxy",
    variant: "Carbon RR",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.mondraker.com/",
  }),
  frameEnduro({
    id: "cm-scott-ransom-frame",
    manufacturer: "Scott",
    model: "Ransom",
    variant: "910",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.scott-sports.com/",
  }),
  frameEnduro({
    id: "cm-giant-trance-x-frame",
    manufacturer: "Giant",
    model: "Trance X",
    variant: "Advanced Pro",
    year: 2024,
    shockEye: 205,
    shockStroke: 60,
    shockMount: "trunnion",
    seatpostMm: 30.9,
    url: "https://www.giant-bicycles.com/",
  }),
  frameEnduro({
    id: "cm-merida-one-sixty-frame",
    manufacturer: "Merida",
    model: "One-Sixty",
    variant: "8000",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 30.9,
    url: "https://www.merida-bikes.com/",
  }),
  frameEnduro({
    id: "cm-intense-tracer-frame",
    manufacturer: "Intense",
    model: "Tracer",
    variant: "279",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.intensecycles.com/",
  }),
  frameEnduro({
    id: "cm-yeti-sb165-frame",
    manufacturer: "Yeti",
    model: "SB165",
    variant: "T1",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.yeticycles.com/",
  }),

  {
    id: "cm-fox-float-x2-20560",
    slot: "rear_shock",
    manufacturer: "Fox",
    model: "Float X2 Factory",
    variant: "205×60 Trunnion",
    modelYear: 2024,
    attributes: [
      attr("eye_to_eye_mm", { num: 205, unit: "mm" }),
      attr("stroke_mm", { num: 60, unit: "mm" }),
      attr("mount_type", { enum: "trunnion" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.ridefox.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-rockshox-superdeluxe-20565",
    slot: "rear_shock",
    manufacturer: "RockShox",
    model: "Super Deluxe Ultimate",
    variant: "205×65 Trunnion",
    modelYear: 2024,
    attributes: [
      attr("eye_to_eye_mm", { num: 205, unit: "mm" }),
      attr("stroke_mm", { num: 65, unit: "mm" }),
      attr("mount_type", { enum: "trunnion" }),
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
    id: "cm-formula-cura-4-front",
    slot: "brake_front",
    manufacturer: "Formula",
    model: "Cura 4",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.formula-brake.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-formula-cura-4-rear",
    slot: "brake_rear",
    manufacturer: "Formula",
    model: "Cura 4",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.formula-brake.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-magura-mt5-front",
    slot: "brake_front",
    manufacturer: "Magura",
    model: "MT5",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.magura.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-magura-mt5-rear",
    slot: "brake_rear",
    manufacturer: "Magura",
    model: "MT5",
    variant: "4-Kolben",
    attributes: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("rotor_mount", { enum: "6_bolt" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.magura.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-schwalbe-nobby-nic-29",
    slot: "tire_front",
    manufacturer: "Schwalbe",
    model: "Nobby Nic",
    variant: "29×2.4 Soft Super Ground",
    attributes: [
      attr("tire_width_mm", { num: 60, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("etrto", { text: "60-622" }),
      attr("tubeless_ready", { enum: "yes" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.schwalbe.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-maxxis-dissector-29-24",
    slot: "tire_rear",
    manufacturer: "Maxxis",
    model: "Dissector",
    variant: "29×2.4 WT EXO+",
    attributes: [
      attr("tire_width_mm", { num: 61, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("etrto", { text: "61-622" }),
      attr("tubeless_ready", { enum: "yes" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.maxxis.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-rockshox-recliner-31-6",
    slot: "seatpost",
    manufacturer: "RockShox",
    model: "Reverb AXS",
    variant: "31.6 × 170mm",
    attributes: [
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("min_insertion_mm", { num: 140, unit: "mm" }),
      attr("dropper_travel_mm", { num: 170, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/en/rockshox",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
];
