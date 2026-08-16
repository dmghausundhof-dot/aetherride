"use client";

import { useSearchParams, useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration, bikeTypeLabel } from "@/lib/utils";
import { Check, X, TrendingUp, Wrench, ArrowLeft, Lightbulb } from "lucide-react";
import Link from "next/link";
import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import type { RideFeedback } from "@/types";
import { analyzePostRide, setupSuggestionToRecommendation } from "@/lib/ai/postRideAnalysis";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import { MapView } from "@/components/MapView";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { ConfidenceBadge } from "@/components/ConfidenceBadge";
import { RideMetricBars } from "@/components/RideMetricBars";
import { contributeHeatmapTrack } from "@/lib/heatmap/client";
import { useHofCopy } from "@/hooks/useHofCopy";
import { mayContributeRideTrack } from "@/lib/tours/routeVisibility";
import { resolveAkteSavedRoute } from "@/lib/tours/tourAkte";
import { getPublicTour } from "@/lib/catalog/publicTours";

function PostRideContent() {
  const copy = useHofCopy();

  const searchParams = useSearchParams();
  const router = useRouter();
  const rideId = searchParams.get("id");
  const rides = useAppStore((s) => s.rides);
  const recommendations = useAppStore((s) => s.recommendations);
  const acceptRecommendation = useAppStore((s) => s.acceptRecommendation);
  const dismissRecommendation = useAppStore((s) => s.dismissRecommendation);
  const submitRideFeedback = useAppStore((s) => s.submitRideFeedback);
  const addRecommendation = useAppStore((s) => s.addRecommendation);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const bikes = useAppStore((s) => s.bikes);
  const consents = useAppStore((s) => s.consents);
  const privacyZones = useAppStore((s) => s.privacyZones);
  const savedRoutes = useAppStore((s) => s.savedRoutes);

  const ride = rides.find((r) => r.id === rideId) || rides[0];
  const bike = ride ? bikes.find((b) => b.id === ride.bikeId) : null;
  const setup = bike?.setups.find(
    (s) => s.id === ride?.setupId || s.isCurrent
  );
  const existingFeedback = ride
    ? rideFeedbacks.find((f) => f.rideId === ride.id)
    : undefined;

  const setupRec = recommendations.find(
    (r) =>
      r.relatedRideId === ride?.id &&
      r.type === "setup" &&
      r.status === "shown"
  );
  const otherRec = recommendations.find(
    (r) =>
      r.relatedRideId === ride?.id &&
      r.type !== "setup" &&
      r.status === "shown"
  );

  const [overall, setOverall] = useState<1 | 2 | 3 | 4 | 5>(3);
  const [frontFeel, setFrontFeel] =
    useState<RideFeedback["frontFeel"]>(undefined);
  const [brakeDive, setBrakeDive] =
    useState<RideFeedback["brakeDive"]>(undefined);
  const [smallBump, setSmallBump] =
    useState<RideFeedback["smallBump"]>(undefined);
  const [feedbackDone, setFeedbackDone] = useState(!!existingFeedback);
  const [heatmapNote, setHeatmapNote] = useState<string | null>(null);
  const heatmapTriedRef = useRef<string | null>(null);

  const analysis = useMemo(() => {
    if (!ride || !bike) return null;
    return analyzePostRide({
      ride,
      bike,
      setup,
      feedback: existingFeedback,
    });
  }, [ride, bike, setup, existingFeedback]);

  // Community-Heatmap beitragen (Consent + Login), wie Mobile post_ride
  useEffect(() => {
    if (!ride?.id || !ride.track?.length) return;
    if (heatmapTriedRef.current === ride.id) return;
    const granted =
      consents.find((c) => c.purpose === "heatmap_contribution")?.granted ??
      false;
    if (!granted) return;
    const saved = ride.savedRouteId
      ? savedRoutes.find((r) => r.id === ride.savedRouteId)
      : undefined;
    if (!mayContributeRideTrack(saved)) {
      heatmapTriedRef.current = ride.id;
      setHeatmapNote(
        "Heatmap: Tour ist privat — Track nicht beigetragen."
      );
      return;
    }
    heatmapTriedRef.current = ride.id;
    void (async () => {
      try {
        const r = await contributeHeatmapTrack({
          track: ride.track!.map((p) => ({ lat: p.lat, lng: p.lng })),
          privacyZones: privacyZones.map((z) => ({
            lat: z.lat,
            lng: z.lng,
            radiusM: z.radiusM,
          })),
        });
        setHeatmapNote(r.message);
      } catch (e) {
        setHeatmapNote(
          `Heatmap: ${e instanceof Error ? e.message : "Fehler"}`
        );
      }
    })();
  }, [ride, consents, privacyZones, savedRoutes]);

  if (!ride) {
    return (
      <div className="p-6 text-center">
        <p className="text-text-secondary">Kein Ride gefunden</p>
        <Link href="/" className="mt-4 inline-block text-chrome">
          Zurück
        </Link>
      </div>
    );
  }

  const persistFeedback = (payload: {
    overallFeel: 1 | 2 | 3 | 4 | 5;
    frontFeel?: RideFeedback["frontFeel"];
    brakeDive?: RideFeedback["brakeDive"];
    smallBump?: RideFeedback["smallBump"];
    skipped: boolean;
  }) => {
    submitRideFeedback({
      rideId: ride.id,
      ...payload,
    });
    setFeedbackDone(true);
    if (!payload.skipped && bike) {
      const next = analyzePostRide({
        ride,
        bike,
        setup,
        feedback: {
          rideId: ride.id,
          createdAt: new Date().toISOString(),
          overallFeel: payload.overallFeel,
          frontFeel: payload.frontFeel,
          brakeDive: payload.brakeDive,
          smallBump: payload.smallBump,
          skipped: false,
        },
      });
      if (
        next.setupSuggestion &&
        !recommendations.some(
          (r) =>
            r.relatedRideId === ride.id &&
            r.type === "setup" &&
            r.status === "shown"
        )
      ) {
        addRecommendation(
          setupSuggestionToRecommendation(
            next.setupSuggestion,
            bike.id,
            ride.id
          )
        );
      }
    }
  };

  const displaySetup = useMemo(() => {
    if (setupRec?.setupDetail) {
      return {
        title: setupRec.title,
        content: setupRec.content,
        reasoning: setupRec.reasoning,
        expectedEffect: setupRec.setupDetail.expectedEffect,
        limits: setupRec.setupDetail.limits,
        confidence: setupRec.setupDetail.confidence,
        id: setupRec.id as string | null,
      };
    }
    // Legacy-Recommendations ohne setupDetail: Analyse-Objekt bevorzugen
    const s = analysis?.setupSuggestion;
    if (!s) return null;
    return {
      title: s.title,
      content: s.content,
      reasoning: s.reasoning,
      expectedEffect: s.expectedEffect,
      limits: s.limits,
      confidence: s.confidence,
      id: (setupRec?.id as string | null) ?? null,
    };
  }, [setupRec, analysis]);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      {heatmapNote && (
        <div
          className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-xs text-text-secondary"
          role="status"
        >
          {heatmapNote}
          <button
            type="button"
            className="ml-2 text-chrome underline"
            onClick={() => setHeatmapNote(null)}
          >
            OK
          </button>
        </div>
      )}
      <header className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => router.push("/")}
          aria-label="Zurück zur Startseite"
          className="p-1"
        >
          <ArrowLeft className="h-6 w-6" aria-hidden />
        </button>
        <div>
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {copy.postRideKicker}
          </p>
          <h1 className="text-xl font-extrabold">{copy.postRideTitle}</h1>
          <p className="text-sm text-text-secondary">
            {new Date(ride.startTime).toLocaleString("de-DE")}
          </p>
          {(() => {
            const saved = resolveAkteSavedRoute(ride.savedRouteId, savedRoutes);
            const href = saved
              ? `/library?akte=${encodeURIComponent(saved.id)}`
              : ride.savedRouteId && getPublicTour(ride.savedRouteId)
                ? `/tours/${encodeURIComponent(ride.savedRouteId)}`
                : null;
            if (!href) return null;
            return (
              <Link
                href={href}
                className="mt-1 inline-block text-sm font-semibold text-accent"
              >
                Tour auf dem Platz
              </Link>
            );
          })()}
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <div className="mb-3 flex items-center gap-2">
          <TrendingUp className="h-5 w-5 text-chrome" />
          <h2 className="font-semibold">Was passiert ist</h2>
        </div>
        {bike && (
          <p className="mb-3 text-sm text-text-secondary">
            {bike.name} · {bikeTypeLabel(ride.sportType)}
            {setup ? ` · Setup „${setup.label}“` : ""}
          </p>
        )}
        {setup && (
          <div className="mb-3">
            <SetupFingerprint setup={setup} />
          </div>
        )}
        {ride.track && ride.track.length >= 2 && (
          <MapView
            className="mb-3 aspect-[16/9] w-full overflow-hidden rounded-xl"
            center={[ride.track[0].lng, ride.track[0].lat]}
            zoom={12}
            track={ride.track.map((p) => ({ lat: p.lat, lng: p.lng }))}
          />
        )}
        {ride.notes && (
          <p className="mb-3 text-xs text-chrome">{ride.notes}</p>
        )}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="text-2xl font-bold tabular-nums">
              {formatDistance(ride.distanceM)}
            </div>
            <div className="text-xs text-text-secondary">Distanz</div>
          </div>
          <div>
            <div className="text-2xl font-bold tabular-nums">
              {formatDuration(ride.durationSec)}
            </div>
            <div className="text-xs text-text-secondary">Dauer</div>
          </div>
          <div>
            <div className="text-2xl font-bold tabular-nums">
              {ride.elevationGainM} m
            </div>
            <div className="text-xs text-text-secondary">Höhenmeter</div>
          </div>
          <div>
            <div className="text-2xl font-bold tabular-nums text-chrome">
              {ride.summaryMetrics.flowScore}
            </div>
            <div className="text-xs text-text-secondary">Flow Score</div>
          </div>
        </div>
        {analysis && (
          <ul className="mt-3 space-y-1 text-xs text-text-secondary">
            {analysis.facts.map((f) => (
              <li key={f}>· {f}</li>
            ))}
          </ul>
        )}
      </section>

      {analysis && analysis.observations.length > 0 && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <div className="mb-2 flex items-center gap-2">
            <Lightbulb className="h-5 w-5 text-chrome" />
            <h2 className="font-semibold">Was aufgefallen ist</h2>
          </div>
          <ul className="space-y-2 text-sm">
            {analysis.observations.map((o) => (
              <li key={o.id} className="rounded-lg bg-surface-elevated px-3 py-2">
                {o.text}
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">Sensor-Details</h3>
        <RideMetricBars
          impactCount={ride.summaryMetrics.impactCount}
          distanceM={ride.distanceM}
          flowScore={ride.summaryMetrics.flowScore}
          gForcePeak={ride.summaryMetrics.gForcePeak}
          gForceRms={ride.summaryMetrics.gForceRms}
        />
        <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-xs text-text-secondary">Max Lean</div>
            <div className="text-lg font-semibold tabular-nums">
              {ride.summaryMetrics.leanAngleMax}°
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-xs text-text-secondary">Impacts gesamt</div>
            <div className="text-lg font-semibold tabular-nums">
              {ride.summaryMetrics.impactCount}
            </div>
          </div>
        </div>
      </section>

      {ride.motorData && (
        <section className="rounded-2xl border border-primary/30 bg-primary/15 p-4">
          <h3 className="mb-1 font-semibold text-chrome">
            E-Bike-Livedaten (Simulation)
          </h3>
          <p className="mb-3 text-[11px] text-text-secondary">
            Web-Demo-Werte — keine echten E-Bike-Livedaten. Echte Kopplung nur
            in der App.
          </p>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <div className="text-xs text-text-secondary">Ø SOC (Sim.)</div>
              <div className="text-lg font-semibold tabular-nums">
                {ride.motorData.avgSoc}%
              </div>
            </div>
            <div>
              <div className="text-xs text-text-secondary">
                Ø Rider Power (Sim.)
              </div>
              <div className="text-lg font-semibold tabular-nums">
                {ride.motorData.avgRiderPower} W
              </div>
            </div>
          </div>
        </section>
      )}

      {ride.assistSummary && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-2 font-semibold">Assist-Modus-Log</h3>
          <p className="mb-2 text-xs text-warning">
            {ride.assistSummary.disclaimer}
          </p>
          <p className="mb-2 text-sm">
            Dominant:{" "}
            <span className="font-semibold uppercase">
              {ride.assistSummary.dominantMode}
            </span>{" "}
            · ≈ {ride.assistSummary.estimatedTotalWh} Wh
          </p>
          <EvidenceSheet title="Segmente">
            <ul className="space-y-1">
              {ride.assistSummary.segments.map((s) => (
                <li key={s.id}>
                  {s.label} · {(s.distanceM / 1000).toFixed(1)} km · Quelle{" "}
                  {s.source}
                </li>
              ))}
            </ul>
          </EvidenceSheet>
        </section>
      )}

      {!feedbackDone && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-1 font-semibold">Wie war&apos;s?</h3>
          <p className="mb-3 text-xs text-text-secondary">
            Max. 3 Taps — verbessert die nächste Setup-Empfehlung.
          </p>
          <div className="mb-3 flex justify-between gap-1">
            {([1, 2, 3, 4, 5] as const).map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setOverall(n)}
                className={`flex-1 rounded-xl py-2 text-sm font-semibold ${
                  overall === n ? "bg-chrome text-on-accent" : "bg-surface-elevated"
                }`}
              >
                {n}
              </button>
            ))}
          </div>
          <div className="mb-2 text-xs text-text-secondary">Front</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["too_soft", "zu weich"],
                ["ok", "passt"],
                ["too_firm", "zu hart"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setFrontFeel(id)}
                className={`flex-1 rounded-xl py-2 text-xs ${
                  frontFeel === id ? "bg-chrome text-on-accent" : "bg-surface-elevated"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="mb-2 text-xs text-text-secondary">Anbremsen</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["dives", "taucht ab"],
                ["neutral", "neutral"],
                ["harsh", "hart"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setBrakeDive(id)}
                className={`flex-1 rounded-xl py-2 text-xs ${
                  brakeDive === id ? "bg-chrome text-on-accent" : "bg-surface-elevated"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="mb-2 text-xs text-text-secondary">Kleine Schläge</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["harsh", "rau"],
                ["ok", "passt"],
                ["vague", "vage"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setSmallBump(id)}
                className={`flex-1 rounded-xl py-2 text-xs ${
                  smallBump === id ? "bg-chrome text-on-accent" : "bg-surface-elevated"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() =>
                persistFeedback({
                  overallFeel: overall,
                  frontFeel,
                  brakeDive,
                  smallBump,
                  skipped: false,
                })
              }
              className="flex-1 rounded-xl bg-chrome py-2.5 text-sm font-medium text-on-accent"
            >
              Speichern
            </button>
            <button
              type="button"
              onClick={() =>
                persistFeedback({
                  overallFeel: overall,
                  skipped: true,
                })
              }
              className="flex-1 rounded-xl border border-border py-2.5 text-sm"
            >
              Überspringen
            </button>
          </div>
        </section>
      )}
      {feedbackDone && (
        <p className="text-center text-xs text-text-secondary">
          Feedback erfasst
          {existingFeedback?.skipped ? " (übersprungen)" : ""}.
        </p>
      )}

      {displaySetup && (
        <section className="rounded-2xl border border-chrome/40 bg-surface p-4">
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <Wrench className="h-5 w-5 text-chrome" />
            <h3 className="font-semibold">Was du ändern kannst</h3>
            {displaySetup.confidence && (
              <ConfidenceBadge confidence={displaySetup.confidence} />
            )}
          </div>
          <p className="text-sm font-medium">{displaySetup.title}</p>
          <p className="mt-1 text-sm text-text-secondary">{displaySetup.content}</p>
          {displaySetup.expectedEffect && (
            <p className="mt-2 text-sm">
              <span className="text-text-secondary">Erwartete Wirkung: </span>
              {displaySetup.expectedEffect}
            </p>
          )}
          {displaySetup.limits && (
            <p className="mt-1 text-xs text-text-secondary">
              Grenzen: {displaySetup.limits}
            </p>
          )}
          <EvidenceSheet title="Warum?" className="mt-2">
            {displaySetup.reasoning}
          </EvidenceSheet>
          {displaySetup.id && (
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => acceptRecommendation(displaySetup.id!)}
                className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-chrome py-2.5 text-sm font-medium text-on-accent"
              >
                <Check className="h-4 w-4" /> Übernehmen
              </button>
              <button
                type="button"
                onClick={() => dismissRecommendation(displaySetup.id!)}
                className="flex flex-1 items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
              >
                <X className="h-4 w-4" /> Verwerfen
              </button>
            </div>
          )}
        </section>
      )}

      {/* Produkt/Wartung nur wenn keine Setup-Empfehlung (F-AI-003: Fokus) */}
      {otherRec && !displaySetup && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-1 text-sm font-semibold">{otherRec.title}</h3>
          <p className="text-sm text-text-secondary">{otherRec.content}</p>
          <EvidenceSheet title="Warum?" className="mt-2">
            {otherRec.reasoning}
          </EvidenceSheet>
          <div className="mt-3 flex gap-2">
            <button
              type="button"
              onClick={() => acceptRecommendation(otherRec.id)}
              className="flex-1 rounded-xl bg-chrome py-2 text-sm font-medium text-on-accent"
            >
              Übernehmen
            </button>
            <button
              type="button"
              onClick={() => dismissRecommendation(otherRec.id)}
              className="flex-1 rounded-xl border border-border py-2 text-sm"
            >
              Verwerfen
            </button>
          </div>
        </section>
      )}

      <p className="text-center text-xs text-text-secondary">
        Tiefe Fragen?{" "}
        <Link href="/chat" className="text-chrome">
          Mehr fragen (KI)
        </Link>
      </p>

      <Link
        href="/"
        className="rounded-xl border border-border bg-surface py-3 text-center font-medium"
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
