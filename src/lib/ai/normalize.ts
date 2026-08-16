/**
 * Defensive Chat-/Coach-Kontexte: Mobile schickt oft Teilobjekte.
 * Engines dürfen nie an fehlenden Arrays/Feldern sterben.
 */

import { categoryToBikeType } from "@/lib/catalog/slots";
import type { Bike, Ride, SensorMetrics } from "@/types";

function num(v: unknown, fallback = 0): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

export function isElectricBike(bike: Pick<Bike, "isEbike" | "category">): boolean {
  return Boolean(bike.isEbike) || bike.category === "emtb" || bike.category === "etrekking";
}

export function normalizeBike(raw: Bike | undefined | null): Bike | undefined {
  if (!raw || typeof raw !== "object") return undefined;
  const category = raw.category || "urban";
  return {
    ...raw,
    name: raw.name || "Rad",
    category,
    type: raw.type || categoryToBikeType(category),
    isActive: Boolean(raw.isActive),
    isEbike: isElectricBike(raw),
    createdAt: raw.createdAt || new Date(0).toISOString(),
    updatedAt: raw.updatedAt || raw.createdAt || new Date(0).toISOString(),
    components: Array.isArray(raw.components) ? raw.components : [],
    setups: Array.isArray(raw.setups) ? raw.setups : [],
    totalOdometerKm: num(raw.totalOdometerKm),
    totalHours: num(raw.totalHours),
  };
}

export function rideDistanceM(ride: Ride): number {
  if (typeof ride.distanceM === "number" && Number.isFinite(ride.distanceM)) {
    return ride.distanceM;
  }
  const km = (ride as { distanceKm?: number }).distanceKm;
  return typeof km === "number" && Number.isFinite(km) ? km * 1000 : 0;
}

export function rideElevationM(ride: Ride): number {
  if (typeof ride.elevationGainM === "number" && Number.isFinite(ride.elevationGainM)) {
    return ride.elevationGainM;
  }
  const hm = (ride as { elevationM?: number }).elevationM;
  return typeof hm === "number" && Number.isFinite(hm) ? hm : 0;
}

export function rideDurationSec(ride: Ride): number {
  if (typeof ride.durationSec === "number" && Number.isFinite(ride.durationSec)) {
    return ride.durationSec;
  }
  const moving = (ride as { movingTimeSec?: number }).movingTimeSec;
  return typeof moving === "number" && Number.isFinite(moving) ? moving : 0;
}

const EMPTY_METRICS: SensorMetrics = {
  gForcePeak: 0,
  gForceRms: 0,
  leanAngleMax: 0,
  impactCount: 0,
  flowScore: 0,
};

export function normalizeRide(raw: Ride | undefined | null): Ride | undefined {
  if (!raw || typeof raw !== "object") return undefined;
  const summary = raw.summaryMetrics ?? EMPTY_METRICS;
  const start =
    raw.startTime ||
    (raw as { startedAt?: string }).startedAt ||
    new Date(0).toISOString();
  return {
    ...raw,
    startTime: start,
    distanceM: rideDistanceM(raw),
    elevationGainM: rideElevationM(raw),
    durationSec: rideDurationSec(raw),
    sportType: raw.sportType || "enduro",
    summaryMetrics: {
      gForcePeak: num(summary.gForcePeak),
      gForceRms: num(summary.gForceRms),
      leanAngleMax: num(summary.leanAngleMax),
      impactCount: num(summary.impactCount),
      flowScore: num(summary.flowScore),
    },
  };
}

export function normalizeBikes(list: Bike[] | undefined): Bike[] {
  return (list ?? []).map(normalizeBike).filter((b): b is Bike => Boolean(b));
}

export function normalizeRides(list: Ride[] | undefined): Ride[] {
  return (list ?? []).map(normalizeRide).filter((r): r is Ride => Boolean(r));
}
