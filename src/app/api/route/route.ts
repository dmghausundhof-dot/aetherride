import { NextResponse } from "next/server";
import {
  computeRoute,
  isValidLngLat,
} from "@/lib/routing/engine";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { ROUTING_PROFILES } from "@/lib/routing/profiles";

/**
 * GET /api/route?profile=mtb_enduro&from=12.15,47.45&to=12.20,47.48&via=12.17,47.46
 * POST { profile, from, to, vias?: [lng,lat][] }
 */
function parsePair(s: string | null): [number, number] | null {
  if (!s) return null;
  const parts = s.split(",").map(Number);
  if (parts.length !== 2 || parts.some((n) => !Number.isFinite(n))) return null;
  return [parts[0], parts[1]];
}

function parseVias(searchParams: URLSearchParams): [number, number][] {
  const vias: [number, number][] = [];
  for (const v of searchParams.getAll("via")) {
    const p = parsePair(v);
    if (p && isValidLngLat(p)) vias.push(p);
  }
  return vias;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const profile = (searchParams.get("profile") ||
    "mtb_allmountain") as RoutingProfile;
  if (!ROUTING_PROFILES[profile]) {
    return NextResponse.json({ error: "invalid_profile" }, { status: 400 });
  }
  const from = parsePair(searchParams.get("from"));
  const to = parsePair(searchParams.get("to"));
  if (!from || !to || !isValidLngLat(from) || !isValidLngLat(to)) {
    return NextResponse.json(
      { error: "from/to required as lng,lat" },
      { status: 400 }
    );
  }
  const vias = parseVias(searchParams);
  try {
    const route = await computeRoute(profile, from, to, vias);
    return NextResponse.json(route);
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "routing failed" },
      { status: 502 }
    );
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const profile = (body.profile || "mtb_allmountain") as RoutingProfile;
    if (!ROUTING_PROFILES[profile]) {
      return NextResponse.json({ error: "invalid_profile" }, { status: 400 });
    }
    const from = body.from as [number, number];
    const to = body.to as [number, number];
    const viasRaw = Array.isArray(body.vias) ? body.vias : [];
    const vias = viasRaw.filter(
      (p: unknown): p is [number, number] =>
        Array.isArray(p) &&
        p.length === 2 &&
        isValidLngLat(p as [number, number])
    ) as [number, number][];
    if (
      !Array.isArray(from) ||
      !Array.isArray(to) ||
      !isValidLngLat(from) ||
      !isValidLngLat(to)
    ) {
      return NextResponse.json({ error: "invalid from/to" }, { status: 400 });
    }
    const route = await computeRoute(profile, from, to, vias);
    return NextResponse.json(route);
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "routing failed" },
      { status: 502 }
    );
  }
}
