/**
 * Daten-Join: SavedRoute ↔ Katalog-Stimmen ↔ Ride/Bike.
 * UI bleibt getrennt: Tour (Mein/Stimmen) ≠ Werkstatt (Das Rad).
 */

import { getPublicTour } from "@/lib/catalog/publicTours";
import { componentWearSinceInstall } from "@/lib/garage/applyRideWear";
import type { Bike, BikeComponent } from "@/types/garage";
import type { Ride } from "@/types";
import type { SavedRoute } from "@/types/route";
import type { TourReview } from "@/lib/community/types";

export function catalogTourIdOf(
  route: Pick<SavedRoute, "id" | "catalogTourId">
): string | null {
  const explicit = route.catalogTourId?.trim();
  if (explicit) return explicit;
  return getPublicTour(route.id) ? route.id : null;
}

export function ridesForSavedRoute(
  rides: Ride[],
  route: Pick<SavedRoute, "id" | "catalogTourId">
): Ride[] {
  const catalog = catalogTourIdOf(route);
  return rides.filter((r) => {
    if (r.savedRouteId && (r.savedRouteId === route.id || r.savedRouteId === catalog)) {
      return true;
    }
    return false;
  });
}

export function componentWearLines(
  bike: Bike,
  comps: BikeComponent[]
): { slot: BikeComponent["slot"]; km: number; hours: number }[] {
  return comps
    .filter((c) => !c.removedAt)
    .map((c) => ({ slot: c.slot, ...componentWearSinceInstall(bike, c) }))
    .filter((row) => row.km > 0 || row.hours > 0);
}

export type TafelKind = "care" | "stimmen" | "mappe" | "gruppe";

export type TafelItem = {
  id: string;
  kind: TafelKind;
  text: string;
  href: string;
};

/** Höchstens drei Zeilen — Pflege, Gruppe, Stimme, Mappe. Kein Feed. */
export function buildHofTafel(input: {
  care?: { text: string; href: string; overdue?: boolean } | null;
  savedRoutes: SavedRoute[];
  myReviews: TourReview[];
  group?: { text: string; href: string } | null;
}): TafelItem[] {
  const out: TafelItem[] = [];
  const push = (item: TafelItem) => {
    if (out.length >= 3) return;
    out.push(item);
  };
  if (input.care) {
    push({
      id: "care",
      kind: "care",
      text: input.care.text,
      href: input.care.href,
    });
  }
  if (input.group?.text.trim()) {
    push({
      id: "gruppe",
      kind: "gruppe",
      text: input.group.text,
      href: input.group.href,
    });
  }
  const pending = input.myReviews.filter((r) => r.status === "pending");
  const savedJoin = input.savedRoutes.map((r) => ({
    route: r,
    catalog: catalogTourIdOf(r),
  }));
  const pendingOnSaved = pending.find((r) =>
    savedJoin.some((s) => s.catalog === r.tourId || s.route.id === r.tourId)
  );
  if (pendingOnSaved) {
    const hit = savedJoin.find(
      (s) =>
        s.catalog === pendingOnSaved.tourId ||
        s.route.id === pendingOnSaved.tourId
    );
    push({
      id: `stimmen-${pendingOnSaved.id}`,
      kind: "stimmen",
      text: `Deine Stimme zu ${hit?.route.name ?? "einer Runde"} — in Prüfung`,
      href: `/library?akte=${encodeURIComponent(hit?.route.id ?? "")}`,
    });
  }
  if (input.savedRoutes.length > 0) {
    push({
      id: "mappe",
      kind: "mappe",
      text: formatTourCount(input.savedRoutes.length, "in der Mappe"),
      href: "/library",
    });
  }
  return out;
}

/** „1 Tour“ / „2 Touren“ — kein „1 Touren“. */
export function formatTourCount(count: number, suffix = ""): string {
  const n = Number.isFinite(count) ? Math.max(0, Math.floor(count)) : 0;
  const noun = n === 1 ? "Tour" : "Touren";
  return suffix ? `${n} ${noun} ${suffix}` : `${n} ${noun}`;
}

/** Post-Ride / Library `?akte=`: Saved-ID oder Katalog-Join. */
export function resolveAkteSavedRoute(
  pendingId: string | null | undefined,
  saved: Array<Pick<SavedRoute, "id" | "catalogTourId">>
): (typeof saved)[number] | null {
  const id = pendingId?.trim();
  if (!id) return null;
  const byId = saved.find((s) => s.id === id);
  if (byId) return byId;
  return saved.find((s) => catalogTourIdOf(s) === id) ?? null;
}

export function inferCatalogTourId(routeId: string, source: SavedRoute["source"]): string | undefined {
  if (source !== "suggestion") return undefined;
  return getPublicTour(routeId) ? routeId : undefined;
}
