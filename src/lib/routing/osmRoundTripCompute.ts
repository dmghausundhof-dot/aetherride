/**
 * Server-only OSM round-trip: ORS `options.round_trip` + closed-loop check.
 * Do not import from client bundles (uses API key).
 */

import { trackIsClosedLoop } from "@/lib/discover/loopHonesty";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { isValidLngLat, type RouteResult } from "@/lib/routing/engine";
import {
  fetchOrsRoundTrip,
  isOrsConfigured,
} from "@/lib/routing/openRouteService";
import {
  OsmRoundTripError,
  normalizeRoundTripSeed,
  profileAllowsOsmRoundTrip,
  riderFacingLoopWarnings,
  roundTripLengthFromInput,
  roundTripWaypointCount,
} from "@/lib/routing/osmRoundTrip";
import type { RoutingProfile } from "@/lib/routing/profiles";

const cache = new Map<string, { at: number; result: RouteResult }>();
const CACHE_TTL_MS = 1000 * 60 * 45;

function cacheKey(
  start: [number, number],
  profile: RoutingProfile,
  lengthM: number,
  seed: number
): string {
  const lng = start[0].toFixed(3);
  const lat = start[1].toFixed(3);
  return `${lng},${lat}|${profile}|${lengthM}|${seed}`;
}

export async function computeOsmRoundTrip(input: {
  profile: RoutingProfile;
  start: [number, number];
  minutes?: number;
  lengthKm?: number;
  seed?: number;
  language?: ChromeLang;
  signal?: AbortSignal;
}): Promise<RouteResult> {
  const profile = input.profile;
  if (!profileAllowsOsmRoundTrip(profile)) {
    throw new OsmRoundTripError("profile_not_loopable");
  }
  if (!isValidLngLat(input.start)) {
    throw new OsmRoundTripError("invalid_from");
  }
  if (!isOrsConfigured()) {
    throw new OsmRoundTripError("ors_unconfigured");
  }

  const lengthM = roundTripLengthFromInput({
    profile,
    minutes: input.minutes,
    lengthKm: input.lengthKm,
  });
  const seed = normalizeRoundTripSeed(input.seed);
  const language = input.language ?? "de";
  const key = cacheKey(input.start, profile, lengthM, seed);
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) {
    return hit.result;
  }

  const ors = await fetchOrsRoundTrip({
    profile,
    start: input.start,
    lengthM,
    seed,
    points: roundTripWaypointCount(lengthM),
    signal: input.signal,
    language,
  });
  const coords = ors.geometry.coordinates as [number, number][];
  if (trackIsClosedLoop(coords) !== true) {
    throw new OsmRoundTripError("not_closed");
  }

  const result: RouteResult = {
    distanceM: ors.distanceM,
    durationS: ors.durationS,
    geometry: ors.geometry,
    engine: "openrouteservice",
    profile,
    steps: ors.steps,
    orsExtras: ors.extras,
    warnings: riderFacingLoopWarnings(ors.warnings, language),
    loop: true,
  };
  cache.set(key, { at: Date.now(), result });
  return result;
}
