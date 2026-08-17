/**
 * User-Ort nur mit Ride-Beweis: Punkt muss auf der mitgeschickten Spur liegen.
 */

import { projectOntoRoute, pointAlongRoute } from "@/lib/routing/routeProgress";

export const PLACE_SNAP_MAX_M = 80;

export type TrackLngLat = [number, number];

export function parseTrackSamples(raw: unknown, max = 40): TrackLngLat[] {
  if (!Array.isArray(raw)) return [];
  const all: TrackLngLat[] = [];
  for (const p of raw) {
    if (!Array.isArray(p) || p.length < 2) continue;
    const lng = Number(p[0]);
    const lat = Number(p[1]);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) continue;
    all.push([lng, lat]);
  }
  if (all.length <= max) return all;
  const out: TrackLngLat[] = [];
  for (let i = 0; i < max; i++) {
    const idx =
      i === max - 1
        ? all.length - 1
        : Math.round((i * (all.length - 1)) / (max - 1));
    const pt = all[idx];
    const last = out[out.length - 1];
    if (last && last[0] === pt[0] && last[1] === pt[1]) continue;
    out.push(pt);
  }
  return out;
}

export function snapPlaceOntoTrack(
  lat: number,
  lng: number,
  track: TrackLngLat[],
  maxOffM = PLACE_SNAP_MAX_M
): { lat: number; lng: number; alongM: number; offM: number } | null {
  if (track.length < 2) return null;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const p = projectOntoRoute(track, lat, lng);
  if (p.crossTrackM > maxOffM) return null;
  const pt = pointAlongRoute(track, p.distanceAlongM);
  return {
    lng: pt[0],
    lat: pt[1],
    alongM: p.distanceAlongM,
    offM: p.crossTrackM,
  };
}
