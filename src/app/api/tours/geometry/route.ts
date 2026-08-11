import { NextResponse } from "next/server";
import { computeTourGeometry } from "@/lib/routing/tourGeometry";
import { ROUTING_PROFILES, type RoutingProfile } from "@/lib/routing/profiles";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
} from "@/lib/routing/engine";

/**
 * GET /api/tours/geometry?id=r-bodensee-road&profile=road
 * Live-Geometrie für öffentliche Tour-Ideen (gecacht serverseitig).
 */
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id")?.trim();
  if (!id) {
    return NextResponse.json({ error: "id required" }, { status: 400 });
  }
  const profileParam = searchParams.get("profile") as RoutingProfile | null;
  const profile =
    profileParam && ROUTING_PROFILES[profileParam]
      ? profileParam
      : undefined;

  try {
    const result = await computeTourGeometry(id, profile);
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
