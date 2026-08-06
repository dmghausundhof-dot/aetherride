/**
 * F-SEN-003 / Kap. 7.3 — Schräglage
 *
 * Spec-MUSS: Nicht aus dem Gravitationsvektor allein.
 * θ = atan(v · ω_yaw / g)
 *
 * Physik (koordinierte Kurve): θ = atan(v²/(r·g)) und ω_yaw = v/r
 * ⇒ θ = atan(v · ω_yaw / g). Quelle u. a. Bicycle/Motorcycle Dynamics,
 * Brake Point GPS-derived lean, Spec 7.3.
 *
 * Gültig ab 8 km/h; darunter kein Wert.
 */

export const G = 9.80665;
export const LEAN_MIN_SPEED_KMH = 8;
export const LEAN_PLAUSIBILITY_DEG = 15;

export interface LeanInput {
  /** Vorwärtsgeschwindigkeit m/s (GNSS geglättet) */
  speedMs: number;
  /** Gierrate um Bike-Hochachse rad/s */
  yawRateRadS: number;
  /** Optional: fusionierte Lage in Grad für Plausibilität */
  fusedAttitudeDeg?: number;
}

export interface LeanResult {
  available: boolean;
  leanDeg: number | null;
  confidence: "high" | "medium" | "low" | "unavailable";
  reason?: string;
}

export function computeLeanAngle(input: LeanInput): LeanResult {
  const speedKmh = input.speedMs * 3.6;
  if (!Number.isFinite(input.speedMs) || !Number.isFinite(input.yawRateRadS)) {
    return {
      available: false,
      leanDeg: null,
      confidence: "unavailable",
      reason: "ungültige Eingabe",
    };
  }
  if (speedKmh < LEAN_MIN_SPEED_KMH) {
    return {
      available: false,
      leanDeg: null,
      confidence: "unavailable",
      reason: `unter ${LEAN_MIN_SPEED_KMH} km/h`,
    };
  }

  const thetaRad = Math.atan((input.speedMs * input.yawRateRadS) / G);
  const leanDeg = (thetaRad * 180) / Math.PI;
  // Vorzeichen aus Gierrate (links negativ / rechts positiv — UI-Spiegelbalken)
  const signed = Math.sign(input.yawRateRadS || 1) * Math.abs(leanDeg);

  let confidence: LeanResult["confidence"] = "high";
  if (input.fusedAttitudeDeg != null) {
    const delta = Math.abs(Math.abs(signed) - Math.abs(input.fusedAttitudeDeg));
    if (delta > LEAN_PLAUSIBILITY_DEG) confidence = "low";
    else if (delta > LEAN_PLAUSIBILITY_DEG / 2) confidence = "medium";
  }
  if (speedKmh < 12) {
    confidence = confidence === "high" ? "medium" : confidence;
  }

  return {
    available: true,
    leanDeg: Math.round(signed * 10) / 10,
    confidence,
  };
}
