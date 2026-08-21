import { haversineM } from "@/lib/routing/routeProgress";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";
import { trackHasRealElev } from "@/lib/routing/elevationAttach";
import type { SavedRoute } from "@/types/route";
import { fitTourLine } from "./tourLine";

export type MappeSort = "recent" | "distance" | "name";

export type MappeCardStatParts = {
  km: string;
  hm: string | null;
  min: string;
};

/** Echte Spur: Geometry, sonst Tour-Layer — nie eine erfundene Linie. */
export function savedRouteTrackCoords(route: SavedRoute): number[][] {
  const from = (line?: GeoJSON.LineString | null): number[][] => {
    const c = line?.coordinates;
    if (!c || c.length < 2) return [];
    const out: number[][] = [];
    for (const p of c) {
      const lng = Number(p[0]);
      const lat = Number(p[1]);
      if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
      const ele = Number(p[2]);
      out.push(
        p.length >= 3 && Number.isFinite(ele) ? [lng, lat, ele] : [lng, lat],
      );
    }
    return out.length >= 2 ? out : [];
  };
  const geo = from(route.geometry);
  if (geo.length >= 2) return geo;
  return from(route.layers?.tour);
}

export function savedRouteHasTrack(route: SavedRoute): boolean {
  return savedRouteTrackCoords(route).length >= 2;
}

/**
 * Library "Losfahren": real track → ride bridge; pin-only → Discover Plan
 * (no silent no-op).
 */
export function mappeGoRideDiscoverHref(route: SavedRoute): string | null {
  if (savedRouteHasTrack(route)) return null;
  return `/discover?panel=plan&route=${encodeURIComponent(route.id)}`;
}

/** Start pin for Mappe → Plan handoff (waypoints first, else track). */
export function mappeRoutePlanCenter(
  route: SavedRoute
): [number, number] | null {
  const start = route.waypoints?.find((w) => w.role === "start");
  if (start?.lngLat?.length === 2) return start.lngLat;
  const end = route.waypoints?.find((w) => w.role === "end");
  if (end?.lngLat?.length === 2) return end.lngLat;
  const first = savedRouteTrackCoords(route)[0];
  if (first && first.length >= 2) {
    return [Number(first[0]), Number(first[1])];
  }
  return null;
}

/** Runde nur aus der echten Spur — nie aus einem gesetzten Flag ohne Track. */
export function savedRouteIsLoop(route: SavedRoute): boolean {
  return fitTourLine(savedRouteTrackCoords(route))?.loop === true;
}

function formatMappeKm(km: number): string {
  if (!Number.isFinite(km)) return "0 km";
  if (Math.abs(km - Math.round(km)) < 1e-6) return `${Math.round(km)} km`;
  return `${km.toFixed(1)} km`;
}

export function sortMappe(input: SavedRoute[], sort: MappeSort): SavedRoute[] {
  const out = [...input];
  switch (sort) {
    case "recent":
      out.sort((a, b) => Date.parse(b.savedAt) - Date.parse(a.savedAt));
      break;
    case "distance":
      out.sort((a, b) => b.distanceKm - a.distanceKm);
      break;
    case "name":
      out.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
      break;
  }
  return out;
}

export function filterMappeQuery(input: SavedRoute[], query: string): SavedRoute[] {
  const q = query.trim().toLowerCase();
  if (!q) return input;
  return input.filter((s) => s.name.toLowerCase().includes(q));
}

export function mappeCardStatParts(route: SavedRoute): MappeCardStatParts | null {
  if (!savedRouteHasTrack(route)) return null;
  const coords = savedRouteTrackCoords(route);
  const hm = mappeElevLooksInvented(route.elevationM, route.distanceKm, {
    source: route.source,
    hasRealElev: trackHasRealElev(coords),
  })
    ? null
    : sanitizeElevationM(route.elevationM, route.distanceKm);
  return {
    km: formatMappeKm(route.distanceKm),
    hm: hm == null ? null : `${hm} hm`,
    min: `${route.durationMin} min`,
  };
}

export function mappeCardStats(route: SavedRoute): string {
  const parts = mappeCardStatParts(route);
  if (!parts) return "";
  return [parts.km, parts.hm, parts.min].filter(Boolean).join(" · ");
}

export type MappeElevOrigin = {
  source?: string;
  hasRealElev?: boolean;
};

/** Fingerabdruck von distanceM * 0.03 — nur Engine/2D-Import, nie Katalog. */
export function mappeElevLooksInvented(
  elevationM: number,
  distanceKm: number,
  origin: MappeElevOrigin = {},
): boolean {
  if (!(elevationM > 0) || !(distanceKm > 0)) return false;
  if (Math.abs(elevationM - distanceKm * 30) > 1) return false;
  switch ((origin.source ?? "").trim().toLowerCase()) {
    case "suggestion":
    case "recorded":
    case "library":
      return false;
    case "import":
      return !origin.hasRealElev;
    case "engine":
    case "":
      return true;
    default:
      return !origin.hasRealElev;
  }
}

export function mappeStoredHmNeedsReplace(
  elevationM: number,
  distanceKm: number,
  origin: MappeElevOrigin = {},
): boolean {
  if (!(elevationM > 0)) return true;
  return mappeElevLooksInvented(elevationM, distanceKm, origin);
}

