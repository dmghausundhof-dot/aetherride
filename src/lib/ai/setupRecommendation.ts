/**
 * F-AI-003 / Kap. 7.4 — Deterministische Setup-Empfehlung
 * DACH Enduro: SAG zuerst (OEM-Doktrin), dann Rebound.
 * Durchschlag (User-Entscheidung C): nur Observation bis G-2 — Druck ODER Token prüfen, keine Auto-Klicks.
 *
 * Sprache: Werkstatt-klar + Coach-freundlich (forumCopy).
 */

import type { Bike, Ride, RideFeedback, Setup } from "@/types";
import type { BikeCalibration } from "@/lib/sensor/calibration";
import { sagPct } from "@/lib/sensor/calibration";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import {
  feedbackSuggestsFastRebound,
  feedbackSuggestsFirmSpring,
  feedbackSuggestsSoftSpring,
  FRONT_SYMPTOM_LABELS,
  SMALL_BUMP_LABELS,
  sagStartBand,
  type FrontSymptom,
  type SmallBumpSymptom,
} from "@/lib/setup/forumCopy";
import { recommendedSagPct } from "@/lib/setup/ranges";

export type RecConfidence = "high" | "medium" | "low";

export interface SetupRecommendationCard {
  ruleId: string;
  title: string;
  why: string;
  expectedEffect: string;
  limits: string;
  confidence: RecConfidence;
  apply: Record<string, number>;
  evidence: string[];
  observationOnly: boolean;
  /** Werkstatt-Zeile */
  workshopLine?: string;
  /** Coach-Zeile */
  coachLine?: string;
}

export interface PostRideAnalysis {
  facts: string[];
  observations: string[];
  recommendation: SetupRecommendationCard | null;
}

/** Hypothese bis G-2 — Low-Speed-Zug-Band Enduro (Spec 7.4 Startwert) */
const ZETA_TARGET_ENDURO: [number, number] = [0.25, 0.4];

function currentSetup(bike: Bike): Setup | undefined {
  return bike.setups.find((s) => s.isCurrent) || bike.setups[0];
}

function valueOf(setup: Setup | undefined, key: string): number | null {
  if (!setup) return null;
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
  const hardEst =
    ride.summaryMetrics.hardImpactCount ?? Math.round(hard * 0.3);
  const km = Math.max(0.1, ride.distanceM / 1000);
  return hardEst / km;
}

function labelFront(f?: RideFeedback["frontFeel"]): string {
  if (!f) return "";
  if (f in FRONT_SYMPTOM_LABELS) {
    return FRONT_SYMPTOM_LABELS[f as FrontSymptom];
  }
  if (f === "too_firm") return "zu straff/rau";
  if (f === "too_soft") return "packt nicht";
  return f;
}

