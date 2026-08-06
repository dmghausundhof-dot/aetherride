/**
 * F-EBK-005 — Assist-Modus-Protokollierung (P2)
 *
 * Nur Logging — keine Motorsteuerung (F-EBK-000).
 * Ohne OEM-Datenquelle: Schätzung aus Leistungs-/Geschwindigkeitssignatur
 * ODER manuelle Angabe — Schätzung MUSS als Schätzung gekennzeichnet sein.
 *
 * Quellen Verbrauchsfaktoren (Bosch Battery Guide / BIKE Magazin / myvelo):
 * Eco effizient, Tour gleichmäßig, Sport/eMTB progressiv, Turbo max. Support
 * → typisch 6–15 Wh/km, Turbo 2–3× Eco.
 */

export type AssistMode = "off" | "eco" | "tour" | "sport" | "turbo";

export interface AssistSegment {
  id: string;
  mode: AssistMode;
  /** 'oem' = ausgelesen, 'estimated' = Signatur, 'manual' = Nutzer */
  source: "oem" | "estimated" | "manual";
  startOffsetSec: number;
  endOffsetSec: number;
  distanceM: number;
  avgSpeedKmh: number;
  avgRiderPowerW?: number;
  estimatedWh?: number;
  label: string;
}

export interface AssistRideSummary {
  segments: AssistSegment[];
  dominantMode: AssistMode;
  modeSharePct: Record<AssistMode, number>;
  estimatedTotalWh: number;
  hasEstimates: boolean;
  disclaimer: string;
  sourceLabel: string;
}

/** Relative Wh/km-Faktoren vs. Tour=1 (Bosch/BIKE-Praxis, grob) */
export const ASSIST_WH_FACTOR: Record<AssistMode, number> = {
  off: 0.15,
  eco: 0.65,
  tour: 1.0,
  sport: 1.45,
  turbo: 2.1,
};

export function estimateModeFromSignature(input: {
  speedKmh: number;
  riderPowerW: number;
  gradeApprox?: number;
}): { mode: AssistMode; confidence: number } {
  const grade = input.gradeApprox ?? 0.03;
  const power = input.riderPowerW;
  const speed = input.speedKmh;

  // Hohe Geschwindigkeit bergauf bei niedriger Fahrerleistung → Turbo/Sport
  if (grade > 0.06 && speed > 14 && power < 120) {
    return { mode: "turbo", confidence: 0.55 };
  }
  if (grade > 0.04 && speed > 12 && power < 140) {
    return { mode: "sport", confidence: 0.5 };
  }
  if (speed < 10 && power > 160) {
    return { mode: "eco", confidence: 0.45 };
  }
  if (power > 180 && speed < 18) {
    return { mode: "eco", confidence: 0.4 };
  }
  return { mode: "tour", confidence: 0.35 };
}

