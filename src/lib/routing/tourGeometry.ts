/**
 * Tour-Geometrie: redaktionelle Overrides, Live-Routing um Pin,
 * und ad-hoc aus GPS/Suche (loop / A→B).
 */

import { computeRoute, type RouteResult } from "@/lib/routing/engine";
import { isOrsConfigured } from "@/lib/routing/openRouteService";
import { profileAllowsOsmRoundTrip } from "@/lib/routing/osmRoundTrip";
import { computeOsmRoundTrip } from "@/lib/routing/osmRoundTripCompute";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { getPublicTour, type PublicTour } from "@/lib/catalog/publicTours";
import { getTourGeometryOverride } from "@/lib/catalog/tourGeometryOverrides";
import { berlinLoopSuggestions } from "@/lib/discover/berlinLoops";
import { rheinNeckarLoopSuggestions } from "@/lib/discover/rheinNeckarLoops";
import type { RouteSuggestion } from "@/lib/routing/suggestions";

export type TourGeometryResult = RouteResult & {
  tourId: string;
  cached: boolean;
  shape: "loop" | "out_and_back" | "point_to_point";
  origin?: [number, number];
  label?: string;
};

const cache = new Map<string, { at: number; result: TourGeometryResult }>();
const CACHE_TTL_MS = 1000 * 60 * 45;

function cacheKey(key: string, profile: RoutingProfile): string {
  return `${key}|${profile}`;
}

export function offsetLngLat(
  center: [number, number],
  eastKm: number,
  northKm: number
): [number, number] {
  const [lng, lat] = center;
  const dLat = northKm / 111;
  const cos = Math.cos((lat * Math.PI) / 180);
  const dLng = eastKm / (111 * Math.max(0.2, cos));
  return [lng + dLng, lat + dLat];
}

export function waypointsForTour(tour: PublicTour): {
  from: [number, number];
  to: [number, number];
  vias: [number, number][];
  shape: TourGeometryResult["shape"];
} {
  return waypointsAround(tour.center, tour.distanceKm, tour.loop);
}

export function waypointsAround(
  center: [number, number],
  distanceKm: number,
  loop: boolean
): {
  from: [number, number];
  to: [number, number];
  vias: [number, number][];
  shape: TourGeometryResult["shape"];
} {
  const half = Math.max(1.5, Math.min(distanceKm * 0.22, 18));

  if (loop) {
    const n = offsetLngLat(center, 0, half);
    const e = offsetLngLat(center, half, 0);
    const s = offsetLngLat(center, 0, -half * 0.85);
    const w = offsetLngLat(center, -half * 0.9, 0);
    return { from: w, to: w, vias: [n, e, s], shape: "loop" };
  }

  const span = Math.max(2, Math.min(distanceKm * 0.45, 35));
  const from = offsetLngLat(center, -span * 0.5, -span * 0.08);
  const mid = offsetLngLat(center, 0, span * 0.12);
  const to = offsetLngLat(center, span * 0.5, span * 0.05);
  return { from, to, vias: [mid], shape: "point_to_point" };
}

export function routingProfileForTour(tour: PublicTour): RoutingProfile {
  return profileForBikeCategory(tour.primaryCategory);
}

function p0SeedSuggestion(tourId: string): RouteSuggestion | undefined {
  return (
    berlinLoopSuggestions().find((s) => s.id === tourId) ??
    rheinNeckarLoopSuggestions().find((s) => s.id === tourId)
  );
}

/** Catalog pin vs P0 Nähe-Seed — Seeds have no PublicTour row. */
export function tourGeometrySource(
  tourId: string
): "catalog" | "p0-seed" | null {
  if (getPublicTour(tourId)) return "catalog";
  if (p0SeedSuggestion(tourId)?.center) return "p0-seed";
  return null;
}

