/**
 * Kap. 7.3 — Impact-Klassifikation
 *
 * Ereignis wenn |a_z| > Median + 6×MAD (30-s-Fenster)
 * UND Ruck |da/dt| > 400 g/s.
 * Klassen: leicht / mittel / hart über Integral über Schwellwert.
 */

export type ImpactClass = "light" | "medium" | "hard";

export interface ImpactEvent {
  t: number;
  magnitudeG: number;
  class: ImpactClass;
  saturated: boolean;
}

const SATURATION_G = 15.5; // ±16 g Sensor

function median(values: number[]): number {
  if (!values.length) return 1;
  const s = [...values].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

function mad(values: number[], med: number): number {
  const devs = values.map((v) => Math.abs(v - med));
  return median(devs) || 0.1;
}

export class AdaptiveImpactDetector {
  private windowG: number[] = [];
  private lastAzG = 0;
  private lastT = 0;
  private readonly windowSec: number;
  private cooldownUntil = 0;

  constructor(windowSec = 30) {
    this.windowSec = windowSec;
  }

  push(azMs2: number, tMs: number): ImpactEvent | null {
    const azG = Math.abs(azMs2) / 9.81;
    this.windowG.push(azG);
    // grob: behalte ~30 s bei 50 Hz → 1500; bei 200 Hz → 6000 (cap)
    const maxLen = 6000;
    if (this.windowG.length > maxLen) this.windowG.shift();

    const med = median(this.windowG);
    const m = mad(this.windowG, med);
    const threshold = med + 6 * m;

    const dt = this.lastT > 0 ? (tMs - this.lastT) / 1000 : 0.005;
    const jerkGps = dt > 0 ? Math.abs(azG - this.lastAzG) / dt : 0;
    this.lastAzG = azG;
    this.lastT = tMs;

    if (tMs < this.cooldownUntil) return null;
    if (azG < threshold || jerkGps < 400) return null;

    const over = azG - threshold;
    let cls: ImpactClass = "light";
    if (over > 2.5) cls = "hard";
    else if (over > 1.2) cls = "medium";

    this.cooldownUntil = tMs + 120;
    return {
      t: tMs,
      magnitudeG: Math.round(azG * 100) / 100,
      class: cls,
      saturated: azG >= SATURATION_G,
    };
  }

  reset() {
    this.windowG = [];
    this.lastAzG = 0;
    this.lastT = 0;
    this.cooldownUntil = 0;
  }
}
