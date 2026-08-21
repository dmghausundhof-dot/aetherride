/**
 * Round 7 — Alltagskatalog: Lastenrad, Faltrad, Kinderrad + passende OEM-Teile.
 * Round 7b — SRAM GX DH 7s, DT 20×110 / 157 Super Boost, Felgenbremse-Slots.
 * Quellen: Riese & Müller Load5, Cube Cargo Dual, Tern GSD, woom EXPLORE 5,
 * Brompton C Line, Bosch Cargo Line, Magura CMe / MT C, Enviolo, Gates CDX,
 * Propain Rage / Spindrift Dual Crown Konfigurator 2025.
 */

import type { ComponentModel, ComponentSlot, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";
const BOSCH = "https://www.bosch-ebike.com/";
const SHIMANO = "https://bike.shimano.com/";
const MAGURA = "https://www.magura.com/";

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
    weightG?: number;
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
    weightG: opts.weightG,
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

function frameCargo(opts: {
  id: string;
  manufacturer: string;
  model: string;
  url: string;
  wheelRear: string;
  axleRear: string;
  seatpostMm?: number;
  maxTireMm?: number;
}): ComponentModel {
  return {
    id: opts.id,
    slot: "frame",
    manufacturer: opts.manufacturer,
    model: opts.model,
    variant: "Aluminium Bosch Cargo Line",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: opts.axleRear }),
      attr("axle_rear", { enum: opts.axleRear }),
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "BSA73" }),
      ...(opts.seatpostMm
        ? [attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" })]
        : []),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 203, unit: "mm" }),
      attr("max_tire_width_mm", { num: opts.maxTireMm ?? 65, unit: "mm" }),
      attr("motor_interface", { enum: "bosch_cargo_line" }),
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

