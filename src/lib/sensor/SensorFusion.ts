/**
 * AetherRide – Sensor Fusion (Spec F-SEN-001…004)
 *
 * Produktion: 200 Hz Accel/Gyro, native Batch-Übergabe 1 s (kein Sample-für-Sample an Flutter).
 * Web-Demo: 200 Hz Batch-Simulator + Spec-treue Metriken.
 *
 * Lean: θ = atan(v · ω_yaw / g) — nicht atan2(ay,az).
 * FNI/Durchschlag: Gate G-2 kennzeichnen.
 */

import { AdaptiveImpactDetector, type ImpactEvent } from "./impacts";
import { computeLeanAngle } from "./leanAngle";
import {
  computeFniFromAz,
  detectBottomOutSuspicion,
  G2_SUSPENSION_GATE_PASSED,
  type BottomOutEvent,
  type FniWindowResult,
} from "./fni";
import {
  computeFlowScore,
  type FlowScoreResult,
  type TerrainClass,
} from "./flowScore";
import type { MountMode } from "./calibration";

export interface RawSensorSample {
  t: number; // ms
  ax: number;
  ay: number;
  az: number;
  gx: number;
  gy: number;
  gz: number; // yaw rate rad/s (device; nach Kalibrierung Bike-Hochachse)
  pressure?: number;
  /** GNSS-Geschwindigkeit m/s, interpoliert */
  speedMs?: number;
}

export interface FusedMetrics {
  timestamp: number;
  gForcePeak: number;
  gForceRms: number;
  /** Spec-Lean; null unter 8 km/h */
  leanAngleDeg: number | null;
  leanConfidence: "high" | "medium" | "low" | "unavailable";
  impactDetected: boolean;
  impactMagnitude: number;
  impactClass?: ImpactEvent["class"];
  /** Legacy-Proxy 0–1; UI soll FlowScoreResult nutzen */
  flowContribution: number;
  suspensionActivityRms?: number;
  fni?: FniWindowResult;
  bottomOut?: BottomOutEvent | null;
  saturationFlag?: boolean;
}

export interface SensorFusionConfig {
  sampleRateHz: number;
  windowSizeMs: number;
  mountMode: MountMode;
  calibrated: boolean;
  bikeFniP99?: number | null;
  terrainClass: TerrainClass;
}

const DEFAULT_CONFIG: SensorFusionConfig = {
  sampleRateHz: 200,
  windowSizeMs: 2000,
  mountMode: "UNKNOWN",
  calibrated: false,
  bikeFniP99: null,
  terrainClass: "s2",
};

export class SensorFusionEngine {
  private config: SensorFusionConfig;
  private samples: RawSensorSample[] = [];
  private impacts = new AdaptiveImpactDetector(30);
  private impactEvents: ImpactEvent[] = [];
  private speeds: number[] = [];
  private yawRates: number[] = [];
  private lastAz = 9.81;
  private jerkAcc = 0;
  private jerkN = 0;
  private brakeEvents = 0;
  private hardBrakes = 0;
  private distanceM = 0;
  private rideStart = 0;

