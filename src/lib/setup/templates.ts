/**
 * F-SET-002 Setup-Vorlagen
 * OEM-Gewichtstabellen + redaktionelle Presets.
 * MUSS als Ausgangspunkt gekennzeichnet sein, nicht als Empfehlung.
 *
 * Quellen:
 * - Fox tech.ridefox.com: FLOAT-Gabel Starting Points; FLOAT X2 = psi ≈ Gewicht in lbs, SAG ~30 %
 * - Fox X2 Tuning Guide: Dämpfer-Klicks abhängig vom Luftdruck (LSR/HSR/LSC/HSC)
 * - RockShox FAQ / TrailHead: Shock Start ≈ lbs; Fork-Charts auf Bein / TrailHead-App
 * - Flow MTB / SAGLY: Gabel XC/Trail ~15–20 % SAG, Enduro ~20–25 %; Dämpfer 25–30 %
 * - Enduro Mag Setup Guide: nass/Bikepark als redaktionelle Ausgangspunkte
 */

import type { BikeCategory, SetupCondition } from "@/types";

export interface SetupTemplate {
  id: string;
  label: string;
  conditions: SetupCondition;
  kind: "oem_weight_table" | "editorial_preset";
  disclaimer: string;
  sourceLabel: string;
  sourceUrl: string;
  /** Nur anwenden wenn Kategorie matcht (leer = alle MTB) */
  categories?: BikeCategory[];
  /** Fahrergewicht kg → Overrides slot.adjuster */
  resolve: (riderWeightKg: number, category: BikeCategory) => Record<string, number>;
}

function fox36Psi(weightKg: number): number {
  // Approximiert Fox 36/34 FLOAT Starting Points (~64–120 psi über 54–113 kg)
  const clamped = Math.min(113, Math.max(54, weightKg));
  return Math.round(64 + ((clamped - 54) / (113 - 54)) * (120 - 64));
}

function weightLbs(weightKg: number): number {
  return Math.round(weightKg * 2.205);
}

/** Fox FLOAT X2: Start-Druck ≈ Körpergewicht in lbs (Owner Manual) */
function foxX2ShockPsi(weightKg: number): number {
  return Math.min(300, weightLbs(weightKg));
}

/**
 * Fox X2 Dämpfer-Startklicks (aus geschlossen) — Auszug Tuning-Tabelle.
 * Druck → [LSR, HSR, LSC, HSC]
 */
function foxX2Clicks(psi: number): {
  lsr: number;
  hsr: number;
  lsc: number;
  hsc: number;
} {
  const table: [number, number, number, number, number][] = [
    [90, 17, 8, 17, 8],
    [120, 14, 7, 16, 7],
    [150, 11, 6, 14, 6],
    [180, 8, 5, 12, 5],
    [210, 7, 4, 9, 4],
    [240, 4, 3, 6, 3],
    [270, 2, 2, 3, 3],
    [300, 1, 1, 2, 2],
  ];
  let best = table[0];
  for (const row of table) {
    if (Math.abs(row[0] - psi) < Math.abs(best[0] - psi)) best = row;
  }
  return { lsr: best[1], hsr: best[2], lsc: best[3], hsc: best[4] };
}

/**
 * RockShox-Gabel Start-PSI (Trail ~140 mm) nach Fahrergewicht —
 * Praxiswerte angelehnt an Bein-Charts / Community-Tabellen (TrailHead primär).
 */
function rockShoxForkPsi(weightKg: number, category: BikeCategory): number {
  const w = Math.min(105, Math.max(55, weightKg));
  // 75 kg Trail ≈ 63 psi Mitte; Enduro etwas weicher
  const base = 38 + ((w - 55) / 50) * 50;
  if (category === "mtb_enduro" || category === "dh" || category === "emtb") {
    return Math.round(base - 5);
  }
  if (category === "mtb_trail") return Math.round(base + 2);
  return Math.round(base);
}

