"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, formatDistance, formatDuration } from "@/lib/utils";
import {
  Play,
  Square,
  Activity,
  Gauge,
  Zap,
  Volume2,
  Map as MapIcon,
  LayoutGrid,
  Waves,
  X,
  Pause,
  Navigation,
  Sun,
  Lock,
  Unlock,
} from "lucide-react";
import { MapView } from "@/components/MapView";
import { WebSensorSimulator, type FusedMetrics } from "@/lib/sensor/SensorFusion";
import { createBoschLDIClient, type BoschLiveData } from "@/lib/ble/BoschLDI";
import { hintsFromMetrics, speakHint, speakNav } from "@/lib/sensor/liveHints";
import { estimateRange } from "@/lib/ebike/range";
import { centerOfGeometry } from "@/lib/routing/demoGeometry";
import { formatRouteChip } from "@/lib/routing/activeRoute";
import {
  resolveNavCues,
  cueBannerText,
  nextCue,
} from "@/lib/routing/navCues";
import {
  projectOntoRoute,
  updateOffRouteState,
} from "@/lib/routing/routeProgress";
import { pickAnnounce } from "@/lib/routing/navSteps";
import { pointAlongLine } from "@/lib/geo/trackMath";
import { activeDurationSec } from "@/lib/ride/activeDuration";
import type { MountCheck, RideLiveLayer } from "@/types/route";

const LAYERS: { id: RideLiveLayer; label: string; icon: typeof MapIcon }[] = [
  { id: "map", label: "Karte", icon: MapIcon },
  { id: "data", label: "Daten", icon: LayoutGrid },
  { id: "suspension", label: "Fahrwerk", icon: Waves },
];

