import { NextResponse } from "next/server";
import { buildTrailforksPins } from "@/lib/geo/trailCondition";

/**
 * Trailforks Attribution + Deep-Links (kein Geometry-Mirror, kein Wetter-als-Zustand).
 * GET /api/trailforks?lat=&lon=
 * `hint` wird ignoriert — Open-Meteo bleibt am Hof.
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
