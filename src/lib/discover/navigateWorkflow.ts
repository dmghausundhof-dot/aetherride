/**
 * Web-Navigieren — Parität zu Flutter `_openPlan` / `_PickMode.end`.
 * NearMe-Rundkurs gilt nur auf der Quick-Schiene, nicht im A→B-Plan.
 */

export type DiscoverSheetMode = "quick" | "plan" | "tours";
export type NearMeRouteMode = "loop" | "point_to_point";

export type NavigatePlaceHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
  name?: string;
};

/** Listen-Rundkurs: Filter-Chip oder NearMe, aber NearMe nur bei Quick. */
export function discoverRundkursActive(opts: {
  loopOnly: boolean;
  nearMeRouteMode: NearMeRouteMode;
  sheetMode: DiscoverSheetMode;
}): boolean {
  if (opts.loopOnly) return true;
  return opts.sheetMode === "quick" && opts.nearMeRouteMode === "loop";
}

export function shouldForceLoopOnlyFromNearMe(opts: {
  nearMeRouteMode: NearMeRouteMode;
  sheetMode: DiscoverSheetMode;
}): boolean {
  return opts.sheetMode === "quick" && opts.nearMeRouteMode === "loop";
}

/** Orts-Chip im Plan wird Ziel, sonst nur Kartenflug. */
export function placeHitAppliesAsDestination(
  sheetMode: DiscoverSheetMode
): boolean {
  return sheetMode === "plan";
}

/**
 * Explore long-press (not short-tap) opens Plan with a browse pin.
 * Flutter: `onMapLongClick` outside plan; short-tap stays trail/tour inspect.
 */
export function discoverExploreMapTapOpensPlan(opts: {
  sheetMode: DiscoverSheetMode;
  picking: boolean;
}): boolean {
  return !opts.picking && opts.sheetMode !== "plan";
}

/**
 * Deep-link `?panel=plan&tour=` should adopt into the plan editor (with track
 * when available), never leave a bare start pin without messaging.
 */
export function discoverTourDeepLinkOpensPlan(opts: {
  hasTourId: boolean;
}): boolean {
  return opts.hasTourId;
}

/**
 * One-shot deep links: apply each id once until cleared from the URL.
 * (history.replaceState alone does not update Next searchParams.)
 */
export function discoverDeepLinkShouldApply(opts: {
  id: string | null | undefined;
  alreadyApplied: string | null;
}): boolean {
  const id = opts.id?.trim() || null;
  if (!id) return false;
  return opts.alreadyApplied !== id;
}

/** Strip `tour` after a one-shot deep-link adopt so remounts do not wipe edits. */
export function discoverTourDeepLinkStripTour(href: string): string {
  try {
    const url = new URL(href, "https://aetherride.local");
    if (!url.searchParams.has("tour")) {
      return `${url.pathname}${url.search}`;
    }
    url.searchParams.delete("tour");
    const q = url.searchParams.toString();
    return q ? `${url.pathname}?${q}` : url.pathname;
  } catch {
    return href;
  }
}

/** Mappe pin-only „Losfahren“: `?panel=plan&route=` opens Plan, not Tour-Detail. */
export function discoverMappeRouteOpensPlan(opts: {
  panelPlan: boolean;
  hasRouteId: boolean;
}): boolean {
  return opts.panelPlan && opts.hasRouteId;
}

/** Strip `route` after Mappe→Plan adopt (keep panel=plan). */
export function discoverMappeDeepLinkStripRoute(href: string): string {
  try {
    const url = new URL(href, "https://aetherride.local");
    if (!url.searchParams.has("route")) {
      return `${url.pathname}${url.search}`;
    }
    url.searchParams.delete("route");
    const q = url.searchParams.toString();
    return q ? `${url.pathname}?${q}` : url.pathname;
  } catch {
    return href;
  }
}

/**
 * Navigieren öffnen: Ziel tippen/suchen, optional letzter Ort als B.
 * Start bleibt, wenn schon gesetzt — sonst übernimmt der Caller den Origin.
 */
export function beginNavigateIntent(opts: {
  hasEnd: boolean;
  lastPlace: NavigatePlaceHit | null;
  pendingHits?: NavigatePlaceHit[];
}): {
  addrTarget: "end";
  pickTarget: "end";
  destination: NavigatePlaceHit | null;
} {
  const pending = opts.pendingHits?.[0] ?? null;
  const destination = opts.hasEnd ? null : opts.lastPlace ?? pending;
  return {
    addrTarget: "end",
    pickTarget: "end",
    destination,
  };
}
