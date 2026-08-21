"use client";

/**
 * Aktivitäten-Liste — Analyse im Web nach Sync von der App.
 * Recording bleibt app-only.
 */
import Link from "next/link";
import { Activity, ChevronRight, Smartphone } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration } from "@/lib/utils";
import { rideSportLabel } from "@/lib/i18n/rideSportLabel";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import { buildRideTelemetry } from "@/lib/ride/rideTelemetry";
import { terrainCaption } from "@/lib/ride/terrainCaption";
import { RideTerrainPeek } from "@/components/ride/ActivitySparkline";

export default function ActivitiesPage() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const tel = rideTelemetryCopy(lang);
  const dateLocale = chromeDateLocale(lang);

  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);

  const sorted = [...rides].sort(
    (a, b) =>
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
  );

  return (
    <div className="mx-auto max-w-3xl px-4 py-8 sm:px-6">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{copy.activitiesTitle}</h1>
          <p className="mt-1 text-sm text-text-secondary">
            {copy.activitiesHint}
          </p>
        </div>
        <Link
          href="/download"
          className="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-xs font-medium"
        >
          <Smartphone className="h-3.5 w-3.5 text-chrome" /> {copy.inTheApp}
        </Link>
      </header>

      {sorted.length === 0 ? (
        <div className="mt-10 rounded-2xl border border-dashed border-border p-10 text-center">
          <Activity className="mx-auto h-10 w-10 text-text-secondary" />
          <h2 className="mt-4 font-semibold">{copy.activitiesEmpty}</h2>
          <p className="mx-auto mt-2 max-w-sm text-sm text-text-secondary">
            {copy.activitiesEmptyHint}
          </p>
          <div className="mt-6 flex flex-wrap justify-center gap-3">
            <Link
              href="/download"
              className="rounded-xl bg-chrome px-4 py-2.5 text-sm font-semibold text-on-accent"
            >
              {tel.openApp}
            </Link>
            <Link
              href="/discover"
              className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium"
            >
              {tel.toMap}
            </Link>
          </div>
        </div>
      ) : (
        <ul className="mt-8 space-y-3">
          {sorted.map((ride) => {
            const bike = bikes.find((b) => b.id === ride.bikeId);
            const telemetry = buildRideTelemetry(ride.track);
            const chips: string[] = [];
            if (telemetry.channels.hr) chips.push(tel.hr);
            if (telemetry.channels.cad) chips.push(tel.cad);
            if (telemetry.channels.power) chips.push(tel.power);
            const climb = telemetry.channels.elev
              ? telemetry.climbM
              : ride.elevationGainM;
            return (
              <li key={ride.id}>
                <Link
                  href={`/activities/${ride.id}`}
                  className="block rounded-2xl border border-border bg-surface p-4 transition hover:border-chrome/40"
                >
                  <div className="flex items-start gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-semibold">
                          {rideSportLabel(ride.sportType, lang)}
                        </span>
                        <span className="text-[11px] text-text-secondary">
                          {new Date(ride.startTime).toLocaleString(dateLocale, {
                            dateStyle: "medium",
                            timeStyle: "short",
                          })}
                        </span>
                      </div>
                      <p className="mt-0.5 text-xs text-text-secondary">
                        {bike?.name ?? tel.freeride} ·{" "}
                        <span className="tabular-nums">
                          {formatDistance(ride.distanceM)} · {climb.toFixed(0)}{" "}
                          {tel.hm} · {formatDuration(ride.durationSec)}
                        </span>
                      </p>
                      {chips.length > 0 ? (
                        <p className="mt-1.5 flex flex-wrap gap-1.5">
                          {chips.map((c) => (
                            <span
                              key={c}
                              className="rounded-full border border-border px-2 py-0.5 text-[10px] font-medium text-text-secondary"
                            >
                              {c}
                            </span>
                          ))}
                        </p>
                      ) : null}
                    </div>
                    <ChevronRight className="mt-1 h-4 w-4 shrink-0 text-text-secondary" />
                  </div>
                  <RideTerrainPeek
                    telemetry={telemetry}
                    caption={terrainCaption(telemetry, tel.hm)}
                    className="mt-3"
                  />
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
