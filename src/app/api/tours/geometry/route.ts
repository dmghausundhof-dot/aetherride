import { NextResponse } from "next/server";
import {
  computeNearGeometry,
  computeTourGeometry,
} from "@/lib/routing/tourGeometry";
import { ROUTING_PROFILES, type RoutingProfile } from "@/lib/routing/profiles";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
  isValidLngLat,
} from "@/lib/routing/engine";

/**
 * GET /api/tours/geometry
 * - ?id=r-bodensee-road&profile=road&forceLive=1
 * - ?lat=48&lng=7.85&profile=road&mode=loop&distanceKm=25
 * - ?lat=&lng=&toLat=&toLng=  (A→B ab GPS)
 */
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id")?.trim();
  const profileParam = searchParams.get("profile") as RoutingProfile | null;
  const profile: RoutingProfile =
    profileParam && ROUTING_PROFILES[profileParam]
      ? profileParam
      : "road";
  const forceLive =
    searchParams.get("forceLive") === "1" ||
    searchParams.get("forceLive") === "true";

  const lat = Number(searchParams.get("lat"));
  const lng = Number(
    searchParams.get("lng") ?? searchParams.get("lon") ?? NaN
  );
  const toLat = Number(searchParams.get("toLat"));
  const toLng = Number(
    searchParams.get("toLng") ?? searchParams.get("toLon") ?? NaN
  );
  const distanceKm = Number(searchParams.get("distanceKm") || 25);
  const modeParam = searchParams.get("mode");
  const mode =
    modeParam === "point_to_point" || modeParam === "loop"
      ? modeParam
      : undefined;
  const label = searchParams.get("label") ?? undefined;

  try {
    if (id) {
      const result = await computeTourGeometry(id, profile, { forceLive });
      if (!result) {
        return NextResponse.json({ error: "tour_not_found" }, { status: 404 });
      }
      return NextResponse.json({
        ...result,
        routing: {
          engine: configuredRoutingEngine(),
          liveConfigured: isLiveRoutingConfigured(),
        },
      });
    }

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      const center: [number, number] = [lng, lat];
      if (!isValidLngLat(center)) {
        return NextResponse.json({ error: "invalid_lat_lng" }, { status: 400 });
      }
      const end =
        Number.isFinite(toLat) && Number.isFinite(toLng)
          ? ([toLng, toLat] as [number, number])
          : undefined;
      if (end && !isValidLngLat(end)) {
        return NextResponse.json({ error: "invalid_to" }, { status: 400 });
      }
      const result = await computeNearGeometry({
        center,
        profile,
        mode: end ? "point_to_point" : mode,
        distanceKm: Number.isFinite(distanceKm) ? distanceKm : 25,
        end,
        label,
      });
      return NextResponse.json({
        ...result,
        routing: {
          engine: configuredRoutingEngine(),
          liveConfigured: isLiveRoutingConfigured(),
        },
      });
    }

    return NextResponse.json(
      {
        error: "id_or_lat_lng_required",
        hint: "Use ?id=tourId or ?lat=&lng= (optional mode, distanceKm, toLat, toLng)",
      },
      { status: 400 }
    );
  } catch (e) {
    return NextResponse.json(
      {
        error: e instanceof Error ? e.message : "geometry failed",
        engine: configuredRoutingEngine(),
        liveConfigured: isLiveRoutingConfigured(),
      },
      { status: 502 }
    );
  }
}
