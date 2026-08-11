/**
 * Live-Geometrie für redaktionelle Tour-Ideen.
 * Baut Start/Via/Ziel aus Zentrum + Distanz und routet über die Engine.
 */

import { computeRoute, type RouteResult } from "@/lib/routing/engine";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { getPublicTour, type PublicTour } from "@/lib/catalog/publicTours";

export type TourGeometryResult = RouteResult & {
  tourId: string;
  cached: boolean;
  shape: "loop" | "out_and_back" | "point_to_point";
};

/** In-memory Cache (Serverless: pro Instanz, trotzdem spart Rate-Limits) */
const cache = new Map<
  string,
  { at: number; result: TourGeometryResult }
>();
const CACHE_TTL_MS = 1000 * 60 * 45; // 45 min

function cacheKey(tourId: string, profile: RoutingProfile): string {
  return `${tourId}|${profile}`;
}

/** Offset in Grad näherungsweise für ~km (Breite DE ~111 km/°) */
function offsetLngLat(
  center: [number, number],
  eastKm: number,
  northKm: number
): [number, number] {
  const [lng, lat] = center;
  const dLat = northKm / 111;
  const dLng = eastKm / (111 * Math.cos((lat * Math.PI) / 180));
  return [lng + dLng, lat + dLat];
}

/**
 * Wegpunkte für ungefähre Tour-Länge.
 * loop: Polygon um Zentrum, Start=Ende
 * A→B: Start westlich, Ziel östlich
 */
export function waypointsForTour(
  tour: PublicTour
): {
  from: [number, number];
  to: [number, number];
  vias: [number, number][];
  shape: TourGeometryResult["shape"];
} {
  const c = tour.center;
  const half = Math.max(1.5, Math.min(tour.distanceKm * 0.22, 18));

  if (tour.loop) {
    // Rechteck-Rundkurs: 4 Ecken, zurück zum Start
    const n = offsetLngLat(c, 0, half);
    const e = offsetLngLat(c, half, 0);
    const s = offsetLngLat(c, 0, -half * 0.85);
    const w = offsetLngLat(c, -half * 0.9, 0);
    return {
      from: w,
      to: w,
      vias: [n, e, s],
      shape: "loop",
    };
  }

  // Point-to-point entlang ~distanceKm
  const span = Math.max(2, Math.min(tour.distanceKm * 0.45, 35));
  const from = offsetLngLat(c, -span * 0.5, -span * 0.08);
  const mid = offsetLngLat(c, 0, span * 0.12);
  const to = offsetLngLat(c, span * 0.5, span * 0.05);
  return {
    from,
    to,
    vias: [mid],
    shape: "point_to_point",
  };
}

export function routingProfileForTour(tour: PublicTour): RoutingProfile {
  return profileForBikeCategory(tour.primaryCategory);
}

export async function computeTourGeometry(
  tourId: string,
  profileOverride?: RoutingProfile
): Promise<TourGeometryResult | null> {
  const tour = getPublicTour(tourId);
  if (!tour) return null;

  const profile = profileOverride ?? routingProfileForTour(tour);
  const key = cacheKey(tourId, profile);
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) {
    return { ...hit.result, cached: true };
  }

  const { from, to, vias, shape } = waypointsForTour(tour);
  const route = await computeRoute(profile, from, to, vias);

  const result: TourGeometryResult = {
    ...route,
    tourId,
    cached: false,
    shape,
    warnings: [
      ...(route.warnings ?? []),
      "Tour-Geometrie aus Live-Routing um den Tour-Pin (Annäherung, kein vermessener Community-Track).",
    ],
  };
  cache.set(key, { at: Date.now(), result });
  return result;
}

export function clearTourGeometryCache(tourId?: string) {
  if (!tourId) {
    cache.clear();
    return;
  }
  for (const k of cache.keys()) {
    if (k.startsWith(`${tourId}|`)) cache.delete(k);
  }
}
