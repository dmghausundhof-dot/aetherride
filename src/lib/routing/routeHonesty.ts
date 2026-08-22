/**
 * Honest surface + mtb:scale on a live route.
 *
 * Surface comes from GraphHopper `details.surface` or ORS extra_info.
 * S-grade comes only from OSM `mtb:scale` / `mtb:scale:imba` on nearby
 * trails — never from weather, never from ORS `traildifficulty` (SAC),
 * never from `sac_scale`.
 */

import { isHonestOsmSGrade, normalizeMtbScale } from "@/lib/coverage/osmLive";
import type { GhDetailRange } from "@/lib/routing/graphhopperHints";
import type { OrsExtras } from "@/lib/routing/openRouteService";
import { haversineM, lineLengthM } from "@/lib/routing/routeProgress";

export type SurfaceBand = {
  fromKm: number;
  toKm: number;
  surface: string | null;
};

export type ScaleBand = {
  fromKm: number;
  toKm: number;
  scale: string | null;
};

export type RouteHonesty = {
  surfaceBands: SurfaceBand[];
  scaleBands: ScaleBand[];
};

export type HonestyTrail = {
  geometry?: { coordinates?: GeoJSON.Position[] } | null;
  difficulty?: string | null;
  mtbScale?: string | null;
  surface?: string | null;
};

/** Wetter bleibt Wetter — nie eine Trail-Schwierigkeit. */
export function scaleFromConditionHint(
  hint?: string | null
): string | null {
  void hint;
  return null;
}

/** ORS traildifficulty is SAC-like. Never map onto S0–S3+. */
export function scaleFromOrsTrailDifficulty(
  value?: number | null
): string | null {
  void value;
  return null;
}

const ORS_SURFACE_OSM: Record<number, string | null> = {
  0: null,
  1: "paved",
  2: "unpaved",
  3: "asphalt",
  4: "concrete",
  5: "paving_stones",
  6: "paved",
  7: "wood",
  8: "compacted",
  9: "gravel",
  10: "earth",
  11: "grass",
  12: "sand",
  13: null,
};

const ORS_LABEL_OSM: Record<string, string> = {
  asphalt: "asphalt",
  beton: "concrete",
  pflaster: "paving_stones",
  "verdichteter schotter": "compacted",
  schotter: "gravel",
  erde: "earth",
  gras: "grass",
  sand: "sand",
  holz: "wood",
  befestigt: "paved",
  unbefestigt: "unpaved",
};

export function orsSurfaceCodeToOsm(id: number): string | null {
  return Object.prototype.hasOwnProperty.call(ORS_SURFACE_OSM, id)
    ? ORS_SURFACE_OSM[id]
    : null;
}

function vertexKm(coords: [number, number][]): number[] {
  const km = [0];
  let acc = 0;
  for (let i = 1; i < coords.length; i++) {
    acc += haversineM(
      coords[i - 1][1],
      coords[i - 1][0],
      coords[i][1],
      coords[i][0]
    );
    km.push(acc / 1000);
  }
  return km;
}

function mergeAdjacent<T extends { fromKm: number; toKm: number }>(
  bands: T[],
  same: (a: T, b: T) => boolean
): T[] {
  if (bands.length < 2) return bands;
  const out: T[] = [{ ...bands[0] }];
  for (let i = 1; i < bands.length; i++) {
    const last = out[out.length - 1];
    const cur = bands[i];
    if (same(last, cur) && cur.fromKm <= last.toKm + 0.02) {
      last.toKm = Math.max(last.toKm, cur.toKm);
    } else {
      out.push({ ...cur });
    }
  }
  return out;
}

/** Vertex ranges `[from, to, value]` → along-track km bands. */
export function surfaceBandsFromVertexRanges(
  coords: [number, number][],
  ranges: GhDetailRange[] | undefined,
  toSurface: (raw: string | number | boolean) => string | null = (raw) => {
    const s = String(raw).trim().toLowerCase();
    return s && s !== "unknown" && s !== "undefined" ? s : null;
  }
): SurfaceBand[] {
  if (coords.length < 2 || !ranges?.length) return [];
  const km = vertexKm(coords);
  const last = km[km.length - 1] ?? 0;
  const bands: SurfaceBand[] = [];
  for (const row of ranges) {
    const a = Math.max(0, Math.floor(Number(row[0])));
    const b = Math.max(a, Math.floor(Number(row[1])));
    if (!Number.isFinite(a) || !Number.isFinite(b) || b <= a) continue;
    const fromKm = km[Math.min(a, km.length - 1)] ?? 0;
    const toKm = km[Math.min(b, km.length - 1)] ?? last;
    if (!(toKm > fromKm + 0.005)) continue;
    bands.push({ fromKm, toKm, surface: toSurface(row[2]) });
  }
  bands.sort((x, y) => x.fromKm - y.fromKm);
  return mergeAdjacent(bands, (p, n) => p.surface === n.surface);
}

