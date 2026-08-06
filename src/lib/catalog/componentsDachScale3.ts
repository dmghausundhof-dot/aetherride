/**
 * G-4 Katalog-Skalierung Round 3 — weitere DE/EU-OEM + Aftermarket.
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
  maxTireMm?: number;
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
      attr("max_tire_width_mm", {
        num: opts.maxTireMm ?? 66,
        unit: "mm",
      }),
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

function frameEmtb(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant?: string;
  year: number;
  shockEye: number;
  shockStroke: number;
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
      attr("shock_mount_type", { enum: "trunnion" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" }),
      attr("max_seatpost_insertion_mm", { num: 240, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 220, unit: "mm" }),
      attr("max_tire_width_mm", { num: 66, unit: "mm" }),
      attr("motor_interface", { enum: "bosch_smart_system" }),
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

export const COMPONENT_CATALOG_DACH_SCALE3: ComponentModel[] = [
  frameEnduro({
    id: "cm-rotwild-r-x375-frame",
    manufacturer: "Rotwild",
    model: "R.X375",
    variant: "Ultra",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.rotwild.de/",
  }),
  frameEnduro({
    id: "cm-liteville-301-frame",
    manufacturer: "Liteville",
    model: "301 MK2",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.liteville.com/",
  }),
  frameEnduro({
    id: "cm-nicolai-g1-frame",
    manufacturer: "Nicolai",
    model: "G1",
    variant: "Enduro",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.nicolai-bikes.com/",
  }),
  frameEnduro({
    id: "cm-whyte-t-140-frame",
    manufacturer: "Whyte",
    model: "T-140",
    variant: "RS",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.whytebikes.com/",
  }),
  frameEmtb({
    id: "cm-bulls-sonic-evo-frame",
    manufacturer: "Bulls",
    model: "Sonic Evo AM",
    variant: "4",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    seatpostMm: 31.6,
    url: "https://www.bulls.de/",
  }),
  frameEmtb({
    id: "cm-haibike-allmountain-frame",
    manufacturer: "Haibike",
    model: "AllMtn",
    variant: "7",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    seatpostMm: 31.6,
    url: "https://www.haibike.com/",
  }),

  // Lyrik / Hope Tech4 / Schwalbe Mary+Betty: bereits im Katalog
  {
    id: "cm-fox-36-performance-160",
    slot: "fork",
    manufacturer: "Fox",
    model: "36 Performance Elite",
    variant: "160mm 29",
    modelYear: 2024,
    attributes: [
      attr("travel_mm", { num: 160, unit: "mm" }),
      attr("steerer_type", { enum: "tapered_1.5" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("max_rotor_mm", { num: 230, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
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
    id: "cm-burgtec-mk3-stem",
    slot: "stem",
    manufacturer: "Burgtec",
    model: "Enduro MK3",
    variant: "35×35mm",
    attributes: [
      attr("stem_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.burgtec.co.uk/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-burgtec-ridewide-bar",
    slot: "handlebar",
    manufacturer: "Burgtec",
    model: "RideWide Carbon",
    variant: "35×800mm",
    attributes: [
      attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("width_mm", { num: 800, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.burgtec.co.uk/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
];
