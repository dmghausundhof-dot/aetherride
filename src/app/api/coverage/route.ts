import { NextResponse } from "next/server";
import {
  assembleCoverageLive,
  assembleCoverageLocal,
  parseBikeClass,
} from "@/lib/coverage/assemble";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";

export const maxDuration = 15;

/**
 * GET /api/coverage?lat=&lng=&bike=mtb|gravel|road|urban&radiusKm=&live=0
 *
 * GPS-first DACH: bundled seeds + OSM viewport trails/routes + weather +
 * Google Places (if GOOGLE_MAPS_API_KEY). Never downloads all of DE.
 * live=0 skips upstreams (deterministic / tests).
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lng = Number(
    url.searchParams.get("lng") ?? url.searchParams.get("lon") ?? NaN
  );
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return NextResponse.json(
      { error: "lat_lng_required", ok: false },
      { status: 400 }
    );
  }
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
    return NextResponse.json(
      { error: "invalid_lat_lng", ok: false, seeds: [], trails: [], places: [] },
      { status: 400 }
    );
  }

  const bikeClass = parseBikeClass(url.searchParams.get("bike"));
  const radiusKm = Number(url.searchParams.get("radiusKm") || 8);
  const live =
    url.searchParams.get("live") !== "0" &&
    url.searchParams.get("live") !== "false";
  const lang = chromeLangFrom(url.searchParams.get("lang"));

  try {
    const body = live
      ? await assembleCoverageLive({
          lat,
          lng,
          bikeClass,
          radiusKm: Number.isFinite(radiusKm) ? radiusKm : 8,
          language: lang,
        })
      : assembleCoverageLocal({ lat, lng, bikeClass });
    return NextResponse.json(body, {
      headers: {
        "Cache-Control": "public, s-maxage=120, stale-while-revalidate=600",
      },
    });
  } catch (e) {
    const fallback = assembleCoverageLocal({ lat, lng, bikeClass });
    return NextResponse.json({
      ...fallback,
      warnings: [
        ...fallback.warnings,
        e instanceof Error ? e.message : "coverage_partial",
      ],
    });
  }
}
