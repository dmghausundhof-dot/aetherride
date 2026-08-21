import { NextResponse } from "next/server";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";
import { isValidLngLat } from "@/lib/routing/engine";
import { OsmRoundTripError } from "@/lib/routing/osmRoundTrip";
import { computeOsmRoundTrip } from "@/lib/routing/osmRoundTripCompute";
import {
  isRoutingProfile,
  type RoutingProfile,
} from "@/lib/routing/profiles";

/**
 * POST /api/route/loop
 * { profile, from: [lng,lat], minutes?, lengthKm?, seed?, lang? }
 *
 * OSM round-trip via OpenRouteService `options.round_trip`.
 * Sport gate: road / urban / gravel / ebike only.
 */

function parseFrom(raw: unknown): [number, number] | null {
  if (Array.isArray(raw) && raw.length >= 2) {
    const lng = Number(raw[0]);
    const lat = Number(raw[1]);
    if (Number.isFinite(lng) && Number.isFinite(lat)) return [lng, lat];
  }
  if (typeof raw === "string") {
    const parts = raw.split(",").map(Number);
    if (
      parts.length === 2 &&
      parts.every((n) => Number.isFinite(n))
    ) {
      return [parts[0], parts[1]];
    }
  }
  return null;
}

function statusFor(code: OsmRoundTripError["code"]): number {
  switch (code) {
    case "profile_not_loopable":
    case "invalid_from":
      return 400;
    case "ors_unconfigured":
      return 503;
    case "not_closed":
      return 422;
    default:
      return 502;
  }
}

export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 });
  }

  const profileRaw = typeof body.profile === "string" ? body.profile : "";
  if (!isRoutingProfile(profileRaw)) {
    return NextResponse.json({ error: "invalid_profile" }, { status: 400 });
  }
  const profile: RoutingProfile = profileRaw;
  const from = parseFrom(body.from);
  if (!from || !isValidLngLat(from)) {
    return NextResponse.json(
      { error: "from required as [lng,lat]" },
      { status: 400 }
    );
  }

  const minutes = Number(body.minutes);
  const lengthKm = Number(body.lengthKm);
  const lang = chromeLangFrom(
    typeof body.lang === "string" ? body.lang : null
  );

  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), 22_000);
  try {
    const route = await computeOsmRoundTrip({
      profile,
      start: from,
      minutes: Number.isFinite(minutes) ? minutes : undefined,
      lengthKm: Number.isFinite(lengthKm) && lengthKm > 0 ? lengthKm : undefined,
      seed: body.seed as number | undefined,
      language: lang,
      signal: ac.signal,
    });
    return NextResponse.json(route);
  } catch (e) {
    if (e instanceof OsmRoundTripError) {
      return NextResponse.json({ error: e.code }, { status: statusFor(e.code) });
    }
    const aborted =
      e instanceof Error &&
      (e.name === "AbortError" || /aborted/i.test(e.message));
    return NextResponse.json(
      {
        error: aborted
          ? "timeout"
          : e instanceof Error
            ? e.message
            : "loop failed",
      },
      { status: 502 }
    );
  } finally {
    clearTimeout(timer);
  }
}
