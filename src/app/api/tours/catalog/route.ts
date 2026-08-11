import { NextResponse } from "next/server";
import { listPublicTours } from "@/lib/catalog/publicTours";

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
      if (sport === "mtb")
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

  const items = tours.map((t) => ({
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
  }));

  return NextResponse.json(
    {
      ok: true,
      count: items.length,
      tours: items,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    }
  );
}
