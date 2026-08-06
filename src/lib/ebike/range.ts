/**
 * F-EBK-004 Reichweitenprognose — Physik + P1 Selbstkalibrierung
 *
 * P = (Crr·m·g·cosα + ½ρ·CdA·v² + m·g·sinα) · v
 * Wh/km = P_motor / v  (mit η_antrieb)
 *
 * Quellen:
 * - Spec-Formel F-EBK-004
 * - ebikes.ca / Kreuzotter: Crr ~0.004–0.012, CdA ~0.3–0.8
 * - DinCalculator E-bike Route: flach ~8–14 Wh/km, 6 % ~18–25 Wh/km
 * - Garage-Kopplung: Reifendruck verändert Crr messbar
 */

import type { Bike, Ride, RiderProfile } from "@/types";

export interface RangeCalibration {
  crr: number;
  cdA: number;
  riderPowerW: number;
  samples: number;
  updatedAt: string;
}

export interface RangeEstimate {
  kmLow: number;
  kmHigh: number;
  whPerKmLow: number;
  whPerKmHigh: number;
  batteryWh: number;
  confidence: "low" | "medium" | "high";
  factors: string[];
  calibrated: boolean;
}

const G = 9.81;
const RHO = 1.225;

function batteryWh(bike: Bike): number {
  const bat = bike.components.find(
    (c) => c.slot === "battery" && !c.removedAt
  );
  const fromModel = bat?.componentModelId;
  // PowerTube 800 etc. in catalog attributes — fallback
  if (fromModel === "cm-bosch-powertube-800") return 800;
  const attr = bat?.attributes.find((a) => a.key === "capacity_wh");
  return attr?.valueNum ?? 500;
}

function tirePressurePsi(bike: Bike): number {
  const t = bike.components.find((c) => c.slot === "tire_rear" && !c.removedAt);
  const p = t?.currentSettings.pressure_psi;
  return typeof p === "number" ? p : 24;
}

function baseCrr(bike: Bike): number {
  // Stollenreifen / niedriger Druck → höherer Crr (Drewanz / Praxis)
  const psi = tirePressurePsi(bike);
  let crr = bike.category === "emtb" || bike.category === "mtb_enduro" ? 0.018 : 0.012;
  if (psi < 22) crr += 0.004;
  else if (psi > 28) crr -= 0.002;
  return crr;
}

function baseCdA(category: Bike["category"]): number {
  // Unimore defaults Cd≈0.7, A≈0.5 → CdA≈0.35; MTB aufrechter
  switch (category) {
    case "road":
      return 0.32;
    case "gravel":
      return 0.36;
    case "emtb":
    case "mtb_enduro":
    case "mtb_am":
      return 0.42;
    default:
      return 0.38;
  }
}

export function defaultCalibration(
  bike: Bike,
  profile: RiderProfile
): RangeCalibration {
  return {
    crr: baseCrr(bike),
    cdA: baseCdA(bike.category),
    riderPowerW: 90 + profile.skillLevel * 15,
    samples: 0,
    updatedAt: new Date().toISOString(),
  };
}

/** Kalman-artige Ein-Schritt-Anpassung nach Ride */
export function calibrateFromRide(
  prev: RangeCalibration,
  ride: Ride,
  batteryWhUsed: number
): RangeCalibration {
  if (ride.distanceM < 2000 || batteryWhUsed < 10) return prev;
  const km = ride.distanceM / 1000;
  const observedWhPerKm = batteryWhUsed / km;
  // Ziel: Wh/km ≈ f(crr, cdA) — grobe Inversion über Mischfaktor
  const expected =
    prev.crr * 180 + prev.cdA * 40 + 200 / Math.max(8, ride.distanceM / ride.durationSec * 3.6);
  const err = observedWhPerKm - expected;
  const k = 1 / (prev.samples + 2);
  return {
    crr: Math.min(0.04, Math.max(0.006, prev.crr + k * err * 0.00008)),
    cdA: Math.min(0.6, Math.max(0.25, prev.cdA + k * err * 0.002)),
    riderPowerW: Math.min(
      250,
      Math.max(60, prev.riderPowerW + k * ((ride.motorData?.avgRiderPower ?? prev.riderPowerW) - prev.riderPowerW))
    ),
    samples: prev.samples + 1,
    updatedAt: new Date().toISOString(),
  };
}

export function estimateRange(input: {
  bike: Bike;
  profile: RiderProfile;
  calibration?: RangeCalibration;
  /** mittlere Steigung rad */
  meanGrade?: number;
  speedKmh?: number;
  socPercent?: number;
}): RangeEstimate {
  const cal = input.calibration ?? defaultCalibration(input.bike, input.profile);
  const m =
    (input.profile.riderWeightKg ?? 78) +
    (input.bike.weightKg ?? 15) +
    2; // leichtes Gepäck
  const v = (input.speedKmh ?? 22) / 3.6;
  const alpha = input.meanGrade ?? 0.03;
  const crr = cal.crr;
  const cdA = cal.cdA;

  const pRoll = crr * m * G * Math.cos(alpha) * v;
  const pAero = 0.5 * RHO * cdA * v ** 3;
  const pGrade = m * G * Math.sin(alpha) * v;
  const pTotal = pRoll + pAero + pGrade;
  const pRider = Math.min(cal.riderPowerW, pTotal * 0.55);
  const eta = 0.78;
  const pMotor = Math.max(0, (pTotal - pRider) / eta);

  const whPerKm = (pMotor / v) * (1000 / 3600); // W·s/m → Wh/km
  const wh = batteryWh(input.bike) * ((input.socPercent ?? 100) / 100);

  // Spanne: ±18 % Unsicherheit, enger mit mehr Samples
  const spread = Math.max(0.08, 0.18 - cal.samples * 0.015);
  const whLow = whPerKm * (1 - spread);
  const whHigh = whPerKm * (1 + spread);

  const factors = [
    `Crr ${crr.toFixed(3)} (Reifendruck ${tirePressurePsi(input.bike)} psi)`,
    `Cd·A ${cdA.toFixed(2)} (${input.bike.category})`,
    `Systemmasse ${m.toFixed(0)} kg · Ø-Steigung ${(alpha * 100).toFixed(1)} %`,
  ];

  return {
    kmLow: Math.round(wh / whHigh),
    kmHigh: Math.round(wh / whLow),
    whPerKmLow: Math.round(whLow * 10) / 10,
    whPerKmHigh: Math.round(whHigh * 10) / 10,
    batteryWh: Math.round(wh),
    confidence:
      cal.samples >= 5 ? "high" : cal.samples >= 2 ? "medium" : "low",
    factors,
    calibrated: cal.samples > 0,
  };
}
