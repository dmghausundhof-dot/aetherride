/**
 * Guard absurd ascent values (bad OSM/catalog data).
 * Typical MTB ~20–40 hm/km; >80 hm/km is almost always garbage.
 */
export function sanitizeElevationM(
  ascentM: number | null | undefined,
  distanceKm: number | null | undefined
): number | null {
  if (ascentM == null || !Number.isFinite(ascentM) || ascentM < 0) return null;
  const km = distanceKm != null && distanceKm > 0 ? distanceKm : null;
  if (km != null && ascentM / km > 80) {
    // Hide nonsense (e.g. ~1670 hm on 16 km) rather than show garbage.
    return null;
  }
  return Math.round(ascentM);
}

/** Display helper — omit hm when ascent is unknown / hidden. */
export function formatDistanceElevation(
  distanceKm: number,
  elevationM: number | null | undefined
): string {
  const base = `${distanceKm} km`;
  if (elevationM == null || !Number.isFinite(elevationM)) return base;
  return `${base} · ${elevationM} hm`;
}
