/** Startpin für „Route hinzufügen“: GPS, sonst Kartenmitte, sonst ohne Pin. */

export type AddRouteStartSource = "gps" | "map";

export type AddRouteStartPin = {
  /** [lng, lat] */
  lngLat: [number, number];
  source: AddRouteStartSource;
};

export type DiscoverViewport = {
  lng: number;
  lat: number;
  zoom: number;
};

/** Unter diesem Zoom ist die Karte Übersicht, kein Start. */
export const MIN_LOCAL_DISCOVER_ZOOM = 9;

/** Web Discover-Kaltstart — nie Tour-Start. */
export const WEB_DISCOVER_FALLBACK: [number, number] = [8.2, 48.0];

export function isLocalDiscoverZoom(zoom: number): boolean {
  return zoom >= MIN_LOCAL_DISCOVER_ZOOM;
}

export function isPlaceholderMapCenter(lngLat: [number, number]): boolean {
  const [lng, lat] = lngLat;
  if (Math.abs(lat - 47.2) < 0.05 && Math.abs(lng - 6.5) < 0.05) return true;
  if (
    Math.abs(lat - WEB_DISCOVER_FALLBACK[1]) < 0.02 &&
    Math.abs(lng - WEB_DISCOVER_FALLBACK[0]) < 0.02
  ) {
    return true;
  }
  return false;
}

function validCoord(lng: number, lat: number): boolean {
  return (
    Number.isFinite(lng) &&
    Number.isFinite(lat) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

export function resolveAddRouteStart(opts: {
  gps?: [number, number] | null;
  map?: [number, number] | null;
}): AddRouteStartPin | null {
  const gps = opts.gps;
  if (gps && validCoord(gps[0], gps[1])) {
    return { lngLat: gps, source: "gps" };
  }
  const map = opts.map;
  if (map && validCoord(map[0], map[1]) && !isPlaceholderMapCenter(map)) {
    return { lngLat: map, source: "map" };
  }
  return null;
}

export function parseDiscoverViewport(raw: unknown): DiscoverViewport | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const lat = typeof o.lat === "number" ? o.lat : Number(o.lat);
  const lng = typeof o.lng === "number" ? o.lng : Number(o.lng);
  const zoom = typeof o.zoom === "number" ? o.zoom : Number(o.zoom);
  if (!validCoord(lng, lat)) return null;
  const z = Number.isFinite(zoom) ? zoom : 12;
  if (!isLocalDiscoverZoom(z)) return null;
  if (isPlaceholderMapCenter([lng, lat])) return null;
  return { lng, lat, zoom: z };
}
