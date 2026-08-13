/**
 * Welche Touren auf Karte / Touren-Liste landen.
 * Nähe zuerst; dünne Nähe mit den nächsten Seeds füllen — kein 3-Karten-Stub.
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
  const minCount = opts?.minCount ?? TOUR_COVERAGE_MIN_LIST;
  const maxItems = opts?.maxItems ?? TOUR_COVERAGE_MAX;
  const ranked = [...items].sort((a, b) => distanceKm(a) - distanceKm(b));
  const nearbyN = ranked.filter((e) => distanceKm(e) <= nearbyKm).length;
  const want = Math.min(maxItems, Math.max(minCount, nearbyN));
  return ranked.slice(0, Math.min(want, ranked.length));
}
