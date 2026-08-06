"use client";

import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDistance, formatDuration } from "@/lib/utils";
import {
  Bike,
  Zap,
  Wrench,
  ChevronRight,
  Play,
  List,
} from "lucide-react";
import Link from "next/link";

export default function HomePage() {
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const recommendations = useAppStore((s) => s.recommendations);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const boschLive = useAppStore((s) => s.boschLive);
  const plannedRoute = useAppStore((s) => s.plannedRoute);

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const openRecs = recommendations.filter((r) => r.status === "shown").slice(0, 2);
  const recent = rides.slice(0, 8);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">AetherRide</h1>
          <p className="text-sm text-text-secondary">
            Finden · Fahren · Merken · Teilen
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href="/onboarding"
            className="rounded-lg bg-surface-elevated px-2 py-1 text-[10px] text-text-secondary"
          >
            Onboarding
          </Link>
          <Link
            href="/profile"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-surface-elevated text-sm font-semibold text-accent"
          >
            AR
          </Link>
        </div>
      </header>

      {activeBike ? (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/30 text-accent">
                <Bike className="h-6 w-6" />
              </div>
              <div>
                <h2 className="text-lg font-semibold">{activeBike.name}</h2>
                <p className="text-sm text-text-secondary">
                  {bikeTypeLabel(activeBike.type)}
                  {activeBike.year ? ` · ${activeBike.year}` : ""}
                </p>
              </div>
            </div>
            <Link
              href="/garage"
              className="flex items-center gap-1 text-sm text-accent"
            >
              Garage <ChevronRight className="h-4 w-4" />
            </Link>
          </div>

          {bikes.length > 1 && (
            <div className="mt-3 flex flex-wrap gap-1.5">
              {bikes.map((b) => (
                <button
                  key={b.id}
                  type="button"
                  onClick={() => setActiveBike(b.id)}
                  className={`rounded-lg px-2.5 py-1 text-[11px] ${
                    b.id === activeBike.id
                      ? "bg-accent text-white"
                      : "bg-surface-elevated text-text-secondary"
                  }`}
                >
                  {b.name}
                </button>
              ))}
            </div>
          )}

          {activeBike.setups.find((s) => s.isCurrent) && (
            <div className="mt-3 rounded-xl bg-surface-elevated px-3 py-2 text-sm">
              <span className="text-text-secondary">Setup: </span>
              <span className="font-medium">
                {activeBike.setups.find((s) => s.isCurrent)?.label}
              </span>
            </div>
          )}

          {boschConnected && boschLive && (
            <div className="mt-3 flex items-center gap-4 rounded-xl bg-primary/20 px-3 py-2">
              <Zap className="h-5 w-5 text-accent" />
              <div className="grid flex-1 grid-cols-3 gap-2 text-center text-sm">
                <div>
                  <div className="text-lg font-semibold tabular-nums">
                    {boschLive.soc}%
                  </div>
                  <div className="text-xs text-text-secondary">Akku</div>
                </div>
                <div>
                  <div className="text-lg font-semibold tabular-nums">
                    {boschLive.odometer}
                  </div>
                  <div className="text-xs text-text-secondary">km gesamt</div>
                </div>
                <div>
                  <div className="text-xs font-medium text-success">verbunden</div>
                  <div className="text-xs text-text-secondary">Bosch LDI</div>
                </div>
              </div>
            </div>
          )}
        </section>
      ) : (
        <section className="rounded-2xl border border-border bg-surface p-6 text-center">
          <p className="mb-3 text-text-secondary">Noch kein Bike angelegt</p>
          <Link
            href="/garage"
            className="inline-flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 font-medium text-white"
          >
            Bike hinzufügen
          </Link>
        </section>
      )}

      {plannedRoute && (
        <Link
          href="/ride"
          className="rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm"
        >
          Geplant: <span className="font-medium">{plannedRoute.name}</span>
          <span className="text-text-secondary">
            {" "}
            · {(plannedRoute.distanceM / 1000).toFixed(1)} km — tippen zum Fahren
          </span>
        </Link>
      )}

      <div className="grid grid-cols-2 gap-2">
        <Link
          href="/discover"
          className="rounded-2xl border border-border bg-surface py-3 text-center text-sm font-semibold"
        >
          Route finden
        </Link>
        <Link
          href="/ride"
          className="flex items-center justify-center gap-2 rounded-2xl bg-accent py-3 text-sm font-semibold text-white"
        >
          <Play className="h-4 w-4 fill-current" /> Ride
        </Link>
      </div>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="flex items-center gap-2 font-semibold">
            <List className="h-4 w-4 text-accent" />
            Aktivitäten
          </h3>
          <span className="text-xs text-text-secondary">{rides.length} gesamt</span>
        </div>
        {recent.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Noch keine Rides — Discover → Route starten.
          </p>
        ) : (
          <ul className="flex flex-col gap-2">
            {recent.map((r) => {
              const bike = bikes.find((b) => b.id === r.bikeId);
              return (
                <li key={r.id}>
                  <Link
                    href={`/post-ride?id=${r.id}`}
                    className="flex items-center justify-between rounded-xl bg-surface-elevated px-3 py-2.5"
                  >
                    <div>
                      <div className="text-sm font-medium">
                        {r.plannedRouteName ?? bike?.name ?? "Ride"}
                      </div>
                      <div className="text-[11px] text-text-secondary">
                        {new Date(r.startTime).toLocaleString("de-DE")}
                        {r.track && r.track.length >= 2
                          ? ` · ${r.track.length} Pts`
                          : ""}
                      </div>
                    </div>
                    <div className="text-right text-xs">
                      <div className="font-semibold tabular-nums">
                        {formatDistance(r.distanceM)}
                      </div>
                      <div className="text-text-secondary">
                        {formatDuration(r.durationSec)}
                      </div>
                    </div>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      {openRecs.length > 0 && (
        <section>
          <h3 className="mb-2 flex items-center gap-2 font-semibold">
            <Wrench className="h-4 w-4 text-accent" />
            Setup-Hinweise
          </h3>
          <div className="flex flex-col gap-2">
            {openRecs.map((rec) => (
              <div
                key={rec.id}
                className="rounded-xl border border-border bg-surface p-3"
              >
                <div className="text-sm font-medium">{rec.title}</div>
                <p className="mt-1 text-sm text-text-secondary">{rec.content}</p>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="grid grid-cols-2 gap-2">
        <Link
          href="/chat"
          className="rounded-xl border border-border bg-surface px-3 py-3 text-center text-sm font-medium"
        >
          KI-Chat
        </Link>
        <Link
          href="/privacy"
          className="rounded-xl border border-border bg-surface px-3 py-3 text-center text-sm font-medium"
        >
          Export & Privacy
        </Link>
      </div>

      <section className="grid grid-cols-2 gap-3">
        <div className="rounded-xl border border-border bg-surface p-3 text-center">
          <div className="text-2xl font-bold tabular-nums">{bikes.length}</div>
          <div className="text-xs text-text-secondary">Bikes</div>
        </div>
        <div className="rounded-xl border border-border bg-surface p-3 text-center">
          <div className="text-2xl font-bold tabular-nums">{rides.length}</div>
          <div className="text-xs text-text-secondary">Rides</div>
        </div>
      </section>
    </div>
  );
}
