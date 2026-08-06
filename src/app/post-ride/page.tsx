"use client";

import { useSearchParams, useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { formatDistance, formatDuration, bikeTypeLabel } from "@/lib/utils";
import { Check, X, TrendingUp, Wrench, ArrowLeft, Download } from "lucide-react";
import Link from "next/link";
import { Suspense, useMemo, useState } from "react";
import type { RideFeedback } from "@/types";
import { SetupLiabilityNotice } from "@/components/SetupLiabilityNotice";
import { MapView } from "@/components/MapView";
import { downloadText } from "@/lib/export/gpx";
import { rideToGpx } from "@/lib/export/gpx";
import { downloadFit, rideToFit } from "@/lib/export/fit";

function PostRideContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const rideId = searchParams.get("id");
  const rides = useAppStore((s) => s.rides);
  const recommendations = useAppStore((s) => s.recommendations);
  const acceptRecommendation = useAppStore((s) => s.acceptRecommendation);
  const dismissRecommendation = useAppStore((s) => s.dismissRecommendation);
  const submitRideFeedback = useAppStore((s) => s.submitRideFeedback);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const bikes = useAppStore((s) => s.bikes);
  const privacyZones = useAppStore((s) => s.privacyZones);

  const ride = rides.find((r) => r.id === rideId) || rides[0];
  const bike = ride ? bikes.find((b) => b.id === ride.bikeId) : null;
  const trackPreview = useMemo(
    () =>
      (ride?.track ?? []).map((p) => ({
        lat: p.lat,
        lng: p.lng,
      })),
    [ride]
  );
  const mapCenter: [number, number] = trackPreview[0]
    ? [trackPreview[0].lng, trackPreview[0].lat]
    : [12.15, 47.45];
  const rec = recommendations.find(
    (r) => r.relatedRideId === ride?.id && r.status === "shown"
  );
  const existingFeedback = ride
    ? rideFeedbacks.find((f) => f.rideId === ride.id)
    : undefined;

  const regenerateSetupRecommendation = useAppStore(
    (s) => s.regenerateSetupRecommendation
  );

  const [overall, setOverall] = useState<1 | 2 | 3 | 4 | 5>(3);
  const [frontFeel, setFrontFeel] =
    useState<RideFeedback["frontFeel"]>(undefined);
  const [brakeDive, setBrakeDive] =
    useState<RideFeedback["brakeDive"]>(undefined);
  const [smallBump, setSmallBump] =
    useState<RideFeedback["smallBump"]>(undefined);
  const [feedbackDone, setFeedbackDone] = useState(!!existingFeedback);

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
            {ride.plannedRouteName ? ` · ${ride.plannedRouteName}` : ""}
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

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">Deine Spur</h3>
        {trackPreview.length >= 2 ? (
          <>
            <MapView
              className="aspect-[4/3] w-full"
              center={mapCenter}
              zoom={12}
              track={trackPreview}
            />
            <p className="mt-2 text-[11px] text-text-secondary">
              {trackPreview.length} GPS-Punkte gespeichert
            </p>
          </>
        ) : (
          <p className="text-sm text-text-secondary">
            Kein Track gespeichert — nächster Ride mit „Route starten“ oder
            freiem Start legt eine Spur an.
          </p>
        )}
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => {
              const gpx = rideToGpx(ride, bike?.name);
              downloadText(
                `aetherride-${ride.id.slice(0, 8)}.gpx`,
                gpx,
                "application/gpx+xml"
              );
            }}
            className="inline-flex items-center gap-1 rounded-lg bg-accent px-3 py-2 text-xs font-medium text-white"
          >
            <Download className="h-3.5 w-3.5" /> GPX
          </button>
          <button
            type="button"
            onClick={() => {
              const fit = rideToFit(ride, { privacyZones });
              downloadFit(`aetherride-${ride.id.slice(0, 8)}.fit`, fit);
            }}
            className="inline-flex items-center gap-1 rounded-lg border border-border px-3 py-2 text-xs font-medium"
          >
            <Download className="h-3.5 w-3.5" /> FIT
          </button>
          <Link
            href="/privacy"
            className="inline-flex items-center rounded-lg border border-border px-3 py-2 text-xs text-text-secondary"
          >
            Mehr Export
          </Link>
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
            <div className="text-text-secondary text-xs">Max Lean (v·ω/g)</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.leanAngleMax}°
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">Impacts</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.impactCount}
              {ride.summaryMetrics.hardImpactCount != null
                ? ` · ${ride.summaryMetrics.hardImpactCount} hart`
                : ""}
            </div>
          </div>
          <div className="rounded-lg bg-surface-elevated p-2">
            <div className="text-text-secondary text-xs">RMS G</div>
            <div className="tabular-nums text-lg font-semibold">
              {ride.summaryMetrics.gForceRms} g
            </div>
          </div>
        </div>
        {ride.summaryMetrics.flowParts && (
          <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
            <div>Geschw.-Konstanz {ride.summaryMetrics.flowParts.speedConstancy}</div>
            <div>Laufruhe {ride.summaryMetrics.flowParts.smoothness}</div>
            <div>Bremsökonomie {ride.summaryMetrics.flowParts.brakeEconomy}</div>
            <div>Linienruhe {ride.summaryMetrics.flowParts.lineStability}</div>
          </div>
        )}
        {ride.summaryMetrics.fni != null && (
          <p className="mt-3 text-xs text-text-secondary">
            FNI {ride.summaryMetrics.fni} — {ride.summaryMetrics.fniReference}{" "}
            {ride.summaryMetrics.fniGated ? "(G-2 Gate — nicht live)" : ""} · nie
            mm/% Federweg
          </p>
        )}
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

      {ride.assistSummary && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-2 font-semibold">Assist-Modus-Log (F-EBK-005)</h3>
          <p className="mb-2 text-xs text-warning">{ride.assistSummary.disclaimer}</p>
          <p className="mb-2 text-sm">
            Dominant:{" "}
            <span className="font-semibold uppercase">
              {ride.assistSummary.dominantMode}
            </span>{" "}
            · ≈ {ride.assistSummary.estimatedTotalWh} Wh
          </p>
          <div className="mb-2 flex flex-wrap gap-2 text-[11px]">
            {Object.entries(ride.assistSummary.modeSharePct).map(([m, pct]) =>
              pct > 0 ? (
                <span
                  key={m}
                  className="rounded-md bg-surface-elevated px-2 py-0.5 uppercase"
                >
                  {m} {pct}%
                </span>
              ) : null
            )}
          </div>
          <ul className="space-y-1 text-xs text-text-secondary">
            {ride.assistSummary.segments.map((s) => (
              <li key={s.id}>
                {s.label} · {(s.distanceM / 1000).toFixed(1)} km · Quelle{" "}
                {s.source}
              </li>
            ))}
          </ul>
          <p className="mt-2 text-[10px] text-text-secondary">
            {ride.assistSummary.sourceLabel}
          </p>
        </section>
      )}

      {/* F-SET-004 Subjektives Feedback ≤3 Taps */}
      {!feedbackDone && (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="mb-1 font-semibold">Wie war&apos;s?</h3>
          <p className="mb-3 text-xs text-text-secondary">
            Max. 3 Taps, überspringbar — kategoriale Antworten für die
            Setup-Auswertung (F-SET-004).
          </p>
          <div className="mb-3 flex justify-between gap-1">
            {([1, 2, 3, 4, 5] as const).map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setOverall(n)}
                className={`flex-1 rounded-xl py-2 text-sm font-semibold ${
                  overall === n ? "bg-accent text-white" : "bg-surface-elevated"
                }`}
              >
                {n}
              </button>
            ))}
          </div>
          <div className="mb-2 text-xs text-text-secondary">
            Front (foren-nah)
          </div>
          <div className="mb-3 grid grid-cols-3 gap-2">
            {(
              [
                ["packt_nicht", "packt nicht"],
                ["taucht", "taucht"],
                ["ok", "passt"],
                ["rupft", "rupft"],
                ["toppt_aus", "toppt aus"],
                ["zu_straff", "zu straff"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setFrontFeel(id)}
                className={`rounded-lg py-2 text-xs ${
                  frontFeel === id ? "bg-primary text-white" : "bg-surface-elevated"
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
                ["taucht", "taucht"],
                ["neutral", "neutral"],
                ["steht", "steht"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setBrakeDive(id)}
                className={`flex-1 rounded-lg py-2 text-xs ${
                  brakeDive === id ? "bg-primary text-white" : "bg-surface-elevated"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="mb-2 text-xs text-text-secondary">Kleine Schläge</div>
          <div className="mb-3 grid grid-cols-2 gap-2">
            {(
              [
                ["rupft", "rupft"],
                ["ok", "passt"],
                ["schmiert", "schmiert"],
                ["tot", "tot"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setSmallBump(id)}
                className={`rounded-lg py-2 text-xs ${
                  smallBump === id ? "bg-primary text-white" : "bg-surface-elevated"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => {
                submitRideFeedback({
                  rideId: ride.id,
                  overallFeel: overall,
                  frontFeel,
                  brakeDive,
                  smallBump,
                  skipped: false,
                });
                setFeedbackDone(true);
                regenerateSetupRecommendation(ride.id);
              }}
              className="flex-1 rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
            >
              Speichern
            </button>
            <button
              type="button"
              onClick={() => {
                submitRideFeedback({
                  rideId: ride.id,
                  overallFeel: overall,
                  skipped: true,
                });
                setFeedbackDone(true);
              }}
              className="flex-1 rounded-xl border border-border py-2.5 text-sm"
            >
              Überspringen
            </button>
          </div>
        </section>
      )}
      {feedbackDone && (
        <p className="text-center text-xs text-text-secondary">
          Feedback erfasst{existingFeedback?.skipped || false ? " (übersprungen)" : ""}.
        </p>
      )}

      {/* F-AI-003 EvidenceSheet */}
      {rec && (
        <section className="rounded-2xl bg-surface border border-accent/40 p-4">
          <div className="mb-2 flex items-center gap-2">
            <Wrench className="h-5 w-5 text-accent" />
            <h3 className="font-semibold">{rec.title}</h3>
          </div>
          {rec.ruleId && (
            <p className="mb-1 text-[10px] uppercase text-text-secondary">
              {rec.ruleId} · Konfidenz {rec.confidence}
              {rec.observationOnly ? " · nur Beobachtung" : ""}
            </p>
          )}
          <p className="text-sm mb-2 whitespace-pre-wrap">{rec.content}</p>
          {rec.expectedEffect && (
            <p className="mb-1 text-xs">
              <span className="text-text-secondary">Erwartete Wirkung: </span>
              {rec.expectedEffect}
            </p>
          )}
          {rec.workshopLine && (
            <p className="mb-1 text-xs">
              <span className="font-medium">Werkstatt: </span>
              {rec.workshopLine}
            </p>
          )}
          {rec.coachLine && (
            <p className="mb-2 text-xs">
              <span className="font-medium">Coach: </span>
              {rec.coachLine}
            </p>
          )}
          {rec.limits && (
            <p className="mb-2 text-xs text-text-secondary">Grenzen: {rec.limits}</p>
          )}
          <div className="mb-3">
            <SetupLiabilityNotice variant="short" />
          </div>
          {rec.evidence && rec.evidence.length > 0 && (
            <ul className="mb-4 list-inside list-disc text-xs text-text-secondary">
              {rec.evidence.map((e) => (
                <li key={e}>{e}</li>
              ))}
            </ul>
          )}
          <p className="text-xs text-text-secondary mb-4">{rec.reasoning}</p>
          <div className="flex gap-2">
            <button
              onClick={() => {
                acceptRecommendation(rec.id);
              }}
              disabled={!!rec.observationOnly || !rec.setupApply || Object.keys(rec.setupApply).length === 0}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-medium text-white disabled:opacity-40"
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