export const COMPONENT_CATALOG_DACH_SCALE7: ComponentModel[] = [
  frameCargo({
    id: "cm-riesemueller-load5-75-frame",
    manufacturer: "Riese & Müller",
    model: "Load5 75",
    url: "https://www.r-m.de/en-de/bikes/load5-75/",
    wheelRear: "26",
    axleRear: "148x12_boost",
    seatpostMm: 34.9,
    maxTireMm: 60,
  }),
  frameCargo({
    id: "cm-cube-cargo-dual-frame",
    manufacturer: "Cube",
    model: "Cargo Dual Hybrid",
    url: "https://www.cube.eu/",
    wheelRear: "650b",
    axleRear: "135x10",
    seatpostMm: 30.9,
    maxTireMm: 65,
  }),
  frameCargo({
    id: "cm-tern-gsd-frame",
    manufacturer: "Tern",
    model: "GSD Gen 3",
    url: "https://www.ternbicycles.com/en/bikes/473/gsd-s10",
    wheelRear: "20",
    axleRear: "135x10",
    maxTireMm: 60,
  }),
  frameCargo({
    id: "cm-bergamont-ecargoville-frame",
    manufacturer: "Bergamont",
    model: "E-Cargoville LJ",
    url: "https://www.bergamont.com/",
    wheelRear: "20",
    axleRear: "135x10",
    seatpostMm: 30.9,
    maxTireMm: 60,
  }),
  {
    id: "cm-tern-link-frame",
    slot: "frame",
    manufacturer: "Tern",
    model: "Link D8",
    variant: "Aluminium 20",
    modelYear: 2024,
    attributes: [
      attr("rear_spacing", { enum: "135x5_qr" }),
      attr("axle_rear", { enum: "135x5_qr" }),
      attr("headset_top", { enum: "EC34" }),
      attr("headset_bottom", { enum: "EC34" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", { num: 33.9, unit: "mm" }),
      attr("brake_mount_rear", { enum: "v_brake" }),
      attr("max_tire_width_mm", { num: 47, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "20" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.ternbicycles.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-brompton-cline-frame",
    slot: "frame",
    manufacturer: "Brompton",
    model: "C Line Explore",
    variant: "Steel 16",
    modelYear: 2024,
    attributes: [
      attr("bb_standard", { enum: "BSA68" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "16" }),
      attr("max_tire_width_mm", { num: 35, unit: "mm" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.brompton.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-woom-explore-5-frame",
    slot: "frame",
    manufacturer: "woom",
    model: "EXPLORE 5",
    variant: "AA 6061 24",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "135x5_qr" }),
      attr("axle_rear", { enum: "135x5_bolt" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS42" }),
      attr("bb_standard", { enum: "square_taper" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("max_rotor_rear_mm", { num: 140, unit: "mm" }),
      attr("max_tire_width_mm", { num: 51, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "24" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://woom.com/en_GB/bikes/explore-5",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-cube-acid-240-frame",
    slot: "frame",
    manufacturer: "Cube",
    model: "Acid 240 Disc",
    variant: "Aluminium 24",
    modelYear: 2024,
    attributes: [
      attr("rear_spacing", { enum: "135x5_qr" }),
      attr("axle_rear", { enum: "135x5_qr" }),
      attr("headset_top", { enum: "EC34" }),
      attr("headset_bottom", { enum: "EC34" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 160, unit: "mm" }),
      attr("max_tire_width_mm", { num: 54, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "24" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.cube.eu/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  {
    id: "cm-specialized-riprock-24-frame",
    slot: "frame",
    manufacturer: "Specialized",
    model: "Riprock 24",
    variant: "A1 Premium 24",
    modelYear: 2024,
    attributes: [
      attr("rear_spacing", { enum: "135x5_qr" }),
      attr("axle_rear", { enum: "135x5_qr" }),
      attr("bb_standard", { enum: "BSA68" }),
      attr("seatpost_diameter_mm", { num: 30.9, unit: "mm" }),
      attr("max_tire_width_mm", { num: 64, unit: "mm" }),
      attr("motor_interface", { enum: "n/a", text: "n/a" }),
      attr("wheel_size_rear", { enum: "24" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: "https://www.specialized.com/",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },

  part("cm-suntour-mobie-34-cgo-80", "fork", "SR Suntour", "Mobie 34 CGO Boost", {
    variant: "80mm 20",
    year: 2025,
    url: "https://www.srsuntour.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 80, unit: "mm" }),
      attr("steerer_type", { enum: "tapered_1.5" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-suntour-mobie-cargo-80", "fork", "SR Suntour", "MOBIE CARGO", {
    variant: "80mm 20",
    year: 2025,
    url: "https://www.srsuntour.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 80, unit: "mm" }),
      attr("axle_front", { enum: "15x100" }),
      attr("brake_mount", { enum: "post_mount" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-woom-explore-fork", "fork", "woom", "Unicrown Alloy", {
    variant: "24 rigid",
    url: "https://woom.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 0, unit: "mm" }),
      attr("steerer_type", { enum: "straight_1.0" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-brompton-steel-fork", "fork", "Brompton", "C Line Steel", {
    variant: "16",
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 0, unit: "mm" }),
      attr("wheel_size", { enum: "16" }),
    ],
  }),
  part("cm-tern-link-fork", "fork", "Tern", "Link Hi-Tensile", {
    variant: "20 rigid",
    url: "https://www.ternbicycles.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 0, unit: "mm" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),

  part("cm-bosch-cargo-line", "motor", "Bosch", "Cargo Line", {
    variant: "Smart System 85 Nm",
    year: 2025,
    url: BOSCH,
    safety: true,
    attrs: [
      attr("motor_system", { enum: "bosch_cargo_line" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
      attr("max_power_w", { num: 250, unit: "W" }),
    ],
  }),
  part("cm-bosch-powerpack-800", "battery", "Bosch", "PowerPack Frame", {
    variant: "800 Wh",
    url: BOSCH,
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 800, unit: "Wh" }),
      attr("battery_system", { enum: "bosch_smart_system" }),
    ],
  }),
  part("cm-bosch-powerpack-545", "battery", "Bosch", "PowerPack Frame", {
    variant: "545 Wh",
    url: BOSCH,
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 545, unit: "Wh" }),
      attr("battery_system", { enum: "bosch_smart_system" }),
    ],
  }),
  part("cm-bosch-dualbattery-1000", "battery", "Bosch", "DualBattery", {
    variant: "1000 Wh",
    url: BOSCH,
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 1000, unit: "Wh" }),
      attr("battery_system", { enum: "bosch_smart_system" }),
    ],
  }),
  part("cm-brose-drive-s-mag", "motor", "Brose", "Drive S Mag", {
    variant: "90 Nm",
    url: "https://www.brose-ebike.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "brose_drive_s" }),
      attr("max_torque_nm", { num: 90, unit: "Nm" }),
    ],
  }),

  part("cm-enviolo-cargo", "rear_hub", "Enviolo", "Cargo", {
    variant: "380% 10x135",
    url: "https://www.enviolo.com/",
    safety: true,
    attrs: [
      attr("axle_rear", { enum: "10x135" }),
      attr("hub_gear", { enum: "cvt" }),
      attr("range_pct", { num: 380 }),
    ],
  }),
  part("cm-enviolo-trekking-shifter", "shifter", "Enviolo", "Manual Twist", {
    variant: "Cargo / Trekking",
    url: "https://www.enviolo.com/",
    attrs: [attr("hub_gear", { enum: "cvt" })],
  }),
  part("cm-shimano-cues-u6000-rd", "rear_derailleur", "Shimano", "CUES RD-U6000", {
    variant: "Linkglide 11s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 11 }), attr("max_cog", { num: 50 })],
  }),
  part("cm-shimano-cues-lg700-cassette", "cassette", "Shimano", "CUES CS-LG700", {
    variant: "11-50 11s",
    url: SHIMANO,
    attrs: [
      attr("cassette_speed", { num: 11 }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-shimano-cues-u6000-shifter", "shifter", "Shimano", "CUES SL-U6000", {
    variant: "11s Linkglide",
    url: SHIMANO,
    attrs: [attr("speed", { num: 11 })],
  }),
  part("cm-microshift-acolyte-rd", "rear_derailleur", "microSHIFT", "Acolyte RD-M5185S", {
    variant: "8s",
    url: "https://www.microshift.com/",
    attrs: [attr("speed", { num: 8 }), attr("max_cog", { num: 42 })],
  }),
  part("cm-microshift-acolyte-shifter", "shifter", "microSHIFT", "Acolyte SL-M5185", {
    variant: "8s Trigger",
    url: "https://www.microshift.com/",
    attrs: [attr("speed", { num: 8 })],
  }),
  part("cm-microshift-acolyte-cassette", "cassette", "microSHIFT", "Acolyte CS-H083", {
    variant: "11-32 8s",
    url: "https://www.microshift.com/",
    attrs: [
      attr("cassette_speed", { num: 8 }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-shimano-tourney-ty300-rd", "rear_derailleur", "Shimano", "Tourney RD-TY300", {
    variant: "7s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 7 })],
  }),
  part("cm-shimano-tourney-tz500-cassette", "cassette", "Shimano", "Tourney MF-TZ500", {
    variant: "14-28 7s",
    url: SHIMANO,
    attrs: [attr("cassette_speed", { num: 7 })],
  }),
  part("cm-brompton-6s-rd", "rear_derailleur", "Brompton", "6-speed", {
    variant: "2×3",
    url: "https://www.brompton.com/",
    attrs: [attr("speed", { num: 6 })],
  }),
  part("cm-brompton-6s-shifter", "shifter", "Brompton", "Trigger 6-speed", {
    url: "https://www.brompton.com/",
    attrs: [attr("speed", { num: 6 })],
  }),
  part("cm-shimano-ultegra-r8100-rd", "rear_derailleur", "Shimano", "Ultegra RD-R8150", {
    variant: "Di2 12s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-campagnolo-ekar-rd", "rear_derailleur", "Campagnolo", "Ekar", {
    variant: "13s 1×",
    url: "https://www.campagnolo.com/",
    attrs: [attr("speed", { num: 13 })],
  }),
  part("cm-sram-rival-axs-rd", "rear_derailleur", "SRAM", "Rival XPLR eTap AXS", {
    variant: "12s",
    url: "https://www.sram.com/",
    attrs: [attr("speed", { num: 12 })],
  }),

  part("cm-magura-cme-front", "brake_front", "Magura", "CMe", {
    variant: "4-Kolben 180",
    url: MAGURA,
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("pistons", { num: 4 }),
      attr("fluid", { enum: "royal_blood" }),
    ],
  }),
  part("cm-magura-cme-rear", "brake_rear", "Magura", "CMe", {
    variant: "4-Kolben 203",
    url: MAGURA,
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("pistons", { num: 4 }),
      attr("fluid", { enum: "royal_blood" }),
    ],
  }),
  part("cm-magura-mtc-front", "brake_front", "Magura", "MT C ABS", {
    variant: "4-Kolben Bosch ABS",
    url: MAGURA,
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("pistons", { num: 4 }),
      attr("fluid", { enum: "royal_blood" }),
    ],
  }),
  part("cm-magura-mtc-rear", "brake_rear", "Magura", "MT C ABS", {
    variant: "4-Kolben Bosch ABS",
    url: MAGURA,
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "post_mount" }),
      attr("pistons", { num: 4 }),
      attr("fluid", { enum: "royal_blood" }),
    ],
  }),
  part("cm-promax-dsk-307-front", "brake_front", "Promax", "DSK-307", {
    variant: "FM 160",
    url: "https://woom.com/",
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "flat_mount" }),
      attr("rotor_diameter_mm", { num: 160, unit: "mm" }),
    ],
  }),
  part("cm-promax-dsk-307-rear", "brake_rear", "Promax", "DSK-307", {
    variant: "FM 140",
    url: "https://woom.com/",
    safety: true,
    attrs: [
      attr("brake_mount", { enum: "flat_mount" }),
      attr("rotor_diameter_mm", { num: 140, unit: "mm" }),
    ],
  }),
  part("cm-tektro-trp-c23-front", "brake_front", "Tektro", "TRP C 2.3", {
    url: "https://www.tektro.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-tektro-trp-c23-rear", "brake_rear", "Tektro", "TRP C 2.3", {
    url: "https://www.tektro.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),

  part("cm-schwalbe-pickup-20-60", "tire_front", "Schwalbe", "Pick-Up Super Defense", {
    variant: "60-406",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 60, unit: "mm" }),
      attr("etrto", { text: "60-406" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-schwalbe-pickup-650b-65", "tire_rear", "Schwalbe", "Pick-Up Super Defense", {
    variant: "65-584",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 65, unit: "mm" }),
      attr("etrto", { text: "65-584" }),
      attr("wheel_size", { enum: "650b" }),
    ],
  }),
  part("cm-schwalbe-supermoto-x-20", "tire_front", "Schwalbe", "Super Moto-X", {
    variant: "62-406 Reflex",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 62, unit: "mm" }),
      attr("etrto", { text: "62-406" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-schwalbe-smart-sam-cargo-26", "tire_rear", "Schwalbe", "Smart Sam Cargo", {
    variant: "60-559 Reflex",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 60, unit: "mm" }),
      attr("etrto", { text: "60-559" }),
      attr("wheel_size", { enum: "26" }),
    ],
  }),
  part("cm-schwalbe-billy-bonkers-24", "tire_front", "Schwalbe", "Billy Bonkers", {
    variant: "50-507",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 50, unit: "mm" }),
      attr("etrto", { text: "50-507" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-schwalbe-billy-bonkers-24-rear", "tire_rear", "Schwalbe", "Billy Bonkers", {
    variant: "50-507",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 50, unit: "mm" }),
      attr("etrto", { text: "50-507" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-schwalbe-marathon-racer-16", "tire_front", "Schwalbe", "Marathon Racer", {
    variant: "35-349",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 35, unit: "mm" }),
      attr("etrto", { text: "35-349" }),
      attr("wheel_size", { enum: "16" }),
    ],
  }),
  part("cm-schwalbe-marathon-racer-16-rear", "tire_rear", "Schwalbe", "Marathon Racer", {
    variant: "35-349",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 35, unit: "mm" }),
      attr("etrto", { text: "35-349" }),
      attr("wheel_size", { enum: "16" }),
    ],
  }),
  part("cm-schwalbe-big-apple-20", "tire_front", "Schwalbe", "Big Apple", {
    variant: "50-406",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 50, unit: "mm" }),
      attr("etrto", { text: "50-406" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-schwalbe-big-apple-20-rear", "tire_rear", "Schwalbe", "Big Apple", {
    variant: "50-406",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 50, unit: "mm" }),
      attr("etrto", { text: "50-406" }),
      attr("wheel_size", { enum: "20" }),
    ],
  }),
  part("cm-pirelli-cinturato-gravel-h", "tire_front", "Pirelli", "Cinturato Gravel H", {
    variant: "40-622",
    url: "https://www.pirelli.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 40, unit: "mm" }),
      attr("etrto", { text: "40-622" }),
      attr("wheel_size", { enum: "700c" }),
    ],
  }),

  part("cm-shimano-hb-mt400-15x100", "front_hub", "Shimano", "HB-MT400", {
    variant: "15x100 Center Lock",
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("axle_front", { enum: "15x100" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
  }),
  part("cm-woom-hub-front-24", "front_hub", "woom", "Sealed QR", {
    variant: "24H",
    url: "https://woom.com/",
    safety: true,
    attrs: [attr("axle_front", { enum: "9x100_qr" })],
  }),
  part("cm-woom-hub-rear-24", "rear_hub", "woom", "Sealed Bolt-on HG", {
    variant: "24H",
    url: "https://woom.com/",
    safety: true,
    attrs: [
      attr("axle_rear", { enum: "135x5_bolt" }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-woom-rim-24-front", "front_rim", "woom", "Superlight 24", {
    url: "https://woom.com/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "24" })],
  }),
  part("cm-woom-rim-24-rear", "rear_rim", "woom", "Superlight 24", {
    url: "https://woom.com/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "24" })],
  }),
  part("cm-mach1-trucky30-20", "front_rim", "Mach1", "Trucky30", {
    variant: "20",
    url: "https://www.r-m.de/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "20" })],
  }),
  part("cm-mach1-trucky30-26", "rear_rim", "Mach1", "Trucky30", {
    variant: "26",
    url: "https://www.r-m.de/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "26" })],
  }),

  part("cm-woom-crank-130-28", "crankset", "woom", "Forged 130 mm", {
    variant: "28T",
    url: "https://woom.com/",
    attrs: [attr("teeth", { num: 28 }), attr("arm_mm", { num: 130, unit: "mm" })],
  }),
  part("cm-woom-ring-28", "chainring", "woom", "Narrow-Wide 28T", {
    url: "https://woom.com/",
    attrs: [attr("teeth", { num: 28 })],
  }),
  part("cm-kmc-z8-chain", "chain", "KMC", "Z8.3", {
    url: "https://www.kmcchain.com/",
    attrs: [attr("speed", { num: 8 })],
  }),
  part("cm-acid-e-crank-38", "crankset", "Acid", "E-Crank", {
    variant: "170mm 38T",
    url: "https://www.cube.eu/",
    attrs: [attr("teeth", { num: 38 })],
  }),
  part("cm-acid-38-ring", "chainring", "Acid", "Narrow-Wide 38T", {
    url: "https://www.cube.eu/",
    attrs: [attr("teeth", { num: 38 })],
  }),
  part("cm-enviolo-20t", "cassette", "Enviolo", "Cog 20T", {
    url: "https://www.enviolo.com/",
    attrs: [attr("teeth", { num: 20 })],
  }),
  part("cm-kmc-z610-chain", "chain", "KMC", "Z610", {
    url: "https://www.kmcchain.com/",
    attrs: [attr("speed", { num: 1 })],
  }),
  part("cm-xfusion-manic-34-9", "seatpost", "X-Fusion", "Manic Dropper", {
    variant: "34.9 150/170",
    url: "https://www.r-m.de/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 34.9, unit: "mm" })],
  }),
  part("cm-newmen-evolution-30-9", "seatpost", "Newmen", "Evolution", {
    variant: "30.9",
    url: "https://www.cube.eu/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 30.9, unit: "mm" })],
  }),
  part("cm-woom-seatpost", "seatpost", "woom", "Micro-Adjust QR", {
    url: "https://woom.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-woom-saddle", "saddle", "woom", "Selle Royal Kids", {
    url: "https://woom.com/",
    attrs: [],
  }),
  part("cm-woom-stem", "stem", "woom", "Adjustable Ahead", {
    url: "https://woom.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-woom-bar", "handlebar", "woom", "Low-Rise 580", {
    url: "https://woom.com/",
    safety: true,
    attrs: [attr("width_mm", { num: 580, unit: "mm" })],
  }),
  part("cm-woom-grips", "grips", "woom", "Slim Lock-On", {
    url: "https://woom.com/",
    attrs: [],
  }),
  part("cm-woom-headset", "headset", "woom", "IS 1-inch sealed", {
    url: "https://woom.com/",
    safety: true,
    attrs: [
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS42" }),
    ],
  }),
  part("cm-woom-pedals", "pedals", "woom", "Platform Kids", {
    url: "https://woom.com/",
    attrs: [],
  }),
  part("cm-brompton-saddle", "saddle", "Brompton", "Standard", {
    url: "https://www.brompton.com/",
    attrs: [],
  }),
  part("cm-brompton-bar", "handlebar", "Brompton", "M Type", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-brompton-stem", "stem", "Brompton", "C Line", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-brompton-seatpost", "seatpost", "Brompton", "Telescopic", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-brompton-grips", "grips", "Brompton", "Lock-On", {
    url: "https://www.brompton.com/",
    attrs: [],
  }),
  part("cm-brompton-pedals", "pedals", "Brompton", "Folding left", {
    url: "https://www.brompton.com/",
    attrs: [],
  }),
  part("cm-brompton-chain", "chain", "Brompton", "3/32", {
    url: "https://www.brompton.com/",
    attrs: [attr("speed", { num: 6 })],
  }),
  part("cm-brompton-crank", "crankset", "Brompton", "Spider 50T", {
    url: "https://www.brompton.com/",
    attrs: [attr("teeth", { num: 50 })],
  }),
  part("cm-brompton-ring", "chainring", "Brompton", "50T", {
    url: "https://www.brompton.com/",
    attrs: [attr("teeth", { num: 50 })],
  }),
  part("cm-brompton-cassette", "cassette", "Brompton", "3-speed sprocket", {
    url: "https://www.brompton.com/",
    attrs: [attr("cassette_speed", { num: 3 })],
  }),
  part("cm-brompton-hub-front", "front_hub", "Brompton", "Sealed 16", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "16" })],
  }),
  part("cm-brompton-hub-rear", "rear_hub", "Brompton", "BWR 3-speed", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("hub_gear", { enum: "3s" })],
  }),
  part("cm-brompton-rim-front", "front_rim", "Brompton", "Double-wall 16", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "16" })],
  }),
  part("cm-brompton-rim-rear", "rear_rim", "Brompton", "Double-wall 16", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "16" })],
  }),
  part("cm-brompton-headset", "headset", "Brompton", "C Line", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-brompton-brake-front", "brake_front", "Brompton", "Dual-pivot", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "caliper" })],
  }),
  part("cm-brompton-brake-rear", "brake_rear", "Brompton", "Dual-pivot", {
    url: "https://www.brompton.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "caliper" })],
  }),

  part("cm-acid-pro-e-110", "light", "Acid", "Front Light PRO-E 110", {
    url: "https://www.cube.eu/",
    safety: true,
    attrs: [attr("lumens", { num: 110 })],
  }),
  part("cm-supernova-m99-mini", "light", "Supernova", "M99 Mini Pro-25", {
    url: "https://www.supernova-lights.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-abus-shield-xplus", "lock", "ABUS", "Shield X+", {
    url: "https://www.abus.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-abus-bordo-6500", "lock", "ABUS", "Bordo Granit XPlus 6500", {
    url: "https://www.abus.com/",
    safety: true,
    attrs: [],
  }),
  part("cm-rm-load-rack", "rack", "Riese & Müller", "Load rear rack", {
    url: "https://www.r-m.de/",
    safety: true,
    attrs: [attr("max_load_kg", { num: 27, unit: "kg" })],
  }),
  part("cm-tern-atlas-g-rack", "rack", "Tern", "Atlas G Rack", {
    url: "https://www.ternbicycles.com/",
    safety: true,
    attrs: [attr("max_load_kg", { num: 100, unit: "kg" })],
  }),
  part("cm-cube-cargo-box", "rack", "Cube", "Cargo box", {
    url: "https://www.cube.eu/",
    safety: true,
    attrs: [],
  }),
  part("cm-ortlieb-back-roller", "bags", "Ortlieb", "Back-Roller City", {
    url: "https://www.ortlieb.com/",
    attrs: [],
  }),
  part("cm-fox-40-factory-203", "fork", "Fox", "40 Factory GRIP X2", {
    variant: "203mm 29",
    year: 2025,
    url: "https://www.ridefox.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 203, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "20x110" }),
      attr("brake_mount", { enum: "post_mount" }),
    ],
  }),
  part("cm-chris-king-nothreadset", "headset", "Chris King", "NoThreadSet", {
    variant: "ZS44/ZS56",
    url: "https://chrisking.com/",
    safety: true,
    attrs: [
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
    ],
  }),
  part("cm-tektro-v-front", "brake_front", "Tektro", "V-Brake 837AL", {
    url: "https://www.tektro.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "v_brake" })],
  }),
  part("cm-tektro-v-rear", "brake_rear", "Tektro", "V-Brake 837AL", {
    url: "https://www.tektro.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "v_brake" })],
  }),
  part("cm-tern-link-seatpost", "seatpost", "Tern", "Telescope", {
    variant: "33.9",
    url: "https://www.ternbicycles.com/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 33.9, unit: "mm" })],
  }),
  part("cm-specialized-rhythm-lite-24", "tire_front", "Specialized", "Rhythm Lite", {
    variant: "24×2.8",
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 71, unit: "mm" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-specialized-rhythm-lite-24-rear", "tire_rear", "Specialized", "Rhythm Lite", {
    variant: "24×2.8",
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 71, unit: "mm" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-cube-ex30-650b", "rear_rim", "Cube", "EX30", {
    variant: "650b 32H TLR",
    url: "https://www.cube.eu/",
    safety: true,
    attrs: [attr("wheel_size", { enum: "650b" })],
  }),
  part("cm-specialized-riprock-fork", "fork", "Specialized", "Riprock 24 Rigid", {
    variant: "24",
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 0, unit: "mm" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-cube-acid-fork", "fork", "Cube", "Acid 240 Rigid", {
    variant: "24",
    url: "https://www.cube.eu/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 0, unit: "mm" }),
      attr("wheel_size", { enum: "24" }),
    ],
  }),
  part("cm-pnw-loam-31-6", "seatpost", "PNW", "Loam Dropper", {
    variant: "31.6",
    url: "https://www.pnwcomponents.com/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 31.6, unit: "mm" })],
  }),

  // —— DH 7-Gang (SRAM GX DH) + Super-Boost / 20×110 ——
  part("cm-sram-gx-dh-rd", "rear_derailleur", "SRAM", "GX DH", {
    variant: "7s",
    year: 2025,
    url: "https://www.sram.com/",
    attrs: [attr("speeds", { num: 7 })],
  }),
  part("cm-sram-gx-dh-shifter", "shifter", "SRAM", "GX DH", {
    variant: "Trigger 7s",
    year: 2025,
    url: "https://www.sram.com/",
    attrs: [attr("speeds", { num: 7 })],
  }),
  part("cm-sram-xg-795", "cassette", "SRAM", "XG-795", {
    variant: "7s 11-24 XD",
    year: 2025,
    url: "https://www.sram.com/",
    attrs: [
      attr("speeds", { num: 7 }),
      attr("freehub_standard", { enum: "XD" }),
      attr("range", { text: "11-24" }),
    ],
  }),
  part("cm-sram-gx-dh-chain", "chain", "SRAM", "GX DH", {
    variant: "7s",
    url: "https://www.sram.com/",
    attrs: [attr("speeds", { num: 7 })],
  }),
  part("cm-sram-gx-dh-crank", "crankset", "SRAM", "GX DH DUB", {
    variant: "165mm",
    url: "https://www.sram.com/",
    attrs: [
      attr("crank_axle", { enum: "DUB_28.99" }),
      attr("crank_length_mm", { num: 165, unit: "mm" }),
    ],
  }),
  part("cm-sram-gx-dh-ring-34", "chainring", "SRAM", "GX DH", {
    variant: "34t",
    url: "https://www.sram.com/",
    attrs: [attr("chainring_teeth", { num: 34 })],
  }),
  part("cm-sram-dub-bsa83", "bottom_bracket", "SRAM", "DUB BSA", {
    variant: "83mm DH",
    url: "https://www.sram.com/",
    attrs: [
      attr("bb_standard", { enum: "BSA83" }),
      attr("crank_axle", { enum: "DUB_28.99" }),
    ],
  }),
  part("cm-dt-350-20x110-front", "front_hub", "DT Swiss", "350", {
    variant: "20×110 DH",
    url: "https://www.dtswiss.com/",
    safety: true,
    attrs: [
      attr("axle_front", { enum: "20x110" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
  }),
  part("cm-dt-350-157-rear-xd", "rear_hub", "DT Swiss", "350", {
    variant: "12×157 Super Boost · XD",
    url: "https://www.dtswiss.com/",
    safety: true,
    attrs: [
      attr("axle_rear", { enum: "12x157" }),
      attr("rear_spacing", { enum: "157x12" }),
      attr("freehub_standard", { enum: "XD" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
  }),
  part("cm-dt-fr1500-rim-29-front", "front_rim", "DT Swiss", "FR 1500 Classic", {
    variant: "30mm 29 DH",
    url: "https://www.dtswiss.com/",
    safety: true,
    attrs: [
      attr("internal_rim_width_mm", { num: 30, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
  }),
  part("cm-dt-fr1500-rim-29-rear", "rear_rim", "DT Swiss", "FR 1500 Classic", {
    variant: "30mm 29 DH",
    url: "https://www.dtswiss.com/",
    safety: true,
    attrs: [
      attr("internal_rim_width_mm", { num: 30, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
    ],
  }),
  part("cm-dt-fr1500-rim-275-rear", "rear_rim", "DT Swiss", "FR 1500 Classic", {
    variant: "30mm 27.5 DH",
    url: "https://www.dtswiss.com/",
    safety: true,
    attrs: [
      attr("internal_rim_width_mm", { num: 30, unit: "mm" }),
      attr("wheel_size", { enum: "27.5" }),
    ],
  }),
  part("cm-schwalbe-big-betty-275", "tire_rear", "Schwalbe", "Big Betty", {
    variant: "27.5×2.4 Super DH",
    url: "https://www.schwalbe.com/",
    safety: true,
    attrs: [
      attr("tire_width_mm", { num: 60, unit: "mm" }),
      attr("wheel_size", { enum: "27.5" }),
    ],
  }),
  part("cm-sram-hs2-220-front", "rotor_front", "SRAM", "HS2", {
    variant: "220mm Center Lock",
    url: "https://www.sram.com/",
    safety: true,
    attrs: [
      attr("rotor_diameter_mm", { num: 220, unit: "mm" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
  }),
  part("cm-sram-hs2-200-rear", "rotor_rear", "SRAM", "HS2", {
    variant: "200mm Center Lock",
    url: "https://www.sram.com/",
    safety: true,
    attrs: [
      attr("rotor_diameter_mm", { num: 200, unit: "mm" }),
      attr("rotor_mount", { enum: "center_lock" }),
    ],
  }),
  part("cm-acros-zs49-zs56", "headset", "Acros", "Stainless ZS49/ZS56", {
    url: "https://www.acros-components.com/",
    safety: true,
    attrs: [
      attr("headset_top", { enum: "ZS49" }),
      attr("headset_bottom", { enum: "ZS56" }),
    ],
  }),
  part("cm-sixpack-kamikaze-31-6", "seatpost", "Sixpack", "Kamikaze", {
    variant: "31.6 × 350mm",
    url: "https://www.sixpack-racing.com/",
    safety: true,
    attrs: [attr("diameter_mm", { num: 31.6, unit: "mm" })],
  }),
  part("cm-tern-square-bb", "bottom_bracket", "Tern", "Square Taper BSA", {
    variant: "68mm",
    url: "https://www.ternbicycles.com/",
    attrs: [attr("bb_standard", { enum: "BSA68" })],
  }),
  part("cm-brompton-bb", "bottom_bracket", "Brompton", "Square Taper", {
    variant: "BSA",
    url: "https://www.brompton.com/",
    attrs: [attr("bb_standard", { enum: "BSA" })],
  }),
];
