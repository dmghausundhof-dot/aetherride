/**
 * P0 Nähe-Peek / 60-min loop seeds — offline fallback when the
 * Discover catalog is empty (e.g. production with demo content off).
 *
 * Sources: Berlin + DACH + Alpen/Ostsee-Lücken + Rhein-Neckar curated Nähe seeds.
 * ~60 / Rundkurs lens: honest loops only (is_loop / closed), never A→B fillers.
 */
import type { BikeCategory } from "@/types";
import type { RoutePoiStop, RouteSuggestion } from "@/lib/routing/suggestions";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";
import { seedIsLoopFlag } from "@/lib/discover/loopHonesty";
import berlinRaw from "@/lib/discover/berlin-loops-v1.json";
import dachRaw from "@/lib/discover/p0-dach-60min-naehe-v1.json";
import gapsRaw from "@/lib/discover/p0-gaps-60min-naehe-v1.json";
import rnRaw from "@/lib/discover/p0-rhein-neckar-60min-naehe-v1.json";

type SeedJson = {
  default_center: { lng: number; lat: number; name?: string };
  label_without_location?: string;
  label_with_location?: string;
  seeds: BerlinSeed[];
};

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
  poi_stops?: unknown;
};

const sportToCategory = (tags: string[] | undefined): BikeCategory => {
  const t = new Set(tags ?? []);
  if (t.has("mtb")) return "mtb_trail";
  if (t.has("gravel")) return "gravel";
  if (t.has("road")) return "road";
  if (t.has("city") || t.has("urban")) return "urban";
  if (t.has("touring")) return "etrekking";
  if (t.has("emtb")) return "emtb";
  // City/Touring-E-Bike — nicht als E-MTB soft-boosten (Mobile-Parität).
  if (t.has("ebike")) return "etrekking";
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

/** Keep seed `poi_stops` (id / title / kind / atMin). No invented catalog. */
export function parseSeedPoiStops(raw: unknown): RoutePoiStop[] {
  if (!Array.isArray(raw)) return [];
  const out: RoutePoiStop[] = [];
  for (const p of raw) {
    if (!p || typeof p !== "object") continue;
    const m = p as Record<string, unknown>;
    const atRaw = m.offset_min ?? m.at_min ?? m.atMin;
    const atMin = typeof atRaw === "number" ? Math.round(atRaw) : Number(atRaw);
    if (!Number.isFinite(atMin)) continue;
    const kind = String(m.type ?? m.kind ?? "place").trim() || "place";
    const title = String(m.title ?? m.name ?? "").trim();
    if (!title) continue;
    const rawId = String(m.id ?? "").trim();
    const slug = kind.toLowerCase().replace(/[^a-z0-9]+/g, "-");
    const id = rawId || `poi-${atMin}-${slug}`;
    const whyRaw = m.why_good ?? m.whyGood;
    const whyGood =
      typeof whyRaw === "string" && whyRaw.trim() ? whyRaw.trim() : undefined;
    out.push({ id, atMin, title, kind, ...(whyGood ? { whyGood } : {}) });
  }
  return out;
}

function haversineKm(
  lng1: number,
  lat1: number,
  lng2: number,
  lat2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const berlinBundle = berlinRaw as SeedJson;
const dachBundle = dachRaw as SeedJson;
const gapsBundle = gapsRaw as SeedJson;
const rnBundle = rnRaw as SeedJson;

/** Merge seed lists; earlier sources win on id collision (Berlin enrich first). */
function mergedRouteSeeds(): BerlinSeed[] {
  const byId = new Map<string, BerlinSeed>();
  for (const bundle of [berlinBundle, dachBundle, gapsBundle, rnBundle]) {
    for (const s of bundle.seeds ?? []) {
      if (s.type !== "route" || s.duration_min == null) continue;
      if (!byId.has(s.id)) byId.set(s.id, s);
    }
  }
  return [...byId.values()];
}

export const BERLIN_DEFAULT_CENTER: [number, number] = [
  berlinBundle.default_center.lng,
  berlinBundle.default_center.lat,
];

function seedToSuggestion(
  s: BerlinSeed,
  near?: [number, number]
): RouteSuggestion {
  // 0 = unknown sentinel — RouteCard/Detail sanitize again and omit hm.
  const elevation = sanitizeElevationM(s.ascent_m, s.distance_km) ?? 0;
  const center: [number, number] | undefined = s.center
    ? [s.center.lng, s.center.lat]
    : undefined;
  let distanceFromOriginKm: number | undefined;
  if (near && center) {
    distanceFromOriginKm = Math.round(
      haversineKm(near[0], near[1], center[0], center[1])
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
      loop ? "Rundkurs-Seed" : "Nähe-Peek",
      s.duration_band === "60" ? "~60 Min Feierabend-Lens" : "Kuratierte Region-Seed",
      "Kuratierte ~60-Min Seeds (nicht Demo-gated)",
    ],
    center,
    distanceFromOriginKm,
    poiStops: parseSeedPoiStops(s.poi_stops),
  } satisfies RouteSuggestion;
}

/** All Nähe route seeds (Berlin + DACH + Lücken + RN), including linear — for catalog fallback. */
export function berlinLoopSuggestions(near?: [number, number]): RouteSuggestion[] {
  return mergedRouteSeeds().map((s) => seedToSuggestion(s, near));
}

/**
 * Feierabend ~60 Min (45–75) Rundkurse — Quick sheet always-on section.
 * Honest loops only: linear seeds (e.g. Spree commute) are excluded.
 */
export function berlinSixtyMinLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  // Honesty via seedIsLoopFlag → suggestion.loop; page also re-filters.
  return berlinLoopSuggestions(near)
    .filter((r) => r.loop === true)
    .filter((r) => r.id !== "seed-route-spree-commute")
    .filter((r) => r.durationMin >= 45 && r.durationMin <= 75)
    .sort((a, b) => {
      return (a.distanceFromOriginKm ?? 999) - (b.distanceFromOriginKm ?? 999);
    });
}

/** Demo-Stadt chips for empty Ort / no useful nearby loops (web Quick). */
export const DEMO_CITY_CHIPS: { name: string; lat: number; lng: number }[] = [
  { name: "Hamburg", lat: 53.551, lng: 9.993 },
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
