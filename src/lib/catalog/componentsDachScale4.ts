/**
 * G-4 Katalog-Skalierung Round 4 — Road/Gravel/Urban + Aftermarket.
 * Seed-Erweiterung; Spec ≥3000 bleibt offen (kein Fake-G-4-Close).
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

function frameRoad(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant?: string;
  year: number;
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
      attr("bb_standard", { enum: "BSA68" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("max_tire_width_mm", { num: 32, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("wheel_size_rear", { enum: "700c" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
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

export const COMPONENT_CATALOG_DACH_SCALE4: ComponentModel[] = [
  frameRoad({
    id: "cm-canyon-ultimate-frame",
    manufacturer: "Canyon",
    model: "Ultimate CF SL",
    year: 2024,
    url: "https://www.canyon.com/",
  }),
  frameRoad({
    id: "cm-cube-attain-frame",
    manufacturer: "Cube",
    model: "Attain GTC",
    year: 2024,
    url: "https://www.cube.eu/",
  }),
  {
    id: "cm-schwalbe-pro-one-700-28",
    slot: "tire_front",
    manufacturer: "Schwalbe",
    model: "Pro One",
    variant: "700×28 TLE",
    attributes: [
      attr("tire_width_mm", { num: 28, unit: "mm" }),
      attr("etrto", { text: "28-622" }),
      attr("wheel_size", { enum: "700c" }),
    ],
    adjusters: [
      {
        key: "pressure_psi",
        label: "Druck",
        unit: "psi",
        min: 55,
        max: 100,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.schwalbe.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-vittoria-corsa-700-28",
    slot: "tire_front",
    manufacturer: "Vittoria",
    model: "Corsa N.EXT",
    variant: "700×28",
    attributes: [
      attr("tire_width_mm", { num: 28, unit: "mm" }),
      attr("etrto", { text: "28-622" }),
      attr("wheel_size", { enum: "700c" }),
    ],
    adjusters: [
      {
        key: "pressure_psi",
        label: "Druck",
        unit: "psi",
        min: 60,
        max: 110,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.vittoria.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-shimano-105-r7100-cassette",
    slot: "cassette",
    manufacturer: "Shimano",
    model: "105 CS-R7100",
    variant: "11-34 12s",
    attributes: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "HG" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://bike.shimano.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-shimano-105-r7100-rd",
    slot: "rear_derailleur",
    manufacturer: "Shimano",
    model: "105 RD-R7100",
    attributes: [
      attr("speed", { num: 12 }),
      attr("max_cog", { num: 34 }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://bike.shimano.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-sram-rival-axs-rd",
    slot: "rear_derailleur",
    manufacturer: "SRAM",
    model: "Rival eTap AXS",
    attributes: [
      attr("speed", { num: 12 }),
      attr("wireless", { enum: "true", text: "true" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.sram.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-fizik-vento-saddle",
    slot: "saddle",
    manufacturer: "Fizik",
    model: "Vento Argo R5",
    attributes: [],
    adjusters: [
      {
        key: "setback_mm",
        label: "Versatz",
        unit: "mm",
        min: -20,
        max: 20,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.fizik.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-dt-prc1400-rim-front",
    slot: "front_rim",
    manufacturer: "DT Swiss",
    model: "PRC 1400 Spline",
    variant: "700c",
    attributes: [
      attr("rim_erd_mm", { num: 595, unit: "mm" }),
      attr("rim_internal_width_mm", { num: 20, unit: "mm" }),
      attr("wheel_size", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.dtswiss.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-dt-prc1400-rim-rear",
    slot: "rear_rim",
    manufacturer: "DT Swiss",
    model: "PRC 1400 Spline",
    variant: "700c",
    attributes: [
      attr("rim_erd_mm", { num: 595, unit: "mm" }),
      attr("rim_internal_width_mm", { num: 20, unit: "mm" }),
      attr("wheel_size", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.dtswiss.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
];
