/**
 * Remembered Navigieren destination — chip offer, never auto-restore.
 */

import { haversineM } from "@/lib/routing/routeProgress";

export const LAST_PLAN_DEST_KEY = "flowline.last_plan_dest";
export const LAST_PLAN_DEST_DISMISS_KEY = "flowline.last_plan_dest_dismissed";

export const LAST_PLAN_DEST_MAX_KM = 80;
const NEAR_MIN_M = 40;
const PAN_SPLIT_M = 40_000;

export type LastPlanDest = { lat: number; lng: number; label?: string };

export function parseLastPlanDest(raw: unknown): LastPlanDest | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const lat = typeof o.lat === "number" ? o.lat : Number(o.lat);
  const lng = typeof o.lng === "number" ? o.lng : Number(o.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  const label = typeof o.label === "string" ? o.label.trim() : "";
  return { lat, lng, ...(label ? { label } : {}) };
}

export function lastPlanDestCoordsMatch(
  a: LastPlanDest | null | undefined,
  b: LastPlanDest | null | undefined,
): boolean {
  if (!a || !b) return false;
  return Math.abs(a.lat - b.lat) < 1e-5 && Math.abs(a.lng - b.lng) < 1e-5;
}

export function lastPlanDestWorthRemembering(opts: {
  destLat: number;
  destLng: number;
  originLat?: number | null;
  originLng?: number | null;
}): boolean {
  if (Math.abs(opts.destLat) > 90 || Math.abs(opts.destLng) > 180) return false;
  if (opts.originLat == null || opts.originLng == null) return true;
  return (
    haversineM(opts.destLat, opts.destLng, opts.originLat, opts.originLng) >=
    NEAR_MIN_M
  );
}

export function lastPlanDestIsNearby(opts: {
  destLat: number;
  destLng: number;
  gpsLat?: number | null;
  gpsLng?: number | null;
  viewLat?: number | null;
  viewLng?: number | null;
  maxKm?: number;
}): boolean {
  if (Math.abs(opts.destLat) > 90 || Math.abs(opts.destLng) > 180) return false;
  const maxM = (opts.maxKm ?? LAST_PLAN_DEST_MAX_KM) * 1000;
  const near = (lat?: number | null, lng?: number | null) => {
    if (lat == null || lng == null) return false;
    const m = haversineM(opts.destLat, opts.destLng, lat, lng);
    return m >= NEAR_MIN_M && m <= maxM;
  };
  const gpsNear = near(opts.gpsLat, opts.gpsLng);
  const viewNear = near(opts.viewLat, opts.viewLng);
  if (
    opts.gpsLat != null &&
    opts.gpsLng != null &&
    opts.viewLat != null &&
    opts.viewLng != null &&
    haversineM(opts.gpsLat, opts.gpsLng, opts.viewLat, opts.viewLng) >
      PAN_SPLIT_M
  ) {
    return viewNear;
  }
  return gpsNear || viewNear;
}

export function lastPlanDestChipName(
  savedLabel: string | undefined | null,
  maxNameChars = 28,
): string {
  const raw = savedLabel?.trim() ?? "";
  if (!raw) return "";
  if (raw.length <= maxNameChars) return raw;
  return `${raw.slice(0, maxNameChars - 1)}…`;
}

export function lastPlanDestShouldOffer(opts: {
  saved: LastPlanDest | null;
  dismissed: LastPlanDest | null;
  hasEnd: boolean;
  gpsLat?: number | null;
  gpsLng?: number | null;
  viewLat?: number | null;
  viewLng?: number | null;
}): LastPlanDest | null {
  if (opts.hasEnd || !opts.saved) return null;
  if (lastPlanDestCoordsMatch(opts.saved, opts.dismissed)) return null;
  if (
    !lastPlanDestIsNearby({
      destLat: opts.saved.lat,
      destLng: opts.saved.lng,
      gpsLat: opts.gpsLat,
      gpsLng: opts.gpsLng,
      viewLat: opts.viewLat,
      viewLng: opts.viewLng,
    })
  ) {
    return null;
  }
  return opts.saved;
}

function readJson(key: string): unknown {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return null;
    return JSON.parse(raw) as unknown;
  } catch {
    return null;
  }
}

function writeJson(key: string, value: unknown): void {
  if (typeof window === "undefined") return;
  try {
    if (value == null) window.localStorage.removeItem(key);
    else window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* quota / private mode */
  }
}

export function loadLastPlanDest(): LastPlanDest | null {
  return parseLastPlanDest(readJson(LAST_PLAN_DEST_KEY));
}

export function saveLastPlanDest(dest: LastPlanDest): void {
  writeJson(LAST_PLAN_DEST_KEY, dest);
  writeJson(LAST_PLAN_DEST_DISMISS_KEY, null);
}

export function loadLastPlanDestDismissed(): LastPlanDest | null {
  return parseLastPlanDest(readJson(LAST_PLAN_DEST_DISMISS_KEY));
}

export function dismissLastPlanDest(dest: LastPlanDest): void {
  writeJson(LAST_PLAN_DEST_DISMISS_KEY, { lat: dest.lat, lng: dest.lng });
}