export function clipBandsToKm(
  bands: SurfaceBand[],
  fromKm: number,
  toKm: number
): SurfaceBand[] {
  const out: SurfaceBand[] = [];
  for (const b of bands) {
    const lo = Math.max(b.fromKm, fromKm);
    const hi = Math.min(b.toKm, toKm);
    if (hi - lo < 0.005) continue;
    out.push({ fromKm: lo, toKm: hi, surface: b.surface });
  }
  return out;
}

export function shiftSurfaceBands(bands: SurfaceBand[], deltaKm: number): SurfaceBand[] {
  if (!deltaKm) return bands;
  return bands.map((b) => ({
    ...b,
    fromKm: Math.max(0, b.fromKm + deltaKm),
    toKm: Math.max(0, b.toKm + deltaKm),
  }));
}

/** Farm-trim: remap GH surface onto the kept polyline. */
export function surfaceBandsAfterTrim(
  original: [number, number][],
  trimmed: [number, number][],
  ranges: GhDetailRange[] | undefined
): SurfaceBand[] {
  const bands = surfaceBandsFromVertexRanges(original, ranges);
  if (!bands.length) return [];
  if (original.length === trimmed.length) return bands;
  const start = trimmed[0];
  let first = 0;
  for (let i = 0; i < original.length; i++) {
    if (original[i][0] === start[0] && original[i][1] === start[1]) {
      first = i;
      break;
    }
  }
  const km = vertexKm(original);
  const headKm = km[first] ?? 0;
  const remainKm = lineLengthM(trimmed) / 1000;
  return shiftSurfaceBands(
    clipBandsToKm(bands, headKm, headKm + remainKm),
    -headKm
  );
}

export function surfaceBandsFromOrs(
  extras: OrsExtras | undefined,
  coords: [number, number][]
): SurfaceBand[] {
  if (!extras || coords.length < 2) return [];
  if (extras.surfaceRanges?.length) {
    const mapped: GhDetailRange[] = extras.surfaceRanges.map((r) => [
      r[0],
      r[1],
      orsSurfaceCodeToOsm(r[2]) ?? "",
    ]);
    return surfaceBandsFromVertexRanges(coords, mapped, (raw) => {
      const s = String(raw).trim();
      return s || null;
    });
  }
  const top = extras.surfaces[0];
  if (!top) return [];
  const key =
    ORS_LABEL_OSM[top.label.trim().toLowerCase()] ??
    orsSurfaceCodeToOsm(top.id);
  if (!key) return [];
  const totalKm = lineLengthM(coords) / 1000;
  if (totalKm < 0.05) return [];
  return [{ fromKm: 0, toKm: totalKm, surface: key }];
}

const SAMPLE_STEP_M = 80;
const TRAIL_SNAP_M = 28;

function trailHonestScale(t: HonestyTrail): string | null {
  const raw = (t.mtbScale ?? t.difficulty ?? "").trim();
  if (!raw) return null;
  const norm = normalizeMtbScale(raw);
  return isHonestOsmSGrade(norm) ? norm : null;
}

function nearestTrailAt(
  lng: number,
  lat: number,
  trails: HonestyTrail[]
): HonestyTrail | null {
  let best: HonestyTrail | null = null;
  let bestM = TRAIL_SNAP_M;
  for (const t of trails) {
    const coords = (t.geometry?.coordinates ?? []) as [number, number][];
    if (coords.length < 2) continue;
    const step = Math.max(1, Math.floor(coords.length / 36));
    for (let i = 0; i < coords.length; i += step) {
      const d = haversineM(lat, lng, coords[i][1], coords[i][0]);
      if (d < bestM) {
        bestM = d;
        best = t;
      }
    }
  }
  return best;
}

