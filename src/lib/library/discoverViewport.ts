/**
 * Letzter Discover-Viewport im Browser — für Platz Add-Route.
 * Nur lokale Zoomstufe, kein Kaltstart-Fallback.
 */
import {
  isLocalDiscoverZoom,
  isPlaceholderMapCenter,
  parseDiscoverViewport,
  type DiscoverViewport,
} from "./addRouteStart";

export const DISCOVER_VIEWPORT_KEY = "aetherride.discoverViewport";

export function readDiscoverViewport(): DiscoverViewport | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(DISCOVER_VIEWPORT_KEY);
    if (!raw) return null;
    return parseDiscoverViewport(JSON.parse(raw));
  } catch {
    return null;
  }
}

export function writeDiscoverViewport(view: {
  center: [number, number];
  zoom: number;
}): void {
  if (typeof window === "undefined") return;
  if (!isLocalDiscoverZoom(view.zoom)) return;
  if (isPlaceholderMapCenter(view.center)) return;
  const payload: DiscoverViewport = {
    lng: view.center[0],
    lat: view.center[1],
    zoom: view.zoom,
  };
  try {
    window.localStorage.setItem(DISCOVER_VIEWPORT_KEY, JSON.stringify(payload));
  } catch {
    // Quota / private mode — Platz bleibt ohne Kartenmitte.
  }
}
