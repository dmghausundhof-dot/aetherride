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

export function aroundKmDisplay(maxAwayKm: number | null): number {
  if (maxAwayKm != null && maxAwayKm > 0) {
    return Math.round(maxAwayKm);
  }
  return DEFAULT_AROUND_KM;
}

/** Umkreis sitzt am Chip, nicht im Filter-Badge. */
export function aroundFilterActive(maxAwayKm: number | null): boolean {
  return maxAwayKm != null && maxAwayKm > 0;
}

/** Filter zurücksetzen lässt den Umkreis in Ruhe. */
export function resetDiscoverSheetFilters(
  current: RouteFilterState,
): RouteFilterState {
  return { ...DEFAULT_ROUTE_FILTERS, maxAwayKm: current.maxAwayKm ?? null };
}

export function resetDiscoverAround(
  current: RouteFilterState,
): RouteFilterState {
  return { ...current, maxAwayKm: null };
}

/**
 * Badge am Filter-Chip. Umkreis zählt am eigenen Chip.
 * Entdecken startet ohne stillen 60-Min-Rundkurs.
 */
export function countActiveRouteFilters(
  filters: RouteFilterState,
  minutes: number,
  defaultMinutes = DEFAULT_FILTER_MINUTES,
): number {
  let n = 0;
  if (minutes !== defaultMinutes) n++;
  if (filters.loopOnly) n++;
  if (filters.scale !== "any") n++;
  if (filters.elevation !== "any") n++;
  if (filters.surfaceQuery) n++;
  if (filters.maxDistanceKm != null) n++;
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

/** Place chips while typing — same threshold as Flutter BrowsePlaceSearch. */
export function shouldOfferExplorePlaceHits(query: string): boolean {
  return query.trim().length >= 3;
}

/** Enter flies to a place unless the query already names a visible tour. */
export function shouldFlyExploreToPlace(
  query: string,
  visibleTourNames: Iterable<string>,
): boolean {
  const q = query.trim();
  if (q.length < 2) return false;
  const lower = q.toLowerCase();
  let strong = 0;
  for (const name of visibleTourNames) {
    const n = name.toLowerCase();
    if (n === lower || n.startsWith(lower)) strong += 1;
  }
  return strong === 0;
}
