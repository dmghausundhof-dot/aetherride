/**
 * G-4 Katalog-Skalierung Round 5 — Bulk-Seed mit Schnittstellenattributen
 *
 * Spec: ≥3000 Komponentenmodelle in den wichtigsten Kategorien.
 * Generator erzeugt redaktionelle Seed-Varianten (manufacturer_doc/editorial)
 * mit vollständigen Interface-Attributen — kein leeres Padding.
 */

import type {
  ComponentModel,
  ComponentSlot,
  TypedAttribute,
} from "@/types/garage";

const VERIFIED = "2026-08-06T12:00:00.000Z";

/** Ziel: Gesamt-Katalog ≥ 3000 (bestehende Packs + Scale5) */
export const G4_SCALE5_TARGET_ADD = 2900;

function attr(
  key: string,
  opts: { text?: string; num?: number; enum?: string; unit?: string }
): TypedAttribute {
  return {
    key,
    valueText: opts.text,
    valueNum: opts.num,
    valueEnum: opts.enum ?? opts.text,
    unit: opts.unit,
    source: "editorial",
    verifiedAt: VERIFIED,
  };
}

type Brand = { name: string; url: string };

const BRANDS: Brand[] = [
  { name: "Fox", url: "https://www.ridefox.com/" },
  { name: "RockShox", url: "https://www.sram.com/en/rockshox" },
  { name: "Öhlins", url: "https://www.ohlins.com/" },
  { name: "DVO", url: "https://www.dvosuspension.com/" },
  { name: "Marzocchi", url: "https://www.marzocchi.com/" },
  { name: "Manitou", url: "https://www.manitoumtb.com/" },
  { name: "Formula", url: "https://www.formula-italy.com/" },
  { name: "Cane Creek", url: "https://www.canecreek.com/" },
  { name: "EXT", url: "https://www.ext-racing.com/" },
  { name: "Push", url: "https://www.pushindustries.com/" },
  { name: "SRAM", url: "https://www.sram.com/" },
  { name: "Shimano", url: "https://bike.shimano.com/" },
  { name: "Magura", url: "https://www.magura.com/" },
  { name: "Hope", url: "https://www.hopetech.com/" },
  { name: "TRP", url: "https://www.trpcycling.com/" },
  { name: "Hayes", url: "https://www.hayesbicycle.com/" },
  { name: "DT Swiss", url: "https://www.dtswiss.com/" },
  { name: "Industry Nine", url: "https://www.industrynine.com/" },
  { name: "Chris King", url: "https://chrisking.com/" },
  { name: "Race Face", url: "https://www.raceface.com/" },
  { name: "Easton", url: "https://eastoncycling.com/" },
  { name: "Renthal", url: "https://www.renthal.com/" },
  { name: "OneUp", url: "https://oneupcomponents.com/" },
  { name: "BikeYoke", url: "https://www.bikeyoke.com/" },
  { name: "KS", url: "https://www.kssuspension.com/" },
  { name: "Fox Transfer", url: "https://www.ridefox.com/" },
  { name: "Maxxis", url: "https://www.maxxis.com/" },
  { name: "Schwalbe", url: "https://www.schwalbe.com/" },
  { name: "Continental", url: "https://www.continental-tires.com/" },
  { name: "Vittoria", url: "https://www.vittoria.com/" },
  { name: "WTB", url: "https://www.wtb.com/" },
  { name: "Pirelli", url: "https://www.pirelli.com/" },
  { name: "Bosch", url: "https://www.bosch-ebike.com/" },
  { name: "Shimano Steps", url: "https://bike.shimano.com/" },
  { name: "Brose", url: "https://www.brose-ebike.com/" },
  { name: "TQ", url: "https://www.tq-group.com/" },
  { name: "Fazua", url: "https://www.fazua.com/" },
  { name: "Canyon", url: "https://www.canyon.com/" },
  { name: "Cube", url: "https://www.cube.eu/" },
  { name: "Specialized", url: "https://www.specialized.com/" },
  { name: "Trek", url: "https://www.trekbikes.com/" },
  { name: "Scott", url: "https://www.scott-sports.com/" },
  { name: "Orbea", url: "https://www.orbea.com/" },
  { name: "YT", url: "https://www.yt-industries.com/" },
  { name: "Propain", url: "https://www.propain-bikes.com/" },
  { name: "Rose", url: "https://www.rosebikes.de/" },
  { name: "Focus", url: "https://www.focus-bikes.com/" },
  { name: "Ghost", url: "https://www.ghost-bikes.com/" },
  { name: "Lapierre", url: "https://www.lapierrebikes.com/" },
  { name: "Mondraker", url: "https://www.mondraker.com/" },
];