  constructor(config: Partial<SensorFusionConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  updateConfig(patch: Partial<SensorFusionConfig>) {
    this.config = { ...this.config, ...patch };
  }

  /** Native/Web: Batch von 1 s Samples */
  pushBatch(batch: RawSensorSample[]): FusedMetrics | null {
    let last: FusedMetrics | null = null;
    for (const s of batch) {
      last = this.pushSample(s) ?? last;
    }
    return last;
  }

  pushSample(sample: RawSensorSample): FusedMetrics | null {
    if (!this.rideStart) this.rideStart = sample.t;
    this.samples.push(sample);
    const cutoff = sample.t - this.config.windowSizeMs;
    this.samples = this.samples.filter((s) => s.t >= cutoff);
    if (this.samples.length < 5) return null;
    return this.compute(sample);
  }

  private suspensionOk() {
    return (
      (this.config.mountMode === "HANDLEBAR" ||
        this.config.mountMode === "STEM") &&
      this.config.calibrated
    );
  }

  private compute(latest: RawSensorSample): FusedMetrics {
    const gForces = this.samples.map(
      (s) => Math.sqrt(s.ax ** 2 + s.ay ** 2 + s.az ** 2) / 9.81
    );
    const gPeak = Math.max(...gForces);
    const gRms =
      Math.sqrt(gForces.reduce((sum, g) => sum + g * g, 0) / gForces.length) ||
      0;

    const speedMs = latest.speedMs ?? 0;
    this.speeds.push(speedMs);
    if (this.speeds.length > 600) this.speeds.shift();
    this.yawRates.push(latest.gz);
    if (this.yawRates.length > 600) this.yawRates.shift();

    // Distanz-Proxy
    const dt = 1 / this.config.sampleRateHz;
    this.distanceM += speedMs * dt;

    // Ruck-Proxy für Flow
    const jerk = Math.abs(latest.az - this.lastAz) / dt / 9.81; // g/s
    this.lastAz = latest.az;
    this.jerkAcc += jerk * jerk;
    this.jerkN += 1;

    // Brems-Proxy: starke negative Längsbeschleunigung
    if (latest.ax < -3.5) {
      this.brakeEvents += 1;
      if (latest.ax < -6) this.hardBrakes += 1;
    }

    const lean = computeLeanAngle({
      speedMs,
      yawRateRadS: latest.gz,
    });

    const impact = this.impacts.push(latest.az, latest.t);
    if (impact) this.impactEvents.push(impact);

    const metrics: FusedMetrics = {
      timestamp: latest.t,
      gForcePeak: Math.round(gPeak * 100) / 100,
      gForceRms: Math.round(gRms * 100) / 100,
      leanAngleDeg: lean.leanDeg,
      leanConfidence: lean.confidence,
      impactDetected: !!impact,
      impactMagnitude: impact?.magnitudeG ?? 0,
      impactClass: impact?.class,
      flowContribution: 0.5,
      saturationFlag: gPeak >= 15.5,
    };

    if (this.suspensionOk()) {
      const bandRms = rmsBand(this.samples.map((s) => s.az), 1, 8, this.config.sampleRateHz);
      metrics.suspensionActivityRms = Math.round(bandRms * 100) / 100;

      const fni = computeFniFromAz(
        this.samples.map((s) => s.az - 9.81),
        this.config.sampleRateHz,
        this.config.bikeFniP99 ?? null
      );
      metrics.fni = fni;

      const bottoms = detectBottomOutSuspicion(
        this.samples.map((s) => s.az),
        this.config.sampleRateHz,
        this.samples[0]?.t ?? latest.t
      );
      metrics.bottomOut = bottoms[bottoms.length - 1] ?? null;
      // Gate: UI muss gated-Flag beachten
      if (!G2_SUSPENSION_GATE_PASSED && metrics.fni) {
        metrics.fni = { ...metrics.fni, gated: true };
      }
    }

    return metrics;
  }

  getImpactCount() {
    return this.impactEvents.length;
  }

  getImpactBreakdown() {
    const c = { light: 0, medium: 0, hard: 0, saturated: 0 };
    for (const e of this.impactEvents) {
      c[e.class] += 1;
      if (e.saturated) c.saturated += 1;
    }
    return c;
  }

  getFlowScore(durationSec: number): FlowScoreResult {
    const km = Math.max(0.01, this.distanceM / 1000);
    const jerkRms =
      this.jerkN > 0 ? Math.sqrt(this.jerkAcc / this.jerkN) : 10;
    const yawMean =
      this.yawRates.reduce((a, b) => a + b, 0) / (this.yawRates.length || 1);
    const yawVariance =
      this.yawRates.reduce((s, y) => s + (y - yawMean) ** 2, 0) /
      (this.yawRates.length || 1);

    return computeFlowScore({
      durationSec,
      terrainClass: this.config.terrainClass,
      speedsMs: this.speeds,
      jerkRms,
      brakesPerKm: this.brakeEvents / km,
      hardBrakeShare: this.brakeEvents
        ? this.hardBrakes / this.brakeEvents
        : 0,
      yawVariance,
      geometryExplainedShare: 0.45,
    });
  }

  reset() {
    this.samples = [];
    this.impacts.reset();
    this.impactEvents = [];
    this.speeds = [];
    this.yawRates = [];
    this.lastAz = 9.81;
    this.jerkAcc = 0;
    this.jerkN = 0;
    this.brakeEvents = 0;
    this.hardBrakes = 0;
    this.distanceM = 0;
    this.rideStart = 0;
  }
}

function rmsBand(
  az: number[],
  fLow: number,
  fHigh: number,
  sampleRateHz: number
): number {
  // Demo-Proxy: RMS der hochpassgefilterten Vertikalbeschleunigung
  void fLow;
  void fHigh;
  void sampleRateHz;
  if (!az.length) return 0;
  const mean = az.reduce((a, b) => a + b, 0) / az.length;
  const v = az.reduce((s, x) => s + (x - mean) ** 2, 0) / az.length;
  return Math.sqrt(v);
}

/**
 * Web-Simulator — 200 Hz in 1-s-Batches (Spec: native Ringpuffer-Übergabe).
 */
export class WebSensorSimulator {
  private engine: SensorFusionEngine;
  private timer: ReturnType<typeof setInterval> | null = null;
  private startTime = 0;
  private onMetrics: ((m: FusedMetrics) => void) | null = null;
  private speedMs = 0;

