/**
 * Discover-Filter — sportabhängig (Schwierigkeit/Belag), nicht MTB-only.
 */
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { isHonestLoopSuggestion } from "@/lib/discover/loopHonesty";

/** Generische Schwierigkeit — Labels sportabhängig via difficultyOptionsForProfile */
export type ScaleChip = "any" | "easy" | "mid" | "hard" | "road";
export type ElevationChip = "any" | "flat" | "hilly" | "alpine";

/** Sport-Familie für Katalog-Filter (unabhängig vom Routing-Profil) */
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
  surfaceQuery: string | null;
  sport: SportFilter;
}

export const DEFAULT_ROUTE_FILTERS: RouteFilterState = {
  loopOnly: false,
  scale: "any",
  elevation: "any",
  surfaceQuery: null,
  sport: "all",
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
      return category === "emtb" || category === "etrekking";
    case "touring":
      return category === "etrekking" || category === "gravel" || category === "road";
    case "hiking":
      return category === "hiking";
    default:
      return true;
  }
}

function isMtbScale(mtbScale: string): boolean {
  return /S\d/i.test(mtbScale);
}

function scaleMatches(mtbScale: string, chip: ScaleChip): boolean {
  if (chip === "any") return true;
  // „Straße/Gravel“-Chip: alles ohne technische Singletrail-Skala
  if (chip === "road") {
    return !isMtbScale(mtbScale) || mtbScale === "—" || mtbScale.startsWith("T");
  }

  const nums = [...mtbScale.matchAll(/S(\d)/gi)].map((m) => Number(m[1]));
  if (nums.length === 0) {
    // Keine S-Skala: Rennrad/Gravel/City — easy+mid ok, hard nur mit T3+ o.ä.
    if (chip === "easy") return true;
    if (chip === "mid") return !/^T[34]/i.test(mtbScale);
    if (chip === "hard") return /^T[34]/i.test(mtbScale) || /S[3-5]/i.test(mtbScale);
    return true;
  }
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
    // D-60-LOOP-FILTER-01: Rundkurs chip — honest loops only, never A→B.
    if (filters.loopOnly && !isHonestLoopSuggestion(r)) return false;
    if (!categoryMatchesSport(r.category, filters.sport)) return false;
    if (!scaleMatches(r.mtbScale, filters.scale)) return false;
    if (!elevationMatches(r.elevationM, filters.elevation)) return false;
    if (filters.surfaceQuery) {
      const q = filters.surfaceQuery.toLowerCase();
      if (!r.surface.toLowerCase().includes(q)) return false;
    }
    return true;
  });
}

/** Schwierigkeits-Chips abhängig vom aktiven Routing-Profil */
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
      { id: "easy", label: "S0–S1" },
      { id: "mid", label: "S1–S2" },
      { id: "hard", label: "S3+" },
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
      { id: "road", label: "Viel Asphalt" },
    ];
  }
  if (profile === "urban" || profile === "road" || profile === "ebike") {
    return [
      { id: "any", label: "Alle" },
      { id: "easy", label: "Entspannt" },
      { id: "mid", label: "Sportlich" },
      { id: "road", label: "Straße/Radweg" },
    ];
  }
  return [
    { id: "any", label: "Alle" },
    { id: "easy", label: "Leicht" },
    { id: "mid", label: "Mittel" },
    { id: "hard", label: "Schwer" },
  ];
}

/** @deprecated — nutze difficultyOptionsForProfile; bleibt für Legacy-Imports */
export const SCALE_OPTIONS: { id: ScaleChip; label: string }[] = [
  { id: "any", label: "Alle" },
  { id: "easy", label: "Leicht" },
  { id: "mid", label: "Mittel" },
  { id: "hard", label: "Schwer" },
  { id: "road", label: "Straße/Radweg" },
];

export const ELEVATION_OPTIONS: { id: ElevationChip; label: string }[] = [
  { id: "any", label: "Alle hm" },
  { id: "flat", label: "< 400 hm" },
  { id: "hilly", label: "400–1100" },
  { id: "alpine", label: "1100+ hm" },
];

export const SURFACE_OPTIONS = [
  { id: null, label: "Belag" },
  { id: "asphalt", label: "Asphalt" },
  { id: "gravel", label: "Gravel" },
  { id: "trail", label: "Trail" },
  { id: "bike-lane", label: "Radweg" },
  { id: "path", label: "Weg" },
] as const;

/** Sport-Filter aus Routing-Profil ableiten (UI-Sync) */
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
      return "ebike";
    case "hiking":
      return "hiking";
    default:
      return "all";
  }
}