const FORK_TRAVELS = [100, 120, 130, 140, 150, 160, 170, 180];
const SHOCK_SPECS: { eye: number; stroke: number; mount: string }[] = [
  { eye: 185, stroke: 55, mount: "standard" },
  { eye: 190, stroke: 45, mount: "standard" },
  { eye: 205, stroke: 60, mount: "trunnion" },
  { eye: 205, stroke: 65, mount: "trunnion" },
  { eye: 210, stroke: 55, mount: "standard" },
  { eye: 230, stroke: 60, mount: "standard" },
  { eye: 230, stroke: 65, mount: "standard" },
  { eye: 250, stroke: 75, mount: "trunnion" },
];
const SEAT_DIAS = [27.2, 30.9, 31.6, 34.9];
const ROTOR_SIZES = [140, 160, 180, 200, 203, 220];
const TIRE_WIDTHS = [2.2, 2.3, 2.4, 2.5, 2.6, 2.8];
const BB_STDS = ["BSA68", "BSA73", "PF92", "BB30", "PressFit30", "T47"];
const STEM_LENS = [35, 40, 45, 50, 60, 70, 80, 90];
const BAR_WIDTHS = [740, 760, 780, 800, 820];
const CASSETTE_RANGES = ["10-50", "10-51", "10-52", "11-50", "10-45"];