/** Demo: segmente einen Ride in Assist-Abschnitte (Schätzung) */
export function buildEstimatedAssistLog(input: {
  durationSec: number;
  distanceM: number;
  elevationGainM: number;
  avgRiderPower?: number;
  avgSpeedKmh?: number;
  preferredMode?: AssistMode;
}): AssistRideSummary {
  const duration = Math.max(60, input.durationSec);
  const dist = Math.max(100, input.distanceM);
  const speed = input.avgSpeedKmh ?? (dist / 1000 / (duration / 3600));
  const power = input.avgRiderPower ?? 110;
  const grade = input.elevationGainM / Math.max(1, dist);

  const climbShare = Math.min(0.55, 0.2 + grade * 8);
  const segments: AssistSegment[] = [];

  // Segment 1: Anfahrt Tour/Eco
  const t1 = Math.round(duration * 0.25);
  const d1 = Math.round(dist * 0.28);
  const m1 = input.preferredMode === "eco" ? "eco" : "tour";
  segments.push({
    id: "seg-1",
    mode: m1,
    source: "estimated",
    startOffsetSec: 0,
    endOffsetSec: t1,
    distanceM: d1,
    avgSpeedKmh: speed * 0.95,
    avgRiderPowerW: power + 10,
    estimatedWh: (d1 / 1000) * 10 * ASSIST_WH_FACTOR[m1],
    label: `Schätzung: ${m1.toUpperCase()} (Anfahrt)`,
  });

  // Segment 2: Steigung → höherer Modus
  const climbEst = estimateModeFromSignature({
    speedKmh: speed * 0.7,
    riderPowerW: power * 0.8,
    gradeApprox: Math.max(grade, 0.07),
  });
  const t2 = Math.round(duration * climbShare);
  const d2 = Math.round(dist * 0.35);
  segments.push({
    id: "seg-2",
    mode: climbEst.mode,
    source: "estimated",
    startOffsetSec: t1,
    endOffsetSec: t1 + t2,
    distanceM: d2,
    avgSpeedKmh: speed * 0.75,
    avgRiderPowerW: power * 0.85,
    estimatedWh: (d2 / 1000) * 14 * ASSIST_WH_FACTOR[climbEst.mode],
    label: `Schätzung: ${climbEst.mode.toUpperCase()} (Steigung, Konfidenz ${(climbEst.confidence * 100).toFixed(0)} %)`,
  });

  // Segment 3: Rest Tour
  const t3 = duration - t1 - t2;
  const d3 = dist - d1 - d2;
  segments.push({
    id: "seg-3",
    mode: "tour",
    source: "estimated",
    startOffsetSec: t1 + t2,
    endOffsetSec: duration,
    distanceM: Math.max(0, d3),
    avgSpeedKmh: speed,
    avgRiderPowerW: power,
    estimatedWh: (Math.max(0, d3) / 1000) * 9 * ASSIST_WH_FACTOR.tour,
    label: "Schätzung: TOUR (Rest)",
  });

  return summarizeAssist(segments);
}

export function summarizeAssist(segments: AssistSegment[]): AssistRideSummary {
  const totals: Record<AssistMode, number> = {
    off: 0,
    eco: 0,
    tour: 0,
    sport: 0,
    turbo: 0,
  };
  let totalDist = 0;
  let wh = 0;
  for (const s of segments) {
    totals[s.mode] += s.distanceM;
    totalDist += s.distanceM;
    wh += s.estimatedWh ?? 0;
  }
  const share = {} as Record<AssistMode, number>;
  (Object.keys(totals) as AssistMode[]).forEach((m) => {
    share[m] = totalDist > 0 ? Math.round((totals[m] / totalDist) * 100) : 0;
  });
  const dominant = (Object.entries(totals).sort((a, b) => b[1] - a[1])[0]?.[0] ??
    "tour") as AssistMode;

  return {
    segments,
    dominantMode: dominant,
    modeSharePct: share,
    estimatedTotalWh: Math.round(wh),
    hasEstimates: segments.some((s) => s.source === "estimated"),
    disclaimer:
      "Schätzungen aus Leistungs-/Geschwindigkeitssignatur — kein OEM-Auslesen. Keine Motorsteuerung (F-EBK-000).",
    sourceLabel:
      "Bosch Battery Guide Moduswirkung · BIKE Magazin Reichweitentest · Spec F-EBK-005",
  };
}

export function manualAssistSegment(
  mode: AssistMode,
  durationSec: number,
  distanceM: number
): AssistSegment {
  return {
    id: `manual-${mode}`,
    mode,
    source: "manual",
    startOffsetSec: 0,
    endOffsetSec: durationSec,
    distanceM,
    avgSpeedKmh: distanceM / 1000 / (durationSec / 3600 || 1),
    estimatedWh: (distanceM / 1000) * 11 * ASSIST_WH_FACTOR[mode],
    label: `Manuell: ${mode.toUpperCase()}`,
  };
}
