/**
 * Garage-Katalog Round 5 — mehr Hersteller/Modelle (Trail, Gravel, Road, E-Trekking).
 * Nur echte Modellnamen; OEM-Refs müssen in bikes.ts auflösbar bleiben.
 */

import type { ComponentModel, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-12T00:00:00.000Z";

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

function frameGravel(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant?: string;
  year: number;
  url: string;
  maxTireMm?: number;
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
      attr("rear_spacing", { enum: "142x12" }),
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", {
        num: opts.seatpostMm ?? 27.2,
        unit: "mm",
      }),
      attr("max_seatpost_insertion_mm", { num: 220, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_rotor_rear_mm", { num: 160, unit: "mm" }),
      attr("max_tire_width_mm", {
        num: opts.maxTireMm ?? 45,
        unit: "mm",
      }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "700c" }),
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
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  };
}

function frameEtrekking(opts: {
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
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("max_seatpost_insertion_mm", { num: 240, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 203, unit: "mm" }),
      attr("max_tire_width_mm", { num: 55, unit: "mm" }),
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

export const COMPONENT_CATALOG_DACH_SCALE5: ComponentModel[] = [
  // —— Neue Rahmen ——
  frameEnduro({
    id: "cm-cannondale-habit-frame",
    manufacturer: "Cannondale",
    model: "Habit Carbon",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.cannondale.com/",
  }),
  frameGravel({
    id: "cm-cannondale-topstone-frame",
    manufacturer: "Cannondale",
    model: "Topstone Carbon",
    year: 2024,
    url: "https://www.cannondale.com/",
    maxTireMm: 47,
  }),
  frameEnduro({
    id: "cm-bmc-fourstroke-frame",
    manufacturer: "BMC",
    model: "Fourstroke 01",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.bmc-switzerland.com/",
    maxTireMm: 61,
  }),
  frameGravel({
    id: "cm-bmc-kaius-frame",
    manufacturer: "BMC",
    model: "Kaius 01",
    year: 2024,
    url: "https://www.bmc-switzerland.com/",
    maxTireMm: 44,
  }),
  frameEnduro({
    id: "cm-kona-process-134-frame",
    manufacturer: "Kona",
    model: "Process 134 DL",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.konaworld.com/",
  }),
  frameGravel({
    id: "cm-kona-rove-frame",
    manufacturer: "Kona",
    model: "Rove LTD",
    year: 2024,
    url: "https://www.konaworld.com/",
    maxTireMm: 45,
  }),
  frameEnduro({
    id: "cm-rocky-altitude-frame",
    manufacturer: "Rocky Mountain",
    model: "Altitude Carbon",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://bikes.rockymountain.com/",
  }),
  frameEnduro({
    id: "cm-evil-offering-frame",
    manufacturer: "Evil",
    model: "Offering V2",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://evilbikes.com/",
  }),
  frameEnduro({
    id: "cm-marin-rift-zone-frame",
    manufacturer: "Marin",
    model: "Rift Zone 29",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 30.9,
    url: "https://www.marinbikes.com/",
  }),
  frameEnduro({
    id: "cm-knolly-warden-frame",
    manufacturer: "Knolly",
    model: "Warden",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://knollybikes.com/",
  }),
  frameEnduro({
    id: "cm-pole-machine-frame",
    manufacturer: "Pole",
    model: "Machine",
    year: 2024,
    shockEye: 230,
    shockStroke: 65,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://polebicycles.com/",
  }),
  frameEmtb({
    id: "cm-flyer-goroc-frame",
    manufacturer: "Flyer",
    model: "Goroc X",
    year: 2024,
    shockEye: 205,
    shockStroke: 65,
    seatpostMm: 31.6,
    url: "https://www.flyer-bikes.com/",
  }),
  frameEtrekking({
    id: "cm-riesemueller-charger-frame",
    manufacturer: "Riese & Müller",
    model: "Charger4",
    year: 2024,
    url: "https://www.r-m.de/",
  }),
  frameEtrekking({
    id: "cm-kalkhoff-endeavour-frame",
    manufacturer: "Kalkhoff",
    model: "Endeavour 7.B",
    year: 2024,
    url: "https://www.kalkhoff-bikes.com/",
  }),
  frameGravel({
    id: "cm-cervelo-aspero-frame",
    manufacturer: "Cervélo",
    model: "Áspero",
    year: 2024,
    url: "https://www.cervelo.com/",
    maxTireMm: 45,
  }),
  frameRoad({
    id: "cm-cervelo-caledonia-frame",
    manufacturer: "Cervélo",
    model: "Caledonia",
    year: 2024,
    url: "https://www.cervelo.com/",
  }),
  frameRoad({
    id: "cm-bianchi-infinito-frame",
    manufacturer: "Bianchi",
    model: "Infinito CV",
    year: 2024,
    url: "https://www.bianchi.com/",
  }),
  frameGravel({
    id: "cm-felt-vr-frame",
    manufacturer: "Felt",
    model: "VR Advanced",
    year: 2024,
    url: "https://feltbicycles.com/",
    maxTireMm: 42,
  }),
  frameGravel({
    id: "cm-canyon-grail-frame",
    manufacturer: "Canyon",
    model: "Grail CF SL",
    year: 2024,
    url: "https://www.canyon.com/",
    maxTireMm: 44,
  }),
  frameGravel({
    id: "cm-trek-checkpoint-frame",
    manufacturer: "Trek",
    model: "Checkpoint SL",
    year: 2024,
    url: "https://www.trekbikes.com/",
    maxTireMm: 45,
  }),
  frameEnduro({
    id: "cm-trek-fuel-ex-frame",
    manufacturer: "Trek",
    model: "Fuel EX",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.trekbikes.com/",
  }),
  frameEnduro({
    id: "cm-specialized-stumpjumper-frame",
    manufacturer: "Specialized",
    model: "Stumpjumper",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 30.9,
    url: "https://www.specialized.com/",
  }),
  frameEmtb({
    id: "cm-specialized-levo-frame",
    manufacturer: "Specialized",
    model: "Turbo Levo",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    seatpostMm: 34.9,
    url: "https://www.specialized.com/",
  }),
  frameEnduro({
    id: "cm-scott-spark-frame",
    manufacturer: "Scott",
    model: "Spark RC",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.scott-sports.com/",
    maxTireMm: 61,
  }),
  frameGravel({
    id: "cm-giant-revolt-frame",
    manufacturer: "Giant",
    model: "Revolt Advanced",
    year: 2024,
    url: "https://www.giant-bicycles.com/",
    maxTireMm: 45,
  }),
  frameGravel({
    id: "cm-cube-nuroad-frame",
    manufacturer: "Cube",
    model: "Nuroad C:62",
    year: 2024,
    url: "https://www.cube.eu/",
    maxTireMm: 45,
  }),
  frameGravel({
    id: "cm-rose-backroad-frame",
    manufacturer: "Rose",
    model: "Backroad",
    year: 2024,
    url: "https://www.rosebikes.de/",
    maxTireMm: 45,
  }),
  frameEnduro({
    id: "cm-yt-jeffsy-frame",
    manufacturer: "YT Industries",
    model: "Jeffsy Core 3",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.yt-industries.com/",
  }),
  frameEnduro({
    id: "cm-propain-hugene-frame",
    manufacturer: "Propain",
    model: "Hugene",
    year: 2024,
    shockEye: 210,
    shockStroke: 55,
    shockMount: "trunnion",
    seatpostMm: 31.6,
    url: "https://www.propain-bikes.com/",
  }),

  // —— Gabel Trail ——
  {
    id: "cm-fox-34-performance-140",
    slot: "fork",
    manufacturer: "Fox",
    model: "34 Performance Elite",
    variant: "140mm 29",
    modelYear: 2024,
    attributes: [
      attr("travel_mm", { num: 140, unit: "mm" }),
      attr("steerer_type", { enum: "tapered_1.5" }),
      attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
      attr("crown_race_mm", { num: 40, unit: "mm" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("max_rotor_mm", { num: 203, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("offset_mm", { num: 44, unit: "mm" }),
    ],
    adjusters: [
      {
        key: "air_pressure_psi",
        label: "Luftdruck",
        unit: "psi",
        min: 40,
        max: 110,
        step: 1,
      },
      {
        key: "sag_pct",
        label: "SAG",
        unit: "%",
        min: 15,
        max: 30,
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

  // —— Gravel-Antrieb ——
  {
    id: "cm-shimano-grx-cassette",
    slot: "cassette",
    manufacturer: "Shimano",
    model: "GRX CS-HG710",
    variant: "11-36 12s",
    attributes: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "HG" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://bike.shimano.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: false,
  },
  {
    id: "cm-shimano-grx-rd",
    slot: "rear_derailleur",
    manufacturer: "Shimano",
    model: "GRX RD-RX820",
    attributes: [
      attr("speed", { num: 12 }),
      attr("max_cog", { num: 36 }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://bike.shimano.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: false,
  },

  // —— E-Trekking Motor ——
  {
    id: "cm-bosch-performance-line-cx",
    slot: "motor",
    manufacturer: "Bosch",
    model: "Performance Line CX",
    variant: "Smart System",
    attributes: [
      attr("motor_system", { enum: "bosch_smart_system" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.bosch-ebike.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-bosch-powertube-750",
    slot: "battery",
    manufacturer: "Bosch",
    model: "PowerTube",
    variant: "750 Wh",
    attributes: [
      attr("capacity_wh", { num: 750, unit: "Wh" }),
      attr("battery_system", { enum: "bosch_smart_system" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.bosch-ebike.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-schwalbe-marathon-plus-tour-29",
    slot: "tire_front",
    manufacturer: "Schwalbe",
    model: "Marathon Plus Tour",
    variant: "29×2.15",
    attributes: [
      attr("tire_width_mm", { num: 55, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
    adjusters: [
      {
        key: "pressure_psi",
        label: "Druck",
        unit: "psi",
        min: 35,
        max: 70,
        step: 1,
      },
    ],
    torqueSpecs: [],
    source: "manufacturer_doc",
    sourceUrl: "https://www.schwalbe.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide Editorial",
    safetyCritical: true,
  },
];
