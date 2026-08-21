/**
 * Round 8 — Motoren- und Systemzulieferer: Shimano STEPS, Yamaha/Giant,
 * Specialized 2.2 (Brose), TQ HPR50, Bosch SX, Mahle, Panasonic, Fazua-UI.
 * Quellen: Herstellerseiten 2024–2026. Fehlende Maße bleiben leer.
 */

import type { ComponentModel, ComponentSlot, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";
const SHIMANO = "https://bike.shimano.com/";
const BOSCH = "https://www.bosch-ebike.com/";

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

function frameE(
  opts: {
    id: string;
    manufacturer: string;
    model: string;
    variant: string;
    year: number;
    url: string;
    motor: string;
    seatpostMm: number;
    wheelRear?: string;
  }
): ComponentModel {
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
      attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 203, unit: "mm" }),
      attr("motor_interface", { enum: opts.motor }),
      attr("wheel_size_rear", { enum: opts.wheelRear ?? "29" }),
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

export const COMPONENT_CATALOG_DACH_SCALE8: ComponentModel[] = [
  // —— Motoren ——
  part("cm-shimano-ep800", "motor", "Shimano", "STEPS EP8", {
    variant: "DU-EP800 85 Nm",
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("motor_system", { enum: "shimano_ep800" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
    ],
  }),
  part("cm-shimano-ep600", "motor", "Shimano", "STEPS EP6", {
    variant: "DU-EP600 85 Nm",
    year: 2024,
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("motor_system", { enum: "shimano_ep600" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
      attr("peak_power_w", { num: 500, unit: "W" }),
    ],
  }),
  part("cm-shimano-e6100", "motor", "Shimano", "STEPS E6100", {
    variant: "DU-E6100 60 Nm",
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("motor_system", { enum: "shimano_e6100" }),
      attr("max_torque_nm", { num: 60, unit: "Nm" }),
    ],
  }),
  part("cm-yamaha-pw-x3", "motor", "Yamaha", "PW-X3", {
    variant: "85 Nm",
    url: "https://www.yamaha-motor.eu/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "yamaha_pw_x3" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
    ],
  }),
  part("cm-giant-syncdrive-pro2", "motor", "Giant", "SyncDrive Pro2", {
    variant: "Yamaha PW-X3 85 Nm",
    year: 2025,
    url: "https://www.giant-bicycles.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "giant_syncdrive_pro2" }),
      attr("max_torque_nm", { num: 85, unit: "Nm" }),
    ],
  }),
  part("cm-specialized-2-2", "motor", "Specialized", "Turbo Full Power 2.2", {
    variant: "Brose Rx Trail 90 Nm",
    year: 2024,
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "specialized_2_2" }),
      attr("max_torque_nm", { num: 90, unit: "Nm" }),
    ],
  }),
  part("cm-tq-hpr50", "motor", "TQ", "HPR50", {
    variant: "50 Nm",
    year: 2025,
    url: "https://www.tq-group.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "tq_hpr50" }),
      attr("max_torque_nm", { num: 50, unit: "Nm" }),
    ],
  }),
  part("cm-bosch-sx", "motor", "Bosch", "Performance Line SX", {
    variant: "Smart System 55 Nm",
    year: 2024,
    url: BOSCH,
    safety: true,
    attrs: [
      attr("motor_system", { enum: "bosch_smart_system" }),
      attr("max_torque_nm", { num: 55, unit: "Nm" }),
    ],
  }),
  part("cm-mahle-x35-plus", "motor", "Mahle", "X35+", {
    variant: "Nabenmotor 40 Nm",
    url: "https://www.mahle-smartbike.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "mahle_x35" }),
      attr("max_torque_nm", { num: 40, unit: "Nm" }),
    ],
  }),
  part("cm-mahle-x20", "motor", "Mahle", "X20", {
    variant: "Nabenmotor 55 Nm",
    year: 2025,
    url: "https://mahle-smartbike.com/x20/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "mahle_x20" }),
      attr("max_torque_nm", { num: 55, unit: "Nm" }),
    ],
  }),
  part("cm-panasonic-gx-ultimate", "motor", "Panasonic", "GX Ultimate", {
    variant: "90 Nm",
    url: "https://www.panasonic.com/",
    safety: true,
    attrs: [
      attr("motor_system", { enum: "panasonic_gx" }),
      attr("max_torque_nm", { num: 90, unit: "Nm" }),
    ],
  }),

  // —— Akkus / Displays ——
  part("cm-shimano-bt-e8036", "battery", "Shimano", "BT-E8036", {
    variant: "630 Wh",
    url: SHIMANO,
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 630, unit: "Wh" }),
      attr("battery_system", { enum: "shimano_ep801" }),
    ],
  }),
  part("cm-orbea-internal-540", "battery", "Orbea", "Internal RS", {
    variant: "540 Wh",
    year: 2025,
    url: "https://www.orbea.com/",
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 540, unit: "Wh" }),
      attr("battery_system", { enum: "shimano_ep600" }),
    ],
  }),
  part("cm-rotwild-ipu375", "battery", "Rotwild", "IPU375", {
    variant: "360 Wh Carbon",
    year: 2024,
    url: "https://www.rotwild.com/en/r-x375-ultra",
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 360, unit: "Wh" }),
      attr("battery_system", { enum: "shimano_ep800" }),
    ],
  }),
  part("cm-giant-energypak-800", "battery", "Giant", "EnergyPak", {
    variant: "800 Wh",
    year: 2025,
    url: "https://www.giant-bicycles.com/",
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 800, unit: "Wh" }),
      attr("battery_system", { enum: "giant_syncdrive_pro2" }),
    ],
  }),
  part("cm-specialized-m3-700", "battery", "Specialized", "M3-700", {
    variant: "700 Wh",
    year: 2024,
    url: "https://www.specialized.com/",
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 700, unit: "Wh" }),
      attr("battery_system", { enum: "specialized_2_2" }),
    ],
  }),
  part("cm-bosch-powertube-600", "battery", "Bosch", "PowerTube", {
    variant: "600 Wh Smart System",
    year: 2025,
    url: BOSCH,
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 600, unit: "Wh" }),
      attr("battery_system", { enum: "bosch_smart_system" }),
    ],
  }),
  part("cm-mahle-i350", "battery", "Mahle", "iX350", {
    variant: "250 Wh",
    url: "https://www.mahle-smartbike.com/",
    safety: true,
    attrs: [
      attr("capacity_wh", { num: 250, unit: "Wh" }),
      attr("battery_system", { enum: "mahle_x35" }),
    ],
  }),
  part("cm-shimano-en600", "display", "Shimano", "EN600", {
    url: SHIMANO,
    attrs: [attr("display_system", { enum: "shimano_ep600" })],
  }),
  part("cm-giant-ridecontrol-go", "display", "Giant", "RideControl GO", {
    url: "https://www.giant-bicycles.com/",
    attrs: [attr("display_system", { enum: "giant_syncdrive_pro2" })],
  }),
  part("cm-specialized-mastermind", "display", "Specialized", "MasterMind TCU", {
    year: 2024,
    url: "https://www.specialized.com/",
    attrs: [attr("display_system", { enum: "specialized_2_2" })],
  }),
  part("cm-tq-led-display", "display", "TQ", "LED Display", {
    url: "https://www.tq-group.com/",
    attrs: [attr("display_system", { enum: "tq_hpr50" })],
  }),
  part("cm-fazua-ring-control", "display", "Fazua", "Ring Control", {
    url: "https://fazua.com/",
    attrs: [attr("display_system", { enum: "fazua_ride_60" })],
  }),
  part("cm-mahle-iwoc-one", "display", "Mahle", "iWOC ONE", {
    url: "https://www.mahle-smartbike.com/",
    attrs: [attr("display_system", { enum: "mahle_x35" })],
  }),
  part("cm-bosch-led-remote", "display", "Bosch", "LED Remote", {
    url: BOSCH,
    attrs: [attr("display_system", { enum: "bosch_smart_system" })],
  }),
  part("cm-brose-allround-display", "display", "Brose", "All Round Display", {
    url: "https://www.brose-ebike.com/",
    attrs: [attr("display_system", { enum: "brose_drive_s" })],
  }),

  // —— Nabe Mahle (Gravel, Slot rear_hub) ——
  part("cm-mahle-x35-hub", "rear_hub", "Mahle", "X35+", {
    variant: "12×142 Nabenmotor",
    url: "https://www.mahle-smartbike.com/",
    safety: true,
    attrs: [
      attr("axle_rear", { enum: "12x142" }),
      attr("motor_system", { enum: "mahle_x35" }),
    ],
  }),

  // —— Weitere Zulieferer ——
  part("cm-formula-cura4-front", "brake_front", "Formula", "Cura 4", {
    url: "https://www.formula-brake.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-formula-cura4-rear", "brake_rear", "Formula", "Cura 4", {
    url: "https://www.formula-brake.com/",
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-saint-m820-front", "brake_front", "Shimano", "Saint BR-M820", {
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-saint-m820-rear", "brake_rear", "Shimano", "Saint BR-M820", {
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-fox-36-rhythm-150", "fork", "Fox", "36 Rhythm Grip", {
    variant: "150mm 29 E-Tuned",
    year: 2025,
    url: "https://www.ridefox.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 150, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-fox-float-dps-185525", "rear_shock", "Fox", "FLOAT DPS Performance", {
    variant: "185×52.5 Trunnion",
    url: "https://www.ridefox.com/",
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 185, unit: "mm" }),
      attr("stroke_mm", { num: 52.5, unit: "mm" }),
      attr("mount_type", { enum: "trunnion" }),
    ],
  }),
  part("cm-praxis-pf30", "bottom_bracket", "Praxis", "PF30 Conversion", {
    url: "https://www.praxiscycles.com/",
    attrs: [attr("bb_standard", { enum: "PF30" })],
  }),

  // —— Rahmen der neuen System-Bikes (ohne geratene Shock-Maße) ——
  frameE({
    id: "cm-orbea-rise-h30-frame",
    manufacturer: "Orbea",
    model: "Rise H30",
    variant: "Alloy EP600-RS",
    year: 2025,
    url: "https://www.orbea.com/",
    motor: "shimano_ep600",
    seatpostMm: 31.6,
  }),
  frameE({
    id: "cm-giant-trance-x-e-frame",
    manufacturer: "Giant",
    model: "Trance X E+",
    variant: "ALUXX SL SyncDrive Pro2",
    year: 2025,
    url: "https://www.giant-bicycles.com/",
    motor: "giant_syncdrive_pro2",
    seatpostMm: 30.9,
  }),
  frameE({
    id: "cm-trek-fuel-exe-frame",
    manufacturer: "Trek",
    model: "Fuel EXe",
    variant: "Alpha Platinum TQ HPR50",
    year: 2025,
    url: "https://www.trekbikes.com/us/en_US/fuel-exe/",
    motor: "tq_hpr50",
    seatpostMm: 34.9,
  }),
  {
    id: "cm-cannondale-topstone-neo-frame",
    slot: "frame",
    manufacturer: "Cannondale",
    model: "Topstone Neo SL",
    variant: "SmartForm C2 Mahle X35+",
    modelYear: 2024,
    attributes: [
      attr("rear_spacing", { enum: "142x12" }),
      attr("axle_rear", { enum: "12x142" }),
      attr("headset_top", { enum: "IS42" }),
      attr("headset_bottom", { enum: "IS52" }),
      attr("bb_standard", { enum: "PF30" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
      attr("brake_mount_rear", { enum: "flat_mount" }),
      attr("motor_interface", { enum: "mahle_x35" }),
      attr("wheel_size_rear", { enum: "700c" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl:
      "https://www.cannondale.com/en/bikes/electric/e-road/topstone-neo/topstone-neo-sl-1",
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
];