/** Summe positiver Schritte. Lücken setzen den vorigen Wert zurück. */
export function mappeTrackClimbM(
  coordsLngLat: ReadonlyArray<ArrayLike<number>>,
): number | null {
  let prev: number | null = null;
  let gain = 0;
  let steps = 0;
  for (const p of coordsLngLat) {
    const elev = Number(p[2]);
    if (p.length < 3 || !Number.isFinite(elev)) {
      prev = null;
      continue;
    }
    if (prev != null) {
      const d = elev - prev;
      if (d > 0) gain += d;
      steps++;
    }
    prev = elev;
  }
  if (steps < 1 || gain <= 0) return null;
  return gain;
}

export function savedRouteNeedsElevBackfill(route: SavedRoute): boolean {
  const coords = savedRouteTrackCoords(route);
  if (coords.length < 2) return false;
  if (!trackHasRealElev(coords)) return true;
  if (
    !mappeStoredHmNeedsReplace(route.elevationM, route.distanceKm, {
      source: route.source,
      hasRealElev: true,
    })
  ) {
    return false;
  }
  return mappeTrackClimbM(coords) != null;
}

/** Catalog-hm bleibt; 0 und 3-%-Formel weichen der Messung. */
export function applyElevBackfill(
  route: SavedRoute,
  nextCoords: number[][],
  climbM: number,
): Partial<SavedRoute> | null {
  if (!trackHasRealElev(nextCoords)) return null;
  const keepCatalog = !mappeStoredHmNeedsReplace(
    route.elevationM,
    route.distanceKm,
    { source: route.source, hasRealElev: true },
  );
  const elevationM = keepCatalog
    ? route.elevationM
    : climbM > 0
      ? climbM
      : route.elevationM;
  const fromGeometry = (route.geometry?.coordinates?.length ?? 0) >= 2;
  if (fromGeometry) {
    return {
      elevationM,
      geometry: { type: "LineString", coordinates: nextCoords },
    };
  }
  return {
    elevationM,
    layers: {
      ...route.layers,
      tour: { type: "LineString", coordinates: nextCoords },
    },
  };
}

/** Chip-Text nur wenn er ein ehrliches Tag ist — keine Defaults, kein „import“. */
export function mappeFaceTag(raw?: string | null): string | null {
  const t = raw?.trim() ?? "";
  if (!t || t === "—" || t === "-") return null;
  if (t.length > 22) return null;
  switch (t.toLowerCase()) {
    case "offen":
    case "import":
    case "mixed":
    case "mixed/urban":
    case "unknown":
      return null;
  }
  return t;
}

/** Höhenkurve nur aus echter 3. Koordinate, mit sichtbarer Amplitude. */
export function mappeElevSpark(
  coordsLngLat: ReadonlyArray<ArrayLike<number>>,
  maxPoints = 32,
): number[] {
  const raw: number[] = [];
  for (const p of coordsLngLat) {
    const ele = Number(p[2]);
    if (p.length >= 3 && Number.isFinite(ele)) raw.push(ele);
  }
  if (raw.length < 4) return [];
  let minE = raw[0]!;
  let maxE = raw[0]!;
  for (const e of raw) {
    if (e < minE) minE = e;
    if (e > maxE) maxE = e;
  }
  if (maxE - minE < 15) return [];
  const pick =
    raw.length <= maxPoints
      ? raw
      : Array.from({ length: maxPoints }, (_, i) => {
          const step = (raw.length - 1) / (maxPoints - 1);
          return raw[Math.round(i * step)]!;
        });
  return pick.map((e) => (e - minE) / (maxE - minE));
}

/** Import und Aufzeichnung — nicht der Default „Geplant“. */
export function mappeSourceChip(
  source: SavedRoute["source"],
  labels: { import: string; planned?: string; recorded: string },
): string | null {
  if (source === "import") return labels.import;
  if (source === "recorded") return labels.recorded;
  return null;
}

/** Echte Spuren einer Sammlung — Reihenfolge der IDs. */
export function mappeCollectionTrackCount(
  routeIds: readonly string[],
  saved: readonly SavedRoute[],
): number {
  return mappeCollectionTracks(routeIds, saved, routeIds.length).length;
}

/** Tourenzahl, plus +N wenn der Stapel Linien weglässt. */
export function mappeCollectionRestLine(
  toursLabel: string,
  extraTracks: number,
): string {
  if (extraTracks <= 0) return toursLabel;
  return `${toursLabel} · +${extraTracks}`;
}

/** Bis zu drei echte Spuren einer Sammlung — Reihenfolge der IDs.
 */
export function mappeCollectionTracks(
  routeIds: readonly string[],
  saved: readonly SavedRoute[],
  max = 3,
): number[][][] {
  if (max <= 0) return [];
  const out: number[][][] = [];
  for (const id of routeIds) {
    const hit = saved.find((s) => s.id === id);
    if (!hit) continue;
    const coords = savedRouteTrackCoords(hit);
    if (coords.length < 2) continue;
    out.push(coords);
    if (out.length >= max) break;
  }
  return out;
}

/** Kilometer zum Start der echten Spur — nie ohne Track, nie unter 1 km. */
export function mappeStartAwayKm(
  coordsLngLat: ReadonlyArray<ArrayLike<number>>,
  userLat: number | null | undefined,
  userLng: number | null | undefined,
): number | null {
  if (coordsLngLat.length < 2 || userLat == null || userLng == null) return null;
  const start = coordsLngLat[0];
  const lng = Number(start[0]);
  const lat = Number(start[1]);
  if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
  const km = haversineM(userLat, userLng, lat, lng) / 1000;
  if (!Number.isFinite(km) || km < 1) return null;
  return Math.round(km);
}