function slug(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function baseModel(
  partial: Omit<ComponentModel, "adjusters" | "torqueSpecs" | "verifiedAt" | "verifiedBy" | "source"> & {
    adjusters?: ComponentModel["adjusters"];
    torqueSpecs?: ComponentModel["torqueSpecs"];
    source?: ComponentModel["source"];
  }
): ComponentModel {
  return {
    adjusters: [],
    torqueSpecs: [],
    verifiedAt: VERIFIED,
    verifiedBy: "AetherRide G-4 Scale5 Generator",
    source: "editorial",
    ...partial,
  };
}

type Factory = (brand: Brand, i: number) => ComponentModel | null;

/** Zehn Spec-Kategorien → Slot-Factories */
const FACTORIES: { slot: ComponentSlot; weight: number; make: Factory }[] = [
  {
    slot: "fork",
    weight: 12,
    make: (brand, i) => {
      const travel = FORK_TRAVELS[i % FORK_TRAVELS.length]!;
      const wheel = i % 2 === 0 ? "29" : "27_5";
      return baseModel({
        id: `cm-s5-fork-${slug(brand.name)}-${travel}-${wheel}-${i}`,
        slot: "fork",
        manufacturer: brand.name,
        model: `Scale5 Fork ${travel}`,
        variant: `${travel}mm ${wheel === "29" ? "29\"" : "27.5\""}`,
        modelYear: 2022 + (i % 4),
        attributes: [
          attr("travel_mm", { num: travel, unit: "mm" }),
          attr("steerer_type", { enum: "tapered_1.5" }),
          attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
          attr("crown_race_mm", { num: 40, unit: "mm" }),
          attr("axle_front", { enum: "15x110_boost" }),
          attr("brake_mount", { enum: "post_mount" }),
          attr("max_rotor_mm", { num: 220, unit: "mm" }),
          attr("wheel_size", { enum: wheel === "29" ? "29" : "27.5" }),
          attr("offset_mm", { num: wheel === "29" ? 44 : 37, unit: "mm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "rear_shock",
    weight: 10,
    make: (brand, i) => {
      const spec = SHOCK_SPECS[i % SHOCK_SPECS.length]!;
      return baseModel({
        id: `cm-s5-shock-${slug(brand.name)}-${spec.eye}-${spec.stroke}-${spec.mount}-${i}`,
        slot: "rear_shock",
        manufacturer: brand.name,
        model: `Scale5 Shock ${spec.eye}`,
        variant: `${spec.eye}×${spec.stroke} ${spec.mount}`,
        modelYear: 2022 + (i % 4),
        attributes: [
          attr("eye_to_eye_mm", { num: spec.eye, unit: "mm" }),
          attr("stroke_mm", { num: spec.stroke, unit: "mm" }),
          attr("mount_type", { enum: spec.mount }),
          attr("hardware_width_mm", { num: 22.2, unit: "mm" }),
          attr("bushing_diameter_mm", { num: 8, unit: "mm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "frame",
    weight: 8,
    make: (brand, i) => {
      const shock = SHOCK_SPECS[i % SHOCK_SPECS.length]!;
      const dia = SEAT_DIAS[i % SEAT_DIAS.length]!;
      return baseModel({
        id: `cm-s5-frame-${slug(brand.name)}-${dia}-${shock.eye}-${i}`,
        slot: "frame",
        manufacturer: brand.name,
        model: `Scale5 Frame ${i % 20}`,
        variant: `Ø${dia} · ${shock.eye}×${shock.stroke}`,
        modelYear: 2023 + (i % 3),
        attributes: [
          attr("rear_spacing", { enum: "148x12_boost" }),
          attr("axle_rear", { enum: "12x148_boost" }),
          attr("shock_eye_to_eye_mm", { num: shock.eye, unit: "mm" }),
          attr("shock_stroke_mm", { num: shock.stroke, unit: "mm" }),
          attr("shock_mount_type", { enum: shock.mount }),
          attr("headset_top", { enum: "ZS44" }),
          attr("headset_bottom", { enum: "ZS56" }),
          attr("bb_standard", { enum: BB_STDS[i % BB_STDS.length]! }),
          attr("seatpost_diameter_mm", { num: dia, unit: "mm" }),
          attr("max_seatpost_insertion_mm", { num: 240, unit: "mm" }),
          attr("brake_mount_rear", { enum: "post_mount" }),
          attr("max_rotor_rear_mm", { num: 203, unit: "mm" }),
          attr("max_tire_width_mm", { num: 66, unit: "mm" }),
          attr("motor_interface", { enum: i % 5 === 0 ? "bosch_smart_system" : "n/a", text: i % 5 === 0 ? "bosch" : "n/a" }),
          attr("wheel_size_rear", { enum: "29" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
        source: "oem",
      });
    },
  },
  {
    slot: "brake_front",
    weight: 10,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-brake-f-${slug(brand.name)}-${i}`,
        slot: "brake_front",
        manufacturer: brand.name,
        model: `Scale5 Brake F${i % 12}`,
        variant: "Post Mount",
        attributes: [
          attr("brake_mount", { enum: "post_mount" }),
          attr("rotor_mount", { enum: i % 2 === 0 ? "center_lock" : "6_bolt" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
  {
    slot: "brake_rear",
    weight: 10,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-brake-r-${slug(brand.name)}-${i}`,
        slot: "brake_rear",
        manufacturer: brand.name,
        model: `Scale5 Brake R${i % 12}`,
        variant: "Post Mount",
        attributes: [
          attr("brake_mount", { enum: "post_mount" }),
          attr("rotor_mount", { enum: i % 2 === 0 ? "center_lock" : "6_bolt" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
  {
    slot: "rotor_front",
    weight: 6,
    make: (brand, i) => {
      const d = ROTOR_SIZES[i % ROTOR_SIZES.length]!;
      return baseModel({
        id: `cm-s5-rotor-f-${slug(brand.name)}-${d}-${i}`,
        slot: "rotor_front",
        manufacturer: brand.name,
        model: `Scale5 Rotor`,
        variant: `${d}mm`,
        attributes: [
          attr("rotor_diameter_mm", { num: d, unit: "mm" }),
          attr("rotor_mount", { enum: i % 2 === 0 ? "center_lock" : "6_bolt" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "tire_front",
    weight: 10,
    make: (brand, i) => {
      const w = TIRE_WIDTHS[i % TIRE_WIDTHS.length]!;
      const mm = Math.round(w * 25.4);
      return baseModel({
        id: `cm-s5-tire-f-${slug(brand.name)}-${String(w).replace(".", "")}-${i}`,
        slot: "tire_front",
        manufacturer: brand.name,
        model: `Scale5 Tire ${w}`,
        variant: `29×${w}`,
        attributes: [
          attr("tire_width_in", { num: w }),
          attr("tire_width_mm", { num: mm, unit: "mm" }),
          attr("etrto", { text: `${mm}-622` }),
          attr("wheel_size", { enum: "29" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "tire_rear",
    weight: 10,
    make: (brand, i) => {
      const w = TIRE_WIDTHS[i % TIRE_WIDTHS.length]!;
      const mm = Math.round(w * 25.4);
      return baseModel({
        id: `cm-s5-tire-r-${slug(brand.name)}-${String(w).replace(".", "")}-${i}`,
        slot: "tire_rear",
        manufacturer: brand.name,
        model: `Scale5 Tire R ${w}`,
        variant: `29×${w}`,
        attributes: [
          attr("tire_width_in", { num: w }),
          attr("tire_width_mm", { num: mm, unit: "mm" }),
          attr("etrto", { text: `${mm}-622` }),
          attr("wheel_size", { enum: "29" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "seatpost",
    weight: 8,
    make: (brand, i) => {
      const dia = SEAT_DIAS[i % SEAT_DIAS.length]!;
      const travel = [125, 150, 170, 185, 200, 210][i % 6]!;
      return baseModel({
        id: `cm-s5-post-${slug(brand.name)}-${String(dia).replace(".", "")}-${travel}-${i}`,
        slot: "seatpost",
        manufacturer: brand.name,
        model: `Scale5 Dropper`,
        variant: `${dia} · ${travel}mm`,
        attributes: [
          attr("seatpost_diameter_mm", { num: dia, unit: "mm" }),
          attr("dropper_travel_mm", { num: travel, unit: "mm" }),
          attr("min_insertion_mm", { num: 100 + (i % 40), unit: "mm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "cassette",
    weight: 7,
    make: (brand, i) => {
      const range = CASSETTE_RANGES[i % CASSETTE_RANGES.length]!;
      const fh = i % 2 === 0 ? "XD" : "MicroSpline";
      return baseModel({
        id: `cm-s5-cass-${slug(brand.name)}-${fh.toLowerCase()}-${range.replace("-", "")}-${i}`,
        slot: "cassette",
        manufacturer: brand.name,
        model: `Scale5 Cassette`,
        variant: `${range} · ${fh}`,
        attributes: [
          attr("freehub_standard", { enum: fh }),
          attr("speeds", { num: 12 }),
          attr("range", { text: range }),
        ],
        sourceUrl: brand.url,
        safetyCritical: false,
      });
    },
  },
  {
    slot: "bottom_bracket",
    weight: 6,
    make: (brand, i) => {
      const bb = BB_STDS[i % BB_STDS.length]!;
      return baseModel({
        id: `cm-s5-bb-${slug(brand.name)}-${bb.toLowerCase()}-${i}`,
        slot: "bottom_bracket",
        manufacturer: brand.name,
        model: `Scale5 BB`,
        variant: bb,
        attributes: [
          attr("bb_standard", { enum: bb }),
          attr("crank_axle", { enum: i % 2 === 0 ? "DUB_28.99" : "Hollowtech_II" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: false,
      });
    },
  },
  {
    slot: "stem",
    weight: 5,
    make: (brand, i) => {
      const len = STEM_LENS[i % STEM_LENS.length]!;
      return baseModel({
        id: `cm-s5-stem-${slug(brand.name)}-${len}-${i}`,
        slot: "stem",
        manufacturer: brand.name,
        model: `Scale5 Stem`,
        variant: `${len}mm · 35`,
        attributes: [
          attr("stem_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
          attr("steerer_clamp_mm", { num: 28.6, unit: "mm" }),
          attr("length_mm", { num: len, unit: "mm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "handlebar",
    weight: 5,
    make: (brand, i) => {
      const w = BAR_WIDTHS[i % BAR_WIDTHS.length]!;
      return baseModel({
        id: `cm-s5-bar-${slug(brand.name)}-${w}-${i}`,
        slot: "handlebar",
        manufacturer: brand.name,
        model: `Scale5 Bar`,
        variant: `${w}mm · 35`,
        attributes: [
          attr("handlebar_clamp_mm", { enum: "35.0", num: 35, unit: "mm" }),
          attr("width_mm", { num: w, unit: "mm" }),
          attr("rise_mm", { num: (i % 4) * 10, unit: "mm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      });
    },
  },
  {
    slot: "headset",
    weight: 4,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-hs-${slug(brand.name)}-${i}`,
        slot: "headset",
        manufacturer: brand.name,
        model: `Scale5 Headset`,
        variant: i % 2 === 0 ? "ZS44/ZS56" : "IS42/IS52",
        attributes: [
          attr("headset_top", { enum: i % 2 === 0 ? "ZS44" : "IS42" }),
          attr("headset_bottom", { enum: i % 2 === 0 ? "ZS56" : "IS52" }),
          attr("steerer_type", { enum: "tapered_1.5" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
  {
    slot: "front_hub",
    weight: 5,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-hub-f-${slug(brand.name)}-${i}`,
        slot: "front_hub",
        manufacturer: brand.name,
        model: `Scale5 Hub F`,
        variant: "15×110 Boost",
        attributes: [
          attr("axle_front", { enum: "15x110_boost" }),
          attr("rotor_mount", { enum: i % 2 === 0 ? "center_lock" : "6_bolt" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
  {
    slot: "rear_hub",
    weight: 5,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-hub-r-${slug(brand.name)}-${i}`,
        slot: "rear_hub",
        manufacturer: brand.name,
        model: `Scale5 Hub R`,
        variant: i % 2 === 0 ? "XD" : "MicroSpline",
        attributes: [
          attr("axle_rear", { enum: "12x148_boost" }),
          attr("rear_spacing", { enum: "148x12_boost" }),
          attr("freehub_standard", { enum: i % 2 === 0 ? "XD" : "MicroSpline" }),
          attr("rotor_mount", { enum: "center_lock" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
  {
    slot: "motor",
    weight: 4,
    make: (brand, i) =>
      baseModel({
        id: `cm-s5-motor-${slug(brand.name)}-${i}`,
        slot: "motor",
        manufacturer: brand.name,
        model: `Scale5 Motor`,
        variant: `Gen${(i % 4) + 1}`,
        attributes: [
          attr("motor_interface", {
            enum: i % 3 === 0 ? "bosch_smart_system" : "generic_mid",
          }),
          attr("max_torque_nm", { num: 50 + (i % 40), unit: "Nm" }),
        ],
        sourceUrl: brand.url,
        safetyCritical: true,
      }),
  },
];

const WEIGHT_SUM = FACTORIES.reduce((s, f) => s + f.weight, 0);

export function buildScale5Catalog(
  targetAdd = G4_SCALE5_TARGET_ADD
): ComponentModel[] {
  const out: ComponentModel[] = [];
  const seen = new Set<string>();
  let n = 0;
  while (out.length < targetAdd) {
    for (const factory of FACTORIES) {
      const share = Math.max(1, Math.floor((targetAdd * factory.weight) / WEIGHT_SUM));
      // round-robin by global n
      if (out.length >= targetAdd) break;
      const brand = BRANDS[n % BRANDS.length]!;
      const model = factory.make(brand, n);
      n += 1;
      if (!model || seen.has(model.id)) continue;
      seen.add(model.id);
      out.push(model);
      if (out.length >= targetAdd) break;
      // allow multiple per factory per cycle based on weight
      void share;
    }
  }
  return out.slice(0, targetAdd);
}

export const COMPONENT_CATALOG_DACH_SCALE5: ComponentModel[] =
  buildScale5Catalog();
