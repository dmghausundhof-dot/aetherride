"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDuration } from "@/lib/utils";
import {
  Play,
  Square,
  Pause,
  Activity,
  Gauge,
  Zap,
  Volume2,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import { MapView } from "@/components/MapView";
import { WebSensorSimulator, type FusedMetrics } from "@/lib/sensor/SensorFusion";
import { createMotorAdapter } from "@/lib/ebike/MotorSystemAdapter";
import { createStandardBleClient } from "@/lib/ble/standardSensors";
import { hintsFromMetrics, speakHint } from "@/lib/sensor/liveHints";
import { estimateRange } from "@/lib/ebike/range";
import { suspensionAnalysisAvailable } from "@/lib/sensor/calibration";
import { createEmptyCalibration } from "@/lib/sensor/calibration";
import { uiVisibilityForMode } from "@/lib/mode/hiking";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import {
  geometryToPreviewTrack,
  pointAlongGeometry,
} from "@/lib/routing/rideHandoff";
import { evaluateRouteFollow } from "@/lib/routing/routeFollow";
import Link from "next/link";

export default function RidePage() {
  const router = useRouter();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const isRiding = useAppStore((s) => s.isRiding);
  const currentRide = useAppStore((s) => s.currentRide);
  const liveMetrics = useAppStore((s) => s.liveMetrics);
  const boschLive = useAppStore((s) => s.boschLive);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const startRide = useAppStore((s) => s.startRide);
  const endRide = useAppStore((s) => s.endRide);
  const plannedRoute = useAppStore((s) => s.plannedRoute);
  const setPlannedRoute = useAppStore((s) => s.setPlannedRoute);
  const appendTrackPoint = useAppStore((s) => s.appendTrackPoint);
  const updateLiveMetrics = useAppStore((s) => s.updateLiveMetrics);
  const updateBoschLive = useAppStore((s) => s.updateBoschLive);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const bikeCalibrations = useAppStore((s) => s.bikeCalibrations);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const appMode = useAppStore((s) => s.appMode);
  const rangePro = canUseProFeature("range");
  const ui = uiVisibilityForMode(appMode);

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const bikeCal =
    (activeBike && bikeCalibrations[activeBike.id]) ||
    (activeBike ? createEmptyCalibration(activeBike.id) : null);
  const susp = suspensionAnalysisAvailable(bikeCal);

  const [elapsed, setElapsed] = useState(0);
  const [track, setTrack] = useState<{ lat: number; lng: number }[]>([]);
  const [hint, setHint] = useState<string | null>(null);
  const [confirmEnd, setConfirmEnd] = useState(false);
  const [paused, setPaused] = useState(false);
  const [showDetails, setShowDetails] = useState(false);
  const [bleCadence, setBleCadence] = useState<number | null>(null);
  const [bleHr, setBleHr] = useState<number | null>(null);
  const [followHint, setFollowHint] = useState<string | null>(null);
  const [progress01, setProgress01] = useState(0);

  const sensorRef = useRef<WebSensorSimulator | null>(null);
  const motorRef = useRef<ReturnType<typeof createMotorAdapter> | null>(null);
  const bleRef = useRef<ReturnType<typeof createStandardBleClient> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const standRef = useRef(0);
  const impactStreakRef = useRef(0);
  const lastImpactRef = useRef(false);
  const hardImpactsRef = useRef(0);
  const bottomOutRef = useRef(0);
  const elapsedRef = useRef(0);
  const pausedRef = useRef(false);

  useEffect(() => {
    pausedRef.current = paused;
  }, [paused]);

  const range =
    activeBike?.isEbike && rangePro && appMode === "bike"
      ? estimateRange({
          bike: activeBike,
          profile,
          calibration: calibration ?? undefined,
          socPercent: boschLive?.soc ?? 87,
          speedKmh: boschLive?.speed ?? 18,
        })
      : null;

  useEffect(() => {
    if (!isRiding) {
      sensorRef.current?.stop();
      motorRef.current?.disconnect();
      bleRef.current?.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
      setElapsed(0);
      setHint(null);
      setConfirmEnd(false);
      setPaused(false);
      setFollowHint(null);
      setProgress01(0);
      return;
    }

    const sensor = new WebSensorSimulator();
    sensor.getEngine().updateConfig({
      mountMode: bikeCal?.mountMode ?? "UNKNOWN",
      calibrated: !!bikeCal && susp.available,
      terrainClass: "s2",
      sampleRateHz: 200,
    });
    sensorRef.current = sensor;
    let impactTotal = 0;
    hardImpactsRef.current = 0;
    bottomOutRef.current = 0;

    sensor.start((m: FusedMetrics) => {
      if (pausedRef.current) return;
      if (m.impactDetected) {
        impactTotal += 1;
        impactStreakRef.current += 1;
        lastImpactRef.current = true;
        if (m.impactClass === "hard") hardImpactsRef.current += 1;
      } else {
        impactStreakRef.current = Math.max(0, impactStreakRef.current - 1);
        lastImpactRef.current = false;
      }
      if (m.bottomOut) bottomOutRef.current += 1;

      const flow = sensor.getEngine().getFlowScore(elapsedRef.current);
      updateLiveMetrics({
        gForcePeak: m.gForcePeak,
        gForceRms: m.gForceRms,
        leanAngleMax: m.leanAngleDeg ?? 0,
        leanConfidence: m.leanConfidence,
        impactCount: impactTotal,
        hardImpactCount: hardImpactsRef.current,
        flowScore: flow.available && flow.total != null ? flow.total : 0,
        flowParts: flow.parts ?? undefined,
        flowTerrainClass: flow.terrainClass,
        fni: m.fni?.fni,
        fniReference: m.fni?.referenceText,
        fniGated: m.fni?.gated ?? !G2_SUSPENSION_GATE_PASSED,
        bottomOutCount: bottomOutRef.current,
        suspensionActivityRms: m.suspensionActivityRms,
      });
    });

    const motor = createMotorAdapter({
      isEbike: !!activeBike?.isEbike && appMode === "bike",
      preferBoschLdi: true,
    });
    motorRef.current = motor;
    const caps = motor.capabilities();
    motor.onTelemetry((t) => {
      if (pausedRef.current) return;
      if (t.speedKmh != null) sensor.setSpeedKmh(t.speedKmh);
      updateBoschLive({
        speed: t.speedKmh ?? 0,
        soc: t.batterySocPercent ?? 0,
        riderPower: t.riderPowerW ?? 0,
        cadence: t.cadenceRpm ?? 0,
        odometer: t.odometerKm ?? 0,
      });
      if ((t.speedKmh ?? 0) < 3) standRef.current += 1;
      else standRef.current = 0;

      const liveHints = hintsFromMetrics({
        speedKmh: t.speedKmh ?? 0,
        standSeconds: standRef.current,
        impactJustDetected: lastImpactRef.current,
        hardImpactStreak: impactStreakRef.current,
      });
      if (liveHints[0]) {
        setHint(liveHints[0].text);
        if (
          liveHints[0].kind === "safety" ||
          liveHints[0].kind === "bracketing"
        ) {
          speakHint(liveHints[0].text);
        }
      }
      void caps;
    });
    motor.connect();

    const ble = createStandardBleClient();
    bleRef.current = ble;
    ble.onData((b) => {
      setBleCadence(b.cscs?.cadenceRpm ?? null);
      setBleHr(b.hrs?.bpm ?? null);
      if (b.cscs?.speedKmh != null && !caps.readSpeed) {
        sensor.setSpeedKmh(b.cscs.speedKmh);
      }
    });
    ble.connect();

    let t = 0;
    const planned = useAppStore.getState().plannedRoute;
    const geom = planned?.geometryLngLat ?? null;
    const durationTargetSec = Math.max(60, (planned?.durationMin ?? 20) * 60);
    const baseLat = geom?.[0]?.[1] ?? 47.45;
    const baseLng = geom?.[0]?.[0] ?? 12.15;

    timerRef.current = setInterval(() => {
      if (pausedRef.current) return;
      t += 1;
      elapsedRef.current = t;
      setElapsed(t);
      let lat: number;
      let lng: number;
      const progress = Math.min(0.98, t / durationTargetSec);
      setProgress01(progress);
      if (geom && geom.length >= 2) {
        const pt = pointAlongGeometry(geom, progress);
        // gelegentlich leichter Off-Route-Drift für Demo-Hinweis
        const drift = t % 47 === 0 ? 0.0009 : 0.00005;
        lat = pt.lat + (Math.random() - 0.5) * drift;
        lng = pt.lng + (Math.random() - 0.5) * drift;
      } else {
        lat =
          baseLat + Math.sin(t / 40) * 0.008 + (Math.random() - 0.5) * 0.0003;
        lng = baseLng + t * 0.00015 + Math.cos(t / 30) * 0.004;
      }
      const elev =
        800 + (planned?.elevationGainM ?? 400) * Math.min(1, progress);
      const point = { lat, lng, elev, time: t };
      setTrack((prev) => [...prev.slice(-400), { lat, lng }]);
      appendTrackPoint(point);

      const follow = evaluateRouteFollow(planned, { lat, lng }, progress);
      if (follow?.hintDe) {
        setFollowHint(follow.hintDe);
        if (follow.offRoute) speakHint(follow.hintDe);
      } else {
        setFollowHint(null);
      }
    }, 1000);

    return () => {
      sensor.stop();
      motor.disconnect();
      ble.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isRiding, updateBoschLive, updateLiveMetrics, appendTrackPoint]);

  const handleStart = () => {
    if (!activeBike) return;
    setTrack([]);
    startRide(
      activeBike.id,
      appMode === "hiking" ? "hiking" : activeBike.type
    );
  };

  const handleEnd = () => {
    if (!confirmEnd) {
      setConfirmEnd(true);
      return;
    }
    const ride = endRide();
    if (ride) router.push(`/post-ride?id=${ride.id}`);
  };

  const routePreview = plannedRoute
    ? geometryToPreviewTrack(plannedRoute.geometryLngLat)
    : [];
  const mapCenter: [number, number] = track[track.length - 1]
    ? [track[track.length - 1].lng, track[track.length - 1].lat]
    : plannedRoute?.geometryLngLat?.[0]
      ? [plannedRoute.geometryLngLat[0][0], plannedRoute.geometryLngLat[0][1]]
      : [12.15, 47.45];

  const speedKmh = boschLive?.speed ?? 0;
  const distanceM = currentRide?.distanceM ?? 0;
  const elevM = useMemo(() => {
    if (!plannedRoute) return Math.round(distanceM * 0.04);
    return Math.round(plannedRoute.elevationGainM * progress01);
  }, [plannedRoute, distanceM, progress01]);

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">
          {appMode === "hiking" ? "Wanderung" : "Ride"}
        </h1>
        {activeBike && appMode === "bike" && (
          <p className="text-sm text-text-secondary">
            {activeBike.name}
            {plannedRoute ? ` · ${plannedRoute.name}` : ""}
          </p>
        )}
      </header>

      {!isRiding && bikes.length > 1 && appMode === "bike" && (
        <section className="rounded-xl border border-border bg-surface p-3">
          <p className="mb-2 text-xs font-medium text-text-secondary">
            Bike wählen
          </p>
          <div className="flex flex-wrap gap-2">
            {bikes.map((b) => (
              <button
                key={b.id}
                type="button"
                onClick={() => setActiveBike(b.id)}
                className={`rounded-lg px-3 py-1.5 text-xs font-medium ${
                  b.id === activeBike?.id
                    ? "bg-accent text-white"
                    : "bg-surface-elevated text-text-secondary"
                }`}
              >
                {b.name}
              </button>
            ))}
          </div>
        </section>
      )}

      {plannedRoute && !isRiding && (
        <div className="rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
          <p className="font-medium">{plannedRoute.name}</p>
          <p className="text-xs text-text-secondary">
            {(plannedRoute.distanceM / 1000).toFixed(1)} km ·{" "}
            {plannedRoute.elevationGainM} hm · ~{plannedRoute.durationMin} min
            {plannedRoute.mtbScale ? ` · ${plannedRoute.mtbScale}` : ""}
          </p>
          <div className="mt-2 flex flex-wrap gap-2">
            <Link href="/discover" className="text-xs text-accent">
              Andere Route
            </Link>
            <button
              type="button"
              onClick={() => setPlannedRoute(null)}
              className="text-xs text-text-secondary"
            >
              Freier Ride
            </button>
          </div>
        </div>
      )}

      <MapView
        className="aspect-[4/3] w-full"
        center={mapCenter}
        zoom={13}
        track={track}
        routeLine={routePreview}
      />

      {(hint || followHint) && isRiding && (
        <div
          className={`flex items-center gap-2 rounded-xl px-3 py-2 text-sm ${
            followHint?.includes("Abseits")
              ? "border border-warning/50 bg-warning/15"
              : "border border-accent/40 bg-accent/10"
          }`}
        >
          <Volume2 className="h-4 w-4 shrink-0" />
          <span>{followHint ?? hint}</span>
        </div>
      )}

      {isRiding ? (
        <div aria-live="polite" className="space-y-3">
          <div className="text-center">
            <div className="text-5xl font-bold tracking-tight tabular-nums">
              {formatDuration(elapsed)}
            </div>
            {paused && (
              <p className="mt-1 text-xs font-medium text-warning">Pausiert</p>
            )}
          </div>

          <div className="grid grid-cols-4 gap-2 text-center">
            <Glance
              label="km/h"
              value={speedKmh ? String(Math.round(speedKmh)) : "—"}
            />
            <Glance
              label="km"
              value={(distanceM / 1000).toFixed(distanceM > 1000 ? 1 : 2)}
            />
            <Glance label="hm" value={String(elevM)} />
            <Glance
              label="Akku"
              value={
                activeBike?.isEbike && boschLive
                  ? `${boschLive.soc}%`
                  : "—"
              }
            />
          </div>

          {plannedRoute && (
            <div className="rounded-xl bg-surface-elevated px-3 py-2 text-xs text-text-secondary">
              Route {Math.round(progress01 * 100)} % · Rest ca.{" "}
              {(
                (plannedRoute.distanceM * (1 - progress01)) /
                1000
              ).toFixed(1)}{" "}
              km
            </div>
          )}

          {range && (
            <p className="text-center text-xs text-text-secondary">
              Restreichweite {range.kmLow}–{range.kmHigh} km
            </p>
          )}

          <button
            type="button"
            onClick={() => setShowDetails((v) => !v)}
            className="flex w-full items-center justify-center gap-1 text-xs text-text-secondary"
          >
            {showDetails ? (
              <>
                Details aus <ChevronUp className="h-3.5 w-3.5" />
              </>
            ) : (
              <>
                Sensor-Details <ChevronDown className="h-3.5 w-3.5" />
              </>
            )}
          </button>

          {showDetails && liveMetrics && (
            <div className="space-y-2">
              <div className="grid grid-cols-2 gap-2">
                <MetricCard
                  icon={<Gauge className="h-4 w-4" />}
                  label="G-Peak"
                  value={`${liveMetrics.gForcePeak} g`}
                />
                <MetricCard
                  icon={<Activity className="h-4 w-4" />}
                  label="Lean"
                  value={
                    liveMetrics.leanAngleMax
                      ? `${liveMetrics.leanAngleMax}°`
                      : "—"
                  }
                />
                <MetricCard
                  icon={<Activity className="h-4 w-4" />}
                  label="Impacts"
                  value={`${liveMetrics.impactCount}`}
                />
                <MetricCard
                  icon={<Activity className="h-4 w-4" />}
                  label="Flow"
                  value={
                    liveMetrics.flowScore > 0
                      ? `${liveMetrics.flowScore}`
                      : "…"
                  }
                  accent
                />
              </div>
              {ui.suspensionMetrics && (
                <p className="rounded-lg bg-surface-elevated px-2 py-1.5 text-[11px] text-text-secondary">
                  {liveMetrics.fniGated
                    ? `Fahrwerk-Index ${liveMetrics.fni ?? "—"} · Validierung ausstehend`
                    : `FNI ${liveMetrics.fni}`}
                  {" · "}
                  Durchschlag {liveMetrics.bottomOutCount ?? 0}×
                </p>
              )}
              {boschConnected && boschLive && activeBike?.isEbike && (
                <div className="flex items-center gap-2 rounded-lg border border-primary/30 bg-primary/10 px-2 py-1.5 text-[11px]">
                  <Zap className="h-3.5 w-3.5 text-accent" />
                  {boschLive.riderPower} W · {boschLive.cadence} rpm
                  {bleHr != null ? ` · HR ${bleHr}` : ""}
                  {bleCadence != null ? ` · Cad ${bleCadence}` : ""}
                </div>
              )}
            </div>
          )}
        </div>
      ) : (
        <div className="rounded-2xl border border-border bg-surface p-4 text-center text-sm text-text-secondary">
          {activeBike
            ? `${activeBike.name} · ${bikeTypeLabel(activeBike.type)} — bereit`
            : "Bitte Bike in der Garage anlegen"}
        </div>
      )}

      <div className="flex items-center justify-center gap-6 pt-1">
        {isRiding && (
          <button
            type="button"
            onClick={() => setPaused((p) => !p)}
            aria-label={paused ? "Fortsetzen" : "Pause"}
            className="flex h-14 w-14 items-center justify-center rounded-full border border-border bg-surface-elevated"
          >
            {paused ? (
              <Play className="ml-0.5 h-6 w-6" />
            ) : (
              <Pause className="h-6 w-6" />
            )}
          </button>
        )}
        {!isRiding ? (
          <button
            type="button"
            onClick={handleStart}
            disabled={!activeBike && appMode === "bike"}
            aria-label="Ride starten"
            className="flex h-20 w-20 items-center justify-center rounded-full bg-accent text-white shadow-xl shadow-accent/30 transition active:scale-95 disabled:opacity-40"
          >
            <Play className="ml-1 h-10 w-10 fill-current" aria-hidden />
          </button>
        ) : (
          <button
            type="button"
            onClick={handleEnd}
            aria-label={
              confirmEnd ? "Ride beenden bestätigen" : "Ride beenden"
            }
            className={`flex h-20 w-20 items-center justify-center rounded-full text-white shadow-xl transition active:scale-95 ${
              confirmEnd ? "bg-error" : "bg-error/70"
            }`}
          >
            <Square className="h-9 w-9 fill-current" aria-hidden />
          </button>
        )}
      </div>
      <p className="text-center text-sm text-text-secondary">
        {isRiding
          ? confirmEnd
            ? "Nochmal tippen zum Beenden"
            : paused
              ? "Pause — Spur gestoppt"
              : "Pause · Beenden mit 2 Tipps"
          : "Tippen zum Starten"}
      </p>
    </div>
  );
}

function Glance({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-surface px-1 py-2">
      <div className="text-xl font-bold tabular-nums">{value}</div>
      <div className="text-[10px] text-text-secondary">{label}</div>
    </div>
  );
}

function MetricCard({
  icon,
  label,
  value,
  accent,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  accent?: boolean;
}) {
  return (
    <div className="rounded-xl border border-border bg-surface p-3">
      <div className="mb-1 flex items-center gap-1.5 text-text-secondary">
        {icon}
        <span className="text-xs">{label}</span>
      </div>
      <div
        className={`text-xl font-bold tabular-nums ${accent ? "text-accent" : ""}`}
      >
        {value}
      </div>
    </div>
  );
}
