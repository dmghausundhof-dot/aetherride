/**
 * F-SEN-004 — Flow-Score, offengelegt (P0)
 *
 * Vier Teilwerte 0–100, gewichtet:
 * - Geschwindigkeitskonstanz 0.30
 * - Laufruhe 0.30
 * - Bremsökonomie 0.25
 * - Linienruhe 0.15
 *
 * MUSS: Teilwerte einzeln sichtbar. Kein nutzerübergreifender Vergleich.
 * Score ohne Terrainklasse wird nicht ausgegeben.
 */

export type TerrainClass =
  | "s0_s1"
  | "s2"
  | "s3_plus"
  | "gravel_road"
  | "unknown";

export interface FlowPartScores {
  speedConstancy: number;
  smoothness: number;
  brakeEconomy: number;
  lineStability: number;
}

export interface FlowScoreResult {
  available: boolean;
  total: number | null;
  parts: FlowPartScores | null;
  terrainClass: TerrainClass;
  reason?: string;
  /** Hinweis: nur gegen eigene Historie derselben Terrainklasse */
  comparisonNote: string;
}

export const FLOW_WEIGHTS = {
  speedConstancy: 0.3,
  smoothness: 0.3,
  brakeEconomy: 0.25,
  lineStability: 0.15,
} as const;

export const FLOW_MIN_DURATION_SEC = 180;

function clamp01(n: number) {
  return Math.max(0, Math.min(100, n));
}

/** Variationskoeffizient → Konstanz */
export function speedConstancyScore(speedsMs: number[]): number {
  if (speedsMs.length < 5) return 50;
  const mean = speedsMs.reduce((a, b) => a + b, 0) / speedsMs.length;
  if (mean <= 0.1) return 40;
  const variance =
    speedsMs.reduce((s, v) => s + (v - mean) ** 2, 0) / speedsMs.length;
  const cv = Math.sqrt(variance) / mean;
  return clamp01(100 * (1 - Math.min(1.5, cv)));
}

/** invers zum RMS des Rucks 2–12 Hz (hier: Proxy über |Δa|) */
export function smoothnessScore(jerkRms: number, terrain: TerrainClass): number {
  // Terrainnormierung: raueres Terrain toleriert höheren Ruck
  const scale =
    terrain === "s3_plus" ? 35 : terrain === "s2" ? 25 : terrain === "s0_s1" ? 18 : 22;
  const norm = jerkRms / scale;
  return clamp01(100 * (1 - Math.min(1, norm)));
}

/** Bremsereignisse/km + Härte */
export function brakeEconomyScore(
  brakesPerKm: number,
  hardBrakeShare: number,
  terrain: TerrainClass
): number {
  const expected =
    terrain === "s3_plus" ? 8 : terrain === "s2" ? 5 : terrain === "gravel_road" ? 2 : 4;
  const intensity = brakesPerKm / expected + hardBrakeShare;
  return clamp01(100 * (1 - Math.min(1.4, intensity) / 1.4));
}

/** Varianz der Gierrate abzüglich Streckengeometrie-Anteil */
export function lineStabilityScore(
  yawVariance: number,
  geometryExplainedShare: number
): number {
  const residual = yawVariance * (1 - Math.min(0.95, Math.max(0, geometryExplainedShare)));
  return clamp01(100 * (1 - Math.min(1, residual / 0.8)));
}

export function computeFlowScore(input: {
  durationSec: number;
  terrainClass: TerrainClass;
  speedsMs: number[];
  jerkRms: number;
  brakesPerKm: number;
  hardBrakeShare: number;
  yawVariance: number;
  geometryExplainedShare?: number;
}): FlowScoreResult {
  const note =
    "Nur gegen eigene Historie derselben Terrainklasse vergleichbar — kein Nutzervergleich (R-09).";

  if (input.terrainClass === "unknown") {
    return {
      available: false,
      total: null,
      parts: null,
      terrainClass: "unknown",
      reason: "Keine Terrainklasse — Flow-Score wird nicht ausgegeben",
      comparisonNote: note,
    };
  }
  if (input.durationSec < FLOW_MIN_DURATION_SEC) {
    return {
      available: false,
      total: null,
      parts: null,
      terrainClass: input.terrainClass,
      reason: `Flow erst ab ${FLOW_MIN_DURATION_SEC / 60} min Fahrzeit`,
      comparisonNote: note,
    };
  }

  const parts: FlowPartScores = {
    speedConstancy: Math.round(speedConstancyScore(input.speedsMs)),
    smoothness: Math.round(smoothnessScore(input.jerkRms, input.terrainClass)),
    brakeEconomy: Math.round(
      brakeEconomyScore(
        input.brakesPerKm,
        input.hardBrakeShare,
        input.terrainClass
      )
    ),
    lineStability: Math.round(
      lineStabilityScore(
        input.yawVariance,
        input.geometryExplainedShare ?? 0.4
      )
    ),
  };

  const total = Math.round(
    parts.speedConstancy * FLOW_WEIGHTS.speedConstancy +
      parts.smoothness * FLOW_WEIGHTS.smoothness +
      parts.brakeEconomy * FLOW_WEIGHTS.brakeEconomy +
      parts.lineStability * FLOW_WEIGHTS.lineStability
  );

  return {
    available: true,
    total,
    parts,
    terrainClass: input.terrainClass,
    comparisonNote: note,
  };
}
