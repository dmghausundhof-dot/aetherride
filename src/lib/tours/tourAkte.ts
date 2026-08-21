/**
 * Daten-Join: SavedRoute ↔ Katalog-Stimmen ↔ Ride/Bike.
 * UI bleibt getrennt: Tour (Mein/Stimmen) ≠ Rad (Das Rad).
 */

import { getPublicTour } from "@/lib/catalog/publicTours";
import { componentWearSinceInstall } from "@/lib/garage/applyRideWear";
import type { Bike, BikeComponent } from "@/types/garage";
import type { Ride } from "@/types";
import type { SavedRoute } from "@/types/route";
import type { TourReview } from "@/lib/community/types";
import { parseStimmeTags } from "@/lib/community/stimmeTags";

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

/** Abgeschlossene Fahrt — laufende Sessions zählen nicht als „zuletzt“. */
export function lastRideForSavedRoute(
  rides: Ride[],
  route: Pick<SavedRoute, "id" | "catalogTourId">,
): Ride | null {
  const hits = ridesForSavedRoute(rides, route).filter((r) => Boolean(r.endTime));
  let best: Ride | null = null;
  for (const r of hits) {
    if (!best || Date.parse(r.startTime) > Date.parse(best.startTime)) best = r;
  }
  return best;
}

export function formatMappeDay(iso: string): string {
  const d = new Date(iso);
  if (!Number.isFinite(d.getTime())) return "";
  return `${d.getDate()}.${d.getMonth() + 1}.`;
}

export function joinMappeCaption(
  parts: Array<string | null | undefined>,
): string | undefined {
  const out = parts
    .map((p) => p?.trim())
    .filter((p): p is string => Boolean(p));
  return out.length ? out.join(" · ") : undefined;
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

export type TafelKind = "care" | "stimmen" | "mappe" | "gruppe" | "listing";

export type TafelItem = {
  id: string;
  kind: TafelKind;
  text: string;
  href: string;
};

/** Höchstens drei Zeilen — Pflege, Freigabe, Gruppe, Stimme, Mappe. Kein Feed. */
export function buildHofTafel(input: {
  care?: { text: string; href: string; overdue?: boolean } | null;
  listing?: { text: string; href: string } | null;
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
  if (input.listing?.text.trim()) {
    push({
      id: "listing",
      kind: "listing",
      text: input.listing.text,
      href: input.listing.href,
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

/** Erster Zustand-Tag der neuesten Stimme — nie aus Text geraten. */
export function latestConditionTag(
  reviews: Array<Pick<TourReview, "tourId" | "createdAt" | "tags">>,
  tourId: string | null | undefined,
): string | undefined {
  const id = tourId?.trim();
  if (!id) return undefined;
  let best: Pick<TourReview, "tourId" | "createdAt" | "tags"> | undefined;
  for (const r of reviews) {
    if (r.tourId !== id) continue;
    if (!best || Date.parse(r.createdAt) > Date.parse(best.createdAt)) best = r;
  }
  return parseStimmeTags(best?.tags)[0];
}

/** Inbox-Titel: Tourname, sonst erster Satz, nie eine Roh-ID. */
export function stimmeInboxTitle(
  routeName: string | undefined,
  body: string,
  untitled: string,
): string {
  const name = routeName?.trim();
  if (name) return name;
  const line = body.trim().split(/\n/)[0]?.trim() ?? "";
  if (!line) return untitled;
  return line.length <= 42 ? line : `${line.slice(0, 41)}…`;
}

/** Untertitel: Body nicht wiederholen, wenn er schon der Titel ist. */
export function stimmeInboxShowsBody(title: string, body: string): boolean {
  const line = body.trim().split(/\n/)[0]?.trim() ?? "";
  if (!line) return false;
  if (line === title) return false;
  if (title.endsWith("…")) {
    const stem = title.slice(0, -1);
    if (stem && line.startsWith(stem)) return false;
  }
  return true;
}