  constructor(engine?: SensorFusionEngine) {
    this.engine =
      engine ??
      new SensorFusionEngine({
        sampleRateHz: 200,
        mountMode: "HANDLEBAR",
        calibrated: true,
        terrainClass: "s2",
      });
  }

  setSpeedKmh(kmh: number) {
    this.speedMs = Math.max(0, kmh) / 3.6;
  }

  getEngine() {
    return this.engine;
  }

  /**
   * @param rateHz UI-Callback-Rate (Batches intern immer 200 Hz / 1 s)
   */
  start(onMetrics: (m: FusedMetrics) => void, _uiHz = 10) {
    void _uiHz;
    this.onMetrics = onMetrics;
    this.startTime = Date.now();
    this.engine.reset();

    // 1-s-Batches à 200 Samples
    this.timer = setInterval(() => {
      const batch: RawSensorSample[] = [];
      const batchStart = Date.now() - this.startTime;
      for (let i = 0; i < 200; i++) {
        const t = batchStart + i * 5;
        const phase = t / 1000;
        const base = 9.81;
        const noise = () => (Math.random() - 0.5) * 2.5;
        const bump = Math.sin(phase * 4.2) * 3.5 + Math.sin(phase * 11) * 2;
        const impactChance = Math.random() > 0.992 ? 18 + Math.random() * 10 : 0;
        // Gierrate für Lean: Kurven-Simulation
        const yaw =
          Math.sin(phase * 0.35) * 0.45 + (Math.random() - 0.5) * 0.05;
        const speed =
          this.speedMs || 4.5 + Math.sin(phase * 0.2) * 1.5 + Math.random() * 0.3;

        batch.push({
          t,
          ax: noise() + bump * 0.2 + (Math.random() > 0.995 ? -5 : 0),
          ay: noise() + Math.sin(phase * 1.7) * 1.5,
          az: base + bump + impactChance + noise() * 0.4,
          gx: (Math.random() - 0.5) * 1.2,
          gy: (Math.random() - 0.5) * 1.0,
          gz: yaw,
          pressure: 1013 - phase * 0.12,
          speedMs: speed,
        });
      }
      const metrics = this.engine.pushBatch(batch);
      if (metrics && this.onMetrics) this.onMetrics(metrics);
    }, 1000);
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  getImpactCount() {
    return this.engine.getImpactCount();
  }
}
