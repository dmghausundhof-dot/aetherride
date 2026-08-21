/**
 * Rider-facing Discover copy — no internal seed/lens jargon, no naked
 * match % without a bike.
 */
import type { RouteFilterState } from "@/lib/routing/routeFilters";
import { DEFAULT_FILTER_MINUTES } from "./discoverExploreChrome";

const JARGON: [RegExp, string][] = [
  [/Rundkurs-Seed(?:\s+Rhein-Neckar)?/gi, "Rundkurs"],
  [/Nähe-Peek(?:\s+Rhein-Neckar)?/gi, "In der Nähe"],
  [/~?\s*60 Min Feierabend-Lens/gi, "~60 Min"],
  [/Kuratierte Region-Seed/gi, "In der Region"],
  [/Kuratierte ~60-Min Seeds \(nicht Demo-gated\)/gi, "~60 Min"],
  [/Kuratierte P0 Seeds \(nicht Demo-gated\)/gi, "In der Region"],
];

export function riderFacingReason(reason: string): string {
  let out = reason;
  for (const [re, replacement] of JARGON) {
    out = out.replace(re, replacement);
  }
  return out.replace(/\s+/g, " ").trim();
}

export function riderFacingReasons(reasons: readonly string[]): string[] {
  return reasons.map(riderFacingReason).filter(Boolean);
}

export function bikeMatchLine(
  hasBike: boolean,
  categoryLabel: string | null | undefined,
  fitsYourBike: (label: string) => string,
): string | null {
  if (!hasBike) return null;
  const label = categoryLabel?.trim();
  if (!label) return null;
  return fitsYourBike(label);
}

/** Chip label: real name for the default loop lens, never "Filter 1". */
export function exploreFilterChipLabel(
  filters: RouteFilterState,
  minutes: number,
  copy: { filter: string; loop: string },
  filterCount: number,
  defaultMinutes = DEFAULT_FILTER_MINUTES,
): string {
  if (
    filterCount === 1 &&
    filters.loopOnly &&
    minutes === defaultMinutes
  ) {
    return copy.loop;
  }
  return copy.filter;
}
