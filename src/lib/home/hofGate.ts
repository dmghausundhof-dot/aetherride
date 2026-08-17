/**
 * One nearby ~60 min loop. GPS picks the region — never a Rhein-Neckar default.
 * Port of mobile/lib/domain/home/hof_gate.dart
 */

import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { haversineKm } from "@/lib/routing/demoGeometry";
import type { SavedRoute } from "@/types/route";
import type { BikeCategory } from "@/types";

export type HofGateHonesty = "loop" | "wetClosed" | "none";

export type HofGatePick = {
  honesty: HofGateHonesty;
  seed?: RouteSuggestion;
  saved?: SavedRoute;
  distanceKm?: number;
};

const TARGET_MIN = 60;
const BAND_LO = 45;
const BAND_HI = 75;
const MAX_DISTANCE_KM = 80;

export function durationInBand(
  durationMin: number,
  targetMin = TARGET_MIN
): boolean {
  const lo = targetMin === 60 ? BAND_LO : Math.round(targetMin * 0.75);
  const hi = targetMin === 60 ? BAND_HI : Math.round(targetMin * 1.25);
  return durationMin >= lo && durationMin <= hi;
}

/** Trail/MTB/gravel loops are not an honest gate hour when the ground is wet. */
export function isTrailHeavyLoop(route: {
  id: string;
  category?: string;
  surface?: string;
}): boolean {
  const id = route.id.toLowerCase();
  if (id.includes("mtb") || id.includes("trail")) return true;
  const cat = (route.category ?? "").toLowerCase();
  if (
    cat.startsWith("mtb") ||
    cat === "emtb" ||
    cat === "dh"
  ) {
    return true;
  }
  const surface = (route.surface ?? "").toLowerCase();
  return /\btrail\b/.test(surface) || /\bgravel\b/.test(surface);
}

function sportFamily(category: string | undefined): string {
  const c = (category ?? "").toLowerCase();
  if (
    c === "mtb_trail" ||
    c === "mtb_am" ||
    c === "mtb_enduro" ||
    c === "dh" ||
    c === "emtb"
  ) {
    return "mtb";
  }
  if (c === "gravel") return "gravel";
  if (c === "road") return "road";
  if (c === "urban") return "urban";
  if (c === "cargo" || c === "folding" || c === "kids") return "urban";
  if (c === "etrekking") return "touring";
  if (c === "hiking") return "hike";
  return c;
}

function softSportMatch(
  tourCategory: string | undefined,
  preferred?: BikeCategory | null
): boolean {
  if (!preferred) return false;
  const tour = (tourCategory ?? "").toLowerCase();
  const pref = preferred.toLowerCase();
  if (tour === pref) return true;
  if (sportFamily(tour) === sportFamily(pref) && sportFamily(pref) !== "") {
    return true;
  }
  if (pref === "etrekking") {
    return tour === "road" || tour === "gravel" || tour === "urban";
  }
  if (tour === "etrekking") {
    return pref === "road" || pref === "gravel" || pref === "urban";
  }
  return false;
}

function savedInWindow(saved: SavedRoute[]): SavedRoute | undefined {
  return saved.find(
    (r) =>
      durationInBand(r.durationMin) &&
      r.distanceKm > 0 &&
      r.distanceKm <= 40
  );
}

export function pickHofGate(opts: {
  loops: RouteSuggestion[];
  saved?: SavedRoute[];
  lat?: number | null;
  lng?: number | null;
  trailsWet?: boolean;
  maxDistanceKm?: number;
  preferred?: BikeCategory | null;
}): HofGatePick {
  const saved = opts.saved ?? [];
  const maxKm = opts.maxDistanceKm ?? MAX_DISTANCE_KM;
  const lat = opts.lat;
  const lng = opts.lng;

  if (lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng)) {
    const ranked: { seed: RouteSuggestion; km: number }[] = [];
    for (const r of opts.loops) {
      if (!r.loop) continue;
      if (!durationInBand(r.durationMin)) continue;
      if (!r.center) continue;
      const km = haversineKm([lng, lat], r.center);
      if (km > maxKm) continue;
      ranked.push({ seed: r, km });
    }
    ranked.sort((a, b) => a.km - b.km);

    if (opts.trailsWet) {
      const asphalt = ranked.find((e) => !isTrailHeavyLoop(e.seed));
      if (asphalt) {
        return {
          honesty: "loop",
          seed: asphalt.seed,
          distanceKm: asphalt.km,
        };
      }
      return { honesty: "wetClosed" };
    }

    if (ranked.length > 0) {
      if (opts.preferred) {
        const match = ranked.find((e) =>
          softSportMatch(e.seed.category, opts.preferred)
        );
        if (match) {
          return {
            honesty: "loop",
            seed: match.seed,
            distanceKm: match.km,
          };
        }
      }
      return {
        honesty: "loop",
        seed: ranked[0].seed,
        distanceKm: ranked[0].km,
      };
    }
  }

  if (opts.trailsWet) return { honesty: "wetClosed" };

  const s = savedInWindow(saved);
  if (s) return { honesty: "loop", saved: s };

  return { honesty: "none" };
}

export function hofGateHasLoop(pick: HofGatePick): boolean {
  return pick.seed != null || pick.saved != null;
}

/** Title when the gate has no loop. Wet-closed is not “no loop exists”. */
export function hofGateEmptyTitle(
  honesty: HofGateHonesty,
  copy: { gateWetClosed: string; noHonestLoop: string }
): string {
  return honesty === "wetClosed" ? copy.gateWetClosed : copy.noHonestLoop;
}

export function hofGateTitle(pick: HofGatePick): string {
  return pick.seed?.name ?? pick.saved?.name ?? "";
}

export function hofGateDurationMin(pick: HofGatePick): number {
  return pick.seed?.durationMin ?? pick.saved?.durationMin ?? 0;
}

export function hofGateId(pick: HofGatePick): string | undefined {
  return pick.seed?.id ?? pick.saved?.id;
}

/** GPS distance to the gate loop. Not the loop length. */
export function formatHofGateAway(
  distanceKm: number | undefined,
  copy: { near: string; km: (n: number) => string }
): string | null {
  if (distanceKm == null || !Number.isFinite(distanceKm) || distanceKm <= 0) {
    return null;
  }
  if (distanceKm < 1) return copy.near;
  return copy.km(Math.min(80, Math.max(1, Math.round(distanceKm))));
}
