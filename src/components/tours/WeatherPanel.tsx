"use client";

import { useEffect, useState } from "react";
import { Cloud, CloudRain, Sun, Wind } from "lucide-react";

type WeatherPayload = {
  provider: string;
  current?: {
    temperature_2m?: number;
    precipitation?: number;
    weather_code?: number;
    wind_speed_10m?: number;
  };
  daily?: {
    precipitation_sum?: number[];
    precipitation_probability_max?: number[];
  };
  trailHint?: string;
  attribution?: string;
  error?: string;
};

const HINT_DE: Record<string, string> = {
  wet_likely: "Nass wahrscheinlich — Trails rutschig möglich",
  damp_possible: "Leicht feucht möglich",
  dry_likely: "Eher trocken",
};

export function WeatherPanel({
  lat,
  lng,
  className = "",
}: {
  lat: number;
  lng: number;
  className?: string;
}) {
  const [data, setData] = useState<WeatherPayload | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setErr(null);
    const q = new URLSearchParams({
      lat: String(lat),
      lon: String(lng),
    });
    void fetch(`/api/weather?${q}`)
      .then(async (r) => {
        const j = (await r.json()) as WeatherPayload;
        if (cancelled) return;
        if (!r.ok) {
          setErr(j.error ?? `Wetter ${r.status}`);
          setData(null);
          return;
        }
        setData(j);
      })
      .catch(() => {
        if (!cancelled) setErr("Wetter nicht erreichbar");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [lat, lng]);

  if (loading) {
    return (
      <div
        className={`rounded-xl border border-border bg-surface px-3 py-2 text-xs text-text-secondary ${className}`}
      >
        Wetter wird geladen…
      </div>
    );
  }

  if (err || !data?.current) {
    return (
      <div
        className={`rounded-xl border border-border bg-surface px-3 py-2 text-xs text-text-secondary ${className}`}
      >
        {err ?? "Keine Wetterdaten"}
      </div>
    );
  }

  const t = data.current.temperature_2m;
  const wind = data.current.wind_speed_10m;
  const precip = data.current.precipitation ?? 0;
  const Icon =
    precip >= 1 ? CloudRain : (data.current.weather_code ?? 0) > 2 ? Cloud : Sun;

  return (
    <div
      className={`rounded-xl border border-border bg-surface p-3 ${className}`}
    >
      <div className="flex items-start gap-3">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-accent" />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold">
            {t != null ? `${Math.round(t)} °C` : "—"}
            {wind != null && (
              <span className="ml-2 font-normal text-text-secondary">
                <Wind className="mr-0.5 inline h-3.5 w-3.5" />
                {Math.round(wind)} km/h
              </span>
            )}
          </p>
          {data.trailHint && (
            <p className="mt-1 text-xs text-text-secondary">
              {HINT_DE[data.trailHint] ?? data.trailHint}
            </p>
          )}
          {data.daily?.precipitation_sum?.[0] != null && (
            <p className="mt-0.5 text-[11px] text-text-secondary">
              Niederschlag heute ~{data.daily.precipitation_sum[0]} mm
              {data.daily.precipitation_probability_max?.[0] != null
                ? ` · max. ${data.daily.precipitation_probability_max[0]} %`
                : ""}
            </p>
          )}
          {data.attribution && (
            <p className="mt-1 text-[10px] text-text-secondary">
              {data.attribution}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
