"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration } from "@/lib/utils";
import { MapView, type MapRouteLayer } from "@/components/MapView";
import { RideMetricBars } from "@/components/RideMetricBars";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { RideTelemetryCard } from "@/components/ride/RideTelemetryCard";
import { analyzePostRide } from "@/lib/ai/postRideAnalysis";
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
  localizeActivityRecTitle,
  localizeAssistDisclaimer,
  localizeAssistSegment,
  localizeAssistSource,
  recapChromeCopy,
} from "@/lib/i18n/recapChromeCopy";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import { useChromeLang } from "@/hooks/useChromeLang";

export default function ActivityDetailPage() {
  const params = useParams();
  const id = typeof params.id === "string" ? params.id : "";
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const recommendations = useAppStore((s) => s.recommendations);
  const lang = useChromeLang();
  const tel = rideTelemetryCopy(lang);
  const analysisCopy = postRideAnalysisCopy(lang);
  const recapChrome = recapChromeCopy(lang);
  const dateLocale = chromeDateLocale(lang);
  const [hover, setHover] = useState<RideSample | null>(null);

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

  const telemetry = useMemo(
    () => buildRideTelemetry(ride?.track),
    [ride]
  );

  const trackLayers: MapRouteLayer[] = useMemo(() => {
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
        id: "activity",
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

  const mapCenter: [number, number] = useMemo(() => {
    const t = ride?.track;
    if (t && t.length) return [t[0].lng, t[0].lat];
    return [8.4, 48.5];
  }, [ride]);

  const recs = recommendations.filter(
    (r) =>
      r.relatedRideId === ride?.id &&
      r.status === "shown" &&
      !(r.type === "setup" && analysis?.setupSuggestion)
  );

  if (!ride) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16 text-center">
        <h1 className="text-xl font-bold">{tel.notFound}</h1>
        <p className="mt-2 text-sm text-text-secondary">
          {tel.notFoundHint}
        </p>
        <Link
          href="/activities"
          className="mt-6 inline-block text-sm font-semibold text-accent"
        >
          {tel.backToList}
        </Link>
      </div>
    );
  }

  const climbShow = telemetry.channels.elev
    ? telemetry.climbM
    : ride.elevationGainM;

  return (
    <div className="mx-auto max-w-4xl px-4 py-6 sm:px-6">
      <Link
        href="/activities"
        className="inline-flex items-center gap-1.5 text-sm text-text-secondary hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> {tel.activitiesNav}
      </Link>

      <header className="mt-4">
        <p className="text-xs font-medium uppercase tracking-wide text-accent">
          {rideSportLabel(ride.sportType, lang)}
        </p>
        <h1 className="mt-1 text-2xl font-bold">
          {bike?.name ?? tel.freeride} ·{" "}
          {new Date(ride.startTime).toLocaleDateString(dateLocale, {
            dateStyle: "long",
          })}
        </h1>
        <p className="mt-1 text-sm tabular-nums text-text-secondary">
          {formatDistance(ride.distanceM)} · {climbShow.toFixed(0)} {tel.hm}
          {telemetry.channels.elev
            ? ` ↑ · ${telemetry.descentM} ${tel.hm} ↓`
            : ""}{" "}
          · {formatDuration(ride.durationSec)}
          {ride.endTime
            ? ` · ${tel.until} ${new Date(ride.endTime).toLocaleTimeString(dateLocale, { timeStyle: "short" })}`
            : ""}
        </p>
      </header>

      <div className="mt-6 grid gap-6 lg:grid-cols-5">
        <div className="space-y-4 lg:col-span-3">
          {ride.track && ride.track.length >= 2 ? (
            <RideTelemetryCard
              telemetry={telemetry}
              copy={tel}
              onHoverSample={setHover}
              map={
                trackLayers.length > 0 ? (
                  <MapView
                    className="absolute inset-0"
                    center={mapCenter}
                    zoom={12}
                    routes={trackLayers}
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
          ) : (
            <div className="flex h-48 flex-col items-center justify-center rounded-2xl border border-dashed border-border text-sm text-text-secondary">
              <ChromeGlyph name="karte" size={32} current className="mb-2 opacity-50" />
              {tel.noTrack}
            </div>
          )}

          {ride.summaryMetrics && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">{tel.chassis}</h2>
              <div className="mt-3">
                <RideMetricBars
                  impactCount={ride.summaryMetrics.impactCount}
                  distanceM={ride.distanceM}
                  flowScore={ride.summaryMetrics.flowScore}
                  gForcePeak={ride.summaryMetrics.gForcePeak}
                  gForceRms={ride.summaryMetrics.gForceRms}
                  labels={{
                    flow: tel.flow,
                    impactsPerKm: tel.impactsPerKm,
                    peakG: tel.peakG,
                    rmsG: tel.rmsG,
                  }}
                />
              </div>
            </section>
          )}

          {analysis && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">{tel.analysis}</h2>
              {analysis.facts.length > 0 && (
                <ul className="mt-2 space-y-1 text-xs text-text-secondary">
                  {analysis.facts.map((f, i) => (
                    <li key={i}>{localizePostRideFact(f, analysisCopy, lang)}</li>
                  ))}
                </ul>
              )}
              {analysis.observations.length > 0 && (
                <ul className="mt-3 list-inside list-disc space-y-1 text-sm text-text-secondary">
                  {analysis.observations.map((o) => (
                    <li key={o.id}>
                      {localizePostRideObservation(o, analysisCopy)}
                    </li>
                  ))}
                </ul>
              )}
              {analysis.setupSuggestion && (
                <div className="mt-4 rounded-xl border border-accent/30 bg-accent/5 p-3">
                  {(() => {
                    const loc = localizeSetupSuggestion(
                      analysis.setupSuggestion,
                      analysisCopy
                    );
                    return (
                      <>
                        <p className="text-sm font-medium">{loc.title}</p>
                        <p className="mt-1 text-xs text-text-secondary">
                          {loc.content}
                        </p>
                        <p className="mt-1 text-[11px] text-text-secondary">
                          {localizePostRideReason(
                            analysis.setupSuggestion.reasoning,
                            analysisCopy
                          )}
                        </p>
                      </>
                    );
                  })()}
                </div>
              )}
            </section>
          )}
        </div>

        <aside className="space-y-4 lg:col-span-2">
          {setup && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="flex items-center gap-2 text-sm font-semibold">
                <RadGlyph name="setup" size={16} /> {tel.setup}
              </h2>
              <p className="mt-1 text-sm">„{setup.label}“</p>
              <div className="mt-2">
                <SetupFingerprint setup={setup} />
              </div>
              <Link
                href="/garage?tab=setups"
                className="mt-3 inline-block text-xs font-medium text-accent hover:underline"
              >
                {tel.openGarage}
              </Link>
            </section>
          )}

          {ride.assistSummary && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">{tel.assist}</h2>
              <p className="mt-2 text-xs text-text-secondary">
                {localizeAssistDisclaimer(ride.assistSummary.disclaimer, recapChrome)}
              </p>
              <ul className="mt-2 space-y-1 text-xs text-text-secondary">
                {ride.assistSummary.segments.map((s) => (
                  <li key={s.id}>
                    {localizeAssistSegment(s.label, recapChrome)} ·{" "}
                    {(s.distanceM / 1000).toFixed(1)} {tel.km} · {tel.source}{" "}
                    {localizeAssistSource(s.source, recapChrome)}
                  </li>
                ))}
              </ul>
            </section>
          )}

          {recs.length > 0 && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">{tel.recommendations}</h2>
              <ul className="mt-2 space-y-2">
                {recs.map((r) => (
                  <li key={r.id} className="text-xs text-text-secondary">
                    <span className="font-medium text-foreground">
                      {localizeActivityRecTitle(r.title, recapChrome)}
                    </span>
                    {r.content && <p className="mt-0.5">{r.content}</p>}
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="rounded-2xl border border-border bg-surface p-4">
            <h2 className="flex items-center gap-2 text-sm font-semibold">
              <ChromeGlyph name="stimmen" size={16} current className="text-accent" /> {tel.feedback}
            </h2>
            {feedback ? (
              <p className="mt-2 text-xs text-text-secondary">
                {tel.feedbackOverall} {feedback.overallFeel}/5
                {feedback.skipped ? ` · ${tel.feedbackSkip}` : ""}
              </p>
            ) : (
              <p className="mt-2 text-xs text-text-secondary">
                {tel.noFeedback}
              </p>
            )}
            <Link
              href={`/post-ride?id=${encodeURIComponent(ride.id)}`}
              className="mt-3 inline-flex text-xs font-semibold text-accent hover:underline"
            >
              {tel.feedbackPostRide}
            </Link>
          </section>

          {bike && (
            <Link
              href={`/shop?job=replace&sport=${bike.category.includes("road") ? "road" : bike.category.includes("gravel") ? "gravel" : "mtb"}`}
              className="block rounded-xl border border-border px-4 py-3 text-center text-xs font-medium hover:border-accent/40"
            >
              {tel.shopParts}
            </Link>
          )}
        </aside>
      </div>
    </div>
  );
}
