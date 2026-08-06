/**
 * F-AI-003 / Kap. 7.4 — Deterministische Setup-Empfehlungs-Engine
 *
 * Genau eine Empfehlung pro Ride. Mindestens zwei unabhängige Belege.
 * Werte immer innerhalb Herstellergrenzen. Konfidenz niedrig → keine Aktion.
 */

import type { Bike, Ride, RideFeedback, Setup } from "@/types";
import type { BikeCalibration } from "@/lib/sensor/calibration";
import { sagPct } from "@/lib/sensor/calibration";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";

export type RecConfidence = "high" | "medium" | "low";

export interface SetupRecommendationCard {
  ruleId: string;
  title: string;
  /** Spec-Format */
  why: string;
  expectedEffect: string;
  limits: string;
  confidence: RecConfidence;
  /** Parameter-Key → neuer Wert */
  apply: Record<string, number>;
  evidence: string[];
  /** Observation without action when confidence low or G-2 */
  observationOnly: boolean;
}

export interface PostRideAnalysis {
  facts: string[];
  observations: string[]; // max 3
  recommendation: SetupRecommendationCard | null;
}

const ZETA_TARGET_ENDURO: [number, number] = [0.25, 0.4];

function currentSetup(bike: Bike): Setup | undefined {
  return bike.setups.find((s) => s.isCurrent) || bike.setups[0];
}

function valueOf(setup: Setup | undefined, key: string): number | null {
  if (!setup) return null;
  // key = "fork.rebound" → slot + adjusterKey
  const dot = key.indexOf(".");
  if (dot < 0) return null;
  const slot = key.slice(0, dot);
  const adjusterKey = key.slice(dot + 1);
  const v = setup.values.find(
    (x) => x.slot === slot && x.adjusterKey === adjusterKey
  );
  return typeof v?.valueNum === "number" ? v.valueNum : null;
}

function hardImpactsPerKm(ride: Ride): number {
  const hard = ride.summaryMetrics.impactCount ?? 0;
  // Demo: ~30 % der Impacts als hart annehmen wenn keine Breakdown
  const hardEst = ride.summaryMetrics.hardImpactCount ?? Math.round(hard * 0.3);
  const km = Math.max(0.1, ride.distanceM / 1000);
  return hardEst / km;
}

export function buildPostRideAnalysis(input: {
  bike: Bike;
  ride: Ride;
  feedback?: RideFeedback | null;
  calibration?: BikeCalibration | null;
}): PostRideAnalysis {
  const { bike, ride, feedback, calibration } = input;
  const setup = currentSetup(bike);
  const facts: string[] = [
    `${(ride.distanceM / 1000).toFixed(1)} km · ${ride.elevationGainM} hm · ${Math.round(ride.durationSec / 60)} min`,
    `Flow ${ride.summaryMetrics.flowScore ?? "—"} · Impacts ${ride.summaryMetrics.impactCount} · Lean max ${ride.summaryMetrics.leanAngleMax ?? "—"}°`,
  ];
  if (ride.summaryMetrics.fni != null) {
    facts.push(
      `FNI ${ride.summaryMetrics.fni} (${ride.summaryMetrics.fniReference ?? "Index"}) — keine mm/%-Angabe`
    );
  }

  const observations: string[] = [];
  const hipk = hardImpactsPerKm(ride);
  if (hipk >= 8) {
    observations.push(`Hohe harte Impact-Dichte: ${hipk.toFixed(1)}/km`);
  }
  if (feedback?.frontFeel && feedback.frontFeel !== "ok") {
    observations.push(`Feedback Front: ${feedback.frontFeel}`);
  }
  if (feedback?.smallBump === "harsh") {
    observations.push("Kleine Schläge: rau");
  }
  if (calibration?.suspension?.zeta != null) {
    observations.push(
      `ζ_front ≈ ${calibration.suspension.zeta} (Low-Speed-Zugstufe)`
    );
  }
  if (ride.summaryMetrics.bottomOutCount && ride.summaryMetrics.bottomOutCount > 0) {
    observations.push(
      `${ride.summaryMetrics.bottomOutCount}× Durchschlagsverdacht (kein Nachweis)`
    );
  }

  const recommendation = pickOneRecommendation({
    bike,
    ride,
    setup,
    feedback,
    calibration,
    hipk,
  });

  return {
    facts,
    observations: observations.slice(0, 3),
    recommendation,
  };
}