function labelBump(b?: RideFeedback["smallBump"]): string {
  if (!b) return "";
  if (b in SMALL_BUMP_LABELS) {
    return SMALL_BUMP_LABELS[b as SmallBumpSymptom];
  }
  if (b === "harsh") return "rupft";
  if (b === "vague") return "schmiert";
  return b;
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
      `FNI ${ride.summaryMetrics.fni} (${ride.summaryMetrics.fniReference ?? "Index"}) — relativ, keine mm/%`
    );
  }

  const observations: string[] = [];
  const hipk = hardImpactsPerKm(ride);
  if (hipk >= 8) {
    observations.push(
      `Viele harte Impacts (~${hipk.toFixed(1)}/km) — Front arbeitet hart`
    );
  }
  if (feedback?.frontFeel && feedback.frontFeel !== "ok") {
    observations.push(`Front: „${labelFront(feedback.frontFeel)}“`);
  }
  if (feedback?.smallBump && feedback.smallBump !== "ok") {
    observations.push(`Kleine Schläge: „${labelBump(feedback.smallBump)}“`);
  }
  if (feedback?.brakeDive === "taucht" || feedback?.brakeDive === "dives") {
    observations.push("Anbremsen: Front taucht spürbar");
  }
  if (calibration?.suspension?.zeta != null) {
    observations.push(
      `ζ ≈ ${calibration.suspension.zeta} (nur Low-Speed-Zug um den Arbeitspunkt)`
    );
  }
  if (
    ride.summaryMetrics.bottomOutCount &&
    ride.summaryMetrics.bottomOutCount > 0
  ) {
    observations.push(
      `${ride.summaryMetrics.bottomOutCount}× Durchschlagsverdacht — Verdacht, kein Beweis`
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

/**
 * Priorität (besser = OEM/Foren-Doktrin):
 * 1) Service am Anschlag
 * 2) SAG / Durchschlag (Observation bis G-2)
 * 3) SAG zu straff / zu weich
 * 4) Rebound (ζ + rupft)
 * 5) Observation-Fallback
 */
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
  const sag =
    sagMm != null ? sagPct(sagMm, travel) : valueOf(setup, "fork.sag_pct");
  const sagBandRec = recommendedSagPct(bike.category, "fork");
  const sagGuide = sagStartBand(bike.category, "fork");
  const sagBand = {
    min: sagGuide.minPct,
    max: sagGuide.maxPct,
    target: sagGuide.targetPct,
    sourceNote: sagGuide.sourceNote,
  };
  void sagBandRec;
  const bottomPerKm =
    (ride.summaryMetrics.bottomOutCount ?? 0) /
    Math.max(0.1, ride.distanceM / 1000);

  const soft = feedbackSuggestsSoftSpring(feedback ?? undefined);
  const firm = feedbackSuggestsFirmSpring(feedback ?? undefined);
  const fastReb = feedbackSuggestsFastRebound(feedback ?? undefined);

  // 1) SR-COMP-05
  if (rebound >= reboundMax && (fastReb || hipk >= 8 || soft)) {
    return {
      ruleId: "SR-COMP-05",
      title: "Zugstufe am Anschlag — Werkstatt statt weiterer Klicks",
      why: "Die Low-Speed-Zug ist bereits voll zu. Weitere Klicks ändern nichts am Symptom.",
      expectedEffect:
        "Kartuschen-Service oder anderes Tune — nicht in der App verdrehen.",
      limits: "Keine sicherheitsrelevanten Eingriffe (Spec 7.4).",
      confidence: "medium",
      apply: {},
      evidence: ["Zugstufe am Anschlag", "Symptom fortbestehend"],
      observationOnly: true,
      workshopLine: "Kartusche / Tune prüfen lassen.",
      coachLine: "Nicht weiter am Rädchen drehen — das Limit ist erreicht.",
    };
  }

  // 2) SR-SAG-02 — Durchschlag: User-Entscheidung C → nur Observation
  if (
    (sag != null && sag > sagBand.max && bottomPerKm > 0.5) ||
    (bottomPerKm > 0.8 && soft)
  ) {
    const psiHint = Math.round(pressure * 1.04);
    return {
      ruleId: "SR-SAG-02",
      title: "Durchschlag: beobachten — keine Sofort-Verstellung",
      why:
        (sag != null
          ? `SAG vorn ~${sag} % (Band ${sagBand.min}–${sagBand.max} %) und `
          : "") +
        `Durchschlagsverdacht ~${bottomPerKm.toFixed(2)}/km. ` +
        "MTBR/BIKE: seltener soft bottom bei Extremhits ist ok; ständig hart durchschlagen spricht für zu weich oder fehlende Endprogression — nicht blind mehr Rebound.",
      expectedEffect:
        "Zum Prüfen (eine Sache, Bracketing): entweder Luftdruck ca. +3–5 % " +
        `(Orientierung ~${psiHint} psi) ODER Token/ABO — nicht beides gleichzeitig.`,
      limits:
        "Bis Gate G-2 keine automatische Klick-/Druck-Übernahme. Immer Verdacht, nie Feststellung.",
      confidence: bottomPerKm > 1 ? "medium" : "low",
      apply: {},
      evidence: [
        sag != null ? `SAG=${sag}%` : "SAG unbekannt",
        `BottomOut/km=${bottomPerKm.toFixed(2)}`,
        soft ? "Feedback packt/taucht" : "Sensor-Verdacht",
      ].filter(Boolean),
      observationOnly: true,
      workshopLine:
        "Druck +3–5 % ODER ein Token/ABO-Klick — eine Änderung, dann gleich Segment wiederholen.",
      coachLine:
        "Nicht panisch zudrehen. Erst notieren, wie oft und wie hart es durchschlägt — dann eine Stellschraube.",
    };
  }

  // 3a) SR-SAG-03 — zu straff / wenig Nutzung
  if (
    sag != null &&
    sag < sagBand.min &&
    (firm || (ride.summaryMetrics.fni ?? 100) < 40) &&
    (firm || feedback?.frontFeel === "zu_straff" || feedback?.smallBump === "tot")
  ) {
    const newPsi = Math.round(pressure * 0.96);
    const gated = !G2_SUSPENSION_GATE_PASSED;
    return {
      ruleId: "SR-SAG-03",
      title: gated
        ? "SAG zu straff — Beobachtung (Druck prüfen)"
        : `Luftdruck Gabel: −4 % (→ ${newPsi} psi)`,
      why: `SAG vorn ~${sag} % liegt unter dem Startband ${sagBand.min}–${sagBand.max} %. Feedback „${labelFront(feedback?.frontFeel) || "zu straff"}“ / kleine Schläge „${labelBump(feedback?.smallBump) || "tot"}“. Fox/RockShox: erst SAG, dann Dämpfung.`,
      expectedEffect:
        "Mehr Ansprechen und Traktion; Federweg wird eher genutzt. Danach Rebound ggf. 1 Klick öffnen (weniger Dämpfung), weil weniger Federenergie.",
      limits: `${sagBand.sourceNote ?? ""} Herstellergrenzen am Ventil beachten.`.trim(),
      confidence: "medium",
      apply: gated ? {} : { "fork.air_pressure_psi": newPsi },
      evidence: [
        `SAG=${sag}% < ${sagBand.min}%`,
        firm ? "Feedback straff/tot" : `FNI=${ride.summaryMetrics.fni}`,
      ],
      observationOnly: gated,
      workshopLine: `Zielband Gabel ~${sagBand.min}–${sagBand.max} % (O-Ring).`,
      coachLine: "Front fühlt sich tot an? Erst Luft raus bis SAG stimmt — nicht gleich Compression aufdrehen.",
    };
  }

  // 3b) SR-SAG-04 — zu viel SAG / packt nicht (ohne zwingenden Bottom-out)
  if (
    sag != null &&
    sag > sagBand.max &&
    soft &&
    bottomPerKm <= 0.5
  ) {
    const newPsi = Math.round(pressure * 1.04);
    const gated = !G2_SUSPENSION_GATE_PASSED;
    return {
      ruleId: "SR-SAG-04",
      title: gated
        ? "SAG zu tief — Beobachtung (Druck/Progression)"
        : `Luftdruck Gabel: +4 % (→ ${newPsi} psi)`,
      why: `SAG vorn ~${sag} % über Band ${sagBand.min}–${sagBand.max} %. Feedback „${labelFront(feedback?.frontFeel)}“. Foren: Front „packt nicht“ / taucht — zuerst Federhärte, nicht Zug zudrehen.`,
      expectedEffect:
        "Mehr Gegenhalt in der Kurve und beim Anbremsen. Bei Bedarf später Progression (Token) — nicht beides auf einmal.",
      limits: "Eine Parameteränderung. Rebound danach ggf. 1 Klick langsamer (mehr Dämpfung) bei höherem Druck.",
      confidence: "medium",
      apply: gated ? {} : { "fork.air_pressure_psi": newPsi },
      evidence: [`SAG=${sag}% > ${sagBand.max}%`, "Feedback packt/taucht"],
      observationOnly: gated,
      workshopLine: "SAG per O-Ring korrigieren, dann 1 Segment testen.",
      coachLine: "Wenn die Front wegtaucht: erst Luft, nicht panisch Zugstufe.",
    };
  }

  // 4) SR-REB-01 — erst nach SAG-Klarheit
  const sagOk =
    sag == null || (sag >= sagBand.min - 2 && sag <= sagBand.max + 2);
  const zetaLow = zeta != null && zeta < ZETA_TARGET_ENDURO[0];
  if (sagOk && zetaLow && fastReb && hipk >= 8) {
    const target = Math.min(reboundMax, rebound + 2);
    const gated = !G2_SUSPENSION_GATE_PASSED;
    return {
      ruleId: "SR-REB-01",
      title: gated
        ? "Zugstufe: Front rupft — Beobachtung (G-2)"
        : `Zugstufe Gabel: ${target - rebound} Klicks langsamer (aktuell ${rebound} → ${target})`,
      why: `ζ ≈ ${zeta} unter dem hypothetischen Enduro-Band ${ZETA_TARGET_ENDURO[0]}–${ZETA_TARGET_ENDURO[1]}. Feedback „rupft“ und ~${hipk.toFixed(1)} harte Impacts/km. SAG wirkt im Rahmen — deshalb Zug, nicht Druck.`,
      expectedEffect:
        "Ruhigere Front in Schlagfolgen, etwas weniger Pop. Nur Low-Speed-Zug — keine Aussage zu High-Speed-Druck (Square-Edge).",
      limits: `Hersteller 0–${reboundMax} Klicks von geschlossen. Zielbänder sind Hypothesen bis G-2 (A-03).`,
      confidence: "medium",
      apply: gated ? {} : { "fork.rebound": target },
      evidence: [
        `ζ=${zeta}`,
        `Impacts/km=${hipk.toFixed(1)}`,
        `Feedback ${labelFront(feedback?.frontFeel) || labelBump(feedback?.smallBump)}`,
      ],
      observationOnly: gated,
      workshopLine: "1–2 Klicks Richtung geschlossen (langsamer), Segment wiederholen.",
      coachLine: "Wenn’s in Schlagfolgen rupft und SAG passt: Zug etwas beruhigen — nicht die ganze Gabel zudrücken.",
    };
  }

  // 5) Top-out Hinweis
  if (feedback?.frontFeel === "toppt_aus" && sagOk) {
    return {
      ruleId: "SR-REB-TOP",
      title: "Top-out: Zugstufe prüfen (Observation)",
      why: "Du meldest „toppt aus“. Fox: Rebound so, dass die Gabel schnell zurückkommt, aber nicht am Ausfederanschlag knallt.",
      expectedEffect: "Meist 1–2 Klicks langsamer (mehr Dämpfung). Nur testen, wenn SAG stimmt.",
      limits: "Keine Auto-Übernahme ohne zweiten Sensorbeleg.",
      confidence: "low",
      apply: {},
      evidence: ["Feedback toppt_aus", sag != null ? `SAG=${sag}%` : "SAG unsicher"],
      observationOnly: true,
      workshopLine: "Rebound 1 Klick schließen, Hörprobe am Ausfedern.",
      coachLine: "Wenn’s oben knallt: Zug etwas beruhigen — kein Luftdruck-Drama.",
    };
  }

  if (hipk > 0 || feedback) {
    return {
      ruleId: "SR-OBS-00",
      title: "Keine Setup-Änderung — noch zu wenig Belege",
      why: "Für eine Empfehlung braucht es mindestens zwei unabhängige Signale (z. B. SAG + Feedback, oder ζ + rupft + Impacts). Einzeln wirken Foren-Symptome mehrdeutig („hart“ ≠ immer Zug).",
      expectedEffect: "Nächster Ride: Feedback foren-nah tippen, optional Bracketing auf genau einem Parameter.",
      limits: "Genau eine Änderung pro Schritt (F-AI-003 / Bracketing).",
      confidence: "low",
      apply: {},
      evidence: ["unzureichende Evidenz"],
      observationOnly: true,
      workshopLine: "Messprotokoll führen, eine Stellschraube.",
      coachLine: "Lieber einen klaren Test als drei gleichzeitige Verdrehungen.",
    };
  }

  return null;
}

export function recommendationToSetupOverrides(
  card: SetupRecommendationCard
): Record<string, number> {
  return { ...card.apply };
}
