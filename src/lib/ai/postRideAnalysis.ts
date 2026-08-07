/**
 * F-AI-003 Post-Ride-Analyse (deterministisch, kein LLM).
 * Struktur: Fakten → max. 3 Beobachtungen → max. 1 Setup-Empfehlung.
 */

import type { Bike, Ride, RideFeedback, Setup, Recommendation } from "@/types";

export interface PostRideObservation {
  id: string;
  text: string;
}

export interface SetupChangeSuggestion {
  title: string;
  content: string;
  reasoning: string;
  expectedEffect: string;
  limits: string;
  confidence: "low" | "medium" | "high";
  adjusterKey?: string;
  suggestedDelta?: number;
}

export interface PostRideAnalysis {
  facts: string[];
  observations: PostRideObservation[];
  setupSuggestion: SetupChangeSuggestion | null;
}

function forkReboundClicks(setup: Setup | undefined): number | null {
  const v = setup?.values.find(
    (x) => x.slot === "fork" && /rebound/i.test(x.adjusterKey)
  );
  return v ? v.valueNum : null;
}

export function analyzePostRide(input: {
  ride: Ride;
  bike: Bike;
  setup?: Setup;
  feedback?: RideFeedback;
}): PostRideAnalysis {
  const { ride, bike, setup, feedback } = input;
  const m = ride.summaryMetrics;
  const km = ride.distanceM / 1000;
  const hours = ride.durationSec / 3600;

  const facts: string[] = [
    `${km.toFixed(1)} km · ${ride.elevationGainM} hm · ${(hours * 60).toFixed(0)} min`,
    `Flow ${m.flowScore} · Peak ${m.gForcePeak} g · ${m.impactCount} Impacts · Lean ${m.leanAngleMax}°`,
  ];
  if (setup) {
    facts.push(`Setup „${setup.label}“ (${setup.conditions})`);
  }
  if (ride.motorData) {
    facts.push(`Ø SOC ${ride.motorData.avgSoc}% · Rider ${ride.motorData.avgRiderPower} W`);
  }

  const observations: PostRideObservation[] = [];
  const impactsPerKm = km > 0.5 ? m.impactCount / km : m.impactCount;

  if (impactsPerKm >= 4) {
    observations.push({
      id: "impacts",
      text: `Viele harte Impacts (${m.impactCount} auf ${km.toFixed(1)} km) — Front/Dämpfer wurden stark belastet.`,
    });
  } else if (m.impactCount <= 2 && km >= 10) {
    observations.push({
      id: "smooth",
      text: `Wenige Impacts bei ${km.toFixed(1)} km — eher flowig oder glatter Untergrund.`,
    });
  }

  if (m.flowScore >= 75) {
    observations.push({
      id: "flow-high",
      text: `Hoher Flow-Score (${m.flowScore}) — Tempo und Linienwahl wirkten stimmig.`,
    });
  } else if (m.flowScore > 0 && m.flowScore < 45) {
    observations.push({
      id: "flow-low",
      text: `Niedriger Flow-Score (${m.flowScore}) — viele Tempo-Brüche oder Stopps.`,
    });
  }

  if (m.gForcePeak >= 4) {
    observations.push({
      id: "peak-g",
      text: `Peak ${m.gForcePeak} g — einzelne harte Einschläge; Setup und Reifendruck prüfen.`,
    });
  }

  if (feedback && !feedback.skipped) {
    if (feedback.frontFeel === "too_firm" || feedback.smallBump === "harsh") {
      observations.push({
        id: "fb-harsh",
        text: `Dein Feedback: Front ${feedback.frontFeel === "too_firm" ? "zu hart" : "ok"} · kleine Schläge ${feedback.smallBump === "harsh" ? "rau" : "—"}.`,
      });
    } else if (feedback.frontFeel === "too_soft" || feedback.brakeDive === "dives") {
      observations.push({
        id: "fb-soft",
        text: `Dein Feedback: Front wirkt weich / taucht beim Anbremsen ab.`,
      });
    }
  }

  const trimmed = observations.slice(0, 3);
  const setupSuggestion = buildSetupSuggestion({
    ride,
    bike,
    setup,
    feedback,
    impactsPerKm,
  });

  return { facts, observations: trimmed, setupSuggestion };
}

