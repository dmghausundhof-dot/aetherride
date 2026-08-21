"use client";

import { useEffect, useState } from "react";
import { WeatherGlyph } from "@/components/shared/WeatherGlyph";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";

type WeatherPayload = {
  provider: string;
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
  };
  trailHint?: string;
  rideWindow?: { label?: string } | null;
  attribution?: string;
  error?: string;
};

type WeatherErr =
  | { kind: "unreachable" }
  | { kind: "status"; code: number }
  | { kind: "api"; text: string };

export function WeatherPanel({
  lat,
  lng,
  profile,
  className = "",
}: {
  lat: number;
  lng: number;
  profile?: string;
  className?: string;
}) {
  const lang = useChromeLang();
  const w = catalogCopy(lang).weather;
  const [data, setData] = useState<WeatherPayload | null>(null);
  const [err, setErr] = useState<WeatherErr | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setErr(null);
    const q = new URLSearchParams({
      lat: String(lat),
      lon: String(lng),
      lang,
    });
    if (profile) q.set("profile", profile);
    void fetch(`/api/weather?${q}`)
      .then(async (r) => {
        const j = (await r.json()) as WeatherPayload;
        if (cancelled) return;
        if (!r.ok) {
          setErr(
            j.error
              ? { kind: "api", text: j.error }
              : { kind: "status", code: r.status },
          );
          setData(null);
          return;
        }
        setData(j);
      })
      .catch(() => {
        if (!cancelled) setErr({ kind: "unreachable" });
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [lat, lng, profile, lang]);

  const hint =
    data?.trailHint === "wet_likely"
      ? w.wet
      : data?.trailHint === "damp_possible"
        ? w.damp
        : data?.trailHint === "dry_likely"
          ? w.dry
          : data?.trailHint;
  const dayTimes = data?.daily?.time ?? [];
  const dayIdx = (() => {
    const key = data?.current?.time?.slice(0, 10);
    if (key) {
      const i = dayTimes.findIndex((t) => t === key || t.startsWith(key));
      if (i >= 0) return i;
    }
    return dayTimes.length > 0 ? dayTimes.length - 1 : 0;
  })();
  const todayPrecip = data?.daily?.precipitation_sum?.[dayIdx];
  const todayProb = data?.daily?.precipitation_probability_max?.[dayIdx];

  if (loading) {
    return (
      <div
        className={`rounded-xl border border-border bg-surface px-3 py-2 text-xs text-text-secondary ${className}`}
      >
        {w.loading}
      </div>
    );
  }

  if (err || !data?.current) {
    const message =
      err?.kind === "unreachable"
        ? w.unreachable
        : err?.kind === "status"
          ? w.status(err.code)
          : err?.kind === "api"
            ? err.text
            : w.none;
    return (
      <div
        className={`flex items-center gap-2 rounded-xl border border-border bg-surface px-3 py-2 text-xs text-text-secondary ${className}`}
      >
        <WeatherGlyph offline size={18} />
        <span>{message}</span>
      </div>
    );
  }

  const t = data.current.temperature_2m;
  const wind = data.current.wind_speed_10m;

  return (
    <div
      className={`rounded-xl border border-border bg-surface p-3 ${className}`}
    >
      <div className="flex items-start gap-3">
        <WeatherGlyph hint={data.trailHint} size={20} className="mt-0.5 shrink-0" />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold">
            {t != null ? `${Math.round(t)} °C` : "—"}
            {wind != null && (
              <span className="ml-2 font-normal text-text-secondary">
                {Math.round(wind)} km/h
              </span>
            )}
          </p>
          {hint && (
            <p className="mt-1 text-xs text-text-secondary">{hint}</p>
          )}
          {data.rideWindow?.label ? (
            <p className="mt-1 text-xs text-text-secondary">
              {data.rideWindow.label}
            </p>
          ) : null}
          {todayPrecip != null && (
            <p className="mt-0.5 text-[11px] text-text-secondary">
              {w.precip(todayPrecip, todayProb)}
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
