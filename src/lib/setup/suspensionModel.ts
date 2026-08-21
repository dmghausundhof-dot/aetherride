import { recommendedSagPct } from "@/lib/setup/ranges";
import type { BikeCategory } from "@/types";

/**
 * Last- und Federweg-Modell für die Einstellhilfe.
 *
 * Statisch (SAG / Start-psi): Fahrer, Gepäck, Rad, Federweg, Ziel-SAG.
 * Dynamisch (Nutzung auf der Strecke): dasselbe plus Peak-g vom Handy.
 *
 * Bewusst linear und ohne Kolbenfläche / Hinterbau-Hebel. Ergebnis ist
 * Richtwert, kein O-Ring-Ersatz.
 */

export const G_MS2 = 9.81;

/** Fox-ähnliche Fahrer-Charts gelten für ein ~14 kg Muskel-MTB. */
export const REFERENCE_BIKE_KG = 14;

/** Lastanteil auf Gabel vs. Dämpfer (stehend auf den Pedalen). */
export const END_BIAS = { fork: 0.4, shock: 0.6 } as const;

export type SuspensionEnd = "fork" | "shock";

export function clamp(n: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, n));
}

/** Ziel-SAG in mm — die Zahl neben dem O-Ring. */
export function targetSagMm(travelMm: number, sagPct: number): number {
  if (!(travelMm > 0) || !(sagPct > 0)) return 0;
  return Math.round(travelMm * (sagPct / 100));
}

/**
 * Fahreräquivalent für empirische psi-Tabellen.
 * Leichtes Rad ändert nichts. Schweres E-MTB zählt nur die Masse über 14 kg,
 * gewichtet nach Gabel/Dämpfer — sonst würden wir Fox-Charts doppelzählen.
 */
export function equivalentRiderKg(input: {
  riderWeightKg: number;
  gearWeightKg?: number;
  bikeWeightKg?: number;
  end: SuspensionEnd;
}): number {
  const rider = clamp(input.riderWeightKg, 40, 180);
  const gear = clamp(input.gearWeightKg ?? 0, 0, 40);
  const bike = input.bikeWeightKg;
  const extra =
    bike != null && bike > REFERENCE_BIKE_KG
      ? (bike - REFERENCE_BIKE_KG) * END_BIAS[input.end]
      : 0;
  return rider + gear + extra;
}

export function estimateAirPsiFromLoad(input: {
  riderWeightKg: number;
  gearWeightKg?: number;
  bikeWeightKg?: number;
  category: BikeCategory;
  end: SuspensionEnd;
  travelMm?: number;
}): {
  sag: ReturnType<typeof recommendedSagPct>;
  sagMm: number | null;
  loadKg: number;
  psiMin: number;
  psiMax: number;
  psiTarget: number;
  note: string;
} {
  const sag = recommendedSagPct(input.category, input.end);
  const loadKg = equivalentRiderKg(input);
  const totalKg = clamp(loadKg, 40, 220);

  const base =
    input.end === "fork"
      ? totalKg * (0.95 + (30 - sag.target) * 0.012)
      : totalKg * (1.15 + (35 - sag.target) * 0.015);

  const travelFactor =
    input.travelMm && input.travelMm > 0
      ? clamp(150 / input.travelMm, 0.85, 1.15)
      : 1;

  const psiTarget = Math.round(base * travelFactor);
  const sagMm =
    input.travelMm && input.travelMm > 0
      ? targetSagMm(input.travelMm, sag.target)
      : null;

  return {
    sag,
    sagMm,
    loadKg: Math.round(totalKg * 10) / 10,
    psiMin: Math.max(30, Math.round(psiTarget * 0.92)),
    psiMax: Math.round(psiTarget * 1.08),
    psiTarget,
    note:
      "Richtwert zum Einstieg — am Rad messen (O-Ring), dann ±5 psi. Keine Kolbenfläche, kein Rahmenhebel.",
  };
}

/**
 * Überschuss-g, der bei linearer Feder den Restfederweg aufbraucht.
 * a/g = (1 − s)/s  → bei 25 % SAG sind das 3 g über Ruhe (= 4 g Peak).
 * Federweg kürzt sich raus: längerer Weg bei gleichem SAG-% ist weicher.
 */
export function remainingTravelExcessG(sagPct: number): number {
  const s = sagPct / 100;
  if (s <= 0.05 || s >= 0.9) return Number.NaN;
  return (1 - s) / s;
}

/**
 * Geschätzte Federweg-Nutzung aus Peak-g (Ruhe = 1.0).
 * Braucht bekanntes SAG. Peak aus 1-s-Blöcken ist kein Impuls — Schätzung.
 */
export function estimateTravelUsage(input: {
  gForcePeak: number;
  sagPct: number;
  travelMm: number;
}): {
  usagePct: number;
  usageMm: number;
  excessG: number;
  charExcessG: number;
  note: string;
} | null {
  const sagPct = input.sagPct;
  const char = remainingTravelExcessG(sagPct);
  if (!Number.isFinite(char) || !(input.travelMm > 0)) return null;
  if (!(input.gForcePeak >= 0)) return null;

  const excessG = Math.max(0, input.gForcePeak - 1);
  const usedRemaining = clamp(excessG / char, 0, 1);
  const sagFrac = sagPct / 100;
  const usageFrac = sagFrac + (1 - sagFrac) * usedRemaining;

  return {
    usagePct: Math.round(usageFrac * 100),
    usageMm: Math.round(input.travelMm * usageFrac),
    excessG: Math.round(excessG * 100) / 100,
    charExcessG: Math.round(char * 100) / 100,
    note:
      "Linear geschätzt aus Peak-g und SAG. Kein Schaftweg, kein Token-Progressiv.",
  };
}
