/**
 * GraphHopper details → honesty warnings.
 * Index-shares (vertex spans) are a proxy, not metres.
 */

import type { RoutingProfile } from "@/lib/routing/profiles";

export type GhDetailRange = [number, number, string | number | boolean];

/** Canonical DE honesty — rider UI localizes from these prefixes. */
export const HONESTY_ROAD_DE =
  "Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.";
export const HONESTY_CYCLEWAY_DE =
  "Wenig eigener Radweg — Live-Strecke oft auf der Fahrbahn.";

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
