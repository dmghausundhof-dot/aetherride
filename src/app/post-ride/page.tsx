"use client";

import { useSearchParams, useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration } from "@/lib/utils";
import { X, ArrowLeft } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { RadGlyph } from "@/components/garage/RadGlyph";
import Link from "next/link";
import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import type { RideFeedback } from "@/types";
import { analyzePostRide, setupSuggestionToRecommendation } from "@/lib/ai/postRideAnalysis";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import { MapView, type MapRouteLayer } from "@/components/MapView";
import { RideTelemetryCard } from "@/components/ride/RideTelemetryCard";
import {
  buildRideTelemetry,
  gradeMapLayers,
  type RideSample,
} from "@/lib/ride/rideTelemetry";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import {
  localizePostRideFact,
  localizePostRideObservation,
  localizePostRideReason,
  localizeSetupSuggestion,
  postRideAnalysisCopy,
} from "@/lib/i18n/postRideAnalysisCopy";
import { rideSportLabel } from "@/lib/i18n/rideSportLabel";
import {
  localizeAssistDisclaimer,
  localizeAssistSegment,
  localizeAssistSource,
  recapChromeCopy,
} from "@/lib/i18n/recapChromeCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
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
  const lang = useChromeLang();
  const telCopy = rideTelemetryCopy(lang);
  const analysisCopy = postRideAnalysisCopy(lang);
  const recapChrome = recapChromeCopy(lang);
  const dateLocale = chromeDateLocale(lang);
  const [hover, setHover] = useState<RideSample | null>(null);

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

  const telemetry = useMemo(
    () => buildRideTelemetry(ride?.track),
    [ride]
  );

  const gradeLayers: MapRouteLayer[] = useMemo(() => {
    if (!ride?.track || ride.track.length < 2) return [];
    const graded = gradeMapLayers(telemetry);
    if (graded.length > 0) {
      return graded.map((g) => ({
        id: g.id,
        role: "tour" as const,
        geometry: { type: "LineString" as const, coordinates: g.coordinates },
        color: g.color,
        width: 4.2,
        opacity: 0.92,
      }));
    }
    return [
      {
        id: "post-ride",
        role: "tour",
        geometry: {
          type: "LineString",
          coordinates: ride.track.map((p) => [p.lng, p.lat] as [number, number]),
        },
        color: "#FF6A00",
        width: 4,
        opacity: 0.9,
      },
    ];
  }, [ride, telemetry]);

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
      setHeatmapNote(telCopy.heatmapPrivate);
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
          `${telCopy.heatmapPrefix}: ${e instanceof Error ? e.message : telCopy.noRide}`
        );
      }
    })();
  }, [ride, consents, privacyZones, savedRoutes, telCopy]);

  if (!ride) {
    return (
      <div className="p-6 text-center">
        <p className="text-text-secondary">{telCopy.noRide}</p>
        <Link href="/" className="mt-4 inline-block text-chrome">
          {telCopy.back}
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
    const s = analysis?.setupSuggestion;
    if (s) {
      const loc = localizeSetupSuggestion(s, analysisCopy);
      return {
        title: loc.title,
        content: loc.content,
        reasoning: localizePostRideReason(s.reasoning, analysisCopy),
        expectedEffect: loc.expectedEffect,
        limits: loc.limits,
        confidence: s.confidence,
        id: (setupRec?.id as string | null) ?? null,
      };
    }
    if (setupRec?.setupDetail) {
      return {
        title: setupRec.title,
        content: setupRec.content,
        reasoning: localizePostRideReason(setupRec.reasoning, analysisCopy),
        expectedEffect: setupRec.setupDetail.expectedEffect,
        limits: setupRec.setupDetail.limits,
        confidence: setupRec.setupDetail.confidence,
        id: setupRec.id as string | null,
      };
    }
    return null;
  }, [setupRec, analysis, analysisCopy]);

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
            {telCopy.dismiss}
          </button>
        </div>
      )}
      <header className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => router.push("/")}
          aria-label={telCopy.back}
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
            {new Date(ride.startTime).toLocaleString(dateLocale)}
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
                {telCopy.tourOnPlatz}
              </Link>
            );
          })()}
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <div className="mb-3 flex items-center gap-2">
          <ChromeGlyph name="heat" size={20} current className="text-chrome" />
          <h2 className="font-semibold">{telCopy.happened}</h2>
        </div>
        {bike && (
          <p className="mb-3 text-sm text-text-secondary">
            {bike.name} · {rideSportLabel(ride.sportType, lang)}
            {setup ? ` · ${telCopy.setup} „${setup.label}“` : ""}
          </p>
        )}
        {setup && (
          <div className="mb-3">
            <SetupFingerprint setup={setup} />
          </div>
        )}
        {ride.notes && (
          <p className="mb-3 text-xs text-chrome">{ride.notes}</p>
        )}
        <div className="grid grid-cols-3 gap-4">
          <div>
            <div className="text-2xl font-bold tabular-nums">
              {formatDistance(ride.distanceM)}
            </div>
            <div className="text-xs text-text-secondary">{telCopy.distance}</div>
          </div>
          <div>
            <div className="text-2xl font-bold tabular-nums">
              {formatDuration(ride.durationSec)}
            </div>
            <div className="text-xs text-text-secondary">{telCopy.duration}</div>
          </div>
          <div>
            <div className="text-2xl font-bold tabular-nums text-chrome">
              {ride.summaryMetrics.flowScore}
            </div>
            <div className="text-xs text-text-secondary">{telCopy.flowScore}</div>
          </div>
        </div>
        {analysis && (
          <ul className="mt-3 space-y-1 text-xs text-text-secondary">
            {analysis.facts.map((f) => (
              <li key={f}>· {localizePostRideFact(f, analysisCopy, lang)}</li>
            ))}
          </ul>
        )}
      </section>

      {ride.track && ride.track.length >= 2 ? (
        <RideTelemetryCard
          telemetry={telemetry}
          copy={telCopy}
          onHoverSample={setHover}
          map={
            gradeLayers.length > 0 ? (
              <MapView
                className="absolute inset-0"
                center={[ride.track[0].lng, ride.track[0].lat]}
                zoom={12}
                routes={gradeLayers}
                fitRoute
                markers={
                  hover
                    ? [
                        {
                          id: "hover",
                          lngLat: [hover.lng, hover.lat],
                          color: "#FF6A00",
                          label: `${hover.distKm.toFixed(1)} km`,
                        },
                      ]
                    : undefined
                }
              />
            ) : undefined
          }
        />
      ) : null}

      {analysis && analysis.observations.length > 0 && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <div className="mb-2 flex items-center gap-2">
            <ChromeGlyph name="hint" size={20} current className="text-chrome" />
            <h2 className="font-semibold">{telCopy.noticed}</h2>
          </div>
          <ul className="space-y-2 text-sm">
            {analysis.observations.map((o) => (
              <li key={o.id} className="rounded-lg bg-surface-elevated px-3 py-2">
                {localizePostRideObservation(o, analysisCopy)}
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">{telCopy.sensorDetails}</h3>
        <RideMetricBars
          impactCount={ride.summaryMetrics.impactCount}
          distanceM={ride.distanceM}
          flowScore={ride.summaryMetrics.flowScore}
          gForcePeak={ride.summaryMetrics.gForcePeak}
          gForceRms={ride.summaryMetrics.gForceRms}
          labels={{
            flow: telCopy.flow,
            impactsPerKm: telCopy.impactsPerKm,
            peakG: telCopy.peakG,
            rmsG: telCopy.rmsG,
          }}
        />
        <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-xs text-text-secondary">{telCopy.maxLean}</div>
            <div className="text-lg font-semibold tabular-nums">
              {ride.summaryMetrics.leanAngleMax}°
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-xs text-text-secondary">{telCopy.impactsTotal}</div>
            <div className="text-lg font-semibold tabular-nums">
              {ride.summaryMetrics.impactCount}
            </div>
          </div>
        </div>
      </section>

      {ride.motorData && (
        <section className="rounded-2xl border border-primary/30 bg-primary/15 p-4">
          <h3 className="mb-1 font-semibold text-chrome">
            {telCopy.ebikeSimTitle}
          </h3>
          <p className="mb-3 text-[11px] text-text-secondary">
            {telCopy.ebikeSimHint}
          </p>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <div className="text-xs text-text-secondary">{telCopy.avgSocSim}</div>
              <div className="text-lg font-semibold tabular-nums">
                {ride.motorData.avgSoc}%
              </div>
            </div>
            <div>
              <div className="text-xs text-text-secondary">
                {telCopy.avgRiderPowerSim}
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
          <h3 className="mb-2 font-semibold">{telCopy.assistLog}</h3>
          <p className="mb-2 text-xs text-warning">
            {localizeAssistDisclaimer(ride.assistSummary.disclaimer, recapChrome)}
          </p>
          <p className="mb-2 text-sm">
            {telCopy.dominant}:{" "}
            <span className="font-semibold uppercase">
              {ride.assistSummary.dominantMode}
            </span>{" "}
            · ≈ {ride.assistSummary.estimatedTotalWh} Wh
          </p>
          <EvidenceSheet title={telCopy.segments}>
            <ul className="space-y-1">
              {ride.assistSummary.segments.map((s) => (
                <li key={s.id}>
                  {localizeAssistSegment(s.label, recapChrome)} ·{" "}
                  {(s.distanceM / 1000).toFixed(1)} {telCopy.km} ·{" "}
                  {telCopy.source} {localizeAssistSource(s.source, recapChrome)}
                </li>
              ))}
            </ul>
          </EvidenceSheet>
        </section>
      )}

      {!feedbackDone && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-1 font-semibold">{telCopy.howWasIt}</h3>
          <p className="mb-3 text-xs text-text-secondary">
            {telCopy.howWasHint}
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
          <div className="mb-2 text-xs text-text-secondary">{telCopy.front}</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["too_soft", telCopy.tooSoft],
                ["ok", telCopy.ok],
                ["too_firm", telCopy.tooFirm],
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
          <div className="mb-2 text-xs text-text-secondary">{telCopy.brake}</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["dives", telCopy.dives],
                ["neutral", telCopy.neutral],
                ["harsh", telCopy.harsh],
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
          <div className="mb-2 text-xs text-text-secondary">{telCopy.smallBump}</div>
          <div className="mb-3 flex gap-2">
            {(
              [
                ["harsh", telCopy.rough],
                ["ok", telCopy.ok],
                ["vague", telCopy.vague],
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
              {telCopy.save}
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
              {telCopy.skip}
            </button>
          </div>
        </section>
      )}
      {feedbackDone && (
        <p className="text-center text-xs text-text-secondary">
          {telCopy.feedbackSaved}
          {existingFeedback?.skipped ? ` (${telCopy.feedbackSkip})` : ""}.
        </p>
      )}

      {displaySetup && (
        <section className="rounded-2xl border border-chrome/40 bg-surface p-4">
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <RadGlyph name="setup" size={20} />
            <h3 className="font-semibold">{telCopy.whatYouCanChange}</h3>
            {displaySetup.confidence && (
              <ConfidenceBadge confidence={displaySetup.confidence} />
            )}
          </div>
          <p className="text-sm font-medium">{displaySetup.title}</p>
          <p className="mt-1 text-sm text-text-secondary">{displaySetup.content}</p>
          {displaySetup.expectedEffect && (
            <p className="mt-2 text-sm">
              <span className="text-text-secondary">{telCopy.expectedEffect}: </span>
              {displaySetup.expectedEffect}
            </p>
          )}
          {displaySetup.limits && (
            <p className="mt-1 text-xs text-text-secondary">
              {telCopy.limits}: {displaySetup.limits}
            </p>
          )}
          <EvidenceSheet title={telCopy.why} className="mt-2">
            {displaySetup.reasoning}
          </EvidenceSheet>
          {displaySetup.id && (
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => acceptRecommendation(displaySetup.id!)}
                className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-chrome py-2.5 text-sm font-medium text-on-accent"
              >
                <ChromeGlyph name="check" size={16} current /> {telCopy.accept}
              </button>
              <button
                type="button"
                onClick={() => dismissRecommendation(displaySetup.id!)}
                className="flex flex-1 items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
              >
                <X className="h-4 w-4" /> {telCopy.reject}
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
          <EvidenceSheet title={telCopy.why} className="mt-2">
            {localizePostRideReason(otherRec.reasoning, analysisCopy)}
          </EvidenceSheet>
          <div className="mt-3 flex gap-2">
            <button
              type="button"
              onClick={() => acceptRecommendation(otherRec.id)}
              className="flex-1 rounded-xl bg-chrome py-2 text-sm font-medium text-on-accent"
            >
              {telCopy.accept}
            </button>
            <button
              type="button"
              onClick={() => dismissRecommendation(otherRec.id)}
              className="flex-1 rounded-xl border border-border py-2 text-sm"
            >
              {telCopy.reject}
            </button>
          </div>
        </section>
      )}

      <p className="text-center text-xs text-text-secondary">
        {telCopy.askMoreLead}{" "}
        <Link href="/chat" className="text-chrome">
          {telCopy.askMore}
        </Link>
      </p>

      <Link
        href="/"
        className="rounded-xl border border-border bg-surface py-3 text-center font-medium"
      >
        {telCopy.done}
      </Link>
    </div>
  );
}

function PostRideFallback() {
  const tel = rideTelemetryCopy(useChromeLang());
  return <div className="p-6 text-center">{tel.loadingAnalysis}</div>;
}

export default function PostRidePage() {
  return (
    <Suspense fallback={<PostRideFallback />}>
      <PostRideContent />
    </Suspense>
  );
}
