import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { getPublicTour } from "@/lib/catalog/publicTours";

/** Discover-Detail für jede Katalog-ID — auch ohne Seed-Liste. */
export function suggestionFromPublicTour(id: string): RouteSuggestion | null {
  const tour = getPublicTour(id.trim());
  if (!tour) return null;
  const summary = tour.summary.trim();
  return {
    id: tour.id,
    name: tour.name,
    category: tour.primaryCategory,
    distanceKm: tour.distanceKm,
    elevationM: tour.elevationM,
    durationMin: tour.durationMin,
    mtbScale: tour.difficulty,
    surface: tour.surface,
    loop: tour.loop,
    uncertainKmPct: 12,
    matchScore: 78,
    reasons: [
      summary.length > 0 ? summary.slice(0, 96) : `Katalog · ${tour.regionSlug}`,
      `${tour.distanceKm} km · ${tour.elevationM} hm`,
      tour.loop ? "Rundkurs" : "Etappe",
    ],
    center: tour.center,
  };
}
