/**
 * Open-Meteo snapshot for Hof / Discover / coverage.
 * 72h hourly soil reservoir when available; same trailHint enum as before.
 * Optional rideWindow (Gravel/MTB) — not shown on the Hof sky line.
 */

import {
  computeSoilTrailHint,
  type TrailHint,
  type TrailHintSource,
} from "@/lib/weather/soilHint";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import {
  formatRideWindowLabel,
  pickRideWindow,
  profileAllowsRideWindow,
  type RideWindowHour,
  type RideWindowResult,
} from "@/lib/weather/rideWindow";

export type RideWindowPayload = {
  label: string;
  kind: RideWindowResult["kind"];
  startHour?: number;
  endHour?: number;
};

export type OpenMeteoWeatherPayload = {
  provider: "open-meteo";
  lat: number;
  lon: number;
  current?: {
    temperature_2m?: number;
    precipitation?: number;
    weather_code?: number;
    wind_speed_10m?: number;
    time?: string;
  };
  daily?: {
    time?: string[];
    precipitation_sum?: number[];
    precipitation_probability_max?: number[];
    sunrise?: string[];
    sunset?: string[];
  };
  trailHint: TrailHint;
  trailHintSource: TrailHintSource;
  precip72hMm: number | null;
  rideWindow: RideWindowPayload | null;
  attribution: string;
};

type OpenMeteoJson = {
  current?: {
    temperature_2m?: number;
    precipitation?: number;
    weather_code?: number;
    wind_speed_10m?: number;
    time?: string;
  };
  hourly?: {
    time?: string[];
    precipitation?: number[];
    precipitation_probability?: number[];
    wind_speed_10m?: number[];
  };
  daily?: {
    time?: string[];
    precipitation_sum?: number[];
    precipitation_probability_max?: number[];
    sunrise?: string[];
    sunset?: string[];
  };
};

/** past_days=3 puts today at the last daily slot, not index 0. */
export function dailyIndexForNow(
  dailyTimes: string[] | undefined,
  nowIso: string | undefined
): number {
  const times = dailyTimes ?? [];
  if (times.length === 0) return -1;
  const key = (nowIso ?? "").slice(0, 10);
  if (key.length === 10) {
    const i = times.findIndex((t) => t === key || t.startsWith(key));
    if (i >= 0) return i;
  }
  return times.length - 1;
}

function parseHourly(json: OpenMeteoJson) {
  const times = json.hourly?.time ?? [];
  const precip = json.hourly?.precipitation ?? [];
  const n = Math.min(times.length, precip.length);
  const out: { time: string; precipitation: number }[] = [];
  for (let i = 0; i < n; i++) {
    const t = times[i];
    const p = Number(precip[i]);
    if (!t || !Number.isFinite(p)) continue;
    out.push({ time: t, precipitation: p });
  }
  return out;
}

function parseRideHours(json: OpenMeteoJson): RideWindowHour[] {
  const times = json.hourly?.time ?? [];
  const precip = json.hourly?.precipitation ?? [];
  const prob = json.hourly?.precipitation_probability ?? [];
  const wind = json.hourly?.wind_speed_10m ?? [];
  const n = times.length;
  const out: RideWindowHour[] = [];
  for (let i = 0; i < n; i++) {
    const t = times[i];
    if (!t) continue;
    const p = Number(precip[i] ?? 0);
    const pr = Number(prob[i] ?? 0);
    const w = Number(wind[i] ?? 0);
    out.push({
      time: t,
      precipitation: Number.isFinite(p) ? p : 0,
      precipitationProbability: Number.isFinite(pr) ? pr : 0,
      windSpeedKmh: Number.isFinite(w) ? w : 0,
    });
  }
  return out;
}

function toRideWindowPayload(
  result: RideWindowResult,
  lang: ChromeLang
): RideWindowPayload {
  const label = formatRideWindowLabel(result, lang);
  if (result.kind === "drier") {
    return {
      label,
      kind: "drier",
      startHour: result.startHour,
      endHour: result.endHour,
    };
  }
  return { label, kind: result.kind };
}

export async function fetchOpenMeteoWeather(opts: {
  lat: number;
  lon: number;
  profile?: string | null;
  lang?: ChromeLang | null;
  signal?: AbortSignal;
}): Promise<OpenMeteoWeatherPayload> {
  const api = new URL("https://api.open-meteo.com/v1/forecast");
  api.searchParams.set("latitude", String(opts.lat));
  api.searchParams.set("longitude", String(opts.lon));
  api.searchParams.set(
    "current",
    "temperature_2m,precipitation,weather_code,wind_speed_10m"
  );
  api.searchParams.set(
    "daily",
    "precipitation_sum,precipitation_probability_max,sunrise,sunset"
  );
  api.searchParams.set(
    "hourly",
    "precipitation,precipitation_probability,wind_speed_10m"
  );
  api.searchParams.set("past_days", "3");
  api.searchParams.set("forecast_days", "1");
  api.searchParams.set("timezone", "auto");

  const res = await fetch(api.toString(), {
    signal: opts.signal,
    next: { revalidate: 1800 },
  });
  if (!res.ok) {
    throw new Error(`open-meteo ${res.status}`);
  }
  const data = (await res.json()) as OpenMeteoJson;
  const hourly = parseHourly(data);
  const nowRaw = data.current?.time;
  const now = nowRaw ? new Date(nowRaw) : new Date();
  const dayIdx = dailyIndexForNow(data.daily?.time, nowRaw);
  const soil = computeSoilTrailHint({
    hourly,
    now: Number.isFinite(now.getTime()) ? now : new Date(),
    profile: opts.profile,
    currentPrecipMm: data.current?.precipitation,
    dailyPrecipMm:
      dayIdx >= 0 ? data.daily?.precipitation_sum?.[dayIdx] : undefined,
  });

  let rideWindow: RideWindowPayload | null = null;
  if (profileAllowsRideWindow(opts.profile)) {
    const sunrise =
      dayIdx >= 0 ? data.daily?.sunrise?.[dayIdx] : data.daily?.sunrise?.[0];
    const sunset =
      dayIdx >= 0 ? data.daily?.sunset?.[dayIdx] : data.daily?.sunset?.[0];
    const nowIso = data.current?.time ?? sunrise;
    if (sunrise && sunset && nowIso) {
      const picked = pickRideWindow({
        nowIso,
        sunriseIso: sunrise,
        sunsetIso: sunset,
        hours: parseRideHours(data),
      });
      rideWindow = toRideWindowPayload(picked, opts.lang ?? "de");
    }
  }

  return {
    provider: "open-meteo",
    lat: opts.lat,
    lon: opts.lon,
    current: data.current,
    daily: data.daily,
    trailHint: soil.trailHint,
    trailHintSource: soil.source,
    precip72hMm: soil.precip72hMm,
    rideWindow,
    attribution: "Weather data by Open-Meteo.com",
  };
}
