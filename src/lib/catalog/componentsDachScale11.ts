/**
 * Round 11 — analoge OEM: City/Trekking (Gazelle Chamonix, Winora Domingo),
 * Road (Aeroad, Domane, Roubaix), Trail (Santa Cruz Blur).
 * Quellen: Hersteller 2024–2025. Fehlende Maße bleiben leer.
 */

import type { ComponentModel, ComponentSlot, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";
const SHIMANO = "https://bike.shimano.com/";

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

function frameRoadish(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant: string;
  year: number;
  url: string;
  bb: string;
  maxTireMm: number;
  seatpostMm?: number;
}): ComponentModel {
  return {
    id: opts.id,
    slot: "frame",
    manufacturer: opts.manufacturer,
    model: opts.model,
    variant: opts.variant,
    modelYear: opts.year,
    attributes: [
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: opts.bb }),
      attr("seatpost_diameter_mm", { num: opts.seatpostMm ?? 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_tire_width_mm", { num: opts.maxTireMm, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
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

export const COMPONENT_CATALOG_DACH_SCALE11: ComponentModel[] = [
  part("cm-shimano-nexus-sg-c6001", "rear_hub", "Shimano", "Nexus SG-C6001-8D", {
    variant: "8s Disc",
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("speed", { num: 8 }),
      attr("freehub_body", { enum: "IGH" }),
    ],
  }),
  part("cm-shimano-nexus-sl-c6000", "shifter", "Shimano", "Nexus SL-C6000-8", {
    variant: "8s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 8 })],
  }),
  part("cm-shimano-nexus-18t", "cassette", "Shimano", "Nexus sprocket", {
    variant: "18T",
    url: SHIMANO,
    attrs: [attr("teeth", { num: 18 })],
  }),
  part("cm-kmc-z1-chain", "chain", "KMC", "Z1", {
    url: "https://www.kmcchain.com/",
    attrs: [attr("speed", { num: 1 })],
  }),
  part("cm-schwalbe-road-cruiser-700-42", "tire_front", "Schwalbe", "Road Cruiser", {
    variant: "42-622",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "700x42" })],
  }),
  part("cm-schwalbe-road-cruiser-700-42-rear", "tire_rear", "Schwalbe", "Road Cruiser", {
    variant: "42-622",
    url: "https://www.schwalbe.com/",
    attrs: [attr("tire_size", { text: "700x42" })],
  }),
  part("cm-gazelle-mono-fork-40", "fork", "Gazelle", "Mono Integrated", {
    variant: "40 mm",
    year: 2025,
    url: "https://www.gazellebikes.com/",
    safety: true,
    attrs: [attr("travel_mm", { num: 40, unit: "mm" })],
  }),
  part("cm-specialized-future-shock-fork", "fork", "Specialized", "Future Shock 3.1", {
    variant: "20 mm FACT Carbon",
    year: 2024,
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 20, unit: "mm" }),
      attr("axle_front", { enum: "12x100" }),
    ],
  }),
  part("cm-shimano-ultegra-chainring-52-36", "chainring", "Shimano", "Ultegra 52/36", {
    url: SHIMANO,
    attrs: [attr("teeth", { num: 52 })],
  }),

  {
    id: "cm-gazelle-chamonix-c8-frame",
    slot: "frame",
    manufacturer: "Gazelle",
    model: "Chamonix C8",
    variant: "Aluminium 700c",
    modelYear: 2025,
    attributes: [
      attr("axle_rear", { enum: "135x5_qr" }),
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
    sourceUrl: "https://www.gazellebikes.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-winora-domingo-8-frame",
    slot: "frame",
    manufacturer: "Winora",
    model: "Domingo 8",
    variant: "Aluminium Trekking",
    modelYear: 2025,
    attributes: [
      attr("axle_rear", { enum: "135x5_qr" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.winora.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  frameRoadish({
    id: "cm-canyon-aeroad-slx-frame",
    manufacturer: "Canyon",
    model: "Aeroad CF SLX",
    variant: "8 Di2",
    year: 2025,
    url: "https://www.canyon.com/en-de/road-bikes/aero-bikes/aeroad/",
    bb: "PF86",
    maxTireMm: 32,
  }),
  frameRoadish({
    id: "cm-trek-domane-sl-frame",
    manufacturer: "Trek",
    model: "Domane SL",
    variant: "OCLV 500 Gen 4",
    year: 2025,
    url: "https://www.trekbikes.com/",
    bb: "T47",
    maxTireMm: 38,
  }),
  frameRoadish({
    id: "cm-specialized-roubaix-sl8-frame",
    manufacturer: "Specialized",
    model: "Roubaix SL8",
    variant: "Sport FACT 10r",
    year: 2024,
    url: "https://www.specialized.com/",
    bb: "BSA68",
    maxTireMm: 38,
  }),
  {
    id: "cm-santa-cruz-blur-frame",
    slot: "frame",
    manufacturer: "Santa Cruz",
    model: "Blur C",
    variant: "Carbon 115",
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
    sourceUrl: "https://www.santacruzbicycles.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
];
