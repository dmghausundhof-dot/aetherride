/**
 * Curated P0 Discover seeds (Berlin + Rhein-Neckar).
 * Always available in production — not gated by allowDemoContent().
 * Fake routing / demo geometry stays fail-closed separately.
 */
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { filterHonestLoopSuggestions } from "@/lib/discover/loopHonesty";
import { berlinLoopSuggestions, berlinSixtyMinLoopSuggestions } from "./berlinLoops";

function dedupeById(routes: RouteSuggestion[]): RouteSuggestion[] {
  const seen = new Set<string>();
  const out: RouteSuggestion[] = [];
  for (const r of routes) {
    if (seen.has(r.id)) continue;
    seen.add(r.id);
    out.push(r);
  }
  return out;
}

/** Full curated catalog fallback when demo SEEDS catalog is empty/off. */
export function curatedP0CatalogSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return dedupeById([
    ...berlinLoopSuggestions(near),
  ]).sort((a, b) => {
    const da = a.distanceFromOriginKm ?? 1e9;
    const db = b.distanceFromOriginKm ?? 1e9;
    if (da !== db) return da - db;
    return b.matchScore - a.matchScore;
  });
}

/** Quick-sheet ~60 Min (45–75) — honest loops only (Tempelhofer + RN). */
export function curatedSixtyMinLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return filterHonestLoopSuggestions(
    dedupeById([
      ...berlinSixtyMinLoopSuggestions(near),
    ])
  ).sort((a, b) => {
    return (a.distanceFromOriginKm ?? 999) - (b.distanceFromOriginKm ?? 999);
  });
}
