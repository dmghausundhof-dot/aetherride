import { NextResponse } from "next/server";
import { fetchTrailViewNear } from "@/lib/routing/trailView";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const lat = Number(searchParams.get("lat") || 47.45);
  const lng = Number(searchParams.get("lng") || 12.15);
  const result = await fetchTrailViewNear(lat, lng);
  return NextResponse.json(result);
}
