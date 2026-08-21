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