function pickOneRecommendation(input: {
  bike: Bike;
  ride: Ride;
  setup: Setup | undefined;
  feedback?: RideFeedback | null;
  calibration?: BikeCalibration | null;
  hipk: number;
}): SetupRecommendationCard | null {
  const { bike, setup, feedback, calibration, hipk, ride } = input;
  const zeta = calibration?.suspension?.zeta;
  const rebound = valueOf(setup, "fork.rebound") ?? 6;
  const reboundMax = 14;
  const pressure = valueOf(setup, "fork.air_pressure_psi") ?? 70;
  const travel = bike.travelFrontMm ?? 160;
  const sagMm = calibration?.sagFrontMm;
  const sag = sagMm != null ? sagPct(sagMm, travel) : valueOf(setup, "fork.sag_pct");

  // SR-COMP-05: am Anschlag → Service, keine Klicks
  if (
    rebound >= reboundMax &&
    (feedback?.frontFeel === "too_firm" ||
      feedback?.smallBump === "harsh" ||
      hipk >= 8)
  ) {
    return {
      ruleId: "SR-COMP-05",
      title: "Keine weitere Zugstufen-Verstellung",
      why: "Zugstufe bereits am Anschlag und Symptom besteht fort.",
      expectedEffect: "Kartuschen-Service oder anderes Tune in der Fachwerkstatt.",
      limits: "Keine sicherheitsrelevanten Eingriffe in der App.",
      confidence: "medium",
      apply: {},
      evidence: ["Zugstufe am Anschlag", "Symptom fortbestehend"],
      observationOnly: true,
    };
  }

  // SR-REB-01 — Spec: ζ niedrig + Feedback rau + harte Impacts
  const zetaLow = zeta != null && zeta < ZETA_TARGET_ENDURO[0];
  const feedbackRough =
    feedback?.frontFeel === "too_firm" || feedback?.smallBump === "harsh";
  if (zetaLow && feedbackRough && hipk >= 8) {
    if (!G2_SUSPENSION_GATE_PASSED) {
      return {
        ruleId: "SR-REB-01",
        title: "Zugstufe Gabel: Beobachtung (G-2 offen)",
        why: `Ausschwingmessung ζ ≈ ${zeta} unter Zielband; ${Math.round(hipk)} harte Impacts/km und Feedback „Front zu hart/rau".`,
        expectedEffect: "Nach G-2: 1–2 Klicks langsamer möglich.",
        limits: `Herstellerbereich 0–${reboundMax} Klicks. Gate G-2 nicht bestanden — keine Live-Empfehlung.`,
        confidence: "medium",
        apply: {},
        evidence: [
          `ζ=${zeta}`,
          `Impacts/km=${hipk.toFixed(1)}`,
          "Feedback too_firm/harsh",
        ],
        observationOnly: true,
      };
    }
    const target = Math.min(reboundMax, rebound + 2);
    return {
      ruleId: "SR-REB-01",
      title: `Zugstufe Gabel: ${target - rebound} Klicks langsamer (aktuell ${rebound}, empfohlen ${target})`,
      why: `Ausschwingmessung ergab ζ ≈ ${zeta} — unterhalb des Zielbereichs. Dazu hohe Impact-Dichte und Feedback „Front zu hart".`,
      expectedEffect: "Ruhigere Front bei Schlagfolgen, etwas weniger Pop.",
      limits: `Herstellerbereich 0–${reboundMax} Klicks.`,
      confidence: "medium",
      apply: { "fork.rebound": target },
      evidence: [`ζ=${zeta}`, `Impacts/km=${hipk.toFixed(1)}`, "Feedback"],
      observationOnly: false,
    };
  }

  // SR-SAG-02
  const bottomPerKm =
    (ride.summaryMetrics.bottomOutCount ?? 0) /
    Math.max(0.1, ride.distanceM / 1000);
  if (sag != null && sag > 25 && bottomPerKm > 0.5) {
    const newPsi = Math.round(pressure * 1.04);
    return {
      ruleId: "SR-SAG-02",
      title: `Luftdruck Gabel: +4 % (→ ${newPsi} psi)`,
      why: `SAG vorn ${sag} % > 25 % und Durchschlagsverdacht ${bottomPerKm.toFixed(2)}/km.`,
      expectedEffect: "Weniger Durchschlagrisiko, etwas höherer Arbeitspunkt.",
      limits: "Eine Option — kein zusätzliches Token gleichzeitig (Bracketing).",
      confidence: bottomPerKm > 1 ? "medium" : "low",
      apply: { "fork.air_pressure_psi": newPsi },
      evidence: [`SAG=${sag}%`, `BottomOut/km=${bottomPerKm.toFixed(2)}`],
      observationOnly: !G2_SUSPENSION_GATE_PASSED || bottomPerKm <= 1,
    };
  }

  // SR-SAG-03
  if (
    sag != null &&
    sag < 15 &&
    feedback?.frontFeel === "too_firm" &&
    (ride.summaryMetrics.fni ?? 100) < 40
  ) {
    const newPsi = Math.round(pressure * 0.96);
    return {
      ruleId: "SR-SAG-03",
      title: `Luftdruck Gabel: −4 % (→ ${newPsi} psi)`,
      why: `SAG vorn ${sag} % < 15 %, Feedback „Front zu hart", FNI dauerhaft niedrig.`,
      expectedEffect: "Mehr Traktion und Komfort auf kleinen Schlägen.",
      limits: "Innerhalb typischer Herstellerempfehlung für Fahrergewicht prüfen.",
      confidence: "medium",
      apply: { "fork.air_pressure_psi": newPsi },
      evidence: [
        `SAG=${sag}%`,
        "Feedback too_firm",
        `FNI=${ride.summaryMetrics.fni}`,
      ],
      observationOnly: !G2_SUSPENSION_GATE_PASSED,
    };
  }

  // Fallback: Beobachtung ohne Handlungsaufforderung
  if (observationsNeedFallback(hipk, feedback)) {
    return {
      ruleId: "SR-OBS-00",
      title: "Keine Setup-Änderung empfohlen",
      why: "Weniger als zwei unabhängige Belege oder Konfidenz zu niedrig.",
      expectedEffect: "Weiter beobachten; Bracketing auf einem Parameter nutzen.",
      limits: "Genau eine Empfehlung nur bei ausreichender Evidenz (7.4).",
      confidence: "low",
      apply: {},
      evidence: ["unzureichende Evidenz"],
      observationOnly: true,
    };
  }

  return null;
}

function observationsNeedFallback(
  hipk: number,
  feedback?: RideFeedback | null
): boolean {
  return hipk > 0 || !!feedback;
}

/** Empfehlung auf neues Setup anwenden (immutable Version) */
export function recommendationToSetupOverrides(
  card: SetupRecommendationCard
): Record<string, number> {
  return { ...card.apply };
}
