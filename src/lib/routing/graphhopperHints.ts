/**
 * GraphHopper details → honesty warnings.
 * Index-shares (vertex spans) are a proxy, not metres.
 */

import type { RoutingProfile } from "@/lib/routing/profiles";
import { haversineM } from "@/lib/routing/routeProgress";

export type GhDetailRange = [number, number, string | number | boolean];

/** Canonical DE honesty — rider UI localizes from these prefixes. */
export const HONESTY_ROAD_DE =
  "Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.";
export const HONESTY_CYCLEWAY_DE =
  "Wenig eigener Radweg — Live-Strecke oft auf der Fahrbahn.";
export const HONESTY_FARM_TAIL_DE =
  "Kein Weg bis zum Pin — Ziel liegt an der Straße.";
export const HONESTY_FARM_MID_DE =
  "Teile der Route folgen Feldwegen — Ziel näher an eine Straße setzen.";

const OFFROAD = new Set(["cycleway", "path", "track", "footway", "bridleway"]);
const BUSY = new Set(["motorway", "trunk", "primary", "secondary"]);
/** City: tertiary is the usual German street next to a separate cycleway. */
const CARRIAGEWAY = new Set([
  "motorway",
  "trunk",
  "primary",
  "secondary",
  "tertiary",
]);

export function detailShares(
  ranges: GhDetailRange[] | undefined
): Record<string, number> {
  const acc: Record<string, number> = {};
  let total = 0;
  for (const row of ranges ?? []) {
    const a = Number(row[0]);
    const b = Number(row[1]);
    if (!Number.isFinite(a) || !Number.isFinite(b) || b <= a) continue;
    const key = String(row[2]);
    const n = b - a;
    acc[key] = (acc[key] ?? 0) + n;
    total += n;
  }
  if (total <= 0) return {};
  const out: Record<string, number> = {};
  for (const [k, v] of Object.entries(acc)) {
    out[k] = v / total;
  }
  return out;
}

function sumKeys(shares: Record<string, number>, keys: Set<string>): number {
  let n = 0;
  for (const [k, v] of Object.entries(shares)) {
    if (keys.has(k.toLowerCase())) n += v;
  }
  return n;
}

/**
 * GraphHopper `bike` stayed on the carriageway and barely used a separate
 * cycleway — worth a rider warning and a gated corridor snap.
 */
export function cityCyclewaySnapWanted(
  roadClass: Record<string, number>
): boolean {
  if (Object.keys(roadClass).length === 0) return false;
  const cycleway = roadClass.cycleway ?? 0;
  const carriage = sumKeys(roadClass, CARRIAGEWAY);
  return cycleway < 0.15 && carriage > 0.4;
}

/**
 * Warn when GraphHopper `bike` clearly misses the sport
 * (trails not in the bike graph, little cycleway on a bike commute).
 */
export function graphhopperSurfaceWarnings(
  profile: RoutingProfile,
  roadClass: Record<string, number>
): string[] {
  if (Object.keys(roadClass).length === 0) return [];
  const offroad = sumKeys(roadClass, OFFROAD);
  const busy = sumKeys(roadClass, BUSY);
  const warnings: string[] = [];

  const trailSport =
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "downhill" ||
    profile === "emtb";
  const gravelish = profile === "gravel";
  const cityish = profile === "urban" || profile === "ebike";

  if (trailSport && offroad < 0.18 && busy > 0.45) {
    warnings.push(HONESTY_ROAD_DE);
  } else if (gravelish && offroad < 0.2 && busy > 0.5) {
    warnings.push(
      "Wenig Track/Schotter auf dieser Linie. Gravel-Wege in OSM als track/path tippen und an die Route hängen."
    );
  } else if (cityish && cityCyclewaySnapWanted(roadClass)) {
    warnings.push(HONESTY_CYCLEWAY_DE);
  }

  return warnings;
}

const FARM_SURFACE = new Set([
  "grass",
  "dirt",
  "ground",
  "earth",
  "unpaved",
  "unknown",
  "",
]);

/** City / road: last-mile TRACK through a field is not the planned ride. */
export function shouldTrimFarmTrackTail(profile: RoutingProfile): boolean {
  return profile === "urban" || profile === "road" || profile === "ebike";
}

function shareKey(shares: Record<string, number>, key: string): number {
  let n = 0;
  for (const [k, v] of Object.entries(shares)) {
    if (k.toLowerCase() === key) n += v;
  }
  return n;
}

