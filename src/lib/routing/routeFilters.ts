/**
 * Discover-Filter — sportneutral (alle Fahrradfahrer), API-/Katalog-Felder.
 * Semantik angeglichen an Mobile `TourFilters` (tour_filters.dart).
 */
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { isHonestLoopSuggestion } from "@/lib/discover/loopHonesty";

/** Generische Beanspruchung — Labels sportabhängig via difficultyOptionsForProfile */
export type ScaleChip = "any" | "easy" | "mid" | "hard";
export type ElevationChip = "any" | "flat" | "hilly" | "alpine";
export type SurfaceKey = "asphalt" | "gravel" | "trail" | "mixed";

/** Sport-Familie: weiche Präferenz (Sortierung), kein Hard-Exclude */
export type SportFilter =
  | "all"
  | "mtb"
  | "road"
  | "gravel"
  | "urban"
  | "ebike"
  | "touring"
  | "hiking";

export interface RouteFilterState {
  loopOnly: boolean;
  scale: ScaleChip;
  elevation: ElevationChip;
  /** Kanonischer Surface-Key (nicht Substring) */
  surfaceQuery: SurfaceKey | null;
  sport: SportFilter;
  /** Max. Distanz in km; null = egal */
  maxDistanceKm: number | null;
}

export const DEFAULT_ROUTE_FILTERS: RouteFilterState = {
  loopOnly: false,
  scale: "any",
  elevation: "any",
  surfaceQuery: null,
  sport: "all",
  maxDistanceKm: null,
};

export const SPORT_FILTER_OPTIONS: { id: SportFilter; label: string }[] = [
  { id: "all", label: "Alle" },
  { id: "road", label: "Rennrad" },
  { id: "gravel", label: "Gravel" },
  { id: "mtb", label: "MTB" },
  { id: "urban", label: "City" },
  { id: "ebike", label: "E-Bike" },
  { id: "touring", label: "Touring" },
  { id: "hiking", label: "Wandern" },
];

export const DISTANCE_MAX_OPTIONS: { id: number | null; label: string }[] = [
  { id: null, label: "Distanz" },
  { id: 20, label: "≤ 20 km" },
  { id: 40, label: "≤ 40 km" },
  { id: 70, label: "≤ 70 km" },
];

/** Normalisiert Katalog-/Seed-Oberflächen auf kanonische Keys. */
export function parseSurfaceKey(raw: string | null | undefined): SurfaceKey | null {
  if (!raw) return null;
  const t = raw.trim().toLowerCase();
  if (!t || t === "—" || t === "-") return null;
  if (
    t.includes("trail") ||
    t.includes("root") ||
    t.includes("alpine") ||
    t.includes("single") ||
    t.includes("naturboden")
  ) {
    return "trail";
  }
  if (
    t.includes("gravel") ||
    t.includes("schotter") ||
    t.includes("forst") ||
    t.includes("unpaved") ||
    t.includes("compact") ||
    t === "flow/compact" ||
    t.startsWith("flow")
  ) {
    return "gravel";
  }
  if (
    t.includes("urban") ||
    t.includes("mixed") ||
    t.includes("stadt") ||
    t.includes("gemischt")
  ) {
    return "mixed";
  }
  if (
    t.includes("asphalt") ||
    t.includes("paved") ||
    t.includes("bike-lane") ||
    t.includes("bike_lane") ||
    t.includes("radweg") ||
    t.includes("pavement") ||
    t === "path" ||
    t.endsWith("/path")
  ) {
    return "asphalt";
  }
  return "mixed";
}

function surfaceMatches(tourSurface: string, filter: SurfaceKey): boolean {
  const key = parseSurfaceKey(tourSurface);
  if (!key) return filter === "mixed";
  if (key === filter) return true;
  const soft: Record<SurfaceKey, Set<SurfaceKey>> = {
    asphalt: new Set(["asphalt", "mixed"]),
    mixed: new Set(["mixed", "asphalt"]),
    gravel: new Set(["gravel", "trail"]),
    trail: new Set(["trail", "gravel"]),
  };
  return soft[filter]?.has(key) ?? false;
}

function categoryMatchesSport(
  category: RouteSuggestion["category"],
  sport: SportFilter
): boolean {
  if (sport === "all") return true;
  switch (sport) {
    case "mtb":
      return (
        category === "mtb_trail" ||
        category === "mtb_am" ||
        category === "mtb_enduro" ||
        category === "dh" ||
        category === "emtb"
      );
    case "road":
      return category === "road";
    case "gravel":
      return category === "gravel";
    case "urban":
      return category === "urban";
    case "ebike":
      // E-MTB-Fahrer sollen MTB-Trails weich bevorzugt sehen (Mobile-Parität).
      return (
        category === "emtb" ||
        category === "etrekking" ||
        category === "mtb_trail" ||
        category === "mtb_am" ||
        category === "mtb_enduro" ||
        category === "dh"
      );
    case "touring":
      return category === "etrekking" || category === "gravel" || category === "road";
    case "hiking":
      return category === "hiking";
    default:
      return true;
  }
}