export async function computeTourGeometry(
  tourId: string,
  profileOverride?: RoutingProfile,
  opts?: { forceLive?: boolean }
): Promise<TourGeometryResult | null> {
  const tour = getPublicTour(tourId);
  if (!tour) {
    const seed = p0SeedSuggestion(tourId);
    if (!seed?.center) return null;
    const profile =
      profileOverride ?? profileForBikeCategory(seed.category);
    const near = await computeNearGeometry({
      center: seed.center,
      profile,
      mode: seed.loop ? "loop" : "point_to_point",
      distanceKm: seed.distanceKm,
      label: seed.name,
    });
    return { ...near, tourId };
  }

  const profile = profileOverride ?? routingProfileForTour(tour);
  const key = cacheKey(`${tourId}${opts?.forceLive ? ":live" : ""}`, profile);
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) {
    return { ...hit.result, cached: true };
  }

  if (!opts?.forceLive) {
    const override = getTourGeometryOverride(tourId);
    if (override?.coordinates && override.coordinates.length >= 2) {
      const result: TourGeometryResult = {
        tourId,
        cached: false,
        shape: override.shape ?? (tour.loop ? "loop" : "point_to_point"),
        distanceM: override.distanceM ?? Math.round(tour.distanceKm * 1000),
        durationS: override.durationS ?? Math.round(tour.durationMin * 60),
        geometry: {
          type: "LineString",
          coordinates: override.coordinates,
        },
        engine: override.source?.includes("osrm") ? "osrm" : "editorial",
        profile,
        origin: tour.center,
        label: tour.name,
        warnings: [
          "Kuratierte Tour-Geometrie (redaktionell). ?forceLive=1 für Engine-Route.",
        ],
      };
      cache.set(key, { at: Date.now(), result });
      return result;
    }
  }

  const { from, to, vias, shape } = waypointsForTour(tour);
  const route = await computeRoute(profile, from, to, vias);

  const result: TourGeometryResult = {
    ...route,
    tourId,
    cached: false,
    shape,
    origin: tour.center,
    label: tour.name,
    warnings: [
      ...(route.warnings ?? []),
      "Tour-Geometrie aus Live-Routing um den Tour-Pin (Annäherung).",
    ],
  };
  cache.set(key, { at: Date.now(), result });
  return result;
}

/**
 * Ad-hoc Route ab GPS oder Suchort (kein Catalog-Tour-ID).
 * GET /api/tours/geometry?lat=&lng=&profile=road&mode=loop&distanceKm=25
 */
export async function computeNearGeometry(input: {
  center: [number, number];
  profile: RoutingProfile;
  mode?: "loop" | "point_to_point";
  distanceKm?: number;
  /** optional Ziel [lng,lat] für A→B */
  end?: [number, number];
  label?: string;
}): Promise<TourGeometryResult> {
  const profile = input.profile;
  const distanceKm = Math.min(120, Math.max(5, input.distanceKm ?? 25));
  const mode = input.mode ?? (input.end ? "point_to_point" : "loop");
  const key = cacheKey(
    `near:${input.center[0].toFixed(3)},${input.center[1].toFixed(3)}:${mode}:${distanceKm}:${input.end?.join(",") ?? ""}`,
    profile
  );
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) {
    return { ...hit.result, cached: true };
  }

  let from: [number, number];
  let to: [number, number];
  let vias: [number, number][];
  let shape: TourGeometryResult["shape"];

  if (
    mode === "loop" &&
    !input.end &&
    profileAllowsOsmRoundTrip(profile) &&
    isOrsConfigured()
  ) {
    const routed = await computeOsmRoundTrip({
      profile,
      start: input.center,
      lengthKm: distanceKm,
      seed: 1,
    });
    const result: TourGeometryResult = {
      ...routed,
      tourId: `near-${input.center[0].toFixed(3)}-${input.center[1].toFixed(3)}`,
      cached: false,
      shape: "loop",
      origin: input.center,
      label: input.label ?? "Runde ab hier",
      warnings: [
        ...(routed.warnings ?? []),
        "Route ab Standort/Suche — OSM-Wege, kein Community-Track.",
      ],
    };
    cache.set(key, { at: Date.now(), result });
    return result;
  }

  if (input.end) {
    from = input.center;
    to = input.end;
    const mid: [number, number] = [
      (from[0] + to[0]) / 2,
      (from[1] + to[1]) / 2,
    ];
    vias = [mid];
    shape = "point_to_point";
  } else {
    const w = waypointsAround(input.center, distanceKm, mode === "loop");
    from = mode === "loop" ? input.center : w.from;
    to = mode === "loop" ? input.center : w.to;
    vias =
      mode === "loop"
        ? [
            offsetLngLat(input.center, 0, distanceKm * 0.18),
            offsetLngLat(input.center, distanceKm * 0.18, 0),
            offsetLngLat(input.center, 0, -distanceKm * 0.16),
          ]
        : w.vias;
    shape = mode === "loop" ? "loop" : "point_to_point";
  }

  const route = await computeRoute(profile, from, to, vias);
  const result: TourGeometryResult = {
    ...route,
    tourId: `near-${input.center[0].toFixed(3)}-${input.center[1].toFixed(3)}`,
    cached: false,
    shape,
    origin: input.center,
    label: input.label ?? (shape === "loop" ? "Runde ab hier" : "Route ab hier"),
    warnings: [
      ...(route.warnings ?? []),
      "Route ab Standort/Suche — Live-Engine, kein Community-Track.",
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
    if (k.startsWith(`${tourId}`)) cache.delete(k);
  }
}
