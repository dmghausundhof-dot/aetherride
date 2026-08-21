/**
 * Die Linie ist das Foto.
 *
 * Komoot/Strava zeigen ein Hero-Foto oder Kacheln. FlowLine zeigt die echte
 * Spur — orange auf Charcoal, ohne erfundenes Höhenprofil und ohne Stockfoto.
 * Kein Track → null (UI nimmt das gestrichelte No-Track-SVG).
 */

export type LngLat = [number, number];

export type TourLinePoint = { x: number; y: number };

export type TourLineFit = {
  d: string;
  start: TourLinePoint;
  end: TourLinePoint;
  loop: boolean;
  pointCount: number;
};

export const TOUR_LINE_SIZE = 64;
export const TOUR_LINE_PAD = 8;
export const TOUR_LINE_MAX_POINTS = 64;
/** Projected start/end closer than this (in px at SIZE) counts as a loop. */
export const TOUR_LINE_LOOP_PX = 3;

export function downsampleLngLats(
  coords: LngLat[],
  max = TOUR_LINE_MAX_POINTS,
): LngLat[] {
  if (coords.length <= max) return coords;
  const step = (coords.length - 1) / (max - 1);
  const out: LngLat[] = [];
  for (let i = 0; i < max; i++) {
    const p = coords[Math.round(i * step)];
    if (p) out.push([Number(p[0]), Number(p[1])]);
  }
  return out;
}

function asLngLat(raw: ArrayLike<number>): LngLat | null {
  if (raw.length < 2) return null;
  const lng = Number(raw[0]);
  const lat = Number(raw[1]);
  if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
  return [lng, lat];
}

export function fitTourLine(
  raw: ReadonlyArray<ArrayLike<number>>,
  width = TOUR_LINE_SIZE,
  height = width,
  pad = TOUR_LINE_PAD,
): TourLineFit | null {
  const coords: LngLat[] = [];
  for (const p of raw) {
    const hit = asLngLat(p);
    if (hit) coords.push(hit);
  }
  if (coords.length < 2) return null;
  const sampled = downsampleLngLats(coords);

  let minLng = Infinity;
  let maxLng = -Infinity;
  let minLat = Infinity;
  let maxLat = -Infinity;
  for (const [lng, lat] of sampled) {
    if (lng < minLng) minLng = lng;
    if (lng > maxLng) maxLng = lng;
    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
  }
  const midLat = (minLat + maxLat) / 2;
  const midLng = (minLng + maxLng) / 2;
  const cosLat = Math.min(1, Math.max(0.05, Math.abs(Math.cos((midLat * Math.PI) / 180))));
  const wDeg = Math.max((maxLng - minLng) * cosLat, 1e-9);
  const hDeg = Math.max(maxLat - minLat, 1e-9);
  const scale = Math.min((width - pad * 2) / wDeg, (height - pad * 2) / hDeg);

  const points: TourLinePoint[] = sampled.map(([lng, lat]) => ({
    x: width / 2 + (lng - midLng) * cosLat * scale,
    y: height / 2 + (midLat - lat) * scale,
  }));

  const start = points[0];
  const end = points[points.length - 1];
  if (!start || !end) return null;
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const loop = Math.hypot(dx, dy) < TOUR_LINE_LOOP_PX;

  const d = points
    .map((p, i) => `${i === 0 ? "M" : "L"}${round(p.x)} ${round(p.y)}`)
    .join(" ");

  return { d, start, end, loop, pointCount: points.length };
}

function round(n: number): string {
  return (Math.round(n * 100) / 100).toFixed(2);
}
