"use client";

import { useSearchParams, useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration, bikeTypeLabel } from "@/lib/utils";
import { Check, X, TrendingUp, Wrench, ArrowLeft } from "lucide-react";
import Link from "next/link";
import { Suspense } from "react";

function PostRideContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rideId = searchParams.get("id");
  const rides = useAppStore((s) => s.rides);
  const recommendations = useAppStore((s) => s.recommendations);
  const acceptRecommendation = useAppStore((s) => s.acceptRecommendation);
  const dismissRecommendation = useAppStore((s) => s.dismissRecommendation);
  const bikes = useAppStore((s) => s.bikes);

  const ride = rides.find((r) => r.id === rideId) || rides[0];
  const bike = ride ? bikes.find((b) => b.id === ride.bikeId) : null;
  const rec = recommendations.find(
    (r) => r.relatedRideId === ride?.id && r.status === "shown"
  );

  if (!ride) {
    return (
      <div className="p-6 text-center">
        <p className="text-text-secondary">Kein Ride gefunden</p>
        <Link href="/" className="mt-4 inline-block text-accent">
          Zurück
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <button onClick={() => router.push("/")} className="p-1">
          <ArrowLeft className="h-6 w-6" />
        </button>
        <div>
          <h1 className="text-xl font-bold">Post-Ride Analyse</h1>
          <p className="text-sm text-text-secondary">
            {new Date(ride.startTime).toLocaleString("de-DE")}
          </p>
        </div>
      </header>

      {/* Summary */}
      <section className="rounded-2xl bg-surface border border-border p-4">
        <div className="mb-3 flex items-center gap-2">
          <TrendingUp className="h-5 w-5 text-accent" />
          <h2 className="font-semibold">Zusammenfassung</h2>
        </div>
        {bike && (
          <p className="mb-3 text-sm text-text-secondary">
            {bike.name} · {bikeTypeLabel(ride.sportType)}
          </p>
        )}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="tabular-nums text-2xl font-bold">
              {formatDistance(ride.distanceM)}
            </div>
            <div className="text-xs text-text-secondary">Distanz</div>
          </div>
          <div>
            <div className="tabular-nums text-2xl font-bold">
              {formatDuration(ride.durationSec)}
            </div>
            <div className="text-xs text-text-secondary">Dauer</div>
          </div>
          <div>
            <div className="tabular-nums text-2xl font-bold">
              {ride.elevationGainM} m
            </div>
            <div className="text-xs text-text-secondary">Höhenmeter</div>
          </div>
          <div>
            <div className="tabular-nums text-2xl font-bold text-accent">
              {ride.summaryMetrics.flowScore}
            </div>
            <div className="text-xs text-text-secondary">Flow Score</div>
          </div>
        </div>
      </section>

      {/* Sensor Details */}
      <section className="rounded-2xl bg-surface border border-border p-4">
        <h3 className="mb-3 font-semibold">Sensor-Analyse</h3>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">Peak G-Force</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.gForcePeak} g
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">Max Lean</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.leanAngleMax}°
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">Impacts</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.impactCount}
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">RMS G</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.gForceRms} g
            </div>
          </div>
        </div>
      </section>

      {/* Motor Data */}
      {ride.motorData && (
        <section className="rounded-2xl bg-primary/15 border border-primary/30 p-4">
          <h3 className="mb-3 font-semibold text-accent">Bosch Motor-Daten</h3>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <div className="text-text-secondary text-xs">Ø SOC</div>
              <div className="tabular-nums text-lg font-semibold">
                {ride.motorData.avgSoc}%
              </div>
            </div>
            <div>
              <div className="text-text-secondary text-xs">Ø Rider Power</div>
              <div className="tabular-nums text-lg font-semibold">
                {ride.motorData.avgRiderPower} W
              </div>
            </div>
          </div>
        </section>
      )}

      {/* Recommendation */}
      {rec && (
        <section className="rounded-2xl bg-surface border border-accent/40 p-4">
          <div className="mb-2 flex items-center gap-2">
            <Wrench className="h-5 w-5 text-accent" />
            <h3 className="font-semibold">{rec.title}</h3>
          </div>
          <p className="text-sm mb-2">{rec.content}</p>
          <p className="text-xs text-text-secondary mb-4">{rec.reasoning}</p>
          <div className="flex gap-2">
            <button
              onClick={() => {
                acceptRecommendation(rec.id);
              }}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
            >
              <Check className="h-4 w-4" /> Übernehmen
            </button>
            <button
              onClick={() => dismissRecommendation(rec.id)}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
            >
              <X className="h-4 w-4" /> Verwerfen
            </button>
          </div>
        </section>
      )}

      <Link
        href="/"
        className="rounded-xl bg-surface border border-border py-3 text-center font-medium"
      >
        Fertig
      </Link>
    </div>
  );
}

export default function PostRidePage() {
  return (
    <Suspense fallback={<div className="p-6 text-center">Lade Analyse…</div>}>
      <PostRideContent />
    </Suspense>
  );
}
