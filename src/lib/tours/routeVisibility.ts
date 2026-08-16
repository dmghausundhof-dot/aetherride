/**
 * Sichtbarkeit gespeicherter Touren.
 * Default privat. Kein stilles GPS in Explore/Community/Near-me.
 */

import type { RouteVisibility, SavedRoute } from "@/types/route";
import { catalogTourIdOf } from "@/lib/tours/tourAkte";

export type { RouteVisibility };

/** Filter in Mappe / Discover-Listen. */
export type VisibilityScope = "all_mine" | "private" | "shared";

export function visibilityOf(
  route: Pick<SavedRoute, "visibility"> | { visibility?: string | null }
): RouteVisibility {
  return route.visibility === "shared" ? "shared" : "private";
}

export function isShared(
  route: Pick<SavedRoute, "visibility"> | { visibility?: string | null }
): boolean {
  return visibilityOf(route) === "shared";
}

/** Stimmen: Katalog (schon öffentlich) oder eigene Freigabe. */
export function allowsStimmen(
  route: Pick<SavedRoute, "id" | "catalogTourId" | "visibility">
): boolean {
  return stimmenTourIdOf(route) != null;
}

export function stimmenTourIdOf(
  route: Pick<SavedRoute, "id" | "catalogTourId" | "visibility">
): string | null {
  const catalog = catalogTourIdOf(route);
  if (catalog) return catalog;
  if (isShared(route)) return route.id;
  return null;
}

/** Öffentliche Explore-/Community-Listen: nur freigegebene Kopien. */
export function visibleInPublicExplore(
  route: Pick<SavedRoute, "visibility">
): boolean {
  return isShared(route);
}

/** Heatmap-Beitrag aus einer gespeicherten Tour-Geometrie: nur nach Freigabe. */
export function mayContributeSavedGeometry(
  route: Pick<SavedRoute, "visibility">
): boolean {
  return isShared(route);
}

/**
 * Ride-GPS in die Heatmap: Freeride ja; private GPX-Akte nein;
 * Katalog-Join oder Freigabe ja.
 */
export function mayContributeRideTrack(
  saved: Pick<SavedRoute, "id" | "catalogTourId" | "visibility"> | undefined
): boolean {
  if (!saved) return true;
  if (isShared(saved)) return true;
  return Boolean(catalogTourIdOf(saved));
}

export function filterSavedByVisibility<T extends Pick<SavedRoute, "visibility">>(
  routes: T[],
  scope: VisibilityScope
): T[] {
  if (scope === "all_mine") return routes;
  if (scope === "shared") return routes.filter(isShared);
  return routes.filter((r) => !isShared(r));
}

/** Sammlung-Share: nur freigegebene oder Katalog-IDs (kein privates GPS). */
export function shareableRouteIds(
  routeIds: string[],
  saved: SavedRoute[]
): string[] {
  return routeIds.filter((id) => {
    const r = saved.find((x) => x.id === id);
    if (!r) return false;
    return isShared(r) || Boolean(catalogTourIdOf(r));
  });
}

export function visibilityLabel(v: RouteVisibility): string {
  return v === "shared" ? "Freigegeben" : "Privat";
}

export function shareHonesty(route: SavedRoute): string {
  const catalog = catalogTourIdOf(route);
  const hasTrack = Boolean(route.geometry?.coordinates && route.geometry.coordinates.length >= 2);
  if (catalog && !hasTrack) {
    return "Katalog-Tour ist schon öffentlich. Freigeben macht deine Akte teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.";
  }
  if (hasTrack) {
    return "Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte Spur (Koordinaten), nicht nur den Namen. Zurück auf Privat nimmt die Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du eingeloggt bist. Ohne Login gilt er nur in diesem Browser.";
  }
  return "Freigeben erzeugt einen Link mit Name und Stats — ohne Track, weil keiner gespeichert ist.";
}
