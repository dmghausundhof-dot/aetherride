"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDuration } from "@/lib/utils";
import { Play, Square, Activity, Gauge, Zap, Volume2 } from "lucide-react";
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

export default function RidePage() {
  const router = useRouter();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const isRiding = useAppStore((s) => s.isRiding);
  const liveMetrics = useAppStore((s) => s.liveMetrics);
  const boschLive = useAppStore((s) => s.boschLive);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const startRide = useAppStore((s) => s.startRide);
  const endRide = useAppStore((s) => s.endRide);
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
  const [bleCadence, setBleCadence] = useState<number | null>(null);
  const [bleHr, setBleHr] = useState<number | null>(null);
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
      return;
    }

    const sensor = new WebSensorSimulator();
    sensor
      .getEngine()
      .updateConfig({
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
        if (liveHints[0].kind === "safety" || liveHints[0].kind === "bracketing") {
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
    const baseLat = 47.45;
    const baseLng = 12.15;
    timerRef.current = setInterval(() => {
      t += 1;
      elapsedRef.current = t;
      setElapsed(t);
      setTrack((prev) => [
        ...prev.slice(-200),
        {
          lat: baseLat + Math.sin(t / 40) * 0.008 + (Math.random() - 0.5) * 0.0003,
          lng: baseLng + t * 0.00015 + Math.cos(t / 30) * 0.004,
        },
      ]);
    }, 1000);

    return () => {
      sensor.stop();
      motor.disconnect();
      ble.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isRiding, updateBoschLive, updateLiveMetrics]);

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

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">
          {appMode === "hiking" ? "Wanderung" : "Ride"}
        </h1>
        {activeBike && appMode === "bike" && (
          <p className="text-sm text-text-secondary">
            {activeBike.name} · {bikeTypeLabel(activeBike.type)} · 200 Hz Batches
          </p>
        )}
        {appMode === "hiking" && (
          <p className="text-sm text-text-secondary">
            Hiking-Modus — Fahrwerk/Bracketing ausgeblendet (Spec 2.8)
          </p>
        )}
      </header>

      <MapView
        className="aspect-[4/3] w-full"
        center={[12.15, 47.45]}
        zoom={13}
        track={track}
      />

      {hint && isRiding && (
        <div className="flex items-center gap-2 rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
          <Volume2 className="h-4 w-4 text-accent" />
          <span>{hint}</span>
          <span className="ml-auto text-[10px] text-text-secondary">
            ≤6 Wörter · F-SEN-005
          </span>
        </div>
      )}

      {range && (
        <div className="rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-sm">
          Restreichweite ca.{" "}
          <span className="font-semibold text-accent">
            {range.kmLow}–{range.kmHigh} km
          </span>
          <span className="text-xs text-text-secondary">
            {" "}
            · {range.confidence}
          </span>
        </div>
      )}

      {isRiding && liveMetrics ? (
        <>
          <div className="grid grid-cols-2 gap-3">
            <MetricCard
              icon={<Gauge className="h-5 w-5" />}
              label="G-Force Peak"
              value={`${liveMetrics.gForcePeak} g`}
              accent
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Lean (v·ω/g)"
              value={
                liveMetrics.leanAngleMax
                  ? `${liveMetrics.leanAngleMax}°`
                  : "—"
              }
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Impacts"
              value={`${liveMetrics.impactCount}`}
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Flow Score"
              value={
                liveMetrics.flowScore > 0 ? `${liveMetrics.flowScore}` : "…"
              }
              accent
            />
          </div>

          {liveMetrics.flowParts && (
            <div className="rounded-xl border border-border bg-surface p-3 text-xs">
              <div className="mb-2 font-medium">Flow-Teilwerte (F-SEN-004)</div>
              <div className="grid grid-cols-2 gap-2">
                <span>Konstanz {liveMetrics.flowParts.speedConstancy}</span>
                <span>Laufruhe {liveMetrics.flowParts.smoothness}</span>
                <span>Bremsen {liveMetrics.flowParts.brakeEconomy}</span>
                <span>Linie {liveMetrics.flowParts.lineStability}</span>
              </div>
              <p className="mt-2 text-[10px] text-text-secondary">
                Nur eigene Historie · Terrain {liveMetrics.flowTerrainClass}
              </p>
            </div>
          )}

          {ui.suspensionMetrics ? (
            susp.available ? (
              <div className="rounded-xl border border-border bg-surface p-3 text-xs">
                <div className="mb-1 font-medium">Fahrwerk</div>
                {liveMetrics.fniGated ? (
                  <p className="text-warning">
                    FNI {liveMetrics.fni ?? "—"} (Index) · Gate G-2 offen — keine
                    mm/%-Angabe, Feature noch nicht live.
                  </p>
                ) : (
                  <p>
                    FNI {liveMetrics.fni} — {liveMetrics.fniReference}
                  </p>
                )}
                <p className="mt-1 text-text-secondary">
                  Aktivität RMS {liveMetrics.suspensionActivityRms ?? "—"} ·
                  Durchschlagsverdacht {liveMetrics.bottomOutCount ?? 0}×
                </p>
              </div>
            ) : (
              <div className="rounded-xl border border-border bg-surface p-3 text-sm">
                {susp.message}
              </div>
            )
          ) : null}
        </>
      ) : (
        <div className="rounded-2xl border border-border bg-surface p-5 text-center text-sm text-text-secondary">
          <p className="mb-1 font-medium text-foreground">Sensor-Pipeline bereit</p>
          <p>
            Spec: 200 Hz Accel/Gyro in 1-s-Batches · Lean = atan(v·ω/g) ab 8
            km/h · keine mm-Federweg-Fantasie.
          </p>
        </div>
      )}

      {isRiding && boschConnected && boschLive && appMode === "bike" && (
        <div className="rounded-2xl border border-primary/30 bg-primary/15 p-4">
          <div className="mb-2 flex items-center gap-2 text-sm font-medium text-accent">
            <Zap className="h-4 w-4" /> MotorSystemAdapter (LDI read-only)
          </div>
          <div className="grid grid-cols-4 gap-2 text-center">
            <div>
              <div className="text-xl font-bold tabular-nums">{boschLive.speed}</div>
              <div className="text-[10px] text-text-secondary">km/h</div>
            </div>
            <div>
              <div className="text-xl font-bold tabular-nums">{boschLive.soc}%</div>
              <div className="text-[10px] text-text-secondary">SOC</div>
            </div>
            <div>
              <div className="text-xl font-bold tabular-nums">
                {boschLive.riderPower}
              </div>
              <div className="text-[10px] text-text-secondary">W Rider</div>
            </div>
            <div>
              <div className="text-xl font-bold tabular-nums">{boschLive.cadence}</div>
              <div className="text-[10px] text-text-secondary">rpm</div>
            </div>
          </div>
        </div>
      )}

      {isRiding && (bleCadence != null || bleHr != null) && (
        <div className="rounded-xl border border-border bg-surface px-3 py-2 text-xs text-text-secondary">
          BLE Standard (F-EBK-003): Cadence {bleCadence ?? "—"} rpm · HR{" "}
          {bleHr ?? "—"} bpm
        </div>
      )}

      <div className="flex flex-col items-center gap-4 pt-2">
        {isRiding && (
          <div className="text-5xl font-bold tracking-tight tabular-nums">
            {formatDuration(elapsed)}
          </div>
        )}
        {!isRiding ? (
          <button
            onClick={handleStart}
            disabled={!activeBike && appMode === "bike"}
            className="flex h-20 w-20 items-center justify-center rounded-full bg-accent text-white shadow-xl shadow-accent/30 transition active:scale-95 disabled:opacity-40"
          >
            <Play className="ml-1 h-10 w-10 fill-current" />
          </button>
        ) : (
          <button
            onClick={handleEnd}
            className={`flex h-20 w-20 items-center justify-center rounded-full text-white shadow-xl transition active:scale-95 ${
              confirmEnd ? "bg-error" : "bg-error/70"
            }`}
          >
            <Square className="h-9 w-9 fill-current" />
          </button>
        )}
        <p className="text-sm text-text-secondary">
          {isRiding
            ? confirmEnd
              ? "Nochmal tippen zum Beenden"
              : "Beenden erfordert 2 Tipps"
            : "Tippen zum Starten"}
        </p>
      </div>
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
        className={`text-2xl font-bold tabular-nums ${accent ? "text-accent" : ""}`}
      >
        {value}
      </div>
    </div>
  );
}
