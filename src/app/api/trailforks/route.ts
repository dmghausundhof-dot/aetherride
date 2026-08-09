import { NextResponse } from "next/server";
import { buildTrailforksPins } from "@/lib/geo/trailCondition";

/**
 * Trailforks Condition Layer (Attribution + Wetter-Proxy).
 * GET /api/trailforks?hint=dry_likely|damp_possible|wet_likely&lat=&lon=
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const hint = url.searchParams.get("hint");
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(url.searchParams.get("lon"));
  const near =
    Number.isFinite(lat) && Number.isFinite(lon) ? { lat, lon } : null;
  const payload = buildTrailforksPins(hint, near);
  return NextResponse.json(payload);
}