/** GH `bike` used farm TRACK as a substantial part of a city/road A–B. */
export function urbanFarmTrackShareTooHigh(
  profile: RoutingProfile,
  roadClass: Record<string, number>
): boolean {
  if (!shouldTrimFarmTrackTail(profile)) return false;
  if (Object.keys(roadClass).length === 0) return false;
  return shareKey(roadClass, "track") > 0.08;
}

export function shouldRetryOrsForFarmGraphhopper(opts: {
  profile: RoutingProfile;
  engine: string;
  roadClass: Record<string, number>;
  viasEmpty: boolean;
  orsConfigured: boolean;
}): boolean {
  if (!opts.orsConfigured || !opts.viasEmpty) return false;
  if (opts.engine !== "graphhopper") return false;
  return urbanFarmTrackShareTooHigh(opts.profile, opts.roadClass);
}

function classAt(
  ranges: GhDetailRange[] | undefined,
  index: number
): string {
  for (const row of ranges ?? []) {
    const a = Number(row[0]);
    const b = Number(row[1]);
    if (Number.isFinite(a) && Number.isFinite(b) && index >= a && index < b) {
      return String(row[2]).toLowerCase();
    }
  }
  for (const row of ranges ?? []) {
    const a = Number(row[0]);
    const b = Number(row[1]);
    if (Number.isFinite(a) && Number.isFinite(b) && index >= a && index <= b) {
      return String(row[2]).toLowerCase();
    }
  }
  return "";
}

function isFarmEdge(road: string, surface: string): boolean {
  if (road === "track" && FARM_SURFACE.has(surface)) return true;
  if (road === "path" && FARM_SURFACE.has(surface) && surface !== "") {
    return true;
  }
  return false;
}

export function polylineLengthM(coords: [number, number][]): number {
  let n = 0;
  for (let i = 1; i < coords.length; i++) {
    n += haversineM(
      coords[i - 1][1],
      coords[i - 1][0],
      coords[i][1],
      coords[i][0]
    );
  }
  return n;
}

/**
 * Drop a grass/dirt TRACK tail when GraphHopper `bike` (no custom model)
 * still legally uses farm tracks as the last mile.
 */
export function trimFarmTrackTail(opts: {
  coordinates: [number, number][];
  roadClass?: GhDetailRange[];
  surface?: GhDetailRange[];
  maxTrimM?: number;
}): [number, number][] {
  const coords = opts.coordinates;
  if (coords.length < 4) return coords;
  if (!opts.roadClass?.length) return coords;
  const maxTrimM = opts.maxTrimM ?? 1200;
  let last = coords.length - 1;
  let trimmedM = 0;
  while (last >= 3) {
    const edgeIndex = last - 1;
    const road = classAt(opts.roadClass, edgeIndex);
    const surface = classAt(opts.surface, edgeIndex);
    if (!isFarmEdge(road, surface)) break;
    const a = coords[edgeIndex];
    const b = coords[last];
    const d = haversineM(a[1], a[0], b[1], b[0]);
    if (trimmedM + d > maxTrimM) break;
    if (last + 1 < coords.length * 0.4) break;
    trimmedM += d;
    last -= 1;
  }
  if (last >= coords.length - 1) return coords;
  if (trimmedM < 40) return coords;
  return coords.slice(0, last + 1);
}

/**
 * First-mile TRACK through a field when start was a pin without GPS.
 */
export function trimFarmTrackHead(opts: {
  coordinates: [number, number][];
  roadClass?: GhDetailRange[];
  surface?: GhDetailRange[];
  maxTrimM?: number;
}): [number, number][] {
  const coords = opts.coordinates;
  if (coords.length < 4) return coords;
  if (!opts.roadClass?.length) return coords;
  const maxTrimM = opts.maxTrimM ?? 1200;
  let first = 0;
  let trimmedM = 0;
  while (first < coords.length - 3) {
    const road = classAt(opts.roadClass, first);
    const surface = classAt(opts.surface, first);
    if (!isFarmEdge(road, surface)) break;
    const a = coords[first];
    const b = coords[first + 1];
    const d = haversineM(a[1], a[0], b[1], b[0]);
    if (trimmedM + d > maxTrimM) break;
    if (coords.length - first - 1 < coords.length * 0.4) break;
    trimmedM += d;
    first += 1;
  }
  if (first <= 0 || trimmedM < 40) return coords;
  return coords.slice(first);
}

/** Tail then head — pin last-miles, keep the street middle. */
export function trimFarmTrackEnds(opts: {
  coordinates: [number, number][];
  roadClass?: GhDetailRange[];
  surface?: GhDetailRange[];
  maxTrimM?: number;
}): [number, number][] {
  return trimFarmTrackHead({
    ...opts,
    coordinates: trimFarmTrackTail(opts),
  });
}
