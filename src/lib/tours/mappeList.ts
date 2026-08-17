import type { SavedRoute } from "@/types/route";

export type MappeSort = "recent" | "distance" | "name";

export function savedRouteHasTrack(route: SavedRoute): boolean {
  return (route.geometry?.coordinates?.length ?? 0) >= 2;
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

export function mappeCardStats(route: SavedRoute): string {
  if (!savedRouteHasTrack(route)) return "";
  return `${route.distanceKm} km · ${route.elevationM} hm · ${route.durationMin} min`;
}
