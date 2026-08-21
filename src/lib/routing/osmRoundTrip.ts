/**
 * OSM round-trip helper — sport gate, length, honesty copy.
 * No network. Client + server may import this file.
 */

import type { ChromeLang } from "@/lib/i18n/chromeLang";
import type { RoutingProfile } from "@/lib/routing/profiles";

/** ORS mountain costing is forest road, not a Trailforks trail. */
const LOOPABLE_PROFILES = new Set<RoutingProfile>([
  "road",
  "urban",
  "gravel",
  "ebike",
]);

export type OsmRoundTripErrorCode =
  | "profile_not_loopable"
  | "ors_unconfigured"
  | "not_closed"
  | "invalid_from";

export class OsmRoundTripError extends Error {
  readonly code: OsmRoundTripErrorCode;
  constructor(code: OsmRoundTripErrorCode, message?: string) {
    super(message ?? code);
    this.name = "OsmRoundTripError";
    this.code = code;
  }
}

export function profileAllowsOsmRoundTrip(
  profile: RoutingProfile
): boolean {
  return LOOPABLE_PROFILES.has(profile);
}

export function defaultLoopSpeedKmh(profile: RoutingProfile): number {
  switch (profile) {
    case "road":
      return 25.2;
    case "gravel":
      return 18;
    case "urban":
    case "ebike":
      return 21.6;
    default:
      return 18;
  }
}

/** Target loop length in metres. Minutes 0 / invalid → 60 min. Clamped 5–120 km. */
export function roundTripLengthM(
  profile: RoutingProfile,
  minutes: number
): number {
  const min =
    Number.isFinite(minutes) && minutes > 0 ? minutes : 60;
  const m = Math.round((min / 60) * defaultLoopSpeedKmh(profile) * 1000);
  return Math.min(120_000, Math.max(5_000, m));
}

export function roundTripLengthFromInput(opts: {
  profile: RoutingProfile;
  minutes?: number;
  lengthKm?: number;
}): number {
  const km = opts.lengthKm;
  if (typeof km === "number" && Number.isFinite(km) && km > 0) {
    return Math.min(120_000, Math.max(5_000, Math.round(km * 1000)));
  }
  return roundTripLengthM(opts.profile, opts.minutes ?? 0);
}

/** ORS round_trip waypoint count — 4–6. */
export function roundTripWaypointCount(lengthM: number): number {
  if (lengthM < 25_000) return 4;
  if (lengthM < 55_000) return 5;
  return 6;
}

export function normalizeRoundTripSeed(raw: unknown): number {
  const n = typeof raw === "number" ? raw : Number(raw);
  if (!Number.isFinite(n) || n < 1) return 1;
  return Math.min(10_000, Math.floor(n));
}

export function loopOsmHonesty(lang: ChromeLang): string {
  switch (lang) {
    case "en":
      return "Loop on OSM ways — not a Trailforks trail";
    case "fr":
      return "Boucle sur chemins OSM — pas un sentier Trailforks";
    case "it":
      return "Anello su vie OSM — non un trail Trailforks";
    case "nl":
      return "Lus over OSM-wegen — geen Trailforks-trail";
    default:
      return "Rundkurs auf OSM-Wegen — kein Trailforks-Trail";
  }
}

const ENGINE_BRAND =
  /openrouteservice|graphhopper|valhalla|\bosrm\b|\bors\b/i;

export function riderFacingLoopWarnings(
  engineWarnings: string[],
  lang: ChromeLang
): string[] {
  const hint = loopOsmHonesty(lang);
  const cleaned: string[] = [];
  for (const raw of engineWarnings) {
    const w = raw
      .replace(/OpenRouteService/gi, "")
      .replace(/\bORS\b/g, "")
      .replace(/\bGraphHopper\b/gi, "")
      .replace(/\bValhalla\b/gi, "")
      .replace(/\bOSRM\b/gi, "")
      .replace(/\s{2,}/g, " ")
      .replace(/^[\s:—\-–]+/, "")
      .trim();
    if (w.length < 8) continue;
    if (ENGINE_BRAND.test(w)) continue;
    if (w === hint) continue;
    cleaned.push(w);
  }
  return [hint, ...cleaned];
}
