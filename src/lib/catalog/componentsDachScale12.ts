/**
 * Round 12 — Path Riot OEM-Korrektur, Haibike LYKE, Centurion Backfire R2000,
 * Corratec X-Vert Pro. Quellen: Herstellerseiten 2025–2026. Fehlende Maße leer.
 */

import type { ComponentModel, ComponentSlot, TypedAttribute } from "@/types/garage";

const VERIFIED = "2026-08-21T00:00:00.000Z";
const SHIMANO = "https://bike.shimano.com/";
const SRAM = "https://www.sram.com/";
const FOX = "https://www.ridefox.com/";
const GHOST = "https://ghost-bikes.com/en-int/products/path-riot-advanced-gfat1";
const HAIBIKE = "https://haibike.com/de-de/products/lyke-cf-11-hmqt1";
const CENTURION = "https://www.centurion.de/de-de/bike/1191/backfire-r2000";
const CORRATEC = "https://www.corratec.com/Bike-Archiv/X-Vert-Pro-oxid.html";

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

function frameHardtail(opts: {
  id: string;
  manufacturer: string;
  model: string;
  variant: string;
  year: number;
  url: string;
  seatpostMm: number;
  bb?: string;
  motor?: string;
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
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: opts.bb ?? "BSA73" }),
      attr("seatpost_diameter_mm", { num: opts.seatpostMm, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_tire_width_mm", { num: opts.maxTireMm ?? 60, unit: "mm" }),
      attr("motor_interface", {
        enum: opts.motor ?? "n/a",
        text: opts.motor ?? "n/a",
      }),
      attr("wheel_size_rear", { enum: "29" }),
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

export const COMPONENT_CATALOG_DACH_SCALE12: ComponentModel[] = [
  // —— Path Riot Advanced (Ghost) ——
  part("cm-eightpins-h01-34-9", "seatpost", "Eightpins", "H01 Hydraulic", {
    variant: "34.9 Dropper",
    url: GHOST,
    safety: true,
    attrs: [
      attr("diameter_mm", { num: 34.9, unit: "mm" }),
      attr("seatpost_diameter_mm", { num: 34.9, unit: "mm" }),
    ],
  }),
  part("cm-rockshox-lyrik-select-150", "fork", "RockShox", "Lyrik Select", {
    variant: "150mm 29 Charger RC",
    year: 2026,
    url: "https://www.sram.com/en/rockshox",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 150, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-shimano-mt520-front", "brake_front", "Shimano", "BR-MT520", {
    variant: "4-Kolben",
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-mt520-rear", "brake_rear", "Shimano", "BR-MT520", {
    variant: "4-Kolben",
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-rt86-203-rear", "rotor_rear", "Shimano", "SM-RT86", {
    variant: "203 mm 6-bolt",
    url: SHIMANO,
    attrs: [attr("rotor_size_mm", { num: 203, unit: "mm" })],
  }),
  part("cm-shimano-cn-m6100", "chain", "Shimano", "CN-M6100", {
    variant: "12s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-rotor-ekapic-crank", "crankset", "Rotor", "E-Kapic", {
    variant: "Fazua Ride 60",
    url: GHOST,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-rotor-ekapic-ring-34", "chainring", "Rotor", "E-Kapic", {
    variant: "34T Fazua",
    url: GHOST,
    attrs: [attr("teeth", { num: 34 })],
  }),
  part("cm-rotor-ekapic-ring-32", "chainring", "Rotor", "E-Kapic", {
    variant: "32T Fazua",
    url: HAIBIKE,
    attrs: [attr("teeth", { num: 32 })],
  }),
  part("cm-fazua-ride-60-bb", "bottom_bracket", "Fazua", "Ride 60", {
    variant: "Motor-BB",
    url: "https://www.fazua.com/",
    attrs: [attr("bb_standard", { enum: "fazua_ride_60" })],
  }),
  part("cm-xlc-riser-31-8", "handlebar", "XLC", "Riser Bar MTB", {
    variant: "31.8 · 800 · 20 rise",
    url: GHOST,
    attrs: [
      attr("handlebar_clamp_mm", { enum: "31.8", num: 31.8, unit: "mm" }),
      attr("width_mm", { num: 800, unit: "mm" }),
      attr("rise_mm", { num: 20, unit: "mm" }),
    ],
  }),
  part("cm-pmg-team-stem-31-8", "stem", "PMG", "Team All Mtn", {
    variant: "31.8 · 40 mm",
    url: GHOST,
    attrs: [attr("handlebar_clamp_mm", { enum: "31.8", num: 31.8, unit: "mm" })],
  }),
  part("cm-xlc-gr-s34-grips", "grips", "XLC", "GR-S34 Gravity", {
    url: GHOST,
  }),
  part("cm-fizik-terra-aidon-x5", "saddle", "Fizik", "Terra Aidon X5", {
    variant: "145 mm",
    url: GHOST,
  }),
  part("cm-acros-azx-220-zs44-zs56", "headset", "Acros", "AZX-220-R4 Blocklock", {
    variant: "ZS44/ZS56",
    url: GHOST,
    attrs: [
      attr("headset_top", { enum: "ZS44" }),
      attr("headset_bottom", { enum: "ZS56" }),
    ],
  }),
  part("cm-shimano-hb-tc500-15-b", "front_hub", "Shimano", "HB-TC500-15-B", {
    variant: "15×110 Boost",
    url: SHIMANO,
    attrs: [attr("axle_front", { enum: "15x110_boost" })],
  }),
  part("cm-shimano-fh-tc600-ms-b", "rear_hub", "Shimano", "FH-TC600-MS-B", {
    variant: "12×148 Microspline",
    url: SHIMANO,
    attrs: [
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("freehub_body", { enum: "MS" }),
    ],
  }),
  part("cm-wtb-st-light-i30-front", "front_rim", "WTB", "ST Light i30", {
    variant: "29 TCS 32H",
    url: GHOST,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),
  part("cm-wtb-st-light-i30-rear", "rear_rim", "WTB", "ST Light i30", {
    variant: "29 TCS 32H",
    url: GHOST,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),
  part("cm-vp-vpe-527", "pedals", "VP", "VPE-527", {
    variant: "Alloy Reflector",
    url: GHOST,
  }),

  // —— Haibike LYKE CF 11 ——
  {
    id: "cm-haibike-lyke-cf-frame",
    slot: "frame",
    manufacturer: "Haibike",
    model: "LYKE CF",
    variant: "11 Carbon Fazua 140",
    modelYear: 2025,
    attributes: [
      attr("rear_spacing", { enum: "148x12_boost" }),
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("shock_eye_to_eye_mm", { num: 210, unit: "mm" }),
      attr("shock_stroke_mm", { num: 52.5, unit: "mm" }),
      attr("shock_mount_type", { enum: "standard" }),
      attr("headset_top", { enum: "ZS56" }),
      attr("headset_bottom", { enum: "ZS56" }),
      attr("bb_standard", { enum: "fazua_ride_60" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("brake_mount_rear", { enum: "post_mount" }),
      attr("max_rotor_rear_mm", { num: 180, unit: "mm" }),
      attr("motor_interface", { enum: "fazua_ride_60" }),
      attr("wheel_size_rear", { enum: "29" }),
    ],
    adjusters: [],
    torqueSpecs: [],
    source: "oem",
    sourceUrl: HAIBIKE,
    verifiedAt: VERIFIED,
    verifiedBy: "FlowLine Editorial",
    safetyCritical: true,
  },
  part("cm-fox-36-performance-140", "fork", "Fox", "36 FLOAT Performance", {
    variant: "140mm 29 GRIP",
    year: 2025,
    url: FOX,
    safety: true,
    attrs: [
      attr("travel_mm", { num: 140, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("offset_mm", { num: 44, unit: "mm" }),
    ],
  }),
  part("cm-fox-float-sl-210525", "rear_shock", "Fox", "FLOAT SL Performance", {
    variant: "210×52.5",
    url: FOX,
    safety: true,
    attrs: [
      attr("eye_to_eye_mm", { num: 210, unit: "mm" }),
      attr("stroke_mm", { num: 52.5, unit: "mm" }),
      attr("mount_type", { enum: "standard" }),
    ],
  }),
  part("cm-limotec-a1h-31-6", "seatpost", "Limotec", "A1H Dropper", {
    variant: "31.6 · 170 mm",
    url: HAIBIKE,
    safety: true,
    attrs: [
      attr("diameter_mm", { num: 31.6, unit: "mm" }),
      attr("seatpost_diameter_mm", { num: 31.6, unit: "mm" }),
      attr("dropper_travel_mm", { num: 170, unit: "mm" }),
    ],
  }),
  part("cm-selle-italia-model-x", "saddle", "Selle Italia", "Model X", {
    url: HAIBIKE,
  }),
  part("cm-raceface-turbine-r-bar", "handlebar", "Race Face", "Turbine R", {
    variant: "35 · 780 · 20 rise",
    url: HAIBIKE,
    attrs: [
      attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("width_mm", { num: 780, unit: "mm" }),
      attr("rise_mm", { num: 20, unit: "mm" }),
    ],
  }),
  part("cm-shimano-slx-shifter-m7100", "shifter", "Shimano", "SLX SL-M7100", {
    variant: "12s I-Spec",
    url: SHIMANO,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-shimano-cs-m7100", "cassette", "Shimano", "SLX CS-M7100", {
    variant: "10-51 12s",
    url: SHIMANO,
    attrs: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "MS" }),
    ],
  }),
  part("cm-xlc-vlg-1751-grips", "grips", "XLC", "VLG-1751D2", {
    url: HAIBIKE,
  }),

  // —— Centurion Backfire R2000 ——
  frameHardtail({
    id: "cm-centurion-backfire-r2000-frame",
    manufacturer: "Centurion",
    model: "Backfire R",
    variant: "R2000 intube III",
    year: 2026,
    url: CENTURION,
    seatpostMm: 34.9,
    bb: "bosch_smart_system",
    motor: "bosch_smart_system",
    maxTireMm: 64,
  }),
  part("cm-fox-awl-sport-120", "fork", "Fox", "AWL Sport eMTB+", {
    variant: "120mm 29",
    year: 2026,
    url: FOX,
    safety: true,
    attrs: [
      attr("travel_mm", { num: 120, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
      attr("offset_mm", { num: 44, unit: "mm" }),
    ],
  }),
  part("cm-shimano-m8130-rd", "rear_derailleur", "Shimano", "Deore XT RD-M8130", {
    variant: "Linkglide 11s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 11 }), attr("max_cog", { num: 50 })],
  }),
  part("cm-shimano-m8130-shifter", "shifter", "Shimano", "Deore XT SL-M8130", {
    variant: "Linkglide I-Spec",
    url: SHIMANO,
    attrs: [attr("speed", { num: 11 })],
  }),
  part("cm-shimano-cn-lg500", "chain", "Shimano", "CN-LG500", {
    variant: "Linkglide 11s",
    url: SHIMANO,
    attrs: [attr("speed", { num: 11 })],
  }),
  part("cm-shimano-m6120-front", "brake_front", "Shimano", "Deore BR-M6120", {
    variant: "4-Kolben",
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-m6120-rear", "brake_rear", "Shimano", "Deore BR-M6120", {
    variant: "4-Kolben",
    url: SHIMANO,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-shimano-rt64-203-front", "rotor_front", "Shimano", "SM-RT64", {
    variant: "203 mm Centerlock",
    url: SHIMANO,
    attrs: [attr("rotor_size_mm", { num: 203, unit: "mm" })],
  }),
  part("cm-shimano-rtem600-180-rear", "rotor_rear", "Shimano", "RT-EM600", {
    variant: "180 mm Centerlock",
    url: SHIMANO,
    attrs: [attr("rotor_size_mm", { num: 180, unit: "mm" })],
  }),
  part("cm-procraft-drop-pro-34-9", "seatpost", "Procraft", "DROP Pro", {
    variant: "34.9 Dropper",
    url: CENTURION,
    safety: true,
    attrs: [
      attr("diameter_mm", { num: 34.9, unit: "mm" }),
      attr("seatpost_diameter_mm", { num: 34.9, unit: "mm" }),
    ],
  }),
  part("cm-procraft-trail-bar-35", "handlebar", "Procraft", "Trail Pro", {
    variant: "35 · 760 · 20 rise",
    url: CENTURION,
    attrs: [
      attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
      attr("width_mm", { num: 760, unit: "mm" }),
      attr("rise_mm", { num: 20, unit: "mm" }),
    ],
  }),
  part("cm-procraft-trail-stem-35", "stem", "Procraft", "Trail Pro", {
    variant: "35 mm",
    url: CENTURION,
    attrs: [attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" })],
  }),
  part("cm-centurion-r-pro-crank", "crankset", "Centurion", "R Pro II Gen4", {
    variant: "Bosch DM",
    url: CENTURION,
    attrs: [attr("speed", { num: 11 })],
  }),
  part("cm-centurion-r-36-ring", "chainring", "Centurion", "R Gen4", {
    variant: "36T Bosch DM",
    url: CENTURION,
    attrs: [attr("teeth", { num: 36 })],
  }),
  part("cm-bosch-cx-bb", "bottom_bracket", "Bosch", "Performance Line CX", {
    variant: "Smart System",
    url: "https://www.bosch-ebike.com/",
    attrs: [attr("bb_standard", { enum: "bosch_smart_system" })],
  }),
  part("cm-maxxis-dissector-29-front", "tire_front", "Maxxis", "Dissector", {
    variant: "29×2.4 EXO",
    url: "https://www.maxxis.com/",
    attrs: [attr("tire_size", { text: "61-622" })],
  }),
  part("cm-bosch-brc3300", "display", "Bosch", "Mini Remote", {
    variant: "BRC3300",
    url: "https://www.bosch-ebike.com/",
    attrs: [attr("motor_system", { enum: "bosch_smart_system" })],
  }),
  part("cm-procraft-standard-grips", "grips", "Procraft", "Standard Advanced", {
    url: CENTURION,
  }),
  part("cm-procraft-e-pro-saddle", "saddle", "Procraft", "E-Pro II", {
    url: CENTURION,
  }),
  part("cm-centurion-backfire-hub-front", "front_hub", "Centurion", "Backfire Boost", {
    variant: "15×110 32H",
    url: CENTURION,
    attrs: [attr("axle_front", { enum: "15x110_boost" })],
  }),
  part("cm-centurion-backfire-hub-rear", "rear_hub", "Centurion", "Backfire Boost", {
    variant: "12×148 32H",
    url: CENTURION,
    attrs: [attr("axle_rear", { enum: "12x148_boost" })],
  }),
  part("cm-centurion-iw30-front", "front_rim", "Centurion", "IW 30", {
    variant: "29 TLR",
    url: CENTURION,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),
  part("cm-centurion-iw30-rear", "rear_rim", "Centurion", "IW 30", {
    variant: "29 TLR",
    url: CENTURION,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),

  // —— Corratec X-Vert Pro ——
  frameHardtail({
    id: "cm-corratec-xvert-pro-frame",
    manufacturer: "Corratec",
    model: "X-Vert Pro",
    variant: "Aluminum 29",
    year: 2025,
    url: CORRATEC,
    seatpostMm: 27.2,
    maxTireMm: 57,
  }),
  part("cm-suntour-xcr32-100", "fork", "SR Suntour", "XCR32 Coil RLR", {
    variant: "100mm 29 15×110",
    year: 2025,
    url: "https://www.srsuntour.com/",
    safety: true,
    attrs: [
      attr("travel_mm", { num: 100, unit: "mm" }),
      attr("wheel_size", { enum: "29" }),
      attr("axle_front", { enum: "15x110_boost" }),
    ],
  }),
  part("cm-sram-sx-eagle-rd", "rear_derailleur", "SRAM", "SX Eagle", {
    variant: "12s",
    url: SRAM,
    attrs: [attr("speed", { num: 12 }), attr("max_cog", { num: 50 })],
  }),
  part("cm-sram-sx-eagle-shifter", "shifter", "SRAM", "SX Eagle", {
    variant: "12s Trigger",
    url: SRAM,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-sram-pg-1210", "cassette", "SRAM", "PG-1210 Eagle", {
    variant: "11-50 12s",
    url: SRAM,
    attrs: [
      attr("cassette_speed", { num: 12 }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-sram-sx-eagle-chain", "chain", "SRAM", "SX Eagle", {
    variant: "12s NK",
    url: SRAM,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-sram-sx-eagle-crank", "crankset", "SRAM", "SX Eagle DUB", {
    variant: "175 32T",
    url: SRAM,
    attrs: [attr("speed", { num: 12 })],
  }),
  part("cm-sram-sx-eagle-ring-32", "chainring", "SRAM", "SX Eagle", {
    variant: "32T",
    url: SRAM,
    attrs: [attr("teeth", { num: 32 })],
  }),
  part("cm-sram-level-front", "brake_front", "SRAM", "Level", {
    variant: "2-Kolben 180",
    url: SRAM,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-sram-level-rear", "brake_rear", "SRAM", "Level", {
    variant: "2-Kolben 160",
    url: SRAM,
    safety: true,
    attrs: [attr("brake_mount", { enum: "post_mount" })],
  }),
  part("cm-sram-centerline-180-front", "rotor_front", "SRAM", "Centerline", {
    variant: "180 mm",
    url: SRAM,
    attrs: [attr("rotor_size_mm", { num: 180, unit: "mm" })],
  }),
  part("cm-sram-centerline-160-rear", "rotor_rear", "SRAM", "Centerline", {
    variant: "160 mm",
    url: SRAM,
    attrs: [attr("rotor_size_mm", { num: 160, unit: "mm" })],
  }),
  part("cm-michelin-force-29-front", "tire_front", "Michelin", "Force", {
    variant: "57-622",
    url: CORRATEC,
    attrs: [attr("tire_size", { text: "57-622" })],
  }),
  part("cm-michelin-force-29-rear", "tire_rear", "Michelin", "Force", {
    variant: "57-622",
    url: CORRATEC,
    attrs: [attr("tire_size", { text: "57-622" })],
  }),
  part("cm-alloy-seatpost-27-2", "seatpost", "Corratec", "Alloy Twin Bolt", {
    variant: "27.2×350",
    url: CORRATEC,
    attrs: [
      attr("diameter_mm", { num: 27.2, unit: "mm" }),
      attr("seatpost_diameter_mm", { num: 27.2, unit: "mm" }),
    ],
  }),
  part("cm-alloy-bar-31-8-760", "handlebar", "Corratec", "Alloy Riser", {
    variant: "31.8 · 760",
    url: CORRATEC,
    attrs: [
      attr("handlebar_clamp_mm", { enum: "31.8", num: 31.8, unit: "mm" }),
      attr("width_mm", { num: 760, unit: "mm" }),
    ],
  }),
  part("cm-alloy-stem-31-8-80", "stem", "Corratec", "Alloy", {
    variant: "31.8 · 80 mm",
    url: CORRATEC,
    attrs: [attr("handlebar_clamp_mm", { enum: "31.8", num: 31.8, unit: "mm" })],
  }),
  part("cm-corratec-xvert-hub-front", "front_hub", "Corratec", "X-Vert 6-bolt", {
    variant: "15×110",
    url: CORRATEC,
    attrs: [attr("axle_front", { enum: "15x110_boost" })],
  }),
  part("cm-corratec-xvert-hub-rear", "rear_hub", "Corratec", "X-Vert 6-bolt", {
    variant: "12×148 HG",
    url: CORRATEC,
    attrs: [
      attr("axle_rear", { enum: "12x148_boost" }),
      attr("freehub_body", { enum: "HG" }),
    ],
  }),
  part("cm-corratec-xvert-rim-front", "front_rim", "Corratec", "Alloy 622-23", {
    variant: "29 6-bolt",
    url: CORRATEC,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),
  part("cm-corratec-xvert-rim-rear", "rear_rim", "Corratec", "Alloy 622-23", {
    variant: "29 6-bolt",
    url: CORRATEC,
    attrs: [attr("wheel_size", { enum: "29" })],
  }),
];
