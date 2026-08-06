/**
 * F-SEN-003 / 7.3 — Federweg-Nutzungs-Index (FNI) + Durchschlagsverdacht
 *
 * FNI: Hochpass 0,5 Hz → doppelte Integration über 2-s-Fenster →
 * 95. Perzentil |Δz|, normiert auf 99. Perzentil der letzten 20 Rides.
 *
 * MUSS: Nie als Millimeter oder % Federweg ausgeben.
 * Gate G-2: Produktion erst nach Validierungsstudie.
 */

export const G2_SUSPENSION_GATE_PASSED = false;

export type Confidence = "high" | "medium" | "low";

export interface FniWindowResult {
  /** Relativer Index 0–100 — keine mm/% */
  fni: number;
  confidence: Confidence;
  referenceText: string;
  /** Gate-Hinweis */
  gated: boolean;
}

export interface BottomOutEvent {
  t: number;
  confidence: Confidence;
  /** Immer Verdacht, nie Feststellung */
  label: "Durchschlagsverdacht";
}

/** Einfacher 1-Pol Hochpass */
export class HighPassFilter {
  private prevX = 0;
  private prevY = 0;
  private readonly alpha: number;

  constructor(cutoffHz: number, sampleRateHz: number) {
    const rc = 1 / (2 * Math.PI * cutoffHz);
    const dt = 1 / sampleRateHz;
    this.alpha = rc / (rc + dt);
  }

  step(x: number): number {
    const y = this.alpha * (this.prevY + x - this.prevX);
    this.prevX = x;
    this.prevY = y;
    return y;
  }

  reset() {
    this.prevX = 0;
    this.prevY = 0;
  }
}

/**
 * Bandbegrenzte doppelte Integration in 2-s-Fenstern.
 * Demo: arbeitet auf Vertikalbeschleunigung (m/s², ohne g).
 */
export function computeFniFromAz(
  azMs2: number[],
  sampleRateHz: number,
  bikeP99History: number | null
): FniWindowResult {
  const gated = !G2_SUSPENSION_GATE_PASSED;
  if (azMs2.length < sampleRateHz) {
    return {
      fni: 0,
      confidence: "low",
      referenceText: "zu wenig Daten",
      gated,
    };
  }

  const hp = new HighPassFilter(0.5, sampleRateHz);
  const filtered = azMs2.map((a) => hp.step(a));
  const dt = 1 / sampleRateHz;
  let v = 0;
  let z = 0;
  const absZ: number[] = [];
  // Fensterweise Reset alle 2 s (Nullphasen-Proxy)
  const window = Math.round(2 * sampleRateHz);
  for (let i = 0; i < filtered.length; i++) {
    if (i % window === 0) {
      v = 0;
      z = 0;
    }
    v += filtered[i] * dt;
    z += v * dt;
    absZ.push(Math.abs(z));
  }

  const sorted = [...absZ].sort((a, b) => a - b);
  const p95 = sorted[Math.floor(sorted.length * 0.95)] ?? 0;
  const ref = bikeP99History && bikeP99History > 0 ? bikeP99History : p95 * 1.2 || 1;
  const fni = Math.max(0, Math.min(100, Math.round((p95 / ref) * 100)));

  let referenceText = "mittel für dieses Bike";
  if (fni >= 80) referenceText = "hoch für dieses Bike";
  else if (fni <= 35) referenceText = "niedrig für dieses Bike";

  return {
    fni,
    confidence: bikeP99History ? "medium" : "low",
    referenceText,
    gated,
  };
}

/**
 * Durchschlagsverdacht: Anstiegszeit < 10 ms + Nachschwingen.
 * Ausgabe stets als Verdacht.
 */
export function detectBottomOutSuspicion(
  azMs2: number[],
  sampleRateHz: number,
  t0Ms: number
): BottomOutEvent[] {
  if (G2_SUSPENSION_GATE_PASSED === false) {
    // Engine läuft für Demo/Bracketing, UI kennzeichnet Gate
  }
  const events: BottomOutEvent[] = [];
  const dtMs = 1000 / sampleRateHz;
  const minRiseSamples = Math.max(1, Math.ceil(10 / dtMs)); // < 10 ms
  for (let i = minRiseSamples; i < azMs2.length - 5; i++) {
    const rise = azMs2[i] - azMs2[i - minRiseSamples];
    // steile Verzögerungsspitze (negativ bei „Bodenkontakt")
    if (rise < -25 && Math.abs(azMs2[i]) > 40) {
      const ring =
        Math.abs(azMs2[i + 2]) > 8 && Math.abs(azMs2[i + 4]) < Math.abs(azMs2[i + 2]);
      if (ring) {
        events.push({
          t: t0Ms + i * dtMs,
          confidence: "medium",
          label: "Durchschlagsverdacht",
        });
        i += sampleRateHz; // debounce 1 s
      }
    }
  }
  return events;
}

export function suspensionMetricsAllowed(mount: string, calibrated: boolean): boolean {
  return (
    (mount === "HANDLEBAR" || mount === "STEM") &&
    calibrated &&
    // Feature-Flag: Engine vorhanden, Live-UI an Gate gebunden
    true
  );
}
