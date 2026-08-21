import { recommendedSagPct } from "@/lib/setup/ranges";
import { estimateAirPsiFromLoad } from "@/lib/setup/suspensionModel";
import type { BikeCategory } from "@/types";

/**
 * Grobe PSI-Schätzung. Massenmodell: rider + gear + Rad über 14 kg.
 * Quellen: Enduro MTB Mag / Dirt / Simplon SAG-Spannen (Range-Lib).
 */
export function estimateAirPsi(input: {
  riderWeightKg: number;
  gearWeightKg?: number;
  bikeWeightKg?: number;
  category: BikeCategory;
  end: "fork" | "shock";
  travelMm?: number;
}): {
  sag: ReturnType<typeof recommendedSagPct>;
  psiMin: number;
  psiMax: number;
  psiTarget: number;
  sagMm: number | null;
  loadKg: number;
  note: string;
} {
  return estimateAirPsiFromLoad(input);
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
