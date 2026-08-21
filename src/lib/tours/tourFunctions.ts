/**
 * Vollständiger Funktionskatalog einer öffentlichen Tour.
 * Katalog-Touren haben Map, Profil, Wetter, Stimmen, Teilen, Mappe,
 * GPX, Planen, Fahrt, Gruppe und Orte immer. Termin/Club nur wenn Seed hängt.
 */

import {
  COMMUNITY_CLUBS,
  COMMUNITY_EVENTS,
} from "@/lib/community/seed";
import type { CommunityClub, CommunityEvent } from "@/lib/community/types";
import type { PublicTour } from "@/lib/catalog/publicTours";

/** Redaktionelle Referenz-Tour mit allen angebundenen Funktionen. */
export const REFERENCE_TOUR_ID = "r-heidelberg-neckar-voll";

export const TOUR_FUNCTION_IDS = [
  "map",
  "elevation",
  "weather",
  "stimmen",
  "share",
  "mappe",
  "gpx",
  "plan",
  "ride",
  "group",
  "event",
  "club",
  "places",
] as const;

export type TourFunctionId = (typeof TOUR_FUNCTION_IDS)[number];

export type TourFunctionState = {
  id: TourFunctionId;
  available: boolean;
};

export function eventsForTour(tourId: string): CommunityEvent[] {
  const id = tourId.trim();
  if (!id) return [];
  return COMMUNITY_EVENTS.filter((e) => e.catalogTourId === id);
}

export function eventsForRegion(regionSlug: string): CommunityEvent[] {
  const slug = regionSlug.trim();
  if (!slug) return [];
  return COMMUNITY_EVENTS.filter((e) => e.regionSlug === slug);
}

export function clubsForTour(tour: Pick<PublicTour, "id" | "regionSlug" | "categories">): CommunityClub[] {
  return COMMUNITY_CLUBS.filter((club) => {
    if (club.regionSlug !== tour.regionSlug) return false;
    return club.sports.some((sport) => tourMatchesSport(tour, sport));
  });
}

export function tourMatchesSport(
  tour: Pick<PublicTour, "categories">,
  sport: string,
): boolean {
  const s = sport.toLowerCase();
  const cats = tour.categories;
  if (s === "mtb") {
    return cats.some((c) =>
      ["mtb_trail", "mtb_am", "mtb_enduro", "dh", "emtb"].includes(c),
    );
  }
  if (s === "road") return cats.includes("road");
  if (s === "gravel") return cats.includes("gravel");
  if (s === "urban") return cats.includes("urban");
  if (s === "ebike") return cats.some((c) => c === "emtb" || c === "etrekking");
  if (s === "touring") {
    return cats.some((c) => c === "etrekking" || c === "road" || c === "gravel");
  }
  if (s === "hiking") return cats.includes("hiking");
  return false;
}

export function tourFunctionStates(
  tour: Pick<PublicTour, "id" | "regionSlug" | "categories">,
): TourFunctionState[] {
  const hasEvent = eventsForTour(tour.id).length > 0;
  const hasClub = clubsForTour(tour).length > 0;
  return TOUR_FUNCTION_IDS.map((id) => ({
    id,
    available: id === "event" ? hasEvent : id === "club" ? hasClub : true,
  }));
}

export function tourHrefForEvent(event: CommunityEvent): string {
  if (event.catalogTourId) return `/tours/${event.catalogTourId}`;
  return event.href ?? `/regions/${event.regionSlug}`;
}
