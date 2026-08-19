/**
 * Tour-Auswahl beim Anlegen einer Fahrgruppe.
 * Eigene (auch private) zuerst; Katalog in der Nähe extra — nicht Explore.
 */

import { pickCoverageCatalog } from "@/lib/coverage/seeds";
import { canAttachCourse } from "@/lib/community/rideGroup";
import type { SavedRoute } from "@/types/route";

/** Weiter als Discover-Coverage (90 km), damit der Picker nicht bei 1–2 Pins endet. */
export const RIDE_GROUP_PICKER_NEARBY_KM = 180;
export const RIDE_GROUP_PICKER_NEARBY_MAX = 40;

export type GroupPickerOriginKind = "gps" | "map" | "saved";

export type GroupPickerOrigin = {
  lat: number;
  lng: number;
  kind: GroupPickerOriginKind;
};

export function savedRouteStart(
  route: SavedRoute
): { lat: number; lng: number } | null {
  const wp = route.waypoints?.find((w) => w.role === "start");
  if (wp) return { lat: wp.lngLat[1], lng: wp.lngLat[0] };
  const c = route.geometry?.coordinates?.[0];
  if (
    Array.isArray(c) &&
    c.length >= 2 &&
    Number.isFinite(Number(c[0])) &&
    Number.isFinite(Number(c[1]))
  ) {
    return { lat: Number(c[1]), lng: Number(c[0]) };
  }
  return null;
}

/** GPS → letzte Discover-Karte → Start der neuesten eigenen Tour. */
export function resolveGroupPickerOrigin(input: {
  gps?: { lat: number; lng: number } | null;
  map?: { lat: number; lng: number } | null;
  saved?: SavedRoute[];
}): GroupPickerOrigin | null {
  const gps = input.gps;
  if (
    gps &&
    Number.isFinite(gps.lat) &&
    Number.isFinite(gps.lng)
  ) {
    return { lat: gps.lat, lng: gps.lng, kind: "gps" };
  }
  const map = input.map;
  if (
    map &&
    Number.isFinite(map.lat) &&
    Number.isFinite(map.lng)
  ) {
    return { lat: map.lat, lng: map.lng, kind: "map" };
  }
  const saved = [...(input.saved ?? [])].sort(
    (a, b) => Date.parse(b.savedAt) - Date.parse(a.savedAt)
  );
  for (const s of saved) {
    const start = savedRouteStart(s);
    if (!start) continue;
    return { ...start, kind: "saved" };
  }
  return null;
}

export function listMineForGroupCreate(saved: SavedRoute[]): SavedRoute[] {
  return saved
    .filter((r) => canAttachCourse(r))
    .slice()
    .sort((a, b) => Date.parse(b.savedAt) - Date.parse(a.savedAt));
}

export function savedIdsForGroupPicker(saved: SavedRoute[]): string[] {
  const out: string[] = [];
  for (const r of saved) {
    if (r.id.trim()) out.push(r.id.trim());
    const catalog = r.catalogTourId?.trim();
    if (catalog) out.push(catalog);
  }
  return out;
}

export function listNearbyCatalogForGroupCreate(input: {
  origin: { lat: number; lng: number } | null;
  excludeIds: Iterable<string>;
}) {
  if (!input.origin) return [];
  const skip = new Set(
    [...input.excludeIds].map((id) => id.trim()).filter(Boolean)
  );
  return pickCoverageCatalog(input.origin.lat, input.origin.lng, {
    nearbyKm: RIDE_GROUP_PICKER_NEARBY_KM,
    maxItems: RIDE_GROUP_PICKER_NEARBY_MAX,
  }).filter((t) => !skip.has(t.id));
}

export function catalogTourAsSaved(t: {
  id: string;
  name: string;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  loop?: boolean;
}): SavedRoute {
  return {
    id: t.id,
    name: t.name,
    distanceKm: t.distanceKm,
    elevationM: t.elevationM,
    durationMin: t.durationMin,
    loop: t.loop,
    savedAt: "1970-01-01T00:00:00.000Z",
    source: "suggestion",
    catalogTourId: t.id,
  };
}
