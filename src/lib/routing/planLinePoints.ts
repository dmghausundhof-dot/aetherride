/**
 * Plan-Linie: Gipfelpunkt aus Höhenprofil + Samples für Filmstrip/Wetter.
 * Coords are GeoJSON [lng, lat].
 */

import { pointAlongRoute } from "@/lib/routing/routeProgress";

export type ElevSample = {
  distKm?: number;
  elevM?: number | null;
  elev?: number | null;
  elevation?: number | null;
  lat?: number;
  lng?: number;
  lon?: number;
};

export function sampleAlongLine(
  coords: [number, number][],
  count = 4
): [number, number][] {
  if (coords.length === 0) return [];
  if (coords.length <= count) return coords;
  const out: [number, number][] = [];
  const last = coords.length - 1;
  for (let i = 0; i < count; i++) {
    const idx = Math.round((i / Math.max(1, count - 1)) * last);
    out.push(coords[idx]);
  }
  return out;
}

function elevOf(p: ElevSample): number | null {
  const raw = p.elevM ?? p.elev ?? p.elevation;
  return typeof raw === "number" && Number.isFinite(raw) ? raw : null;
}

/** Highest point on the line. Prefers lat/lng on the sample, else distKm. */
export function maxElevAlong(
  line: [number, number][],
  points: ElevSample[]
): { lat: number; lng: number; elevM: number } | null {
  let best: ElevSample | null = null;
  let bestE = -Infinity;
  for (const p of points) {
    const e = elevOf(p);
    if (e == null || e <= bestE) continue;
    bestE = e;
    best = p;
  }
  if (!best) return null;
  const lat = best.lat;
  const lng = best.lng ?? best.lon;
  if (
    typeof lat === "number" &&
    typeof lng === "number" &&
    Number.isFinite(lat) &&
    Number.isFinite(lng)
  ) {
    return { lat, lng, elevM: bestE };
  }
  const distKm = best.distKm;
  if (typeof distKm === "number" && Number.isFinite(distKm) && line.length >= 2) {
    const pt = pointAlongRoute(line, distKm * 1000);
    return { lat: pt[1], lng: pt[0], elevM: bestE };
  }
  return null;
}
