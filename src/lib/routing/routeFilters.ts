import type { RouteSuggestion } from "@/lib/routing/suggestions";

export type ScaleChip = "any" | "easy" | "mid" | "hard" | "road";
export type ElevationChip = "any" | "flat" | "hilly" | "alpine";

export interface RouteFilterState {
  loopOnly: boolean;
  scale: ScaleChip;
  elevation: ElevationChip;
  surfaceQuery: string | null;
}

export const DEFAULT_ROUTE_FILTERS: RouteFilterState = {
  loopOnly: false,
  scale: "any",
  elevation: "any",
  surfaceQuery: null,
};

function scaleMatches(mtbScale: string, chip: ScaleChip): boolean {
  if (chip === "any") return true;
  if (chip === "road") return mtbScale === "—" || mtbScale.startsWith("T");
  const nums = [...mtbScale.matchAll(/S(\d)/gi)].map((m) => Number(m[1]));
  if (nums.length === 0) return chip === "easy";
  const max = Math.max(...nums);
  if (chip === "easy") return max <= 1;
  if (chip === "mid") return max >= 1 && max <= 2;
  return max >= 3;
}

function elevationMatches(hm: number, chip: ElevationChip): boolean {
  if (chip === "any") return true;
  if (chip === "flat") return hm < 400;
  if (chip === "hilly") return hm >= 400 && hm < 1100;
  return hm >= 1100;
}

export function filterRouteSuggestions(
  routes: RouteSuggestion[],
  filters: RouteFilterState
): RouteSuggestion[] {
  return routes.filter((r) => {
    if (filters.loopOnly && !r.loop) return false;
    if (!scaleMatches(r.mtbScale, filters.scale)) return false;
    if (!elevationMatches(r.elevationM, filters.elevation)) return false;
    if (filters.surfaceQuery) {
      const q = filters.surfaceQuery.toLowerCase();
      if (!r.surface.toLowerCase().includes(q)) return false;
    }
    return true;
  });
}

export const SCALE_OPTIONS: { id: ScaleChip; label: string }[] = [
  { id: "any", label: "Alle" },
  { id: "easy", label: "S0–S1" },
  { id: "mid", label: "S1–S2" },
  { id: "hard", label: "S3+" },
  { id: "road", label: "Straße/Gravel" },
];

export const ELEVATION_OPTIONS: { id: ElevationChip; label: string }[] = [
  { id: "any", label: "Alle hm" },
  { id: "flat", label: "< 400 hm" },
  { id: "hilly", label: "400–1100" },
  { id: "alpine", label: "1100+ hm" },
];

export const SURFACE_OPTIONS = [
  { id: null, label: "Belag" },
  { id: "trail", label: "Trail" },
  { id: "flow", label: "Flow" },
  { id: "gravel", label: "Gravel" },
  { id: "asphalt", label: "Asphalt" },
] as const;
