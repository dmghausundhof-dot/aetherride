/**
 * D-60-LOOP-FILTER-01 — Rundkurs / loop filter honesty (Web / src).
 *
 * Rundkurs may only surface real closed routes — never fill with linear A→B.
 * Prefer explicit seed/catalog flags; optionally confirm geometry via
 * start≈end closure (≤200 m). Flutter/mobile owned separately by Android eng.
 */

/** Known linear pads that must never appear under Rundkurs / ~60 rails. */
const LINEAR_SEED_IDS = new Set([
  "seed-route-spree-commute",
  "seed-route-uckermark-weekend",
]);

/** Title patterns that are never honest loops (Test Agent / Prod fails). */
const LINEAR_NAME_RE =
  /alltagsrunde|spree-radweg\s*alltag|out-and-back|a\s*→\s*b|a\s*->\s*b/i;

/** Explicit catalog/seed flags that mean "honest loop". */
export function seedIsLoopFlag(seed: {
  is_loop?: boolean;
  loop?: boolean;
  closed?: boolean;
}): boolean {
  return seed.is_loop === true || seed.loop === true || seed.closed === true;
}

/**
 * Suggestion/catalog field used by Discover cards + filters.
 * Geometry (when present) wins; known linear seed ids / titles never pass.
 */
export function isHonestLoopSuggestion(route: {
  id?: string;
  name?: string;
  loop?: boolean;
  trackLngLat?: [number, number][] | null;
}): boolean {
  if (route.id && LINEAR_SEED_IDS.has(route.id)) return false;
  if (route.name && LINEAR_NAME_RE.test(route.name)) return false;
  return isHonestLoop({
    loopFlag: route.loop === true,
    trackLngLat: route.trackLngLat,
  });
}

/** Filter a list to honest loops only (Rundkurs / ~60 rails). */
export function filterHonestLoopSuggestions<
  T extends {
    id?: string;
    name?: string;
    loop?: boolean;
    trackLngLat?: [number, number][] | null;
  },
>(routes: T[]): T[] {
  return routes.filter((r) => isHonestLoopSuggestion(r));
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
 * Geometry closure: start≈end within [maxGapM] (default **200 m**).
 * Returns null when track is too short for a reliable call.
 */
export function trackIsClosedLoop(
  coords: [number, number][] | null | undefined,
  maxGapM = 200
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

/** True for directional out-and-back Quick pads („60 min · Norden“, …). */
export function isOutAndBackQuickOption(q: {
  id?: string;
  label?: string;
  reason?: string;
}): boolean {
  const id = (q.id ?? "").toLowerCase();
  if (id.startsWith("quick-")) return true;
  const reason = (q.reason ?? "").toLowerCase();
  if (reason.includes("out-and-back") || reason.includes("out and back")) {
    return true;
  }
  const label = (q.label ?? "").toLowerCase();
  return (
    /\d+\s*min\s*·\s*(norden|osten|südwest|sudwest|süden|westen)/i.test(
      q.label ?? ""
    ) ||
    label.includes("· norden") ||
    label.includes("· osten") ||
    label.includes("· südwest") ||
    label.includes("· sudwest")
  );
}

/**
 * Under Rundkurs: strip out-and-back / non-closed computed geometry from a
 * plan draft so the map cannot paint A→B as the primary suggestion.
 */
export function sanitizeDraftForRundkurs<
  T extends {
    mode?: string;
    label?: string;
    computed?: {
      geometry?: { coordinates?: [number, number][] | number[][] } | null;
      engine?: string;
    } | null;
  },
>(draft: T): T {
  const label = draft.label ?? "";
  if (isOutAndBackQuickOption({ label })) {
    return { ...draft, computed: null, label: "" };
  }
  const coords = draft.computed?.geometry?.coordinates as
    | [number, number][]
    | undefined;
  if (!coords || coords.length < 4) {
    // Quick mode without honest loop geometry → clear (no A→B pad).
    if (draft.mode === "quick") {
      return { ...draft, computed: null, label: "" };
    }
    return draft;
  }
  if (!isHonestLoop({ loopFlag: true, trackLngLat: coords })) {
    return { ...draft, computed: null, label: "" };
  }
  return draft;
}