export default function RidePage() {
  const router = useRouter();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const activeRoute = useAppStore((s) => s.activeRoute);
  const clearActiveRoute = useAppStore((s) => s.clearActiveRoute);
  const isRiding = useAppStore((s) => s.isRiding);
  const isPaused = useAppStore((s) => s.isPaused);
  const pauseRide = useAppStore((s) => s.pauseRide);
  const resumeRide = useAppStore((s) => s.resumeRide);
  const currentRide = useAppStore((s) => s.currentRide);
  const liveMetrics = useAppStore((s) => s.liveMetrics);
  const boschLive = useAppStore((s) => s.boschLive);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const startRide = useAppStore((s) => s.startRide);
  const endRide = useAppStore((s) => s.endRide);
  const updateLiveMetrics = useAppStore((s) => s.updateLiveMetrics);
  const updateBoschLive = useAppStore((s) => s.updateBoschLive);
  const appendTrackPoint = useAppStore((s) => s.appendTrackPoint);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const rangePro = canUseProFeature("range");

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [hint, setHint] = useState<string | null>(null);
  const [confirmEnd, setConfirmEnd] = useState(false);
  const [mountCheck, setMountCheck] = useState<MountCheck>("unknown");
  const [layer, setLayer] = useState<RideLiveLayer>("map");
  const [navBanner, setNavBanner] = useState<string | null>(null);
  const [offRouteBanner, setOffRouteBanner] = useState<string | null>(null);
  const [ttsMuted, setTtsMuted] = useState(false);
  const [gpsMode, setGpsMode] = useState<"live" | "sim" | "idle">("idle");
  const [sunlight, setSunlight] = useState(false);
  const [autoLocked, setAutoLocked] = useState(false);
  const [sunlightAuto, setSunlightAuto] = useState(false);

  const sensorRef = useRef<WebSensorSimulator | null>(null);
  const boschRef = useRef<ReturnType<typeof createBoschLDIClient> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const geoWatchRef = useRef<number | null>(null);
  const standRef = useRef(0);
  const impactStreakRef = useRef(0);
  const lastImpactRef = useRef(false);
  const simTickRef = useRef(0);
  const gpsLiveRef = useRef(false);
  const lastSpokenCueRef = useRef<string | null>(null);
  const announceSpokenRef = useRef<Set<string>>(new Set());
  const idleSinceRef = useRef<number>(Date.now());
  const brightSinceRef = useRef<number | null>(null);
  const offRouteRef = useRef(false);
  const alongRouteRef = useRef(0);
  const ttsMutedRef = useRef(false);
  ttsMutedRef.current = ttsMuted;

  const track = currentRide?.track ?? [];
  const elapsed = currentRide?.durationSec ?? 0;
  const distanceM = currentRide?.distanceM ?? 0;

  const mapCenter = useMemo((): [number, number] => {
    if (track.length > 0) {
      const last = track[track.length - 1];
      return [last.lng, last.lat];
    }
    return centerOfGeometry(activeRoute?.geometry ?? null);
  }, [track, activeRoute?.geometry]);

  const remainingElev = useMemo(() => {
    if (!activeRoute) return null;
    const planned = activeRoute.elevationM;
    const done = currentRide?.elevationGainM ?? 0;
    return Math.max(0, planned - done);
  }, [activeRoute, currentRide?.elevationGainM]);

  const range =
    activeBike?.isEbike && rangePro
      ? estimateRange({
          bike: activeBike,
          profile,
          calibration: calibration ?? undefined,
          socPercent: boschLive?.soc ?? 87,
          speedKmh: boschLive?.speed ?? 18,
        })
      : null;

  const suspensionActive = mountCheck === "mounted";

  useEffect(() => {
    if (!isRiding) {
      sensorRef.current?.stop();
      boschRef.current?.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
      if (geoWatchRef.current != null && navigator.geolocation) {
        navigator.geolocation.clearWatch(geoWatchRef.current);
        geoWatchRef.current = null;
      }
      setHint(null);
      setConfirmEnd(false);
      setNavBanner(null);
      setOffRouteBanner(null);
      setGpsMode("idle");
      simTickRef.current = 0;
      gpsLiveRef.current = false;
      lastSpokenCueRef.current = null;
      announceSpokenRef.current = new Set();
      offRouteRef.current = false;
      alongRouteRef.current = 0;
      setAutoLocked(false);
      idleSinceRef.current = Date.now();
      return;
    }

    const sensor = new WebSensorSimulator();
    sensorRef.current = sensor;
    let impactTotal = 0;

    sensor.start((m: FusedMetrics) => {
      if (useAppStore.getState().isPaused) return;
      if (m.impactDetected) {
        impactTotal += 1;
        impactStreakRef.current += 1;
        lastImpactRef.current = true;
      } else {
        impactStreakRef.current = Math.max(0, impactStreakRef.current - 1);
        lastImpactRef.current = false;
      }
      updateLiveMetrics({
        gForcePeak: m.gForcePeak,
        gForceRms: m.gForceRms,
        leanAngleMax: m.leanAngleDeg,
        impactCount: impactTotal,
        flowScore: Math.round(55 + m.flowContribution * 40),
        estimatedTravelUsagePct: suspensionActive
          ? Math.round(40 + m.flowContribution * 45)
          : undefined,
      });
    }, 15);

    const bosch = createBoschLDIClient();
    boschRef.current = bosch;
    bosch.onData((data: BoschLiveData) => {
      if (useAppStore.getState().isPaused) return;
      updateBoschLive({
        speed: data.speedKmh,
        soc: data.batterySocPercent,
        riderPower: data.riderPowerW,
        cadence: data.cadenceRpm,
        odometer: data.odometerKm,
      });

      if (data.speedKmh < 2) standRef.current += 1;
      else standRef.current = 0;

      if (standRef.current > 30 && !useAppStore.getState().isPaused) {
        pauseRide();
      }

      const liveHints = hintsFromMetrics({
        speedKmh: data.speedKmh,
        standSeconds: standRef.current,
        impactJustDetected: lastImpactRef.current,
        hardImpactStreak: impactStreakRef.current,
      });
      if (liveHints[0]) {
        setHint(liveHints[0].text);
        if (liveHints[0].kind === "safety" || liveHints[0].kind === "bracketing") {
          speakHint(liveHints[0].text, { muted: ttsMutedRef.current });
        }
      }
    });
    bosch.connect();

    if (typeof navigator !== "undefined" && navigator.geolocation) {
      geoWatchRef.current = navigator.geolocation.watchPosition(
        (pos) => {
          gpsLiveRef.current = true;
          setGpsMode("live");
          if (useAppStore.getState().isPaused) return;
          const lat = pos.coords.latitude;
          const lng = pos.coords.longitude;
          appendTrackPoint({
            lat,
            lng,
            elev: pos.coords.altitude ?? undefined,
            time: pos.timestamp,
          });
          const route = useAppStore.getState().activeRoute;
          const coords = route?.geometry?.coordinates;
          if (coords && coords.length >= 2) {
            const prog = projectOntoRoute(coords, lat, lng);
            alongRouteRef.current = prog.distanceAlongM;
            const nextOff = updateOffRouteState(
              offRouteRef.current,
              prog.crossTrackM
            );
            if (nextOff !== offRouteRef.current) {
              offRouteRef.current = nextOff;
              setOffRouteBanner(nextOff ? "Route verlassen" : null);
              if (nextOff) {
                speakNav("Route verlassen", { muted: ttsMutedRef.current });
              }
            }
          }
        },
        () => {
          if (!gpsLiveRef.current) setGpsMode("sim");
        },
        { enableHighAccuracy: true, maximumAge: 2000, timeout: 8000 }
      );
      window.setTimeout(() => {
        if (!gpsLiveRef.current && useAppStore.getState().isRiding) {
          setGpsMode("sim");
        }
      }, 2500);
    } else {
      setGpsMode("sim");
    }

    timerRef.current = setInterval(() => {
      const state = useAppStore.getState();
      if (!state.isRiding || state.isPaused) return;

      if (state.currentRide?.startTime) {
        const startMs = new Date(state.currentRide.startTime).getTime();
        const durationSec = activeDurationSec({
          startMs,
          pauseAccumMs: state.pauseAccumMs,
          pauseStartedAt: null,
          isPaused: false,
        });
        useAppStore.setState({
          currentRide: { ...state.currentRide, durationSec },
        });
      }

      if (!gpsLiveRef.current) {
        setGpsMode("sim");
        simTickRef.current += 1;
        const geometry = state.activeRoute?.geometry;
        const plannedSec = Math.max(
          60,
          (state.activeRoute?.durationMin ?? 90) * 60
        );
        if (geometry && geometry.coordinates.length > 1) {
          const progress = Math.min(0.995, simTickRef.current / plannedSec);
          const pt = pointAlongLine(geometry, progress);
          appendTrackPoint({
            lat: pt.lat,
            lng: pt.lng,
            elev:
              (state.activeRoute?.elevationM ?? 0) *
              Math.sin(progress * Math.PI),
            time: Date.now(),
          });
        } else {
          const t = simTickRef.current;
          appendTrackPoint({
            lat:
              47.45 +
              Math.sin(t / 40) * 0.008 +
              (Math.random() - 0.5) * 0.0002,
            lng: 12.15 + t * 0.00015 + Math.cos(t / 30) * 0.004,
            time: Date.now(),
          });
        }
      }

      const route = state.activeRoute;
      if (route) {
        const cues = resolveNavCues({
          steps: route.steps,
          geometry: route.geometry,
        });
        let along = alongRouteRef.current;
        const last = state.currentRide?.track?.at(-1);
        const coords = route.geometry?.coordinates;
        if (last && coords && coords.length >= 2) {
          const prog = projectOntoRoute(coords, last.lat, last.lng);
          along = prog.distanceAlongM;
          alongRouteRef.current = along;
          const nextOff = updateOffRouteState(
            offRouteRef.current,
            prog.crossTrackM
          );
          if (nextOff !== offRouteRef.current) {
            offRouteRef.current = nextOff;
            setOffRouteBanner(nextOff ? "Route verlassen" : null);
            if (nextOff) {
              speakNav("Route verlassen", { muted: ttsMutedRef.current });
            }
          }
        }
        const nxt = nextCue(cues, along);
        const speed = state.boschLive?.speed ?? 18;
        if (nxt) {
          const text = cueBannerText(nxt.cue, nxt.remainingM);
          setNavBanner(text);
          const step = route.steps?.find((s) => s.id === nxt.cue.id);
          if (step) {
            const ann = pickAnnounce(
              step,
              nxt.remainingM,
              speed,
              announceSpokenRef.current
            );
            if (ann) speakNav(ann, { muted: ttsMutedRef.current });
          } else if (
            nxt.remainingM < 120 &&
            lastSpokenCueRef.current !== nxt.cue.id
          ) {
            lastSpokenCueRef.current = nxt.cue.id;
            speakNav(text, { muted: ttsMutedRef.current });
          }
        } else {
          setNavBanner(null);
        }
      }

      // Auto-Lock nach 20 s ohne Interaktion (Spec Flow B)
      if (
        Date.now() - idleSinceRef.current > 20_000 &&
        !useAppStore.getState().isPaused
      ) {
        setAutoLocked(true);
      }
    }, 1000);

    return () => {
      sensor.stop();
      bosch.disconnect();
      if (timerRef.current) clearInterval(timerRef.current);
      if (geoWatchRef.current != null && navigator.geolocation) {
        navigator.geolocation.clearWatch(geoWatchRef.current);
      }
    };
  }, [
    isRiding,
    updateBoschLive,
    updateLiveMetrics,
    appendTrackPoint,
    pauseRide,
    suspensionActive,
  ]);

  // Sunlight Mode: AmbientLightSensor > 8000 lx für > 4 s, sonst manuell
  useEffect(() => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const ALS = (window as any).AmbientLightSensor;
    if (!ALS) return;
    let sensor: { start: () => void; stop: () => void; illuminance?: number } | null =
      null;
    try {
      sensor = new ALS({ frequency: 1 });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (sensor as any).onreading = () => {
        const lux = (sensor as { illuminance?: number } | null)?.illuminance ?? 0;
        if (lux > 8000) {
          if (brightSinceRef.current == null) brightSinceRef.current = Date.now();
          else if (Date.now() - brightSinceRef.current > 4000) {
            setSunlightAuto(true);
            setSunlight(true);
          }
        } else {
          brightSinceRef.current = null;
          if (sunlightAuto) {
            setSunlightAuto(false);
            setSunlight(false);
          }
        }
      };
      sensor?.start();
    } catch {
      /* Browser ohne Sensor / Permission */
    }
    return () => {
      try {
        sensor?.stop();
      } catch {
        /* ignore */
      }
    };
  }, [sunlightAuto]);

  const bumpIdle = () => {
    idleSinceRef.current = Date.now();
    if (autoLocked) setAutoLocked(false);
  };

  const handleStart = () => {
    bumpIdle();
    if (activeBike) {
      startRide(activeBike.id, activeBike.type);
      return;
    }
    // Freeride ohne Garage-Bike — Track immer, Analyse nur mit Mount + Bike
    startRide(null, "all_mountain");
  };

  const handleEnd = () => {
    bumpIdle();
    if (!confirmEnd) {
      setConfirmEnd(true);
      return;
    }
    const ride = endRide();
    if (ride) router.push(`/post-ride?id=${ride.id}`);
  };

  const speedKmh = boschLive?.speed ?? 0;

  return (
    <div
      className="relative flex min-h-[calc(100dvh-4.5rem)] flex-col"
      data-ride-theme={sunlight ? "sunlight" : undefined}
      onPointerDown={bumpIdle}
      onDoubleClick={() => {
        bumpIdle();
        setAutoLocked(false);
      }}
    >
      {isRiding && autoLocked && (
        <button
          type="button"
          className="ride-autolock"
          onClick={bumpIdle}
          onDoubleClick={bumpIdle}
          aria-label="Entsperren"
        >
          <Lock className="mb-3 h-10 w-10 text-accent" />
          <p className="text-lg font-semibold">Auto-Lock</p>
          <p className="mt-1 text-sm text-text-secondary">
            Doppeltipp oder tippen zum Aufwecken
          </p>
          <Unlock className="mt-4 h-5 w-5 text-text-secondary" />
        </button>
      )}

      {/* Recording pulse */}
      {isRiding && (
        <div className="flex items-center gap-2 border-b border-border/60 px-4 py-2">
          <span
            className={`h-2.5 w-2.5 rounded-full bg-accent ${
              isPaused ? "opacity-40" : "animate-pulse"
            }`}
            aria-hidden
          />
          <span className="text-xs font-medium text-accent">
            {isPaused ? "Pausiert" : "Aufnahme läuft"}
          </span>
          <span className="ml-auto text-[10px] text-text-secondary">
            {gpsMode === "live"
              ? "GPS live"
              : gpsMode === "sim"
                ? "Track-Simulation"
                : "…"}
          </span>
        </div>
      )}

      {/* Web: Sensor + Bosch LDI sind immer Simulation — kein echtes BLE */}
      <div
        className="border-b border-amber-500/40 bg-amber-500/10 px-4 py-2 text-[11px] leading-snug text-amber-950 dark:text-amber-100"
        role="status"
      >
        <strong className="font-semibold">Simulation:</strong> Sensoren
        (WebSensorSimulator) und Bosch LDI laufen im Browser nur als Demo —
        keine echte Hardware-Verbindung. Echtes BLE gibt es in der Mobile-App.
      </div>

      <div className="flex flex-1 flex-col gap-3 p-4 pt-4">
        <header className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <h1 className="text-2xl font-bold">
              {isRiding ? "Live" : "Bereit"}
            </h1>
            {activeBike && (
              <p className="truncate text-sm text-text-secondary">
                {activeBike.name} · {bikeTypeLabel(activeBike.type)}
              </p>
            )}
          </div>
          <div className="flex shrink-0 items-center gap-1">
            <button
              type="button"
              onClick={() => {
                setSunlightAuto(false);
                setSunlight((v) => !v);
              }}
              className={`rounded-lg p-1.5 ${
                sunlight
                  ? "bg-accent/20 text-accent"
                  : "text-text-secondary hover:bg-surface-elevated"
              }`}
              aria-label="Sunlight Mode"
              title="Sunlight Mode"
            >
              <Sun className="h-4 w-4" />
            </button>
            {activeRoute && !isRiding && (
              <button
                type="button"
                onClick={() => clearActiveRoute()}
                className="rounded-lg p-1.5 text-text-secondary hover:bg-surface-elevated"
                aria-label="Route entfernen"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
        </header>

        {/* Route chip */}
        {activeRoute ? (
          <div className="flex items-start gap-2 rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
            <Navigation className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
            <div className="min-w-0 flex-1">
              <div className="font-medium">{activeRoute.name}</div>
              <div className="text-xs text-text-secondary">
                {formatRouteChip(activeRoute)}
              </div>
            </div>
          </div>
        ) : (
          !isRiding && (
            <Link
              href="/discover"
              className="rounded-xl border border-dashed border-border px-3 py-2 text-center text-sm text-text-secondary"
            >
              Optional: Route in Discover wählen →
            </Link>
          )
        )}

        {/* Nav banner */}
        {isRiding && offRouteBanner && (
          <div className="rounded-xl border border-amber-500/60 bg-amber-500/15 px-3 py-2.5 text-center text-sm font-semibold text-amber-900 dark:text-amber-100">
            {offRouteBanner}
          </div>
        )}
        {isRiding && navBanner && (
          <div className="rounded-xl border border-accent/50 bg-accent/15 px-3 py-2.5 text-center text-sm font-semibold">
            {navBanner}
          </div>
        )}
        {isRiding && (
          <button
            type="button"
            onClick={() => setTtsMuted((m) => !m)}
            className="self-end text-xs text-text-secondary underline"
          >
            {ttsMuted ? "Nav-Ansagen an" : "Nav-Ansagen stumm"}
          </button>
        )}

        {/* Live layer switcher */}
        {isRiding && (
          <div className="grid grid-cols-3 gap-1 rounded-xl bg-surface-elevated p-1">
            {LAYERS.map(({ id, label, icon: Icon }) => (
              <button
                key={id}
                type="button"
                onClick={() => setLayer(id)}
                className={`flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-medium ${
                  layer === id
                    ? "bg-accent text-white"
                    : "text-text-secondary"
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
                {label}
              </button>
            ))}
          </div>
        )}

        {/* Layer content */}
        {(!isRiding || layer === "map") && (
          <MapView
            className={`w-full overflow-hidden rounded-2xl ${
              isRiding ? "min-h-[42vh] flex-1" : "aspect-[4/3]"
            }`}
            center={mapCenter}
            zoom={13}
            track={track.map((p) => ({ lat: p.lat, lng: p.lng }))}
            route={activeRoute?.geometry ?? null}
          />
        )}

        {isRiding && layer === "data" && (
          <div className="grid grid-cols-2 gap-3">
            <MetricCard
              icon={<Gauge className="h-5 w-5" />}
              label="Geschwindigkeit"
              value={`${speedKmh}`}
              unit="km/h"
              accent
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Distanz"
              value={formatDistance(distanceM)}
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Zeit"
              value={formatDuration(elapsed)}
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Höhenmeter"
              value={`${currentRide?.elevationGainM ?? 0}`}
              unit="m"
            />
            {boschConnected && boschLive && (
              <>
                <MetricCard
                  icon={<Zap className="h-5 w-5" />}
                  label="Akku (Sim.)"
                  value={`${boschLive.soc}`}
                  unit="%"
                />
                <MetricCard
                  icon={<Zap className="h-5 w-5" />}
                  label="Leistung (Sim.)"
                  value={`${boschLive.riderPower}`}
                  unit="W"
                />
              </>
            )}
            {range && (
              <div className="col-span-2 rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-sm">
                Restreichweite ca.{" "}
                <span className="font-semibold text-accent">
                  {range.kmLow}–{range.kmHigh} km
                </span>
              </div>
            )}
          </div>
        )}

        {isRiding && layer === "suspension" && (
          <div className="rounded-2xl border border-border bg-surface p-4">
            {suspensionActive ? (
              <div className="grid grid-cols-2 gap-3">
                <MetricCard
                  icon={<Gauge className="h-5 w-5" />}
                  label="G-Force Peak"
                  value={`${liveMetrics?.gForcePeak ?? 0} g`}
                  accent
                />
                <MetricCard
                  icon={<Activity className="h-5 w-5" />}
                  label="Lean"
                  value={`${liveMetrics?.leanAngleMax ?? 0}°`}
                />
                <MetricCard
                  icon={<Activity className="h-5 w-5" />}
                  label="Impacts"
                  value={`${liveMetrics?.impactCount ?? 0}`}
                />
                <MetricCard
                  icon={<Activity className="h-5 w-5" />}
                  label="Flow"
                  value={`${liveMetrics?.flowScore ?? 0}`}
                  accent
                />
                <div className="col-span-2">
                  <div className="mb-1 text-xs text-text-secondary">
                    Federweg-Nutzung (geschätzt)
                  </div>
                  <div className="h-3 overflow-hidden rounded-full bg-surface-elevated">
                    <div
                      className="h-full rounded-full bg-accent transition-all"
                      style={{
                        width: `${liveMetrics?.estimatedTravelUsagePct ?? 50}%`,
                      }}
                    />
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center text-sm text-text-secondary">
                <p className="mb-2 font-medium text-foreground">
                  Fahrwerksanalyse aus
                </p>
                <p className="mb-3">
                  Handy am Lenker befestigen und als montiert markieren — sonst
                  keine Federungsdaten.
                </p>
                <button
                  type="button"
                  onClick={() => setMountCheck("mounted")}
                  className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
                >
                  Als montiert markieren
                </button>
              </div>
            )}
          </div>
        )}

        {hint && isRiding && !isPaused && (
          <div className="flex items-center gap-2 rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
            <Volume2 className="h-4 w-4 text-accent" />
            <span>{hint}</span>
          </div>
        )}

        {/* Ready checks */}
        {!isRiding && (
          <div className="rounded-2xl border border-border bg-surface p-4">
            <p className="mb-3 text-sm font-medium">Vor dem Start</p>
            <ul className="mb-4 space-y-2 text-sm">
              <li className="flex justify-between gap-3">
                <span className="text-text-secondary">Aktives Bike</span>
                {activeBike ? (
                  <span className="text-success">{activeBike.name}</span>
                ) : (
                  <Link href="/garage?wizard=basic" className="text-accent">
                    Optional — anlegen
                  </Link>
                )}
              </li>
              <li className="flex justify-between">
                <span className="text-text-secondary">Route</span>
                <span>
                  {activeRoute ? activeRoute.name : "Freeride (optional)"}
                </span>
              </li>
            </ul>
            {!activeBike && (
              <p className="mb-3 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-xs text-text-secondary">
                Du kannst sofort tracken. Setup- und Fahrwerksanalyse brauchen
                ein Bike in der Garage.
              </p>
            )}
            <p className="mb-2 text-sm text-text-secondary">
              Handy am Lenker?
            </p>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setMountCheck("mounted")}
                className={`rounded-xl border py-2.5 text-sm font-medium ${
                  mountCheck === "mounted"
                    ? "border-accent bg-accent/15 text-accent"
                    : "border-border"
                }`}
              >
                Ja — Analyse an
              </button>
              <button
                type="button"
                onClick={() => setMountCheck("handheld")}
                className={`rounded-xl border py-2.5 text-sm font-medium ${
                  mountCheck === "handheld"
                    ? "border-accent bg-accent/15 text-accent"
                    : "border-border"
                }`}
              >
                Nein — nur Track
              </button>
            </div>
            {mountCheck === "unknown" && (
              <p className="mt-2 text-xs text-text-secondary">
                Optional — ohne Antwort startet Freeride ohne Fahrwerksanalyse.
              </p>
            )}
          </div>
        )}

        {/* Bottom chrome — always in thumb zone */}
        <div className="mt-auto flex flex-col items-center gap-3 pb-2 pt-2">
          {isRiding && (
            <div className="grid w-full grid-cols-3 gap-2 text-center">
              <div>
                <div className="text-2xl font-bold tabular-nums">
                  {speedKmh}
                </div>
                <div className="text-[10px] text-text-secondary">km/h</div>
              </div>
              <div>
                <div className="text-2xl font-bold tabular-nums">
                  {formatDistance(distanceM)}
                </div>
                <div className="text-[10px] text-text-secondary">Distanz</div>
              </div>
              <div>
                <div className="text-2xl font-bold tabular-nums">
                  {remainingElev != null
                    ? remainingElev
                    : (currentRide?.elevationGainM ?? 0)}
                </div>
                <div className="text-[10px] text-text-secondary">
                  {remainingElev != null ? "hm übrig" : "hm"}
                </div>
              </div>
            </div>
          )}

          {isRiding && (
            <div className="text-4xl font-bold tracking-tight tabular-nums">
              {formatDuration(elapsed)}
            </div>
          )}

          <div className="flex items-center gap-6">
            {isRiding && (
              <button
                type="button"
                onClick={() => (isPaused ? resumeRide() : pauseRide())}
                className="flex h-14 w-14 items-center justify-center rounded-full border border-border bg-surface"
                aria-label={isPaused ? "Fortsetzen" : "Pause"}
              >
                {isPaused ? (
                  <Play className="ml-0.5 h-6 w-6 fill-current" />
                ) : (
                  <Pause className="h-6 w-6" />
                )}
              </button>
            )}

            {!isRiding ? (
              <button
                type="button"
                onClick={handleStart}
                className="flex h-20 w-20 items-center justify-center rounded-full bg-accent text-white shadow-xl shadow-accent/30 transition active:scale-95"
                aria-label="Ride starten"
              >
                <Play className="ml-1 h-10 w-10 fill-current" />
              </button>
            ) : (
              <button
                type="button"
                onClick={handleEnd}
                className={`flex h-20 w-20 items-center justify-center rounded-full text-white shadow-xl transition active:scale-95 ${
                  confirmEnd ? "bg-error" : "bg-error/70"
                }`}
                aria-label="Ride beenden"
              >
                <Square className="h-9 w-9 fill-current" />
              </button>
            )}
          </div>

          <p className="text-sm text-text-secondary">
            {isRiding
              ? confirmEnd
                ? "Nochmal tippen zum Beenden"
                : isPaused
                  ? "Pausiert — tippe Play zum Weiterfahren"
                  : "Beenden erfordert 2 Tipps"
              : activeRoute
                ? `${activeRoute.name} starten`
                : "Freifahren starten"}
          </p>
        </div>
      </div>
    </div>
  );
}

function MetricCard({
  icon,
  label,
  value,
  unit,
  accent,
}: {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  unit?: string;
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
        {unit ? (
          <span className="ml-1 text-sm font-medium text-text-secondary">
            {unit}
          </span>
        ) : null}
      </div>
    </div>
  );
}
