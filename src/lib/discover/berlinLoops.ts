/**
 * P0 Berlin Nähe-Peek / 60-min loop seeds — offline fallback when the
 * Discover catalog is empty (e.g. production with demo content off).
 *
 * source:"seed" (never "demo") — curated fail-open (#35).
 * Loop flags: is_loop | loop | closed (#37).
 */
import type { BikeCategory } from "@/types";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";
import { seedIsLoopFlag } from "@/lib/discover/loopHonesty";
import raw from "@/lib/discover/berlin-loops-v1.json";

type BerlinSeed = {
  id: string;
  type: string;
  title: string;
  distance_km: number;
  ascent_m: number | null;
  duration_min: number | null;
  sport_tags?: string[];
  surface_mix?: Record<string, number> | null;
  center?: { lat: number; lng: number };
  is_loop?: boolean;
  loop?: boolean;
  closed?: boolean;
  duration_band?: string;
};

const sportToCategory = (tags: string[] | undefined): BikeCategory => {
  const t = new Set(tags ?? []);
  if (t.has("mtb")) return "mtb_trail";
  if (t.has("gravel")) return "gravel";
  if (t.has("road")) return "road";
  if (t.has("city") || t.has("urban")) return "urban";
  if (t.has("touring")) return "etrekking";
  if (t.has("ebike")) return "emtb";
  return "urban";
};

const surfaceLabel = (mix: Record<string, number> | null | undefined): string => {
  if (!mix) return "mixed";
  const parts = Object.entries(mix)
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 2)
    .map(([k, v]) => `${k} ${v}%`);
  return parts.join(" / ") || "mixed";
};

export const BERLIN_DEFAULT_CENTER: [number, number] = [
  (raw as { default_center: { lng: number; lat: number } }).default_center.lng,
  (raw as { default_center: { lng: number; lat: number } }).default_center.lat,
];

export function berlinLoopSuggestions(near?: [number, number]): RouteSuggestion[] {
  const seeds = (raw as { seeds: BerlinSeed[] }).seeds.filter(
    (s) => s.type === "route" && s.duration_min != null
  );
  return seeds.map((s) => {
    // Keep 0 when hidden — RouteCard re-sanitizes and omits absurd hm.
    const elevation = sanitizeElevationM(s.ascent_m, s.distance_km) ?? 0;
    const center: [number, number] | undefined = s.center
      ? [s.center.lng, s.center.lat]
      : undefined;
    let distanceFromOriginKm: number | undefined;
    if (near && center) {
      const R = 6371;
      const dLat = ((center[1] - near[1]) * Math.PI) / 180;
      const dLng = ((center[0] - near[0]) * Math.PI) / 180;
      const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((near[1] * Math.PI) / 180) *
          Math.cos((center[1] * Math.PI) / 180) *
          Math.sin(dLng / 2) ** 2;
      distanceFromOriginKm = Math.round(
        R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      );
    }
    const loop = seedIsLoopFlag(s);
    return {
      id: s.id,
      name: s.title,
      category: sportToCategory(s.sport_tags),
      distanceKm: s.distance_km,
      elevationM: elevation,
      durationMin: s.duration_min!,
      mtbScale: "—",
      surface: surfaceLabel(s.surface_mix),
      loop,
      uncertainKmPct: 12,
      matchScore: s.duration_band === "60" ? 82 : 70,
      reasons: [
        loop ? "Rundkurs-Seed Berlin" : "Nähe-Peek Berlin",
        s.duration_band === "60" ? "~60 Min Feierabend-Lens" : "Kuratierte Region-Seed",
        "Kuratierte ~60-Min Seeds (nicht Demo-gated)",
      ],
      center,
      distanceFromOriginKm,
      source: "seed",
    } satisfies RouteSuggestion;
  });
}

/**
 * Feierabend ~60 Min (45–75) — Quick sheet always-on section.
 * Honest loops only (#37) — linear A→B seeds excluded.
 */
export function berlinSixtyMinLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return berlinLoopSuggestions(near)
    .filter((r) => r.loop)
    .filter((r) => r.durationMin >= 45 && r.durationMin <= 75)
    .sort((a, b) => {
      return (a.distanceFromOriginKm ?? 999) - (b.distanceFromOriginKm ?? 999);
    });
}

/** Demo-Stadt chips for empty Ort / no useful nearby loops (web Quick). */
export const DEMO_CITY_CHIPS: { name: string; lat: number; lng: number }[] = [
  { name: "Berlin", lat: 52.52, lng: 13.405 },
  { name: "München", lat: 48.183, lng: 11.61 },
  { name: "Köln", lat: 50.941, lng: 6.958 },
  { name: "Zürich", lat: 47.366, lng: 8.541 },
  { name: "Wien", lat: 48.218, lng: 16.392 },
  { name: "Innsbruck", lat: 47.286, lng: 11.399 },
  { name: "Konstanz", lat: 47.677, lng: 9.174 },
  { name: "Heidelberg", lat: 49.409, lng: 8.694 },
  { name: "Mannheim", lat: 49.483, lng: 8.462 },
];
