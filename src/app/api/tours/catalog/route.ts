import { NextResponse } from "next/server";
import { listEditorialSets } from "@/lib/catalog/editorialSets";
import { listPublicTours } from "@/lib/catalog/publicTours";
import { COMMUNITY_EVENTS } from "@/lib/community/seed";
import { eventsForTour, tourFunctionStates } from "@/lib/tours/tourFunctions";

/**
 * GET /api/tours/catalog
 * Redaktionelle Tour-Ideen für Mobile Discover (Metadaten + Pin, keine Geometry).
 * Query: ?sport=road|gravel|mtb|urban|ebike|all  &region=slug
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const sport = (url.searchParams.get("sport") || "all").toLowerCase();
  const region = url.searchParams.get("region")?.trim() || "";

  let tours = listPublicTours();
  if (region) {
    tours = tours.filter((t) => t.regionSlug === region);
  }
  if (sport && sport !== "all") {
    tours = tours.filter((t) => {
      if (sport === "mtb" || sport === "downhill" || sport === "enduro")
        return t.categories.some((c) =>
          ["mtb_trail", "mtb_am", "mtb_enduro", "dh", "emtb"].includes(c)
        );
      if (sport === "road") return t.categories.includes("road");
      if (sport === "gravel") return t.categories.includes("gravel");
      if (sport === "urban") return t.categories.includes("urban");
      if (sport === "ebike")
        return t.categories.some((c) => c === "emtb" || c === "etrekking");
      if (sport === "touring")
        return t.categories.some(
          (c) => c === "etrekking" || c === "road" || c === "gravel"
        );
      return true;
    });
  }

  const items = tours.map((t) => {
    const events = eventsForTour(t.id).map((e) => ({
      id: e.id,
      title: e.title,
      dateLabel: e.dateLabel,
      sport: e.sport,
    }));
    return {
      id: t.id,
      name: t.name,
      summary: t.summary,
      primaryCategory: t.primaryCategory,
      categories: t.categories,
      distanceKm: t.distanceKm,
      elevationM: t.elevationM,
      durationMin: t.durationMin,
      difficulty: t.difficulty,
      surface: t.surface,
      loop: t.loop,
      regionSlug: t.regionSlug,
      center: t.center, // [lng, lat]
      tags: t.tags,
      events,
      functions: tourFunctionStates(t)
        .filter((s) => s.available)
        .map((s) => s.id),
    };
  });

  return NextResponse.json(
    {
      ok: true,
      count: items.length,
      tours: items,
      sets: listEditorialSets(3),
      events: COMMUNITY_EVENTS.map((e) => ({
        id: e.id,
        title: e.title,
        regionSlug: e.regionSlug,
        dateLabel: e.dateLabel,
        sport: e.sport,
        catalogTourId: e.catalogTourId,
      })),
      honesty: "Redaktionelle Ideen — keine User-Sammlungen.",
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    }
  );
}
