import { NextResponse } from "next/server";
import { fetchOsmRoutesNear } from "@/lib/coverage/osmLive";

/**
 * Live OSM-Routen (relation route=bicycle|mtb|hiking) — DACH+FR.
 * GET /api/osm-routes?lat=&lon=&radiusKm=
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(
    url.searchParams.get("lon") ?? url.searchParams.get("lng") ?? NaN
  );
  const radiusKm = Math.min(
    40,
    Math.max(5, Number(url.searchParams.get("radiusKm") || 18))
  );

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return NextResponse.json(
      { error: "lat_lon_required", routes: [] },
      { status: 400 }
    );
  }

  try {
    const { routes, warning } = await fetchOsmRoutesNear({
      lat,
      lon,
      radiusKm,
    });
    return NextResponse.json({
      provider: "osm_overpass",
      configured: true,
      usingDemoFallback: false,
      lat,
      lon,
      radiusKm,
      routes,
      tours: routes,
      warning,
      attribution: "© OpenStreetMap Mitwirkende",
    });
  } catch (e) {
    return NextResponse.json({
      provider: "osm_overpass",
      routes: [],
      tours: [],
      warning: e instanceof Error ? e.message : "overpass_failed",
    });
  }
}