export const SETUP_TEMPLATES: SetupTemplate[] = [
  {
    id: "tpl-fox-oem-base",
    label: "Fox OEM Basis (Gewichtstabelle)",
    conditions: "general",
    kind: "oem_weight_table",
    disclaimer:
      "Ausgangspunkt laut Fox Starting-Points-Tabelle — keine persönliche Empfehlung. SAG danach messen und Kammern ausgleichen.",
    sourceLabel: "Fox Owner's Manual – Setting Fork Air Pressure",
    sourceUrl: "https://tech.ridefox.com/",
    categories: ["mtb_trail", "mtb_am", "mtb_enduro", "emtb", "dh"],
    resolve: (w, cat) => {
      const sagF = cat === "mtb_enduro" || cat === "dh" || cat === "emtb" ? 23 : 22;
      const sagR = cat === "mtb_enduro" || cat === "dh" || cat === "emtb" ? 30 : 28;
      const shockPsi = foxX2ShockPsi(w);
      const clicks = foxX2Clicks(shockPsi);
      return {
        "fork.air_pressure_psi": fox36Psi(w),
        "fork.sag_pct": sagF,
        "fork.rebound": Math.max(4, Math.min(14, Math.round(18 - w / 10))),
        "fork.lsc": 6,
        "fork.hsc": 4,
        "rear_shock.air_pressure_psi": shockPsi,
        "rear_shock.sag_pct": sagR,
        "rear_shock.rebound": clicks.lsr,
        "rear_shock.hsr": clicks.hsr,
        "rear_shock.lsc": clicks.lsc,
        "rear_shock.hsc": clicks.hsc,
        "tire_front.pressure_psi": w > 85 ? 24 : 22,
        "tire_rear.pressure_psi": w > 85 ? 26 : 24,
      };
    },
  },
  {
    id: "tpl-fox-x2-oem",
    label: "Fox Float X2 OEM (lbs→psi + Klicks)",
    conditions: "general",
    kind: "oem_weight_table",
    disclaimer:
      "Fox X2: Start-Druck ≈ Gewicht in lbs, SAG ~30 %, dann Dämpfer-Tabelle. Rahmenhebelverhältnis nicht enthalten — Ausgangspunkt.",
    sourceLabel: "Fox FLOAT X2 Owner Manual / Tuning Guide",
    sourceUrl: "https://tech.ridefox.com/bike/owners-manuals/2984/shock--2025-float-x2",
    categories: ["mtb_am", "mtb_enduro", "emtb", "dh"],
    resolve: (w) => {
      const psi = foxX2ShockPsi(w);
      const c = foxX2Clicks(psi);
      return {
        "rear_shock.air_pressure_psi": psi,
        "rear_shock.sag_pct": 30,
        "rear_shock.rebound": c.lsr,
        "rear_shock.hsr": c.hsr,
        "rear_shock.lsc": c.lsc,
        "rear_shock.hsc": c.hsc,
        "fork.air_pressure_psi": fox36Psi(w),
        "fork.sag_pct": 25,
      };
    },
  },
  {
    id: "tpl-rockshox-sag-start",
    label: "RockShox SAG-Start (TrailHead-Näherung)",
    conditions: "general",
    kind: "oem_weight_table",
    disclaimer:
      "RockShox: Dämpfer-Start ≈ Körpergewicht in lbs; Gabel nach Bein-Chart/TrailHead. Dann auf 25–30 % SAG trimmen. Kein Ersatz für die TrailHead-App mit Seriennummer.",
    sourceLabel: "RockShox FAQ · TrailHead · Suspension Welcome Guide",
    sourceUrl:
      "https://www.sram.com/en/rockshox/learn/suspension-welcome-guide",
    categories: ["mtb_trail", "mtb_am", "mtb_enduro", "emtb"],
    resolve: (w, cat) => ({
      "fork.air_pressure_psi": rockShoxForkPsi(w, cat),
      "fork.sag_pct":
        cat === "mtb_enduro" || cat === "emtb" ? 22 : 18,
      "rear_shock.air_pressure_psi": weightLbs(w),
      "rear_shock.sag_pct": 30,
      "fork.rebound": 8,
      "rear_shock.rebound": 9,
      "tire_front.pressure_psi": 22,
      "tire_rear.pressure_psi": 24,
    }),
  },
  {
    id: "tpl-editorial-wet-roots",
    label: "Editorial: Nasse Roots",
    conditions: "wet",
    kind: "editorial_preset",
    disclaimer:
      "Redaktions-Preset als Ausgangspunkt — kein Ersatz für Bracketing auf deinem Trail.",
    sourceLabel: "AetherRide Editorial (angelehnt an Enduro Mag Setup Guide)",
    sourceUrl: "https://enduro-mtb.com/en/setup-guide-mtb-suspension/",
    categories: ["mtb_am", "mtb_enduro", "emtb"],
    resolve: (w) => ({
      "fork.air_pressure_psi": fox36Psi(w) - 4,
      "fork.sag_pct": 28,
      "fork.rebound": 10,
      "fork.lsc": 4,
      "rear_shock.sag_pct": 32,
      "rear_shock.rebound": 12,
      "tire_front.pressure_psi": 20,
      "tire_rear.pressure_psi": 22,
    }),
  },
  {
    id: "tpl-editorial-bikepark",
    label: "Editorial: Bikepark",
    conditions: "bikepark",
    kind: "editorial_preset",
    disclaimer: "Ausgangspunkt für Park — mehr Support, weniger SAG-Spiel.",
    sourceLabel: "AetherRide Editorial · Enduro Mag",
    sourceUrl: "https://enduro-mtb.com/en/setup-guide-mtb-suspension/",
    categories: ["mtb_enduro", "dh", "emtb"],
    resolve: (w) => ({
      "fork.air_pressure_psi": fox36Psi(w) + 6,
      "fork.sag_pct": 20,
      "fork.hsc": 6,
      "fork.lsc": 8,
      "rear_shock.sag_pct": 28,
      "rear_shock.lsc": 7,
      "tire_front.pressure_psi": 26,
      "tire_rear.pressure_psi": 28,
    }),
  },
  {
    id: "tpl-editorial-marathon",
    label: "Editorial: Marathon / lange Tour",
    conditions: "dry",
    kind: "editorial_preset",
    disclaimer:
      "Effizienz-lastiger Ausgangspunkt für lange Touren — weniger SAG, mehr Pedal-Plattform.",
    sourceLabel: "AetherRide Editorial (Marathon-Praxis)",
    sourceUrl: "https://enduro-mtb.com/en/setup-guide-mtb-suspension/",
    categories: ["mtb_trail", "mtb_am", "emtb", "gravel"],
    resolve: (w, cat) => {
      const tires = {
        "tire_front.pressure_psi": cat === "gravel" ? (w > 80 ? 38 : 34) : 24,
        "tire_rear.pressure_psi": cat === "gravel" ? (w > 80 ? 40 : 36) : 26,
      };
      if (cat === "gravel") return tires;
      return {
        "fork.air_pressure_psi": fox36Psi(w) + 4,
        "fork.sag_pct": 18,
        "fork.lsc": 8,
        "rear_shock.sag_pct": 25,
        "rear_shock.lsc": 8,
        ...tires,
      };
    },
  },
  {
    id: "tpl-editorial-race-enduro",
    label: "Editorial: Enduro-Rennen",
    conditions: "race",
    kind: "editorial_preset",
    disclaimer:
      "Race-Ausgangspunkt — aggressiver Support. Nur Startpunkt vor Track-Walk-Bracketing.",
    sourceLabel: "AetherRide Editorial",
    sourceUrl: "https://enduro-mtb.com/en/setup-guide-mtb-suspension/",
    categories: ["mtb_enduro", "dh", "emtb"],
    resolve: (w) => {
      const psi = foxX2ShockPsi(w) + 8;
      const c = foxX2Clicks(psi);
      return {
        "fork.air_pressure_psi": fox36Psi(w) + 5,
        "fork.sag_pct": 20,
        "fork.hsc": 7,
        "fork.lsc": 7,
        "rear_shock.air_pressure_psi": Math.min(300, psi),
        "rear_shock.sag_pct": 28,
        "rear_shock.lsc": c.lsc,
        "rear_shock.hsc": c.hsc,
        "tire_front.pressure_psi": 23,
        "tire_rear.pressure_psi": 25,
      };
    },
  },
  {
    id: "tpl-gravel-base",
    label: "Gravel Basisdruck",
    conditions: "general",
    kind: "editorial_preset",
    disclaimer: "Grobe Startdrücke für 40–45 mm Gravelreifen — Tubeless beachten.",
    sourceLabel: "Industriepraxis Gravel",
    sourceUrl: "https://www.specialized.com/",
    categories: ["gravel"],
    resolve: (w) => ({
      "tire_front.pressure_psi": w > 80 ? 40 : 36,
      "tire_rear.pressure_psi": w > 80 ? 42 : 38,
    }),
  },
];

export function templatesForCategory(category: BikeCategory): SetupTemplate[] {
  return SETUP_TEMPLATES.filter(
    (t) => !t.categories || t.categories.includes(category)
  ).map((t) => ({
    ...t,
    resolve: (w, cat) => {
      const raw = t.resolve(w, cat);
      const cleaned: Record<string, number> = {};
      for (const [k, v] of Object.entries(raw)) {
        if (typeof v === "number" && !Number.isNaN(v)) cleaned[k] = v;
      }
      return cleaned;
    },
  }));
}
