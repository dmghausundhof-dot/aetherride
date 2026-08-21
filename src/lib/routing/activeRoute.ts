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
