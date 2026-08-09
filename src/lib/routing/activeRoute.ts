import type { ActiveRoute } from "@/types/route";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { ClientRouteResult } from "@/lib/routing/profiles";
import { stepsFromDemoGeometry } from "@/lib/routing/navSteps";

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
  return {
    id: `engine-${Date.now()}`,
    name,
    distanceKm: Math.round((result.distanceM / 1000) * 10) / 10,
    elevationM: Math.round(result.distanceM * 0.03),
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
  return `${route.name} · ${route.distanceKm} km · ${route.elevationM} hm`;
}
