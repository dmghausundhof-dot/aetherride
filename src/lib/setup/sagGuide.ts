import { recommendedSagPct } from "@/lib/setup/ranges";
import type { BikeCategory } from "@/types";

/**
 * Grobe PSI-Schätzung aus Magazin-/OEM-Praxis (Richtwert, kein Tuning).
 * Formel-Idee: Ziel-SAG % und Fahrergewicht → Luft-Druck-Spanne.
 * Quellen: Enduro MTB Mag / Dirt / Simplon SAG-Tabellen (gleiche Range-Lib).
 */
export function estimateAirPsi(input: {
  riderWeightKg: number;
  gearWeightKg?: number;
  category: BikeCategory;
  end: "fork" | "shock";
  travelMm?: number;
}): { sag: ReturnType<typeof recommendedSagPct>; psiMin: number; psiMax: number; psiTarget: number; note: string } {
  const sag = recommendedSagPct(input.category, input.end);
  const totalKg = Math.max(40, input.riderWeightKg + (input.gearWeightKg ?? 0));

  // Heuristik: ~0.9–1.1 psi/kg Gabel, ~1.1–1.4 psi/kg Dämpfer, skaliert mit SAG-Ziel
  const base =
    input.end === "fork"
      ? totalKg * (0.95 + (30 - sag.target) * 0.012)
      : totalKg * (1.15 + (35 - sag.target) * 0.015);

  const travelFactor =
    input.travelMm && input.travelMm > 0
      ? Math.min(1.15, Math.max(0.85, 150 / input.travelMm))
      : 1;

  const psiTarget = Math.round(base * travelFactor);
  const psiMin = Math.max(30, Math.round(psiTarget * 0.92));
  const psiMax = Math.round(psiTarget * 1.08);

  return {
    sag,
    psiMin,
    psiMax,
    psiTarget,
    note:
      "Richtwert zum Einstieg — am Bike messen (O-Ring), dann ±5 psi feinjustieren. Keine Hersteller-Garantie.",
  };
}

export function sagMeasureSteps(end: "fork" | "shock"): string[] {
  const part = end === "fork" ? "Gabel" : "Dämpfer";
  return [
    `${part} voll ausfedern, O-Ring an die Dichtung schieben.`,
    "Fahrbereit aufsteigen (gesamte Ausrüstung), Füße auf den Pedalen, 3× leicht einfedern.",
    "Vorsichtig absteigen, ohne den O-Ring zu verschieben.",
    `Negativfederweg messen und durch Gesamtfederweg teilen → SAG in %.`,
    "Luft nachpumpen oder ablassen, bis du im Zielbereich landest.",
  ];
}