function buildSetupSuggestion(input: {
  ride: Ride;
  bike: Bike;
  setup?: Setup;
  feedback?: RideFeedback;
  impactsPerKm: number;
}): SetupChangeSuggestion | null {
  const { ride, setup, feedback, impactsPerKm } = input;
  const m = ride.summaryMetrics;
  const rebound = forkReboundClicks(setup);

  const harshFront =
    feedback?.frontFeel === "too_firm" ||
    feedback?.smallBump === "harsh" ||
    (impactsPerKm >= 3.5 && m.gForceRms >= 1.2);

  const softFront =
    feedback?.frontFeel === "too_soft" ||
    feedback?.brakeDive === "dives";

  if (harshFront && !softFront) {
    const current = rebound ?? 8;
    const next = Math.max(0, current - 2);
    return {
      title: "Zugstufe Gabel: 2 Klicks langsamer",
      content: `Aktuell ca. ${current} Klicks von geschlossen → Ziel ${next}.`,
      reasoning: [
        harshFront && feedback?.smallBump === "harsh"
          ? "Feedback „kleine Schläge rau“"
          : null,
        feedback?.frontFeel === "too_firm" ? "Feedback „Front zu hart“" : null,
        impactsPerKm >= 3.5
          ? `${m.impactCount} Impacts / ${ (ride.distanceM / 1000).toFixed(1)} km`
          : null,
        m.gForceRms >= 1.2 ? `RMS ${m.gForceRms} g` : null,
      ]
        .filter(Boolean)
        .join(" · ") || "Hohe Schlagbelastung an der Front",
      expectedEffect: "Ruhigere Front bei Schlagfolgen, etwas weniger Pop.",
      limits: "Herstellerbereich typisch 0–14 Klicks von geschlossen.",
      confidence: feedback && !feedback.skipped ? "high" : "medium",
      adjusterKey: "fork.rebound",
      suggestedDelta: -2,
    };
  }

  if (softFront) {
    const current = rebound ?? 8;
    const next = Math.min(14, current + 2);
    return {
      title: "Zugstufe Gabel: 2 Klicks schneller",
      content: `Aktuell ca. ${current} Klicks → Ziel ${next} (weniger Dive).`,
      reasoning: [
        feedback?.brakeDive === "dives" ? "Feedback „taucht ab“" : null,
        feedback?.frontFeel === "too_soft" ? "Feedback „Front zu weich“" : null,
      ]
        .filter(Boolean)
        .join(" · ") || "Front zu weich / Dive",
      expectedEffect: "Stabileres Anbremsen, weniger Durchschlag-Gefühl.",
      limits: "Herstellerbereich typisch 0–14 Klicks von geschlossen.",
      confidence: feedback && !feedback.skipped ? "high" : "medium",
      adjusterKey: "fork.rebound",
      suggestedDelta: 2,
    };
  }

  // Nur Sensor, keine klare Richtung → keine Empfehlung (Spec: max. 1, nicht erzwingen)
  if (impactsPerKm >= 5 && m.flowScore < 50) {
    return {
      title: "Luftdruck Front: +1–2 psi prüfen",
      content: "Viele Impacts bei niedrigem Flow — Reifendruck und Sag kurz checken.",
      reasoning: `${m.impactCount} Impacts · Flow ${m.flowScore}`,
      expectedEffect: "Weniger Felgenschläge, klareres Handling.",
      limits: "Im Rahmen der Reifen-/Felgenangaben bleiben.",
      confidence: "low",
      adjusterKey: "tire_front.pressure_psi",
      suggestedDelta: 1.5,
    };
  }

  return null;
}

/** Mappt Analyse auf Store-Recommendation (type setup). */
export function setupSuggestionToRecommendation(
  suggestion: SetupChangeSuggestion,
  bikeId: string,
  rideId: string
): Omit<Recommendation, "id" | "status"> {
  return {
    type: "setup",
    title: suggestion.title,
    content: `${suggestion.content} Erwartet: ${suggestion.expectedEffect}`,
    reasoning: `${suggestion.reasoning}. Grenzen: ${suggestion.limits}. Konfidenz: ${suggestion.confidence}.`,
    score:
      suggestion.confidence === "high"
        ? 0.9
        : suggestion.confidence === "medium"
          ? 0.75
          : 0.55,
    relatedBikeId: bikeId,
    relatedRideId: rideId,
  };
}
