/**
 * Public `/tours/[id]` — editorial catalog or P0 Nähe seed.
 * Seeds stay off SEO lists (no filler routes).
 */
import { getPublicTour, type PublicTour } from "@/lib/catalog/publicTours";
import { getP0SeedById, type P0SeedPage } from "@/lib/discover/berlinLoops";

export type ResolvedTourPage =
  | { kind: "catalog"; tour: PublicTour }
  | { kind: "seed"; seed: P0SeedPage };

export function resolveTourPage(id: string): ResolvedTourPage | null {
  const tour = getPublicTour(id);
  if (tour) return { kind: "catalog", tour };
  const seed = getP0SeedById(id);
  if (seed) return { kind: "seed", seed };
  return null;
}

/** Discover may show engine routes that have no public page — do not 404. */
export function hasPublicTourPage(id: string): boolean {
  return resolveTourPage(id) != null;
}
