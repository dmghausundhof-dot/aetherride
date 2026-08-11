/**
 * P0 Rhein-Neckar ~60-min loop seeds — curated catalog for Discover.
 * Always available in production (not allowDemoContent-gated).
 */
import type { BikeCategory } from "@/types";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";
import raw from "@/lib/discover/rhein-neckar-loops-v1.json";

type RnSeed = {
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

function distanceKm(
  near: [number, number],
  center: [number, number]
): number {
  const R = 6371;
  const dLat = ((center[1] - near[1]) * Math.PI) / 180;
  const dLng = ((center[0] - near[0]) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((near[1] * Math.PI) / 180) *
      Math.cos((center[1] * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

export function rheinNeckarLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  const seeds = (raw as { seeds: RnSeed[] }).seeds.filter(
    (s) => s.type === "route" && s.duration_min != null
  );
  return seeds.map((s) => {
    // 0 = unknown sentinel — list/panel omit via sanitizeElevationM.
    const elevation = sanitizeElevationM(s.ascent_m, s.distance_km) ?? 0;
    const center: [number, number] | undefined = s.center
      ? [s.center.lng, s.center.lat]
      : undefined;
    const loop = Boolean(s.is_loop);
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
        loop ? "Rundkurs-Seed Rhein-Neckar" : "Nähe-Peek Rhein-Neckar",
        s.duration_band === "60" ? "~60 Min Feierabend-Lens" : "Kuratierte Region-Seed",
        "Kuratierte P0 Seeds (nicht Demo-gated)",
      ],
      center,
      distanceFromOriginKm:
        near && center ? distanceKm(near, center) : undefined,
    } satisfies RouteSuggestion;
  });
}

/** Honest ~60 Rundkurse only — never linear A→B under this lens. */
export function rheinNeckarSixtyMinLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return rheinNeckarLoopSuggestions(near)
    .filter((r) => r.loop)
    .filter((r) => r.durationMin >= 45 && r.durationMin <= 75)
    .sort((a, b) => {
      return (a.distanceFromOriginKm ?? 999) - (b.distanceFromOriginKm ?? 999);
    });
}
