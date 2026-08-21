/**
 * Round 10 — analoge OEM: DH (Cube TWO15, Trek Session, Specialized Demo),
 * Trail (Canyon Lux), Road (Scott Addict, BMC Teammachine), Urban (Bulls Copperhead).
 * Quellen: Herstellerseiten 2025. Fehlende Maße bleiben leer.
 */

import type { ComponentModel, ComponentSlot, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";
const SHIMANO = "https://bike.shimano.com/";
const SRAM = "https://www.sram.com/";
const FOX = "https://www.ridefox.com/";

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

function part(
  id: string,
  slot: ComponentSlot,
  manufacturer: string,
  model: string,
  opts: {
    variant?: string;
    year?: number;
    url: string;
    attrs?: TypedAttribute[];
    safety?: boolean;
  }
): ComponentModel {
  return {
    id,
    slot,
    manufacturer,
    model,
    variant: opts.variant,
    modelYear: opts.year,
    attributes: opts.attrs ?? [],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: opts.url,
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: opts.safety ?? false,
  };
}

export const COMPONENT_CATALOG_DACH_SCALE10: ComponentModel[] = [
  part("cm-sram-hs2-220-rear", "rotor_rear", "SRAM", "HS2", {
    variant: "220 mm",
    url: SRAM,
    safety: true,
    attrs: [attr("rotor_size_mm", { num: 220, unit: "mm" })],
  }),
  part("cm-fox-float-x2-25075", "rear_shock", "Fox", "FLOAT X2 Performance", {
    variant: "250×75",
    url: FOX,
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("stroke_mm", { num: 75, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-marzocchi-bomber-250725", "rear_shock", "Marzocchi", "Bomber CR", {
    variant: "250×72.5 Coil",
    year: 2025,
    url: "https://www.ridefox.com/marzocchi",
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("stroke_mm", { num: 72.5, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-sram-dub-pf107", "bottom_bracket", "SRAM", "DUB MTB DH", {
    variant: "PF 107 mm",
    url: SRAM,
    attrs: [attr("bb_standard", { enum: "PF107" })],
  }),
  part("cm-fox-34-sc-120", "fork", "Fox", "34 Stepcast Performance Elite", {
    variant: "120mm 29",
    year: 2025,
    url: FOX,
    safety: true,
    attrs: [
      attr("travel_mm", { num: 120, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-rockshox-reba-100", "fork", "RockShox", "Reba RL", {
    variant: "100mm 29",
    year: 2025,
    url: "https://www.sram.com/en/rockshox",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 100, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-dt-fr1500-rim-275-front", "front_rim", "DT Swiss", "FR 1500 Classic", {
    variant: "27.5",
    url: "https://www.dtswiss.com/",
    attrs: [attr("wheel_size", { enum: "27.5" })],
  }),
  part("cm-schwalbe-magic-mary-275", "tire_front", "Schwalbe", "Magic Mary", {
    variant: "27.5×2.40 Super Gravity",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "27.5x2.4" })],
  }),
  part("cm-schwalbe-one-700-32", "tire_front", "Schwalbe", "ONE", {
    variant: "700×32",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "700x32" })],
  }),
  part("cm-schwalbe-one-700-32-rear", "tire_rear", "Schwalbe", "ONE", {
    variant: "700×32",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "700x32" })],
  }),
  part("cm-shimano-ultegra-r8150-fd", "front_derailleur", "Shimano", "Ultegra FD-R8150", {
    variant: "Di2 12s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-shimano-ultegra-r8170-shifter", "shifter", "Shimano", "Ultegra ST-R8170", {
    variant: "Di2 12s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-shimano-ultegra-r8170-front", "brake_front", "Shimano", "Ultegra BR-R8170", {
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "flat_mount" })],
  }),
  part("cm-shimano-ultegra-r8170-rear", "brake_rear", "Shimano", "Ultegra BR-R8170", {
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "flat_mount" })],
  }),
  part("cm-shimano-ultegra-r8100-crank", "crankset", "Shimano", "Ultegra FC-R8100", {
    variant: "50/34",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),

  {
    id: "cm-cube-two15-race-frame",
    slot: "frame",
    manufacturer: "Cube",
    model: "TWO15 Race",
    variant: "HPA 27.5 200",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "157x12" }),
      attr("axle_rear", { enum: "12x157" }),
      attr("shock_eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("shock_stroke_mm", { num: 75, unit: "mm" }),
      attr("shock_mount_type", { enum: "standard" }),
      attr("headset_top", { enum: "ZS56" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "PF107" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "27.5" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.cube.eu/cube-two15-race-27.5-cyclamen-n-black/839110",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-trek-session-8-frame",
    slot: "frame",
    manufacturer: "Trek",
    model: "Session 8",
    variant: "Alpha Platinum 29",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "157x12" }),
      attr("axle_rear", { enum: "12x157" }),
      attr("shock_eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("shock_stroke_mm", { num: 72.5, unit: "mm" }),
      attr("shock_mount_type", { enum: "standard" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "BSA83" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 220, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.trekbikes.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-specialized-demo-race-frame",
    slot: "frame",
    manufacturer: "Specialized",
    model: "Demo Race",
    variant: "M5 Mullet 200",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: 30.9, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "27.5" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.specialized.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-canyon-lux-trail-frame",
    slot: "frame",
    manufacturer: "Canyon",
    model: "Lux Trail CF",
    variant: "115 mm",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.canyon.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-scott-addict-20-frame",
    slot: "frame",
    manufacturer: "Scott",
    model: "Addict 20",
    variant: "HMF Carbon",
    modelYear: 2025,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "PF86" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_tire_width_mm", { num: 38, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.scott-sports.com/global/en/product/scott-addict-20-bike",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-bmc-teammachine-slr-frame",
    slot: "frame",
    manufacturer: "BMC",
    model: "Teammachine SLR",
    variant: "Five",
    modelYear: 2025,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "PF86" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_tire_width_mm", { num: 30, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.bmc-switzerland.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-bulls-copperhead-3s-frame",
    slot: "frame",
    manufacturer: "Bulls",
    model: "Copperhead 3 S",
    variant: "Alloy 29 Hardtail",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.bulls.de/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
];
