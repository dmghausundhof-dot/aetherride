/**
 * Web Discover-Chrome — Parität zu Flutter `_komootExploreChrome`.
 * Suche, Navigieren, Umkreis, Filter. Zwei Chips, zwei Flächen.
 * Kein Sport-Rainbow. Disziplin sitzt im Filter-Sheet, Distanz im Umkreis.
 */
import {
  DEFAULT_ROUTE_FILTERS,
  type RouteFilterState,
} from "@/lib/routing/routeFilters";

/** Native zeigt `in 35 km`, solange kein Distanz-Max gesetzt ist. */
export const DEFAULT_AROUND_KM = 35;

/** ~60-Min-Linse — Discover-Default, nicht der nackte Katalog-Reset. */
export const DEFAULT_FILTER_MINUTES = 60;

export const DISCOVER_LENS_FILTERS: RouteFilterState = {
  ...DEFAULT_ROUTE_FILTERS,
  loopOnly: true,
};

export function aroundKmDisplay(maxDistanceKm: number | null): number {
  if (maxDistanceKm != null && maxDistanceKm > 0) {
    return Math.round(maxDistanceKm);
  }
  return DEFAULT_AROUND_KM;
}

/** Distanz-Max sitzt am Umkreis-Chip, nicht im Filter-Badge. */
export function aroundFilterActive(maxDistanceKm: number | null): boolean {
  return maxDistanceKm != null && maxDistanceKm > 0;
}

/** Filter zurücksetzen lässt den Umkreis in Ruhe. */
export function resetDiscoverSheetFilters(
  current: RouteFilterState,
): RouteFilterState {
  return { ...DISCOVER_LENS_FILTERS, maxDistanceKm: current.maxDistanceKm };
}

export function resetDiscoverAround(
  current: RouteFilterState,
): RouteFilterState {
  return { ...current, maxDistanceKm: null };
}

/**
 * Badge am Filter-Chip. Die 60-Min-Rundkurs-Linse zählt nicht als aktiv —
 * sonst stünde immer „Filter 1“ auf dem Hof. Distanz zählt am Umkreis.
 */
export function countActiveRouteFilters(
  filters: RouteFilterState,
  minutes: number,
  defaultMinutes = DEFAULT_FILTER_MINUTES,
): number {
  let n = 0;
  if (minutes !== defaultMinutes) n++;
  const loopIsLensDefault = minutes === defaultMinutes;
  if (loopIsLensDefault ? !filters.loopOnly : filters.loopOnly) n++;
  if (filters.scale !== "any") n++;
  if (filters.elevation !== "any") n++;
  if (filters.surfaceQuery) n++;
  if (filters.sport !== "all") n++;
  if ((filters.visibility ?? "all_mine") !== "all_mine") n++;
  return n;
}

export function matchesExploreQuery(
  route: { name: string; category?: string; reasons?: string[] },
  query: string,
): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const hay = [route.name, route.category ?? "", ...(route.reasons ?? [])]
    .join(" ")
    .toLowerCase();
  return hay.includes(q);
}
