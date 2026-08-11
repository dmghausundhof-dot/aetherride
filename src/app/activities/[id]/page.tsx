"use client";

import { useMemo } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import {
  ArrowLeft,
  Map as MapIcon,
  MessageSquare,
  Wrench,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration, bikeTypeLabel } from "@/lib/utils";
import { MapView, type MapRouteLayer } from "@/components/MapView";
import { RideMetricBars } from "@/components/RideMetricBars";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { analyzePostRide } from "@/lib/ai/postRideAnalysis";

export default function ActivityDetailPage() {
  const params = useParams();
  const id = typeof params.id === "string" ? params.id : "";
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const recommendations = useAppStore((s) => s.recommendations);

  const ride = rides.find((r) => r.id === id);
  const bike = ride ? bikes.find((b) => b.id === ride.bikeId) : null;
  const setup = bike?.setups.find(
    (s) => s.id === ride?.setupId || s.isCurrent
  );
  const feedback = ride
    ? rideFeedbacks.find((f) => f.rideId === ride.id)
    : undefined;

  const analysis = useMemo(() => {
    if (!ride || !bike) return null;
    return analyzePostRide({ ride, bike, setup, feedback });
  }, [ride, bike, setup, feedback]);

  const trackLayers: MapRouteLayer[] = useMemo(() => {
    if (!ride?.track || ride.track.length < 2) return [];
    return [
      {
        id: "activity",
        role: "tour",
        geometry: {
          type: "LineString",
          coordinates: ride.track.map((p) => [p.lng, p.lat] as [number, number]),
        },
        color: "#FF6B35",
        width: 4,
        opacity: 0.9,
      },
    ];
  }, [ride]);

  const mapCenter: [number, number] = useMemo(() => {
    const t = ride?.track;
    if (t && t.length) return [t[0].lng, t[0].lat];
    return [8.4, 48.5];
  }, [ride]);

  const recs = recommendations.filter(
    (r) => r.relatedRideId === ride?.id && r.status === "shown"
  );

  if (!ride) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16 text-center">
        <h1 className="text-xl font-bold">Aktivität nicht gefunden</h1>
        <p className="mt-2 text-sm text-text-secondary">
          Möglicherweise noch nicht gesynct oder lokal gelöscht.
        </p>
        <Link
          href="/activities"
          className="mt-6 inline-block text-sm font-semibold text-accent"
        >
          ← Zur Liste
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-6 sm:px-6">
      <Link
        href="/activities"
        className="inline-flex items-center gap-1.5 text-sm text-text-secondary hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Aktivitäten
      </Link>

      <header className="mt-4">
        <p className="text-xs font-medium uppercase tracking-wide text-accent">
          {bikeTypeLabel(ride.sportType)}
        </p>
        <h1 className="mt-1 text-2xl font-bold">
          {bike?.name ?? "Freeride"} ·{" "}
          {new Date(ride.startTime).toLocaleDateString("de-DE", {
            dateStyle: "long",
          })}
        </h1>
        <p className="mt-1 text-sm tabular-nums text-text-secondary">
          {formatDistance(ride.distanceM)} · {ride.elevationGainM.toFixed(0)} hm
          · {formatDuration(ride.durationSec)}
          {ride.endTime
            ? ` · bis ${new Date(ride.endTime).toLocaleTimeString("de-DE", { timeStyle: "short" })}`
            : ""}
        </p>
      </header>

      <div className="mt-6 grid gap-6 lg:grid-cols-5">
        <div className="space-y-4 lg:col-span-3">
          {trackLayers.length > 0 ? (
            <div className="relative h-64 overflow-hidden rounded-2xl border border-border sm:h-80">
              <MapView
                className="absolute inset-0"
                center={mapCenter}
                zoom={12}
                routes={trackLayers}
                fitRoute
              />
            </div>
          ) : (
            <div className="flex h-48 flex-col items-center justify-center rounded-2xl border border-dashed border-border text-sm text-text-secondary">
              <MapIcon className="mb-2 h-8 w-8 opacity-50" />
              Kein Track gespeichert
            </div>
          )}

          {ride.summaryMetrics && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Metriken</h2>
              <div className="mt-3">
                <RideMetricBars
                  impactCount={ride.summaryMetrics.impactCount}
                  distanceM={ride.distanceM}
                  flowScore={ride.summaryMetrics.flowScore}
                  gForcePeak={ride.summaryMetrics.gForcePeak}
                  gForceRms={ride.summaryMetrics.gForceRms}
                />
              </div>
            </section>
          )}

          {analysis && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Analyse</h2>
              {analysis.facts.length > 0 && (
                <ul className="mt-2 space-y-1 text-xs text-text-secondary">
                  {analysis.facts.map((f, i) => (
                    <li key={i}>{f}</li>
                  ))}
                </ul>
              )}
              {analysis.observations.length > 0 && (
                <ul className="mt-3 list-inside list-disc space-y-1 text-sm text-text-secondary">
                  {analysis.observations.map((o) => (
                    <li key={o.id}>{o.text}</li>
                  ))}
                </ul>
              )}
              {analysis.setupSuggestion && (
                <div className="mt-4 rounded-xl border border-accent/30 bg-accent/5 p-3">
                  <p className="text-sm font-medium">
                    {analysis.setupSuggestion.title}
                  </p>
                  <p className="mt-1 text-xs text-text-secondary">
                    {analysis.setupSuggestion.content}
                  </p>
                  <p className="mt-1 text-[11px] text-text-secondary">
                    {analysis.setupSuggestion.reasoning}
                  </p>
                </div>
              )}
            </section>
          )}
        </div>

        <aside className="space-y-4 lg:col-span-2">
          {setup && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="flex items-center gap-2 text-sm font-semibold">
                <Wrench className="h-4 w-4 text-accent" /> Setup
              </h2>
              <p className="mt-1 text-sm">„{setup.label}“</p>
              <div className="mt-2">
                <SetupFingerprint setup={setup} />
              </div>
              <Link
                href="/garage?tab=setups"
                className="mt-3 inline-block text-xs font-medium text-accent hover:underline"
              >
                In Garage öffnen →
              </Link>
            </section>
          )}

          {ride.assistSummary && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Assist (E-Bike)</h2>
              <p className="mt-2 text-xs text-text-secondary">
                Geschätzte Verteilung — keine Motorsteuerung.
              </p>
              <pre className="mt-2 overflow-x-auto text-[11px] text-text-secondary">
                {JSON.stringify(ride.assistSummary, null, 0).slice(0, 200)}
              </pre>
            </section>
          )}

          {recs.length > 0 && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Empfehlungen</h2>
              <ul className="mt-2 space-y-2">
                {recs.map((r) => (
                  <li key={r.id} className="text-xs text-text-secondary">
                    <span className="font-medium text-foreground">
                      {r.title}
                    </span>
                    {r.content && <p className="mt-0.5">{r.content}</p>}
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="rounded-2xl border border-border bg-surface p-4">
            <h2 className="flex items-center gap-2 text-sm font-semibold">
              <MessageSquare className="h-4 w-4 text-accent" /> Feedback
            </h2>
            {feedback ? (
              <p className="mt-2 text-xs text-text-secondary">
                Gesamtgefühl {feedback.overallFeel}/5
                {feedback.skipped ? " · übersprungen" : ""}
              </p>
            ) : (
              <p className="mt-2 text-xs text-text-secondary">
                Noch kein Post-Ride-Feedback.
              </p>
            )}
            <Link
              href={`/post-ride?id=${encodeURIComponent(ride.id)}`}
              className="mt-3 inline-flex text-xs font-semibold text-accent hover:underline"
            >
              Feedback / Post-Ride →
            </Link>
          </section>

          {bike && (
            <Link
              href={`/shop?job=replace&sport=${bike.category.includes("road") ? "road" : bike.category.includes("gravel") ? "gravel" : "mtb"}`}
              className="block rounded-xl border border-border px-4 py-3 text-center text-xs font-medium hover:border-accent/40"
            >
              Passende Teile im Shop
            </Link>
          )}
        </aside>
      </div>
    </div>
  );
}
