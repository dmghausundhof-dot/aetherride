/**
 * Live OSM-Trailnetz (Ways) — Singletrack/Cycleway mit Difficulty.
 * GET /api/osm-trails?lat=&lon=&radiusKm=
 * Optional: west=&south=&east=&north= (viewport, max ~0.4°)
 *
 * Relations bleiben bei /api/osm-routes (Touren).
 * sac_scale wird NICHT auf S0–S3+ umgemünzt.
 */

import { NextResponse } from "next/server";
import {
  bboxFromRadius,
  clampBbox,
  fetchOsmTrailsNear,
  type OsmTrail,
} from "@/lib/coverage/osmLive";

export type { OsmTrail };

export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(
    url.searchParams.get("lon") ?? url.searchParams.get("lng") ?? NaN
  );
  const west = Number(url.searchParams.get("west"));
  const south = Number(url.searchParams.get("south"));
  const east = Number(url.searchParams.get("east"));
  const north = Number(url.searchParams.get("north"));
  const hasBbox = [west, south, east, north].every((n) => Number.isFinite(n));
  const hasPoint = Number.isFinite(lat) && Number.isFinite(lon);

  if (!hasBbox && !hasPoint) {
    return NextResponse.json(
      { error: "lat_lon_or_bbox_required", trails: [] },
      { status: 400 }
    );
  }

  const bbox = hasBbox
    ? clampBbox({ west, south, east, north })
    : undefined;
  const centerLat = hasPoint ? lat : (south + north) / 2;
  const centerLon = hasPoint ? lon : (west + east) / 2;
  const radiusKm = Math.min(
    18,
    Math.max(3, Number(url.searchParams.get("radiusKm") || 8))
  );

  try {
    const { trails, warning } = await fetchOsmTrailsNear({
      lat: centerLat,
      lon: centerLon,
      radiusKm,
      bbox: bbox ?? bboxFromRadius(centerLat, centerLon, radiusKm),
    });
    return NextResponse.json({
      provider: "osm_overpass",
      configured: true,
      lat: centerLat,
      lon: centerLon,
      radiusKm,
      trails,
      warning,
      attribution: "© OpenStreetMap Mitwirkende",
      legend: {
        S0: "#4CAF50",
        S1: "#8BC34A",
        S2: "#FFC107",
        "S3+": "#E53935",
        offen: "#90A4AE",
      },
    });
  } catch (e) {
    return NextResponse.json({
      provider: "osm_overpass",
      trails: [],
      warning: e instanceof Error ? e.message : "overpass_failed",
    });
  }
}
