"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDuration } from "@/lib/utils";
import { Play, Square, Activity, Gauge, Zap } from "lucide-react";
import { MapView } from "@/components/MapView";
import { WebSensorSimulator, type FusedMetrics } from "@/lib/sensor/SensorFusion";
import { createBoschLDIClient, type BoschLiveData } from "@/lib/ble/BoschLDI";

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

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [elapsed, setElapsed] = useState(0);
  const [track, setTrack] = useState<{ lat: number; lng: number }[]>([]);
  const sensorRef = useRef<WebSensorSimulator | null>(null);
  const boschRef = useRef<ReturnType<typeof createBoschLDIClient> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!isRiding) {
      sensorRef.current?.stop();
      boschRef.current?.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
      setElapsed(0);
      return;
    }

    const sensor = new WebSensorSimulator();
    sensorRef.current = sensor;
    let impactTotal = 0;

    sensor.start((m: FusedMetrics) => {
      if (m.impactDetected) impactTotal += 1;
      updateLiveMetrics({
        gForcePeak: m.gForcePeak,
        gForceRms: m.gForceRms,
        leanAngleMax: m.leanAngleDeg,
        impactCount: impactTotal,
        flowScore: Math.round(55 + m.flowContribution * 40),
      });
    }, 15);

    const bosch = createBoschLDIClient();
    boschRef.current = bosch;
    bosch.onData((data: BoschLiveData) => {
      updateBoschLive({
        speed: data.speedKmh,
        soc: data.batterySocPercent,
        riderPower: data.riderPowerW,
        cadence: data.cadenceRpm,
        odometer: data.odometerKm,
      });
    });
    bosch.connect();

    let t = 0;
    const baseLat = 47.45;
    const baseLng = 12.15;
    timerRef.current = setInterval(() => {
      t += 1;
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
      bosch.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isRiding]);

  const handleStart = () => {
    if (!activeBike) return;
    setTrack([]);
    startRide(activeBike.id, activeBike.type);
  };

  const handleEnd = () => {
    const ride = endRide();
    if (ride) router.push(`/post-ride?id=${ride.id}`);
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Ride</h1>
        {activeBike && (
          <p className="text-sm text-text-secondary">
            {activeBike.name} · {bikeTypeLabel(activeBike.type)}
          </p>
        )}
      </header>

      <MapView
        className="aspect-[4/3] w-full"
        center={[12.15, 47.45]}
        zoom={13}
        track={track}
      />

      {isRiding && liveMetrics ? (
        <div className="grid grid-cols-2 gap-3">
          <MetricCard icon={<Gauge className="h-5 w-5" />} label="G-Force Peak" value={`${liveMetrics.gForcePeak} g`} accent />
          <MetricCard icon={<Activity className="h-5 w-5" />} label="Lean Angle" value={`${liveMetrics.leanAngleMax}°`} />
          <MetricCard icon={<Activity className="h-5 w-5" />} label="Impacts" value={`${liveMetrics.impactCount}`} />
          <MetricCard icon={<Activity className="h-5 w-5" />} label="Flow Score" value={`${liveMetrics.flowScore}`} accent />
        </div>
      ) : (
        <div className="rounded-2xl bg-surface border border-border p-5 text-center text-sm text-text-secondary">
          <p className="font-medium text-foreground mb-1">Sensor-Pipeline bereit</p>
          <p>Accelerometer · Gyro · Barometer · Fusion @ 15–50 Hz</p>
          <p className="mt-1 text-xs opacity-70">Native: CoreMotion / SensorManager</p>
        </div>
      )}

      {isRiding && boschConnected && boschLive && (
        <div className="rounded-2xl bg-primary/15 border border-primary/30 p-4">
          <div className="mb-2 flex items-center gap-2 text-sm font-medium text-accent">
            <Zap className="h-4 w-4" /> Bosch Live Data Interface (LDI)
          </div>
          <div className="grid grid-cols-4 gap-2 text-center">
            <div>
              <div className="tabular-nums text-xl font-bold">{boschLive.speed}</div>
              <div className="text-[10px] text-text-secondary">km/h</div>
            </div>
            <div>
              <div className="tabular-nums text-xl font-bold">{boschLive.soc}%</div>
              <div className="text-[10px] text-text-secondary">SOC</div>
            </div>
            <div>
              <div className="tabular-nums text-xl font-bold">{boschLive.riderPower}</div>
              <div className="text-[10px] text-text-secondary">W Rider</div>
            </div>
            <div>
              <div className="tabular-nums text-xl font-bold">{boschLive.cadence}</div>
              <div className="text-[10px] text-text-secondary">rpm</div>
            </div>
          </div>
        </div>
      )}

      <div className="flex flex-col items-center gap-4 pt-2">
        {isRiding && (
          <div className="tabular-nums text-5xl font-bold tracking-tight">
            {formatDuration(elapsed)}
          </div>
        )}
        {!isRiding ? (
          <button
            onClick={handleStart}
            disabled={!activeBike}
            className="flex h-20 w-20 items-center justify-center rounded-full bg-accent text-white shadow-xl shadow-accent/30 transition active:scale-95 disabled:opacity-40"
          >
            <Play className="h-10 w-10 fill-current ml-1" />
          </button>
        ) : (
          <button
            onClick={handleEnd}
            className="flex h-20 w-20 items-center justify-center rounded-full bg-error text-white shadow-xl transition active:scale-95"
          >
            <Square className="h-9 w-9 fill-current" />
          </button>
        )}
        <p className="text-sm text-text-secondary">
          {isRiding ? "Ride beenden → Analyse" : "Tippen zum Starten"}
        </p>
      </div>
    </div>
  );
}

function MetricCard({
  icon, label, value, accent,
}: { icon: React.ReactNode; label: string; value: string; accent?: boolean }) {
  return (
    <div className="rounded-xl bg-surface border border-border p-3">
      <div className="mb-1 flex items-center gap-1.5 text-text-secondary">
        {icon}
        <span className="text-xs">{label}</span>
      </div>
      <div className={`tabular-nums text-2xl font-bold ${accent ? "text-accent" : ""}`}>
        {value}
      </div>
    </div>
  );
}
