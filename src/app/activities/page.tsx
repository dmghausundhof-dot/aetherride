"use client";

/**
 * Aktivitäten-Liste — Analyse im Web nach Sync von der App.
 * Recording bleibt app-only.
 */
import Link from "next/link";
import { Activity, Bike, ChevronRight, Smartphone } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration, bikeTypeLabel } from "@/lib/utils";
import { useHofCopy } from "@/hooks/useHofCopy";

export default function ActivitiesPage() {
  const copy = useHofCopy();

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
          <Smartphone className="h-3.5 w-3.5 text-chrome" /> App laden
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
              App öffnen
            </Link>
            <Link
              href="/discover"
              className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium"
            >
              Zur Karte
            </Link>
          </div>
        </div>
      ) : (
        <ul className="mt-8 space-y-3">
          {sorted.map((ride) => {
            const bike = bikes.find((b) => b.id === ride.bikeId);
            return (
              <li key={ride.id}>
                <Link
                  href={`/activities/${ride.id}`}
                  className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-4 transition hover:border-chrome/40"
                >
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/25 text-chrome">
                    <Bike className="h-5 w-5" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-semibold">
                        {bikeTypeLabel(ride.sportType)}
                      </span>
                      <span className="text-[11px] text-text-secondary">
                        {new Date(ride.startTime).toLocaleString("de-DE", {
                          dateStyle: "medium",
                          timeStyle: "short",
                        })}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-text-secondary">
                      {bike?.name ?? "Freeride"} ·{" "}
                      <span className="tabular-nums">
                        {formatDistance(ride.distanceM)} ·{" "}
                        {ride.elevationGainM.toFixed(0)} hm ·{" "}
                        {formatDuration(ride.durationSec)}
                      </span>
                    </p>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-text-secondary" />
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
