/**
 * Loop honesty for Discover (D-60-02 / Test Latte #3).
 *
 * Rundkurs / loop filter may only surface real closed routes — never fill
 * with linear A→B tours. Prefer explicit seed/catalog flags; optionally
 * confirm geometry via start≈end closure.
 */

/** Explicit catalog/seed flags that mean "honest loop". */
export function seedIsLoopFlag(seed: {
  is_loop?: boolean;
  loop?: boolean;
  closed?: boolean;
}): boolean {
  return seed.is_loop === true || seed.loop === true || seed.closed === true;
}

/** Suggestion/catalog field used by Discover cards + filters. */
export function isHonestLoopSuggestion(route: { loop?: boolean }): boolean {
  return route.loop === true;
}

function haversineM(
  lng1: number,
  lat1: number,
  lng2: number,
  lat2: number
): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Geometry closure: start≈end within [maxGapM] (default 300 m = upper 150–300 m band).
 * Returns null when track is too short for a reliable call.
 */
export function trackIsClosedLoop(
  coords: [number, number][] | null | undefined,
  maxGapM = 300
): boolean | null {
  if (!coords || coords.length < 4) return null;
  let lengthM = 0;
  for (let i = 1; i < coords.length; i++) {
    const a = coords[i - 1];
    const b = coords[i];
    lengthM += haversineM(a[0], a[1], b[0], b[1]);
  }
  if (lengthM < 1000) return null;
  const first = coords[0];
  const last = coords[coords.length - 1];
  const gapM = haversineM(first[0], first[1], last[0], last[1]);
  const tol = Math.max(maxGapM, lengthM * 0.05);
  return gapM < tol;
}

/**
 * Honest loop for filter: geometry wins when known; else explicit flag.
 * Point-to-point geometry never passes even if a seed lied with is_loop.
 */
export function isHonestLoop(opts: {
  loopFlag?: boolean;
  trackLngLat?: [number, number][] | null;
  maxGapM?: number;
}): boolean {
  const shape = trackIsClosedLoop(opts.trackLngLat, opts.maxGapM);
  if (shape === true) return true;
  if (shape === false) return false;
  return opts.loopFlag === true;
}
