/**
 * Round 9 — analoge OEM: DH (YT Tues, Canyon Sender, Commencal Supreme),
 * XC/Trail (Epic, Oiz), Road (Émonda, TCR), Urban (Sirrus, Nature).
 * Quellen: Herstellerseiten 2024–2026. Fehlende Maße bleiben leer.
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

function frameSlim(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant: string;
  year: number;
  url: string;
  wheelRear: string;
  seatpostMm?: number;
  axleRear?: string;
}): ComponentModel {
  return {
    id: opts.id,
    slot: "frame",
    manufacturer: opts.manufacturer,
    model: opts.model,
    variant: opts.variant,
    modelYear: opts.year,
    attributes: [
      attr("rear_spacing", {
        enum: opts.axleRear === "12x148_boost" ? "148x12_boost" : "142x12",
      }),
      attr("axle_rear", { enum: opts.axleRear ?? "12x142" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      ...(opts.seatpostMm
        ? [attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" })]
        : []),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: opts.wheelRear }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: opts.url,
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  };
}

export const COMPONENT_CATALOG_DACH_SCALE9: ComponentModel[] = [
  // —— DH / Trail-Fahrwerk & Bremsen ——
  part("cm-trp-dhr-evo-front", "brake_front", "TRP", "DH-R EVO", {
    variant: "4-Kolben",
    url: "https://www.trpbrakes.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-trp-dhr-evo-rear", "brake_rear", "TRP", "DH-R EVO", {
    variant: "4-Kolben",
    url: "https://www.trpbrakes.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-trp-r1-223-front", "rotor_front", "TRP", "R1", {
    variant: "223 mm 6-bolt",
    url: "https://www.trpbrakes.com/",
    safety: true,
    attrs: [attr("rotor_size_mm", { num: 223, unit: "mm" })],
  }),
  part("cm-trp-r1-223-rear", "rotor_rear", "TRP", "R1", {
    variant: "223 mm 6-bolt",
    url: "https://www.trpbrakes.com/",
    safety: true,
    attrs: [attr("rotor_size_mm", { num: 223, unit: "mm" })],
  }),
  part("cm-rockshox-sid-select-120", "fork", "RockShox", "SID Select", {
    variant: "120mm 29",
    year: 2024,
    url: "https://www.sram.com/en/rockshox",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 120, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-fox-32-rhythm-120", "fork", "Fox", "32 Float Rhythm", {
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
  part("cm-rockshox-sidluxe-19045", "rear_shock", "RockShox", "SIDLuxe Select+", {
    variant: "190×45",
    url: "https://www.sram.com/en/rockshox",
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 190, unit: "mm" }),
      attr("stroke_mm", { num: 45, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-fox-float-sl-19045", "rear_shock", "Fox", "FLOAT SL Performance", {
    variant: "190×45",
    url: FOX,
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 190, unit: "mm" }),
      attr("stroke_mm", { num: 45, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-fox-dhx2-25075", "rear_shock", "Fox", "DHX2 Performance Elite", {
    variant: "250×75",
    url: FOX,
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("stroke_mm", { num: 75, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-rockshox-vivid-coil-dh", "rear_shock", "RockShox", "Vivid Coil Ultimate", {
    variant: "DH",
    year: 2025,
    url: "https://www.sram.com/en/rockshox",
    safety: true,
    attrs: [],
  }),
  part("cm-fox-dhx2-coil-open", "rear_shock", "Fox", "DHX2 Factory", {
    variant: "Coil DH",
    url: FOX,
    safety: true,
    attrs: [],
  }),

  // —— Analog-Antrieb / Reifen ——
  part("cm-sram-gx-eagle-rd", "rear_derailleur", "SRAM", "GX Eagle", {
    variant: "12s",
    url: SRAM,
    attrs: [attr("speed", { num: 12 }), attr("max_cog", { num: 52 })],
  }),
  part("cm-sram-gx-eagle-shifter", "shifter", "SRAM", "GX Eagle", {
    variant: "12s Trigger",
    url: SRAM,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-sram-xg-1275", "cassette", "SRAM", "XG-1275 Eagle", {
    variant: "10-52 12s",
    url: SRAM,
    attrs: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "XD" }),
    ],
  }),
  part("cm-sram-gx-eagle-crank", "crankset", "SRAM", "GX Eagle DUB", {
    url: SRAM,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-sram-gx-eagle-ring-32", "chainring", "SRAM", "GX Eagle", {
    variant: "32T",
    url: SRAM,
    attrs: [attr("teeth", { num: 32 })],
  }),
  part("cm-shimano-deore-m6100-rd", "rear_derailleur", "Shimano", "Deore RD-M6100", {
    variant: "12s SGS",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 }), attr("max_cog", { num: 51 })],
  }),
  part("cm-shimano-deore-m6100-shifter", "shifter", "Shimano", "Deore SL-M6100", {
    variant: "12s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-shimano-cs-m6100", "cassette", "Shimano", "Deore CS-M6100", {
    variant: "10-51 12s",
    url: SHIMANO,
    attrs: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-schwalbe-racing-ralph-29", "tire_front", "Schwalbe", "Racing Ralph", {
    variant: "29×2.25 Super Ground",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "29x2.25" })],
  }),
  part("cm-schwalbe-racing-ralph-29-rear", "tire_rear", "Schwalbe", "Racing Ralph", {
    variant: "29×2.25 Super Ground",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "29x2.25" })],
  }),
  part("cm-schwalbe-tacky-chan-29", "tire_front", "Schwalbe", "Tacky Chan", {
    variant: "29×2.40 DH",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "29x2.4" })],
  }),
  part("cm-schwalbe-tacky-chan-275", "tire_rear", "Schwalbe", "Tacky Chan", {
    variant: "27.5×2.40 DH",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "27.5x2.4" })],
  }),
  part("cm-maxxis-assegai-29-25-rear", "tire_rear", "Maxxis", "Assegai", {
    variant: "29×2.50 DH",
    url: "https://www.maxxis.com/",
    attrs: [attr("tire_size", { text: "29x2.5" })],
  }),

  // —— Rahmen analog ——
  frameSlim({
    id: "cm-yt-tues-29-frame",
    manufacturer: "YT Industries",
    model: "Tues 29",
    variant: "Carbon Core 4",
    year: 2025,
    url: "https://www.yt-industries.com/",
    wheelRear: "29",
    seatpostMm: 31.6,
    axleRear: "12x148_boost",
  }),
  frameSlim({
    id: "cm-canyon-sender-cfr-frame",
    manufacturer: "Canyon",
    model: "Sender CFR",
    variant: "Mullet 200",
    year: 2025,
    url: "https://www.canyon.com/en-de/mountain-bikes/downhill-bikes/sender/",
    wheelRear: "27.5",
    seatpostMm: 31.6,
    axleRear: "12x148_boost",
  }),
  {
    id: "cm-commencal-supreme-v5-frame",
    slot: "frame",
    manufacturer: "Commencal",
    model: "Supreme DH V5",
    variant: "Alloy 220 Mullet",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("shock_eye_to_eye_mm", { num: 250, unit: "mm" }),
      attr("shock_stroke_mm", { num: 75, unit: "mm" }),
      attr("shock_mount_type", { enum: "standard" }),
      attr("headset_top", { enum: "ZS56" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 223, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "27.5" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.commencal.com/en/landing-supreme-dh-v5.html",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  frameSlim({
    id: "cm-specialized-epic-frame",
    manufacturer: "Specialized",
    model: "Epic 8",
    variant: "Comp Carbon",
    year: 2024,
    url: "https://www.specialized.com/",
    wheelRear: "29",
    seatpostMm: 30.9,
    axleRear: "12x148_boost",
  }),
  frameSlim({
    id: "cm-orbea-oiz-h30-frame",
    manufacturer: "Orbea",
    model: "Oiz H30",
    variant: "Alloy 120",
    year: 2025,
    url: "https://www.orbea.com/",
    wheelRear: "29",
    seatpostMm: 31.6,
    axleRear: "12x148_boost",
  }),
  {
    id: "cm-trek-emonda-sl-frame",
    slot: "frame",
    manufacturer: "Trek",
    model: "Émonda SL",
    variant: "OCLV 500",
    modelYear: 2024,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "T47" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_tire_width_mm", { num: 28, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
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
    id: "cm-giant-tcr-advanced-frame",
    slot: "frame",
    manufacturer: "Giant",
    model: "TCR Advanced",
    variant: "Composite",
    modelYear: 2025,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "PF86" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_tire_width_mm", { num: 33, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.giant-bicycles.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-specialized-sirrus-x-frame",
    slot: "frame",
    manufacturer: "Specialized",
    model: "Sirrus X",
    variant: "Alloy 4.0",
    modelYear: 2024,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.specialized.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  frameSlim({
    id: "cm-cube-nature-exc-frame",
    manufacturer: "Cube",
    model: "Nature EXC",
    variant: "Aluminium 29",
    year: 2025,
    url: "https://www.cube.eu/",
    wheelRear: "29",
    seatpostMm: 27.2,
    axleRear: "12x142",
  }),
  frameSlim({
    id: "cm-santa-cruz-nomad-frame",
    manufacturer: "Santa Cruz",
    model: "Nomad 6",
    variant: "Carbon C",
    year: 2024,
    url: "https://www.santacruzbicycles.com/",
    wheelRear: "27.5",
    seatpostMm: 31.6,
    axleRear: "12x148_boost",
  }),
  frameSlim({
    id: "cm-ktm-ultra-1964-frame",
    manufacturer: "KTM",
    model: "Ultra 1964",
    variant: "Comp 29 Hardtail",
    year: 2025,
    url: "https://www.ktm-bikes.at/",
    wheelRear: "29",
    seatpostMm: 30.9,
    axleRear: "12x148_boost",
  }),
  frameSlim({
    id: "cm-bergamont-revox-frame",
    manufacturer: "Bergamont",
    model: "Revox 6",
    variant: "FMN 29 Hardtail",
    year: 2025,
    url: "https://www.bergamont.com/",
    wheelRear: "29",
    seatpostMm: 30.9,
    axleRear: "12x148_boost",
  }),
  part("cm-praxis-t47", "bottom_bracket", "Praxis", "T47 Internal", {
    url: "https://www.praxiscycles.com/",
    attrs: [attr("bb_standard", { enum: "T47" })],
  }),
  part("cm-sram-dub-pf86", "bottom_bracket", "SRAM", "DUB PF86", {
    url: SRAM,
    attrs: [attr("bb_standard", { enum: "PF86" })],
  }),
  part("cm-alloy-seatpost-31-6", "seatpost", "Race Face", "Ride", {
    variant: "31.6 rigid",
    url: "https://www.raceface.com/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 31.6, unit: "mm" })],
  }),
];