/** Project nearby OSM trails onto the route. Unmatched stays null. */
export function honestyFromOsmTrails(
  coords: [number, number][],
  trails: HonestyTrail[]
): RouteHonesty {
  if (coords.length < 2 || trails.length === 0) {
    return { surfaceBands: [], scaleBands: [] };
  }
  const totalM = lineLengthM(coords);
  if (totalM < 40) return { surfaceBands: [], scaleBands: [] };
  const samples: { km: number; surface: string | null; scale: string | null }[] =
    [];
  let walked = 0;
  let nextAt = 0;
  const pushAt = (i: number, km: number) => {
    const hit = nearestTrailAt(coords[i][0], coords[i][1], trails);
    samples.push({
      km,
      surface: hit?.surface?.trim().toLowerCase() || null,
      scale: hit ? trailHonestScale(hit) : null,
    });
  };
  pushAt(0, 0);
  for (let i = 1; i < coords.length; i++) {
    walked += haversineM(
      coords[i - 1][1],
      coords[i - 1][0],
      coords[i][1],
      coords[i][0]
    );
    if (walked + 0.5 >= nextAt + SAMPLE_STEP_M || i === coords.length - 1) {
      nextAt = walked;
      pushAt(i, walked / 1000);
    }
  }
  const surfaceBands: SurfaceBand[] = [];
  const scaleBands: ScaleBand[] = [];
  for (let i = 0; i < samples.length - 1; i++) {
    const a = samples[i];
    const b = samples[i + 1];
    if (b.km - a.km < 0.005) continue;
    surfaceBands.push({ fromKm: a.km, toKm: b.km, surface: a.surface });
    scaleBands.push({ fromKm: a.km, toKm: b.km, scale: a.scale });
  }
  return {
    surfaceBands: mergeAdjacent(surfaceBands, (p, n) => p.surface === n.surface),
    scaleBands: mergeAdjacent(scaleBands, (p, n) => p.scale === n.scale),
  };
}

export function dominantHonestScale(bands: ScaleBand[]): string | null {
  const kmBy = new Map<string, number>();
  let known = 0;
  for (const b of bands) {
    const s = (b.scale ?? "").trim();
    if (!isHonestOsmSGrade(s)) continue;
    const km = Math.max(0, b.toKm - b.fromKm);
    if (km <= 0) continue;
    kmBy.set(s, (kmBy.get(s) ?? 0) + km);
    known += km;
  }
  if (known < 0.08) return null;
  let best: string | null = null;
  let bestKm = 0;
  for (const [k, km] of kmBy) {
    if (km > bestKm) {
      best = k;
      bestKm = km;
    }
  }
  return best;
}

export function attachRouteHonesty<
  T extends {
    geometry?: GeoJSON.LineString | null;
    surfaceBands?: SurfaceBand[];
    scaleBands?: ScaleBand[];
  },
>(result: T, opts?: { trails?: HonestyTrail[] }): T {
  const coords = (result.geometry?.coordinates ?? []) as [number, number][];
  const fromTrails = honestyFromOsmTrails(coords, opts?.trails ?? []);
  return {
    ...result,
    surfaceBands:
      result.surfaceBands && result.surfaceBands.length > 0
        ? result.surfaceBands
        : fromTrails.surfaceBands,
    scaleBands:
      result.scaleBands && result.scaleBands.length > 0
        ? result.scaleBands
        : fromTrails.scaleBands,
  };
}

export function mergeHonestyIntoElevation<
  T extends { surfaceBands: SurfaceBand[]; scaleBands: ScaleBand[] },
>(elev: T, honesty: RouteHonesty): T {
  const elevSurfKnown = elev.surfaceBands.some((b) => (b.surface ?? "").trim());
  const elevScaleKnown = elev.scaleBands.some((b) =>
    isHonestOsmSGrade((b.scale ?? "").trim())
  );
  return {
    ...elev,
    surfaceBands: elevSurfKnown ? elev.surfaceBands : honesty.surfaceBands,
    scaleBands: elevScaleKnown ? elev.scaleBands : honesty.scaleBands,
  };
}

/** Auto-recompute owns A+B. Manual CTA only after a failed pass. */
export function planManualComputeVisible(opts: {
  hasStart: boolean;
  hasEnd: boolean;
  routingBusy: boolean;
  hasComputed: boolean;
}): boolean {
  return (
    opts.hasStart && opts.hasEnd && !opts.routingBusy && !opts.hasComputed
  );
}

export const SCALE_RIBBON_COLOR: Record<string, string> = {
  S0: "#8BC34A",
  S1: "#F9A825",
  S2: "#EF6C00",
  S3: "#C62828",
  "S3+": "#B71C1C",
};
