/**
 * Curated P0 Discover seeds (Berlin + Rhein-Neckar).
 * Always available in production — not gated by allowDemoContent().
 * Fake routing / demo geometry stays fail-closed separately.
 *
 * All suggestions carry source:"seed" (never "demo").
 * ~60 lens: honest loops only (align #37).
 */
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { berlinLoopSuggestions, berlinSixtyMinLoopSuggestions } from "./berlinLoops";
import {
  rheinNeckarLoopSuggestions,
  rheinNeckarSixtyMinLoopSuggestions,
} from "./rheinNeckarLoops";

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

function withSeedSource(routes: RouteSuggestion[]): RouteSuggestion[] {
  return routes.map((r) =>
    r.source === "seed" ? r : { ...r, source: "seed" as const }
  );
}

/** Full curated catalog fallback when demo SEEDS catalog is empty/off. */
export function curatedP0CatalogSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return withSeedSource(
    dedupeById([
      ...berlinLoopSuggestions(near),
      ...rheinNeckarLoopSuggestions(near),
    ])
  ).sort((a, b) => {
    const da = a.distanceFromOriginKm ?? 1e9;
    const db = b.distanceFromOriginKm ?? 1e9;
    if (da !== db) return da - db;
    return b.matchScore - a.matchScore;
  });
}

/** Quick-sheet ~60 Min (45–75) honest loops — Tempelhofer + RN Feierabend. */
export function curatedSixtyMinLoopSuggestions(
  near?: [number, number]
): RouteSuggestion[] {
  return withSeedSource(
    dedupeById([
      ...berlinSixtyMinLoopSuggestions(near),
      ...rheinNeckarSixtyMinLoopSuggestions(near),
    ])
  )
    .filter((r) => r.loop)
    .sort((a, b) => {
      return (a.distanceFromOriginKm ?? 999) - (b.distanceFromOriginKm ?? 999);
    });
}
