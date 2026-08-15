/**
 * GPS-first seed pick from bundled DACH + Berlin + Rhein-Neckar catalogs.
 * No invented tracks — ranking only.
 */

import { berlinLoopSuggestions } from "@/lib/discover/berlinLoops";
import {
  pickNearbyThenFill,
  TOUR_COVERAGE_NEARBY_KM,
} from "@/lib/discover/tourCoverage";
import { listPublicTours } from "@/lib/catalog/publicTours";
import { haversineKm } from "@/lib/routing/demoGeometry";
import {
  dachHonesty,
  dachHonestyLabel,
  pointInDach,
  type DachHonesty,
} from "./dach";

export type CoverageSeed = {
  id: string;
  title: string;
  distanceKm: number;
  durationMin: number;
  elevationM: number;
  loop: boolean;
  category: string;
  surface: string;
  center: [number, number];
  distanceFromOriginKm: number;
  source: "seed";
};

export type CoverageCatalogTour = {
  id: string;
  name: string;
  distanceKm: number;
  durationMin: number;
  elevationM: number;
  loop: boolean;
  regionSlug: string;
  center: [number, number];
  distanceFromOriginKm: number;
  source: "catalog";
};

const HEIDELBERG_RE = /heidelberg|rhein-neckar|neckarwiese|boxberg/i;

export function pickCoverageSeeds(
  lat: number,
  lng: number,
  opts?: { nearbyKm?: number; minCount?: number; maxItems?: number }
): {
  seeds: CoverageSeed[];
  nearbyCount: number;
  inDach: boolean;
  honesty: DachHonesty;
  honestyLabel: string;
} {
  const near: [number, number] = [lng, lat];
  const nearbyKm = opts?.nearbyKm ?? TOUR_COVERAGE_NEARBY_KM;
  const ranked = berlinLoopSuggestions(near).filter(
    (r) => r.center && Number.isFinite(r.distanceFromOriginKm)
  );
  const picked = pickNearbyThenFill(
    ranked,
    (r) => r.distanceFromOriginKm ?? 9999,
    {
      nearbyKm,
      minCount: opts?.minCount ?? 12,
      maxItems: opts?.maxItems ?? 16,
    }
  );
  const nearbyCount = picked.filter(
    (r) => (r.distanceFromOriginKm ?? 9999) <= nearbyKm
  ).length;
  const inDach = pointInDach(lat, lng);
  const honesty = dachHonesty({ inDach, nearbySeedCount: nearbyCount });
  return {
    seeds: picked.map((r) => ({
      id: r.id,
      title: r.name,
      distanceKm: r.distanceKm,
      durationMin: r.durationMin,
      elevationM: r.elevationM,
      loop: r.loop,
      category: r.category,
      surface: r.surface,
      center: r.center as [number, number],
      distanceFromOriginKm: r.distanceFromOriginKm ?? 9999,
      source: "seed" as const,
    })),
    nearbyCount,
    inDach,
    honesty,
    honestyLabel: dachHonestyLabel(honesty),
  };
}

export function pickCoverageCatalog(
  lat: number,
  lng: number,
  opts?: { nearbyKm?: number; maxItems?: number }
): CoverageCatalogTour[] {
  const origin: [number, number] = [lng, lat];
  const nearbyKm = opts?.nearbyKm ?? TOUR_COVERAGE_NEARBY_KM;
  const items = listPublicTours().map((t) => ({
    id: t.id,
    name: t.name,
    distanceKm: t.distanceKm,
    durationMin: t.durationMin,
    elevationM: t.elevationM,
    loop: t.loop,
    regionSlug: t.regionSlug,
    center: t.center,
    distanceFromOriginKm: Math.round(haversineKm(origin, t.center)),
    source: "catalog" as const,
  }));
  return pickNearbyThenFill(items, (t) => t.distanceFromOriginKm, {
    nearbyKm,
    minCount: 8,
    maxItems: opts?.maxItems ?? 12,
  });
}

/** True when the nearest seed is a Heidelberg/RN loop (used in GPS honesty tests). */
export function seedLooksLikeHeidelberg(id: string, title?: string): boolean {
  return HEIDELBERG_RE.test(id) || HEIDELBERG_RE.test(title ?? "");
}
