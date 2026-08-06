/**
 * DACH-Enduro Setup-Sprache — Werkstatt-klar + Coach-freundlich.
 * Quellen: Fox/RockShox Tuning Guides, eMTB-News, MTBR, BIKE Magazin.
 */

import type { BikeCategory } from "@/types/garage";

/** Foren-nahe Front-Symptome (nicht nur „hart/weich“) */
export type FrontSymptom =
  | "packt_nicht" // bläst durch / zu wenig Gegenhalt
  | "taucht" // Anbremsen, Front sackt
  | "ok"
  | "rupft" // Schlagfolgen, zu schnelle Zugstufe / rauh
  | "toppt_aus" // knallt am Ausfederanschlag
  | "zu_straff"; // nutzt Federweg nicht, tot/ungefühlig

export type SmallBumpSymptom =
  | "rupft" // kleine Schläge knallen
  | "ok"
  | "schmiert" // vage, wallowy, wenig Feedback
  | "tot"; // kaum Ansprechen

export type BrakeDiveSymptom = "taucht" | "neutral" | "steht";

export const FRONT_SYMPTOM_LABELS: Record<FrontSymptom, string> = {
  packt_nicht: "packt nicht",
  taucht: "taucht ab",
  ok: "passt",
  rupft: "rupft",
  toppt_aus: "toppt aus",
  zu_straff: "zu straff",
};

export const FRONT_SYMPTOM_HINTS: Record<FrontSymptom, string> = {
  packt_nicht: "Werkstatt: zu wenig Federhärte/Progression · Coach: Front sackt in Kurven/Schlägen weg",
  taucht: "Werkstatt: oft SAG/LSC · Coach: beim Anbremsen nickt die Front stark",
  ok: "Kein akuter Front-Befund",
  rupft: "Werkstatt: oft zu schnelle Low-Speed-Zug · Coach: Schlagfolgen fühlen sich unruhig an",
  toppt_aus: "Werkstatt: Zug zu langsam/schnell am Anschlag · Coach: hör-/fühlbarer Stopp beim Ausfedern",
  zu_straff: "Werkstatt: zu viel Druck oder Compression · Coach: Front wirkt tot, wenig Traktion",
};

export const SMALL_BUMP_LABELS: Record<SmallBumpSymptom, string> = {
  rupft: "rupft",
  ok: "passt",
  schmiert: "schmiert",
  tot: "tot",
};

export const BRAKE_DIVE_LABELS: Record<BrakeDiveSymptom, string> = {
  taucht: "taucht",
  neutral: "neutral",
  steht: "steht",
};

/**
 * SAG-Startbänder DACH Enduro — Fox Tuning Guide (Gabel oft 15–20 %),
 * RockShox/Enduro-Praxis (Dämpfer ~25–30 %, Gabel etwas weniger),
 * BIKE/Dirt-Empfehlungen. Kein Gesetz — TrailHead-Charts können danebenliegen (eMTB-News).
 */
export function sagStartBand(
  category: BikeCategory,
  end: "fork" | "shock"
): {
  minPct: number;
  maxPct: number;
  targetPct: number;
  sourceNote: string;
  disclaimer: string;
} {
  const disclaimer =
    "Startwerte aus OEM-Guides und DACH-Forenpraxis — kein Gesetz. Gefühl und O-Ring schlagen die App-Tabelle. Nach ±5–10 psi Rebound 1–2 Klicks mitziehen (RockShox).";

  if (end === "fork") {
    if (category === "mtb_enduro" || category === "emtb" || category === "dh") {
      return {
        minPct: 18,
        maxPct: 25,
        targetPct: 22,
        sourceNote:
          "Enduro-Gabel: Fox oft 15–20 % plush; DACH-Enduro-Alltag eher ~20–25 % (Foren/BIKE).",
        disclaimer,
      };
    }
    return {
      minPct: 15,
      maxPct: 22,
      targetPct: 18,
      sourceNote: "Trail/AM-Gabel: Fox 15–20 % SAG als OEM-Start.",
      disclaimer,
    };
  }

  // shock
  if (category === "mtb_enduro" || category === "emtb" || category === "dh") {
    return {
      minPct: 25,
      maxPct: 32,
      targetPct: 28,
      sourceNote:
        "Enduro-Dämpfer: Fox FLOAT oft 25–30 %; X2 ~30 %. Mehr SAG = plush, weniger Reserve.",
      disclaimer,
    };
  }
  return {
    minPct: 25,
    maxPct: 30,
    targetPct: 27,
    sourceNote: "Trail-Dämpfer: typisch 25–30 % SAG.",
    disclaimer,
  };
}

export function sagMmFromPct(travelMm: number, pct: number): number {
  return Math.round((travelMm * pct) / 100);
}

/** Ob Feedback auf „Front zu rau / zu schnelle Zug“ hindeutet */
export function feedbackSuggestsFastRebound(f?: {
  frontFeel?: FrontSymptom | "too_soft" | "ok" | "too_firm";
  smallBump?: SmallBumpSymptom | "harsh" | "ok" | "vague";
}): boolean {
  if (!f) return false;
  const front = f.frontFeel;
  const bump = f.smallBump;
  return (
    front === "rupft" ||
    front === "too_firm" ||
    bump === "rupft" ||
    bump === "harsh"
  );
}

/** Ob Feedback auf zu wenig Federhärte / Durchsacken hindeutet */
export function feedbackSuggestsSoftSpring(f?: {
  frontFeel?: FrontSymptom | "too_soft" | "ok" | "too_firm";
  brakeDive?: BrakeDiveSymptom | "dives" | "neutral" | "harsh";
}): boolean {
  if (!f) return false;
  return (
    f.frontFeel === "packt_nicht" ||
    f.frontFeel === "taucht" ||
    f.frontFeel === "too_soft" ||
    f.brakeDive === "taucht" ||
    f.brakeDive === "dives"
  );
}

/** Ob Feedback auf zu straff / wenig Nutzung hindeutet */
export function feedbackSuggestsFirmSpring(f?: {
  frontFeel?: FrontSymptom | "too_soft" | "ok" | "too_firm";
  smallBump?: SmallBumpSymptom | "harsh" | "ok" | "vague";
}): boolean {
  if (!f) return false;
  return (
    f.frontFeel === "zu_straff" ||
    f.smallBump === "tot" ||
    (f.frontFeel === "too_firm" && f.smallBump !== "rupft" && f.smallBump !== "harsh")
  );
}
