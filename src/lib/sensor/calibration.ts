/**
 * F-SEN-002 / Kap. 7.2 — Montage-Erkennung und Kalibrierung (~45 s)
 *
 * 1. Ausrichtung → Montage-Quaternion (g_dev → g_bike)
 * 2. Federungs-Antwort: ζ aus log. Dekrement (3 Wiederholungen)
 * 3. SAG manuell (O-Ring) — nie aus Accel geschätzt
 *
 * Verfällt bei Halterungs- oder Fahrwerkswechsel.
 */

export type MountMode =
  | "HANDLEBAR"
  | "STEM"
  | "POCKET"
  | "BACKPACK"
  | "BODY"
  | "UNKNOWN";

export type CalibrationStep =
  | "idle"
  | "orientation"
  | "bounce"
  | "sag"
  | "confirm_mount"
  | "done"
  | "failed";

export interface MountQuaternion {
  /** Vereinfachte 3×3-Rotation Device→Bike (Demo) */
  gDev: [number, number, number];
  gBike: [number, number, number];
  /** Gierwinkel aus GNSS später ergänzt — aus Stillstand nicht bestimmbar */
  yawFromGnssPending: true;
}

export interface SuspensionResponse {
  zeta: number;
  fdHz: number;
  fnHz: number;
  cv: number;
  accepted: boolean;
  /** Low-Speed-Zugstufe — keine Aussage zu High-Speed-Druck */
  scopeNote: string;
}

export interface BikeCalibration {
  bikeId: string;
  mountMode: MountMode;
  mountConfirmed: boolean;
  quaternion: MountQuaternion | null;
  suspension: SuspensionResponse | null;
  sagFrontMm: number | null;
  sagRearMm: number | null;
  travelFrontMm: number | null;
  travelRearMm: number | null;
  calibratedAt: string | null;
  invalidReason?: string;
}

export function createEmptyCalibration(bikeId: string): BikeCalibration {
  return {
    bikeId,
    mountMode: "UNKNOWN",
    mountConfirmed: false,
    quaternion: null,
    suspension: null,
    sagFrontMm: null,
    sagRearMm: null,
    travelFrontMm: null,
    travelRearMm: null,
    calibratedAt: null,
  };
}

export function isCalibrationValid(c: BikeCalibration | null | undefined): boolean {
  if (!c) return false;
  if (c.invalidReason) return false;
  if (!c.mountConfirmed) return false;
  if (c.mountMode !== "HANDLEBAR" && c.mountMode !== "STEM") return false;
  if (!c.quaternion || !c.suspension?.accepted) return false;
  if (c.sagFrontMm == null) return false;
  return true;
}

export function suspensionAnalysisAvailable(c: BikeCalibration | null | undefined): {
  available: boolean;
  message?: string;
} {
  if (!c?.mountConfirmed || (c.mountMode !== "HANDLEBAR" && c.mountMode !== "STEM")) {
    return {
      available: false,
      message: "Fahrwerksanalyse nicht verfügbar — Halterung am Lenker nötig",
    };
  }
  if (!isCalibrationValid(c)) {
    return {
      available: false,
      message: "Kalibrierung fehlt oder ungültig — 45 s Kalibrierung nötig",
    };
  }
  return { available: true };
}

/** Montage-Erkennung aus Vibrationsspektrum-Proxy (Demo) */
export function suggestMountMode(input: {
  highFreqEnergyRatio: number; // Anteil > 15 Hz
  orientationStability: number; // 0–1
}): MountMode {
  if (input.highFreqEnergyRatio > 0.35 && input.orientationStability > 0.7) {
    return "HANDLEBAR";
  }
  if (input.highFreqEnergyRatio > 0.25 && input.orientationStability > 0.6) {
    return "STEM";
  }
  if (input.highFreqEnergyRatio < 0.12) return "BODY";
  if (input.highFreqEnergyRatio < 0.18) return "POCKET";
  return "UNKNOWN";
}

export function orientationFromStillSamples(
  samples: { ax: number; ay: number; az: number }[]
): MountQuaternion | null {
  if (samples.length < 20) return null;
  const n = samples.length;
  const gDev: [number, number, number] = [
    samples.reduce((s, x) => s + x.ax, 0) / n,
    samples.reduce((s, x) => s + x.ay, 0) / n,
    samples.reduce((s, x) => s + x.az, 0) / n,
  ];
  const mag = Math.hypot(...gDev) || 1;
  gDev[0] /= mag;
  gDev[1] /= mag;
  gDev[2] /= mag;
  return {
    gDev,
    gBike: [0, 0, -1],
    yawFromGnssPending: true,
  };
}

