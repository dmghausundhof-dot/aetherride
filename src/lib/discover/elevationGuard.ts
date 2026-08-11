/**
 * Guard absurd / unknown ascent values (bad OSM/catalog data).
 * Typical road/urban ~10–30 hm/km; >50 hm/km on Discover is almost always garbage.
 * 0 is treated as unknown (seed sentinel after sanitize → omit on list + panel).
 */
export function sanitizeElevationM(
  ascentM: number | null | undefined,
  distanceKm: number | null | undefined
): number | null {
  if (ascentM == null || !Number.isFinite(ascentM) || ascentM <= 0) return null;
  const km = distanceKm != null && distanceKm > 0 ? distanceKm : null;
  if (km != null && ascentM / km > 50) {
    // Hide nonsense (e.g. 518 hm / 6.9 km ≈ 75 hm/km, or ~1670/16) rather than show garbage.
    return null;
  }
  return Math.round(ascentM);
}

/** Display helper — omit hm when ascent is unknown / hidden (list ↔ panel parity). */
export function formatDistanceElevation(
  distanceKm: number,
  elevationM: number | null | undefined
): string {
  const base = `${distanceKm} km`;
  const elev = sanitizeElevationM(
    elevationM,
    distanceKm > 0 ? distanceKm : null
  );
  if (elev == null) return base;
  return `${base} · ${elev} hm`;
}