/** Beanspruchung — unklassifiziert (—) matcht easy+mid (Road/City/Katalog). */
function scaleMatches(mtbScale: string, chip: ScaleChip): boolean {
  if (chip === "any") return true;
  const t = mtbScale.trim().toLowerCase();
  if (!t || t === "—" || t === "-" || t === "offen" || t === "open") {
    return chip === "easy" || chip === "mid";
  }
  if (/anspruch|schwer|hard|difficult|rau/.test(t)) return chip === "hard";
  if (/leicht|easy|entspannt|flach/.test(t)) return chip === "easy";
  if (/mittel|medium|sportlich|gemischt/.test(t)) {
    return chip === "mid" || chip === "easy";
  }

  const nums = [...mtbScale.matchAll(/S(\d)/gi)].map((m) => Number(m[1]));
  if (nums.length === 0) {
    if (chip === "easy") return true;
    if (chip === "mid") return !/^T[34]/i.test(mtbScale);
    if (chip === "hard") return /^T[34]/i.test(mtbScale);
    return true;
  }
  const max = Math.max(...nums);
  if (chip === "easy") return max <= 1;
  if (chip === "mid") return max >= 1 && max <= 2;
  return max >= 2;
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
  const hard = routes.filter((r) => {
    // D-60-LOOP-FILTER-01: Rundkurs chip — honest loops only, never A→B.
    if (filters.loopOnly && !isHonestLoopSuggestion(r)) return false;
    if (!scaleMatches(r.mtbScale, filters.scale)) return false;
    if (!elevationMatches(r.elevationM, filters.elevation)) return false;
    if (
      filters.maxDistanceKm != null &&
      filters.maxDistanceKm > 0 &&
      r.distanceKm > filters.maxDistanceKm + 0.05
    ) {
      return false;
    }
    if (filters.surfaceQuery) {
      if (!surfaceMatches(r.surface, filters.surfaceQuery)) return false;
    }
    return true;
  });

  // Sport: weiche Präferenz — Treffer nach vorn, Rest bleibt sichtbar.
  if (filters.sport === "all") return hard;
  const matched: RouteSuggestion[] = [];
  const rest: RouteSuggestion[] = [];
  for (const r of hard) {
    if (categoryMatchesSport(r.category, filters.sport)) matched.push(r);
    else rest.push(r);
  }
  if (matched.length === 0) return hard;
  return [...matched, ...rest];
}

/** Schwierigkeits-Chips — Labels sportabhängig, Keys einheitlich easy/mid/hard */
export function difficultyOptionsForProfile(
  profile: RoutingProfile
): { id: ScaleChip; label: string }[] {
  const mtbLike =
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "emtb";

  if (mtbLike) {
    return [
      { id: "any", label: "Alle" },
      { id: "easy", label: "Leicht" },
      { id: "mid", label: "Mittel" },
      { id: "hard", label: "Anspruchsvoll" },
    ];
  }
  if (profile === "hiking") {
    return [
      { id: "any", label: "Alle" },
      { id: "easy", label: "Leicht" },
      { id: "mid", label: "Mittel" },
      { id: "hard", label: "Anspruchsvoll" },
    ];
  }
  if (profile === "gravel") {
    return [
      { id: "any", label: "Alle" },
      { id: "easy", label: "Leicht" },
      { id: "mid", label: "Gemischt" },
      { id: "hard", label: "Rau" },
    ];
  }
  if (profile === "urban" || profile === "road" || profile === "ebike") {
    return [
      { id: "any", label: "Alle" },
      { id: "easy", label: "Entspannt" },
      { id: "mid", label: "Sportlich" },
      { id: "hard", label: "Anspruchsvoll" },
    ];
  }
  return [
    { id: "any", label: "Alle" },
    { id: "easy", label: "Leicht" },
    { id: "mid", label: "Mittel" },
    { id: "hard", label: "Anspruchsvoll" },
  ];
}

/** @deprecated — nutze difficultyOptionsForProfile; bleibt für Legacy-Imports */
export const SCALE_OPTIONS: { id: ScaleChip; label: string }[] = [
  { id: "any", label: "Alle" },
  { id: "easy", label: "Leicht" },
  { id: "mid", label: "Mittel" },
  { id: "hard", label: "Anspruchsvoll" },
];

export const ELEVATION_OPTIONS: { id: ElevationChip; label: string }[] = [
  { id: "any", label: "Alle hm" },
  { id: "flat", label: "< 400 hm" },
  { id: "hilly", label: "400–1100" },
  { id: "alpine", label: "1100+ hm" },
];

export const SURFACE_OPTIONS: { id: SurfaceKey | null; label: string }[] = [
  { id: null, label: "Belag" },
  { id: "asphalt", label: "Asphalt" },
  { id: "gravel", label: "Schotter" },
  { id: "trail", label: "Trail" },
  { id: "mixed", label: "Gemischt" },
];

/** Sport-Filter aus Routing-Profil ableiten (UI-Sync / Default-Präferenz) */
export function sportFilterFromProfile(profile: RoutingProfile): SportFilter {
  switch (profile) {
    case "mtb_allmountain":
    case "mtb_enduro":
      return "mtb";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "urban":
      return "urban";
    case "ebike":
      return "touring";
    case "emtb":
      // E-MTB → MTB-Familie (Trails bevorzugt), nicht nur emtb/etrekking-Bucket.
      return "mtb";
    case "hiking":
      return "hiking";
    default:
      return "all";
  }
}