/**
 * ζ aus Amplituden aufeinanderfolgender Maxima.
 * δ = (1/n)·ln(x0/xn); ζ = δ / √(4π² + δ²)
 */
export function estimateZetaFromPeaks(
  peakAmplitudes: number[],
  fdHz: number
): SuspensionResponse {
  const scopeNote =
    "Misst Low-Speed-Zugstufe um den Arbeitspunkt — keine Aussage zur High-Speed-Druckstufe.";
  if (peakAmplitudes.length < 2) {
    return {
      zeta: 0,
      fdHz,
      fnHz: fdHz,
      cv: 1,
      accepted: false,
      scopeNote,
    };
  }
  const x0 = Math.abs(peakAmplitudes[0]);
  const xn = Math.abs(peakAmplitudes[peakAmplitudes.length - 1]);
  const n = peakAmplitudes.length - 1;
  if (x0 <= 0 || xn <= 0) {
    return { zeta: 0, fdHz, fnHz: fdHz, cv: 1, accepted: false, scopeNote };
  }
  const delta = (1 / n) * Math.log(x0 / xn);
  const zeta = delta / Math.sqrt(4 * Math.PI ** 2 + delta ** 2);
  const fn = Math.abs(zeta) < 1 ? fdHz / Math.sqrt(1 - zeta ** 2) : fdHz;

  // Demo: eine Messung → CV aus Peak-Abnahme-Varianz schätzen
  const ratios: number[] = [];
  for (let i = 1; i < peakAmplitudes.length; i++) {
    if (peakAmplitudes[i - 1] > 0)
      ratios.push(Math.log(Math.abs(peakAmplitudes[i - 1] / peakAmplitudes[i])));
  }
  const mean = ratios.reduce((a, b) => a + b, 0) / (ratios.length || 1);
  const variance =
    ratios.reduce((s, r) => s + (r - mean) ** 2, 0) / (ratios.length || 1);
  const cv = mean !== 0 ? Math.sqrt(variance) / Math.abs(mean) : 1;
  const accepted = cv <= 0.2 && zeta > 0.05 && zeta < 0.8;

  return {
    zeta: Math.round(zeta * 1000) / 1000,
    fdHz: Math.round(fdHz * 100) / 100,
    fnHz: Math.round(fn * 100) / 100,
    cv: Math.round(cv * 1000) / 1000,
    accepted,
    scopeNote,
  };
}

/** Drei Bounce-Wiederholungen kombinieren — CV > 20 % ⇒ verwerfen */
export function combineBounceTrials(trials: SuspensionResponse[]): SuspensionResponse {
  const ok = trials.filter((t) => t.zeta > 0);
  const scopeNote =
    "Misst Low-Speed-Zugstufe um den Arbeitspunkt — keine Aussage zur High-Speed-Druckstufe.";
  if (ok.length < 3) {
    return {
      zeta: 0,
      fdHz: 0,
      fnHz: 0,
      cv: 1,
      accepted: false,
      scopeNote,
    };
  }
  const mean = ok.reduce((s, t) => s + t.zeta, 0) / ok.length;
  const sd = Math.sqrt(
    ok.reduce((s, t) => s + (t.zeta - mean) ** 2, 0) / ok.length
  );
  const cv = mean > 0 ? sd / mean : 1;
  const fd = ok.reduce((s, t) => s + t.fdHz, 0) / ok.length;
  const fn = ok.reduce((s, t) => s + t.fnHz, 0) / ok.length;
  return {
    zeta: Math.round(mean * 1000) / 1000,
    fdHz: Math.round(fd * 100) / 100,
    fnHz: Math.round(fn * 100) / 100,
    cv: Math.round(cv * 1000) / 1000,
    accepted: cv <= 0.2,
    scopeNote,
  };
}

export function sagPct(sagMm: number, travelMm: number): number | null {
  if (travelMm <= 0) return null;
  return Math.round((sagMm / travelMm) * 1000) / 10;
}

export function invalidateCalibration(
  c: BikeCalibration,
  reason: string
): BikeCalibration {
  return {
    ...c,
    calibratedAt: null,
    suspension: null,
    quaternion: null,
    invalidReason: reason,
    mountConfirmed: false,
  };
}
