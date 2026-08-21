/**
 * Daylight ride window — Gravel/MTB only.
 * Score is internal. Rider copy is a Hof sentence, never GO/NO-GO.
 * Numbers in the label are clock hours only (Numeric-Guard).
 */

import type { ChromeLang } from "@/lib/i18n/chromeLang";

export type RideWindowHour = {
  time: string;
  precipitation: number;
  precipitationProbability: number;
  windSpeedKmh: number;
};

export type RideWindowKind = "drier" | "all_dry" | "none";

export type RideWindowHit = {
  kind: "drier";
  startHour: number;
  endHour: number;
  startIso: string;
  endIso: string;
};

export type RideWindowResult =
  | RideWindowHit
  | { kind: "all_dry" | "none" };

const DRY_PROB = 25;
const DRY_MM = 0.15;
const DRIER_MARGIN = 8;
const WIND_HARD = 40;
const WIND_SOFT = 28;

export function profileAllowsRideWindow(
  profile?: string | null
): boolean {
  const p = (profile ?? "").trim().toLowerCase();
  if (!p) return false;
  if (
    p === "road" ||
    p === "urban" ||
    p === "auto" ||
    p === "city" ||
    p === "ebike" ||
    p === "hiking" ||
    p === "hike"
  ) {
    return false;
  }
  return (
    p === "gravel" ||
    p === "emtb" ||
    p === "downhill" ||
    p === "dh" ||
    p === "enduro" ||
    p.includes("mtb")
  );
}

export function hourOfIso(iso: string): number {
  const m = /T(\d{2})/.exec(iso);
  return m ? Number(m[1]) : NaN;
}

function avg(xs: number[]): number {
  if (xs.length === 0) return 0;
  return xs.reduce((s, n) => s + n, 0) / xs.length;
}

function slotScore(hours: RideWindowHour[]): number {
  const meanProb = avg(hours.map((h) => h.precipitationProbability));
  const meanMm = avg(hours.map((h) => h.precipitation));
  const meanWind = avg(hours.map((h) => h.windSpeedKmh));
  const windPen = meanWind > WIND_HARD ? 25 : meanWind > WIND_SOFT ? 10 : 0;
  return meanProb + meanMm * 8 + windPen;
}

function inDaylight(time: string, sunrise: string, sunset: string): boolean {
  return time >= sunrise && time <= sunset;
}

export function pickRideWindow(opts: {
  nowIso: string;
  sunriseIso: string;
  sunsetIso: string;
  hours: RideWindowHour[];
}): RideWindowResult {
  const daylight = opts.hours.filter(
    (h) =>
      inDaylight(h.time, opts.sunriseIso, opts.sunsetIso) &&
      h.time >= opts.nowIso
  );
  if (daylight.length < 2) return { kind: "none" };

  const dryAll = daylight.every(
    (h) =>
      h.precipitationProbability < DRY_PROB && h.precipitation < DRY_MM
  );
  if (dryAll) return { kind: "all_dry" };

  const candidates: {
    hours: RideWindowHour[];
    score: number;
  }[] = [];
  for (const len of [2, 3, 4]) {
    if (daylight.length < len) continue;
    for (let i = 0; i + len <= daylight.length; i++) {
      const slice = daylight.slice(i, i + len);
      candidates.push({ hours: slice, score: slotScore(slice) });
    }
  }
  if (candidates.length === 0) return { kind: "none" };
  candidates.sort((a, b) => {
    const ds = a.score - b.score;
    if (ds !== 0) return ds;
    return a.hours[0].time.localeCompare(b.hours[0].time);
  });
  const best = candidates[0];
  const dayScore = slotScore(daylight);
  const drier =
    best.score <= dayScore - DRIER_MARGIN ||
    best.hours.every(
      (h) =>
        h.precipitationProbability < DRY_PROB && h.precipitation < DRY_MM
    );
  if (!drier) return { kind: "none" };

  const startIso = best.hours[0].time;
  const lastIso = best.hours[best.hours.length - 1].time;
  const startHour = hourOfIso(startIso);
  const lastHour = hourOfIso(lastIso);
  if (!Number.isFinite(startHour) || !Number.isFinite(lastHour)) {
    return { kind: "none" };
  }
  return {
    kind: "drier",
    startHour,
    endHour: lastHour + 1,
    startIso,
    endIso: lastIso,
  };
}

export function formatRideWindowLabel(
  result: RideWindowResult,
  lang: ChromeLang = "de"
): string {
  if (result.kind === "all_dry") {
    switch (lang) {
      case "en":
        return "today looks dry throughout daylight";
      case "fr":
        return "aujourd’hui plutôt sec pendant le jour";
      case "it":
        return "oggi piuttosto asciutto nelle ore di luce";
      case "nl":
        return "vandaag overdag eerder droog";
      default:
        return "heute den ganzen Tag eher trocken";
    }
  }
  if (result.kind === "none") {
    switch (lang) {
      case "en":
        return "no clearer window today";
      case "fr":
        return "pas de créneau plus sec aujourd’hui";
      case "it":
        return "oggi nessuno spazio più asciutto";
      case "nl":
        return "vandaag geen droger venster";
      default:
        return "heute kein klareres Fenster";
    }
  }
  const a = result.startHour;
  const b = result.endHour;
  switch (lang) {
    case "en":
      return `today ${a}–${b} drier`;
    case "fr":
      return `aujourd’hui ${a}–${b} h plus sec`;
    case "it":
      return `oggi ${a}–${b} più asciutto`;
    case "nl":
      return `vandaag ${a}–${b} uur droger`;
    default:
      return `heute ${a}–${b} Uhr trockener`;
  }
}

export function rideWindowNumbers(hit: RideWindowHit): {
  value: number;
  unit: string;
  source: string;
}[] {
  return [
    { value: hit.startHour, unit: "", source: "weather.window.start" },
    { value: hit.endHour, unit: "", source: "weather.window.end" },
    { value: hit.startHour, unit: "h", source: "weather.window.start" },
    { value: hit.endHour, unit: "h", source: "weather.window.end" },
  ];
}

const GO_NOGO = /go\/?no-?go|\bno-?go\b|\bgo\b/i;

export function rideWindowCopyIsHof(label: string): boolean {
  return !GO_NOGO.test(label) && !/\bmm\b|\bpsi\b/i.test(label);
}
