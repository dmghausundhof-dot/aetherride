/**
 * AetherRide – High-Frequency Sensor Fusion Layer
 *
 * Web-Simulation + klare Schnittstelle für native Implementierung
 * (Flutter Platform Channels / Swift CoreMotion / Android SensorManager).
 *
 * Ziel-Abtastrate Produktion: 50–100 Hz
 * Fusion: Complementary Filter + einfache Peak-/Impact-Detection
 */

export interface RawSensorSample {
  t: number; // ms timestamp
  ax: number; // m/s²
  ay: number;
  az: number;
  gx: number; // rad/s
  gy: number;
  gz: number;
  pressure?: number; // hPa
}

export interface FusedMetrics {
  timestamp: number;
  gForcePeak: number; // |a| / 9.81
  gForceRms: number;
  leanAngleDeg: number;
  impactDetected: boolean;
  impactMagnitude: number;
  flowContribution: number; // 0–1 smoothness
  estimatedTravelUsagePct?: number;
}

export interface SensorFusionConfig {
  sampleRateHz: number;
  impactThresholdG: number;
  leanFilterAlpha: number;
  windowSizeMs: number;
}

const DEFAULT_CONFIG: SensorFusionConfig = {
  sampleRateHz: 50,
  impactThresholdG: 2.8,
  leanFilterAlpha: 0.15,
  windowSizeMs: 1000,
};

/**
 * Complementary-Filter basierte Fusion.
 * In nativer Implementierung: CoreMotion / SensorManager + Madgwick/Mahony.
 */
export class SensorFusionEngine {
  private config: SensorFusionConfig;
  private samples: RawSensorSample[] = [];
  private lastLean = 0;
  private impactCount = 0;
  private gHistory: number[] = [];

  constructor(config: Partial<SensorFusionConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /** In Produktion: von nativem Sensor-Stream gefüttert */
  pushSample(sample: RawSensorSample): FusedMetrics | null {
    this.samples.push(sample);
    const cutoff = sample.t - this.config.windowSizeMs;
    this.samples = this.samples.filter((s) => s.t >= cutoff);

    if (this.samples.length < 5) return null;

    return this.compute();
  }

  private compute(): FusedMetrics {
    const latest = this.samples[this.samples.length - 1];
    const gForces = this.samples.map((s) => {
      const mag = Math.sqrt(s.ax ** 2 + s.ay ** 2 + s.az ** 2) / 9.81;
      return mag;
    });

    const gPeak = Math.max(...gForces);
    const gRms =
      Math.sqrt(gForces.reduce((sum, g) => sum + g * g, 0) / gForces.length) || 0;

    this.gHistory.push(gPeak);
    if (this.gHistory.length > 30) this.gHistory.shift();

    // Einfache Lean-Schätzung aus Accel (in Produktion: Gyro-Integration + Accel-Korrektur)
    const leanRaw = (Math.atan2(latest.ay, latest.az) * 180) / Math.PI;
    this.lastLean =
      this.config.leanFilterAlpha * leanRaw +
      (1 - this.config.leanFilterAlpha) * this.lastLean;

    const impactDetected = gPeak >= this.config.impactThresholdG;
    if (impactDetected) this.impactCount += 1;

    // Flow: niedrige Varianz + moderate G = hoher Flow
    const meanG = gForces.reduce((a, b) => a + b, 0) / gForces.length;
    const variance =
      gForces.reduce((sum, g) => sum + (g - meanG) ** 2, 0) / gForces.length;
    const flowContribution = Math.max(0, Math.min(1, 1 - variance * 2));

    return {
      timestamp: latest.t,
      gForcePeak: Math.round(gPeak * 100) / 100,
      gForceRms: Math.round(gRms * 100) / 100,
      leanAngleDeg: Math.round(Math.abs(this.lastLean) * 10) / 10,
      impactDetected,
      impactMagnitude: impactDetected ? gPeak : 0,
      flowContribution,
    };
  }

  getImpactCount() {
    return this.impactCount;
  }

  reset() {
    this.samples = [];
    this.gHistory = [];
    this.impactCount = 0;
    this.lastLean = 0;
  }
}

/**
 * Web-Simulator – erzeugt realistische Sensor-Samples.
 * Ersetzt in Produktion den nativen Sensor-Stream.
 */
export class WebSensorSimulator {
  private engine: SensorFusionEngine;
  private timer: ReturnType<typeof setInterval> | null = null;
  private startTime = 0;
  private onMetrics: ((m: FusedMetrics) => void) | null = null;

  constructor(engine?: SensorFusionEngine) {
    this.engine = engine ?? new SensorFusionEngine();
  }

  start(onMetrics: (m: FusedMetrics) => void, rateHz = 20) {
    this.onMetrics = onMetrics;
    this.startTime = Date.now();
    this.engine.reset();

    this.timer = setInterval(() => {
      const t = Date.now() - this.startTime;
      // Simuliere realistische Trail-Dynamik
      const phase = t / 1000;
      const base = 9.81;
      const noise = () => (Math.random() - 0.5) * 3;
      const bump = Math.sin(phase * 4.2) * 4 + Math.sin(phase * 11) * 2.5;
      const impactChance = Math.random() > 0.94 ? 12 + Math.random() * 8 : 0;

      const sample: RawSensorSample = {
        t,
        ax: noise() + bump * 0.3,
        ay: noise() + Math.sin(phase * 1.7) * 2,
        az: base + bump + impactChance + noise() * 0.5,
        gx: (Math.random() - 0.5) * 1.5,
        gy: (Math.random() - 0.5) * 1.2,
        gz: (Math.random() - 0.5) * 0.8,
        pressure: 1013 - phase * 0.15 + (Math.random() - 0.5),
      };

      const metrics = this.engine.pushSample(sample);
      if (metrics && this.onMetrics) this.onMetrics(metrics);
    }, 1000 / rateHz);
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  getImpactCount() {
    return this.engine.getImpactCount();
  }
}
