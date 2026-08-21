import { NextResponse } from "next/server";
import {
  computeRoute,
  isValidLngLat,
} from "@/lib/routing/engine";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { isRoutingProfile } from "@/lib/routing/profiles";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";

/**
 * GET /api/route?profile=mtb_enduro&from=12.15,47.45&to=12.20,47.48&via=12.17,47.46
 *     &engine=graphhopper|openrouteservice|ors|valhalla|osrm
 *     &variant=planned|flatter|unpaved
 *     &access=1  — gravity/access leg: no OSM trail splice
 * POST { profile, from, to, vias?, engine?, variant?, access? }
 * Costing comes from `profile` (auto = car, hiking = foot). Engine only
 * translates that costing. Discover A–B keeps the engine line. OSM
 * trail/cycleway splice only with corridorSnap=1.
 */

function parseAccessFlag(raw: unknown): boolean {
  if (raw === true || raw === 1) return true;
  if (typeof raw !== "string") return false;
  const v = raw.trim().toLowerCase();
  return v === "1" || v === "true" || v === "yes";
}
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
  const profileRaw = searchParams.get("profile") || "mtb_allmountain";
  if (!isRoutingProfile(profileRaw)) {
    return NextResponse.json({ error: "invalid_profile" }, { status: 400 });
  }
  const profile: RoutingProfile = profileRaw;
  const from = parsePair(searchParams.get("from"));
  const to = parsePair(searchParams.get("to"));
  if (!from || !to || !isValidLngLat(from) || !isValidLngLat(to)) {
    return NextResponse.json(
      { error: "from/to required as lng,lat" },
      { status: 400 }
    );
  }
  const vias = parseVias(searchParams);
    const lang = chromeLangFrom(searchParams.get("lang"));
    const variant = searchParams.get("variant");
    try {
      const route = await computeRoute(profile, from, to, vias, lang, {
        engine: searchParams.get("engine"),
        accessLeg: parseAccessFlag(searchParams.get("access")),
        variant,
      });
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
    const profileRaw = (body.profile || "mtb_allmountain") as string;
    if (!isRoutingProfile(profileRaw)) {
      return NextResponse.json({ error: "invalid_profile" }, { status: 400 });
    }
    const profile: RoutingProfile = profileRaw;
    const from = body.from as [number, number];
    const to = body.to as [number, number];
    const viasRaw = Array.isArray(body.vias) ? body.vias : [];
    const vias = viasRaw.filter(
      (p: unknown): p is [number, number] =>
        Array.isArray(p) &&
        p.length === 2 &&
        isValidLngLat(p as [number, number])
    ) as [number, number][];
    const lang = chromeLangFrom(
      typeof body.lang === "string" ? body.lang : null
    );
    if (
      !Array.isArray(from) ||
      !Array.isArray(to) ||
      !isValidLngLat(from) ||
      !isValidLngLat(to)
    ) {
      return NextResponse.json({ error: "invalid from/to" }, { status: 400 });
    }
      const route = await computeRoute(profile, from, to, vias, lang, {
        engine: typeof body.engine === "string" ? body.engine : null,
        accessLeg: parseAccessFlag(body.access ?? body.accessLeg),
        variant: typeof body.variant === "string" ? body.variant : null,
      });
    return NextResponse.json(route);
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "routing failed" },
      { status: 502 }
    );
  }
}
