/**
 * Welche Touren auf Karte / Touren-Liste landen.
 * Nur echte Nähe — dünne Regionen bleiben kurz, statt fremde Landschaft
 * auf 12 Karten aufzufüllen.
 */

export const TOUR_COVERAGE_NEARBY_KM = 90;
export const TOUR_COVERAGE_MIN_LIST = 12;
export const TOUR_COVERAGE_MAX = 32;

export function pickNearbyThenFill<T>(
  items: T[],
  distanceKm: (item: T) => number,
  opts?: {
    nearbyKm?: number;
    minCount?: number;
    maxItems?: number;
  }
): T[] {
  if (items.length === 0) return [];
  const nearbyKm = opts?.nearbyKm ?? TOUR_COVERAGE_NEARBY_KM;
  const maxItems = opts?.maxItems ?? TOUR_COVERAGE_MAX;
  const nearby = items
    .filter((e) => distanceKm(e) <= nearbyKm)
    .sort((a, b) => distanceKm(a) - distanceKm(b));
  if (nearby.length === 0) return [];
  return nearby.slice(0, Math.min(maxItems, nearby.length));
}
