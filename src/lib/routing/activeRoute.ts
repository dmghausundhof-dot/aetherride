import type { ActiveRoute, SavedRoute } from "@/types/route";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { ClientRouteResult } from "@/lib/routing/profiles";
import { stepsFromDemoGeometry } from "@/lib/routing/navSteps";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";

export function activeRouteFromSuggestion(
  suggestion: RouteSuggestion,
  geometry?: GeoJSON.LineString | null,
  steps?: ClientRouteResult["steps"]
): ActiveRoute {
  const geom = geometry && geometry.coordinates.length >= 2 ? geometry : null;
  return {
    id: suggestion.id,
    name: suggestion.name,
    distanceKm: suggestion.distanceKm,
    elevationM: suggestion.elevationM,
    durationMin: suggestion.durationMin,
    mtbScale: suggestion.mtbScale,
    surface: suggestion.surface,
    reasons: suggestion.reasons,
    geometry: geom,
    steps: geom
      ? steps ??
        stepsFromDemoGeometry(geom.coordinates as [number, number][])
      : steps,
    source: geom ? "engine" : "suggestion",
    setAt: new Date().toISOString(),
  };
}

export function activeRouteFromEngine(
  name: string,
  result: ClientRouteResult
): ActiveRoute {
  const distanceKm = Math.round((result.distanceM / 1000) * 10) / 10;
  // Engine geometry alone has no honest ascent — 0 = unknown (display omits hm).
  return {
    id: `engine-${Date.now()}`,
    name,
    distanceKm,
    elevationM: 0,
    durationMin: Math.round(result.durationS / 60),
    geometry: result.geometry,
    steps:
      result.steps ??
      stepsFromDemoGeometry(
        result.geometry.coordinates as [number, number][]
      ),
    source: "engine",
    setAt: new Date().toISOString(),
  };
}

export function formatRouteChip(route: ActiveRoute): string {
  const elev = sanitizeElevationM(route.elevationM, route.distanceKm);
  return `${route.name} · ${formatDistanceElevation(route.distanceKm, elev)}`;
}

/** HUD nur mit echtem Track — kein stiller Tab. */
export function activeRouteFromSaved(route: SavedRoute): ActiveRoute | null {
  const coords = route.geometry?.coordinates;
  if (!coords || coords.length < 2) return null;
  return {
    id: route.id,
    name: route.name,
    distanceKm: route.distanceKm,
    elevationM: route.elevationM,
    durationMin: route.durationMin,
    mtbScale: route.mtbScale,
    surface: route.surface,
    geometry: route.geometry ?? null,
    source:
      route.source === "import"
        ? "import"
        : route.source === "recorded"
          ? "recorded"
          : "engine",
    setAt: new Date().toISOString(),
  };
}

/** Browser ride bridge needs a real polyline — pin-only stays in Plan. */
export function webRideBridgeNeedsTrack(
  coordinateCount: number | null | undefined
): boolean {
  return (coordinateCount ?? 0) >= 2;
}

/**
 * Browser ride bridge needs a library entry — not a bare `engine-*` ghost.
 * Returns a SavedRoute ready to persist + hand off when geometry is real.
 */
export function savedRouteForWebRideHandoff(opts: {
  id: string;
  name: string;
  distanceKm: number;
  elevationM?: number | null;
  durationMin: number;
  geometry: GeoJSON.LineString | null | undefined;
  source?: SavedRoute["source"];
  mtbScale?: string;
  surface?: string;
  loop?: boolean;
  reasons?: [string, string, string];
}): SavedRoute | null {
  const coords = opts.geometry?.coordinates;
  if (!coords || coords.length < 2) return null;
  if (opts.id.startsWith("engine-")) return null;
  return {
    id: opts.id,
    name: opts.name,
    distanceKm: opts.distanceKm,
    elevationM: opts.elevationM ?? 0,
    durationMin: opts.durationMin,
    mtbScale: opts.mtbScale,
    surface: opts.surface,
    loop: opts.loop,
    reasons: opts.reasons,
    savedAt: new Date().toISOString(),
    source: opts.source ?? "engine",
    geometry: {
      type: "LineString",
      coordinates: coords,
    },
  };
}

/** ActiveRoute for the bridge after a library save (never ephemeral engine-*). */
export function activeRouteForWebRideBridge(
  entry: SavedRoute | null | undefined
): ActiveRoute | null {
  if (!entry) return null;
  return activeRouteFromSaved(entry);
}
