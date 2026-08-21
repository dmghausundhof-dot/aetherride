/**
 * 72h soil / trail wetness — maps onto existing trailHint enum only.
 * No "Mud Extreme". Hourly Open-Meteo series, decay by surface class.
 */

export type TrailHint = "dry_likely" | "damp_possible" | "wet_likely";
export type SoilClass = "asphalt" | "mixed" | "earth";
export type TrailHintSource = "soil_72h" | "current_precip" | "daily_sum";

export type HourlyPrecip = {
  time: string;
  precipitation: number;
};

const WET_WEIGHTED_MM = 8;
const DAMP_WEIGHTED_MM = 2;
const WET_INSTANT_MM = 5;
const DAMP_INSTANT_MM = 1;
const WINDOW_H = 72;

export function soilClassForProfile(profile?: string | null): SoilClass {
  const p = (profile ?? "").trim().toLowerCase();
  if (
    p === "road" ||
    p === "urban" ||
    p === "auto" ||
    p === "city"
  ) {
    return "asphalt";
  }
  if (
    p === "mtb" ||
    p === "mtbam" ||
    p === "mtb_allmountain" ||
    p === "mtb_enduro" ||
    p === "mtb_am" ||
    p === "mtb_trail" ||
    p === "downhill" ||
    p === "dh" ||
    p === "emtb" ||
    p === "hiking" ||
    p === "hike"
  ) {
    return "earth";
  }
  return "mixed";
}

/** Decay time constant: asphalt drains faster, earth holds rain longer. */
export function soilTauHours(soil: SoilClass): number {
  switch (soil) {
    case "asphalt":
      return 16;
    case "earth":
      return 48;
    default:
      return 32;
  }
}

export function trailHintFromWeightedMm(mm: number): TrailHint {
  if (mm >= WET_WEIGHTED_MM) return "wet_likely";
  if (mm >= DAMP_WEIGHTED_MM) return "damp_possible";
  return "dry_likely";
}

/** Legacy / fallback: current hour or today's daily sum. */
export function trailHintFromInstantPrecip(mm: number): TrailHint {
  if (mm >= WET_INSTANT_MM) return "wet_likely";
  if (mm >= DAMP_INSTANT_MM) return "damp_possible";
  return "dry_likely";
}

export function weightedPrecipMm(
  hours: HourlyPrecip[],
  now: Date,
  tauHours: number,
  windowH = WINDOW_H
): number {
  const nowMs = now.getTime();
  let sum = 0;
  for (const h of hours) {
    const t = Date.parse(h.time);
    if (!Number.isFinite(t)) continue;
    const ageH = (nowMs - t) / 3_600_000;
    if (!Number.isFinite(ageH) || ageH < -0.5 || ageH > windowH) continue;
    const age = Math.max(0, ageH);
    const p = Number(h.precipitation);
    if (!Number.isFinite(p) || p <= 0) continue;
    sum += p * Math.exp(-age / tauHours);
  }
  return sum;
}

export function computeSoilTrailHint(opts: {
  hourly?: HourlyPrecip[] | null;
  now?: Date;
  profile?: string | null;
  currentPrecipMm?: number | null;
  dailyPrecipMm?: number | null;
}): {
  trailHint: TrailHint;
  source: TrailHintSource;
  precip72hMm: number | null;
} {
  const now = opts.now ?? new Date();
  const soil = soilClassForProfile(opts.profile);
  const hourly = opts.hourly ?? [];
  if (hourly.length >= 8) {
    const precip72hMm = weightedPrecipMm(
      hourly,
      now,
      soilTauHours(soil)
    );
    return {
      trailHint: trailHintFromWeightedMm(precip72hMm),
      source: "soil_72h",
      precip72hMm: Math.round(precip72hMm * 10) / 10,
    };
  }
  const current = opts.currentPrecipMm;
  if (typeof current === "number" && Number.isFinite(current) && current > 0) {
    return {
      trailHint: trailHintFromInstantPrecip(current),
      source: "current_precip",
      precip72hMm: null,
    };
  }
  const daily = opts.dailyPrecipMm ?? 0;
  return {
    trailHint: trailHintFromInstantPrecip(
      Number.isFinite(daily) ? daily : 0
    ),
    source: "daily_sum",
    precip72hMm: null,
  };
}
