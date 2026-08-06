"use client";

import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDistance, formatDuration } from "@/lib/utils";
import { Bike, Zap, TrendingUp, Wrench, ChevronRight, Play } from "lucide-react";
import Link from "next/link";

export default function HomePage() {
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const recommendations = useAppStore((s) => s.recommendations);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const boschLive = useAppStore((s) => s.boschLive);

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const lastRide = rides[0];
  const openRecs = recommendations.filter((r) => r.status === "shown").slice(0, 2);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">AetherRide</h1>
          <p className="text-sm text-text-secondary">Dein intelligenter Riding Companion</p>
        </div>
        <Link
          href="/profile"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-surface-elevated text-sm font-semibold text-accent"
        >
          AR
        </Link>
      </header>

      {activeBike ? (
        <section className="rounded-2xl bg-surface border border-border p-4">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/30 text-accent">
                <Bike className="h-6 w-6" />
              </div>
              <div>
                <h2 className="font-semibold text-lg">{activeBike.name}</h2>
                <p className="text-sm text-text-secondary">
                  {bikeTypeLabel(activeBike.type)}
                  {activeBike.year ? ` · ${activeBike.year}` : ""}
                </p>
              </div>
            </div>
            <Link href="/garage" className="text-sm text-accent flex items-center gap-1">
              Garage <ChevronRight className="h-4 w-4" />
            </Link>
          </div>

          {activeBike.setups.find((s) => s.isActive) && (
            <div className="mt-3 rounded-xl bg-surface-elevated px-3 py-2 text-sm">
              <span className="text-text-secondary">Aktives Setup: </span>
              <span className="font-medium">
                {activeBike.setups.find((s) => s.isActive)?.name}
              </span>
            </div>
          )}

          {boschConnected && boschLive && (
            <div className="mt-3 flex items-center gap-4 rounded-xl bg-primary/20 px-3 py-2">
              <Zap className="h-5 w-5 text-accent" />
              <div className="flex-1 grid grid-cols-3 gap-2 text-center text-sm">
                <div>
                  <div className="tabular-nums font-semibold text-lg">{boschLive.soc}%</div>
                  <div className="text-xs text-text-secondary">Akku</div>
                </div>
                <div>
                  <div className="tabular-nums font-semibold text-lg">{boschLive.odometer}</div>
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
        <section className="rounded-2xl bg-surface border border-border p-6 text-center">
          <p className="text-text-secondary mb-3">Noch kein Bike angelegt</p>
          <Link
            href="/garage"
            className="inline-flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 font-medium text-white"
          >
            Bike hinzufügen
          </Link>
        </section>
      )}

      <Link
        href="/ride"
        className="flex items-center justify-center gap-3 rounded-2xl bg-accent py-4 text-lg font-semibold text-white shadow-lg shadow-accent/25 transition hover:bg-accent-hover active:scale-[0.98]"
      >
        <Play className="h-6 w-6 fill-current" />
        Ride starten
      </Link>

      {lastRide && (
        <section className="rounded-2xl bg-surface border border-border p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="font-semibold flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-accent" />
              Letzter Ride
            </h3>
            <span className="text-xs text-text-secondary">
              {new Date(lastRide.startTime).toLocaleDateString("de-DE")}
            </span>
          </div>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div>
              <div className="tabular-nums text-xl font-bold">
                {formatDistance(lastRide.distanceM)}
              </div>
              <div className="text-xs text-text-secondary">Distanz</div>
            </div>
            <div>
              <div className="tabular-nums text-xl font-bold">
                {formatDuration(lastRide.durationSec)}
              </div>
              <div className="text-xs text-text-secondary">Zeit</div>
            </div>
            <div>
              <div className="tabular-nums text-xl font-bold text-accent">
                {lastRide.summaryMetrics.flowScore}
              </div>
              <div className="text-xs text-text-secondary">Flow</div>
            </div>
          </div>
        </section>
      )}

      {openRecs.length > 0 && (
        <section>
          <h3 className="mb-2 font-semibold flex items-center gap-2">
            <Wrench className="h-4 w-4 text-accent" />
            KI-Empfehlungen
          </h3>
          <div className="flex flex-col gap-2">
            {openRecs.map((rec) => (
              <div key={rec.id} className="rounded-xl bg-surface border border-border p-3">
                <div className="font-medium text-sm">{rec.title}</div>
                <p className="text-sm text-text-secondary mt-1">{rec.content}</p>
                <p className="text-xs text-text-secondary/70 mt-2">{rec.reasoning}</p>
              </div>
            ))}
          </div>
        </section>
      )}

      <section className="grid grid-cols-2 gap-3">
        <div className="rounded-xl bg-surface border border-border p-3 text-center">
          <div className="tabular-nums text-2xl font-bold">{bikes.length}</div>
          <div className="text-xs text-text-secondary">Bikes</div>
        </div>
        <div className="rounded-xl bg-surface border border-border p-3 text-center">
          <div className="tabular-nums text-2xl font-bold">{rides.length}</div>
          <div className="text-xs text-text-secondary">Rides</div>
        </div>
      </section>
    </div>
  );
}
