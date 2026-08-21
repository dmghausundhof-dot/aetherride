import { NextResponse } from "next/server";
import { isValidLngLat, warmGraphhopperFlexible } from "@/lib/routing/engine";
import {
  isRoutingProfile,
  type RoutingProfile,
} from "@/lib/routing/profiles";

export const maxDuration = 20;

/**
 * GET /api/route/warmup?profile=gravel&near=lng,lat
 *
 * Compiles GraphHopper custom_model in the rider's cell so the first
 * visible A–B is not the cold POST. Fire-and-forget from Discover.
 */

function parsePair(s: string | null): [number, number] | null {
  if (!s) return null;
  const parts = s.split(",").map(Number);
  if (parts.length !== 2 || parts.some((n) => !Number.isFinite(n))) return null;
  return [parts[0], parts[1]];
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const profileRaw = searchParams.get("profile") || "mtb_allmountain";
  if (!isRoutingProfile(profileRaw)) {
    return NextResponse.json({ error: "invalid_profile", ok: false }, { status: 400 });
  }
  const near = parsePair(searchParams.get("near"));
  if (!near || !isValidLngLat(near)) {
    return NextResponse.json(
      { error: "near required as lng,lat", ok: false },
      { status: 400 }
    );
  }
  const profile: RoutingProfile = profileRaw;
  const ok = await warmGraphhopperFlexible(profile, near);
  return NextResponse.json({ ok });
}
