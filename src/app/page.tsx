"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import {
  bikeTypeLabel,
  formatDistance,
  formatDuration,
} from "@/lib/utils";
import {
  Bike,
  Zap,
  TrendingUp,
  AlertTriangle,
  ChevronRight,
  Play,
  CloudSun,
  ShoppingBag,
} from "lucide-react";
import Link from "next/link";
import { suggestRoutes, listAllRouteSuggestions } from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { greetingLine, avatarInitials } from "@/lib/home/greeting";
import {
  buildMaintenanceAlerts,
  bikeReadyStatus,
} from "@/lib/home/maintenanceAlerts";
import { setupConditionHint, type TrailHint } from "@/lib/home/setupHint";
import { useRouter } from "next/navigation";
import { ElevationStrip } from "@/components/ElevationStrip";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { BikeChip } from "@/components/BikeChip";
import { activeRouteFromSuggestion } from "@/lib/routing/activeRoute";
import { shopHref } from "@/lib/shop/catalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import type { Recommendation } from "@/types";
import type { ProductRecommendation } from "@/lib/shop/recommendations";

type WeatherPayload = {
  trailHint: TrailHint;
  current?: {
    temperature_2m?: number;
    precipitation?: number;
    weather_code?: number;
  };
  attribution?: string;
};

const FALLBACK_COORDS = { lat: 48.0, lon: 8.2 }; // Nordschwarzwald / Kaltenbronn-Nähe

function trailHintLabel(hint: TrailHint): string {
  if (hint === "wet_likely") return "eher nass";
  if (hint === "damp_possible") return "feucht möglich";
  return "eher trocken";
}

export default function HomePage() {
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const recommendations = useAppStore((s) => s.recommendations);
  const boschConnected = useAppStore((s) => s.boschConnected);
  const boschLive = useAppStore((s) => s.boschLive);
  const profile = useAppStore((s) => s.riderProfile);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const consents = useAppStore((s) => s.consents);
  const setCurrentSetup = useAppStore((s) => s.setCurrentSetup);
  const activeRoute = useAppStore((s) => s.activeRoute);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const clearActiveRoute = useAppStore((s) => s.clearActiveRoute);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const rangePro = canUseProFeature("range");
  const router = useRouter();

  const [weather, setWeather] = useState<WeatherPayload | null>(null);
  const [displayName, setDisplayName] = useState<string | null>(null);
  const [authChecked, setAuthChecked] = useState(false);
  const [homeNear, setHomeNear] = useState<[number, number] | null>(null);

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const lastRide = rides[0];
  const currentSetup = activeBike?.setups.find((s) => s.isCurrent);

  const alerts = useMemo(
    () =>
      activeBike
        ? buildMaintenanceAlerts({
            bike: activeBike,
            rides,
            intervals,
            max: 2,
          })
        : [],
    [activeBike, rides, intervals]
  );

  const ready = bikeReadyStatus(alerts);

  const productConsent =
    consents.find((c) => c.purpose === "product_recommendations")?.granted ??
    false;

  /** Spec 4.7.1: maximal eine Empfehlung — Setup vor Shop */
  const primaryTip = useMemo(():
    | { kind: "rec"; rec: Recommendation }
    | { kind: "shop"; shop: ProductRecommendation }
    | null => {
    const setupOrTech = recommendations.find(
      (r) =>
        r.status === "shown" &&
        (r.type === "setup" || r.type === "technique")
    );
    if (setupOrTech) return { kind: "rec", rec: setupOrTech };

    const productRec = recommendations.find(
      (r) => r.status === "shown" && r.type === "product"
    );
    if (productRec) return { kind: "rec", rec: productRec };

    if (!activeBike || !productConsent) return null;
    const setup = activeBike.setups.find((s) => s.isCurrent);
    const shop =
      allProductRecommendations({
        bike: activeBike,
        rides,
        setup,
      })[0] ?? null;
    return shop ? { kind: "shop", shop } : null;
  }, [recommendations, activeBike, rides, productConsent]);

  const loadWeather = useCallback(async (lat: number, lon: number) => {
    try {
      const res = await fetch(`/api/weather?lat=${lat}&lon=${lon}`);
      if (!res.ok) return;
      const data = (await res.json()) as WeatherPayload;
      if (data.trailHint) setWeather(data);
    } catch {
      /* offline / API down — Hero bleibt ohne Wetter */
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    if (typeof navigator !== "undefined" && navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          if (!cancelled) {
            const near: [number, number] = [
              pos.coords.longitude,
              pos.coords.latitude,
            ];
            setHomeNear(near);
            void loadWeather(pos.coords.latitude, pos.coords.longitude);
          }
        },
        () => {
          if (!cancelled) {
            setHomeNear([FALLBACK_COORDS.lon, FALLBACK_COORDS.lat]);
            void loadWeather(FALLBACK_COORDS.lat, FALLBACK_COORDS.lon);
          }
        },
        { timeout: 8000, maximumAge: 30 * 60 * 1000 }
      );
    } else {
      setHomeNear([FALLBACK_COORDS.lon, FALLBACK_COORDS.lat]);
      void loadWeather(FALLBACK_COORDS.lat, FALLBACK_COORDS.lon);
    }
    return () => {
      cancelled = true;
    };
  }, [loadWeather]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const res = await fetch("/api/auth/me");
        const data = await res.json();
        if (!cancelled && data.user?.displayName) {
          setDisplayName(data.user.displayName);
        } else if (!cancelled && data.user?.email) {
          setDisplayName(data.user.email.split("@")[0]);
        }
      } catch {
        /* anon */
      } finally {
        if (!cancelled) setAuthChecked(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const todayRoute = useMemo(() => {
    if (!activeBike) return null;
    const minutes = profile.fitnessIndicators.avgRideDurationMin || 150;
    const rangeEst =
      activeBike.isEbike && rangePro
        ? estimateRange({
            bike: activeBike,
            profile,
            calibration: calibration ?? undefined,
            socPercent: boschLive?.soc ?? undefined,
          })
        : undefined;
    const near =
      homeNear ??
      ([FALLBACK_COORDS.lon, FALLBACK_COORDS.lat] as [number, number]);
    const local = listAllRouteSuggestions({
      bike: activeBike,
      profile,
      availableMinutes: minutes,
      rangeKmHigh: rangeEst?.kmHigh,
      near,
    }).filter((r) => (r.distanceFromOriginKm ?? 9999) <= 80);
    if (local[0]) return local[0];
    return (
      suggestRoutes({
        bike: activeBike,
        profile,
        availableMinutes: minutes,
        rangeKmHigh: rangeEst?.kmHigh,
        near,
      })[0] ?? null
    );
  }, [activeBike, profile, rangePro, calibration, boschLive, homeNear]);

  const heroRange = useMemo(() => {
    if (!activeBike?.isEbike || !rangePro) return null;
    return estimateRange({
      bike: activeBike,
      profile,
      calibration: calibration ?? undefined,
      socPercent: boschLive?.soc ?? undefined,
    });
  }, [activeBike, profile, rangePro, calibration, boschLive]);

  const rangeTight =
    !!todayRoute &&
    !!heroRange &&
    todayRoute.distanceKm > heroRange.kmHigh * 0.85;

  const setupHint = useMemo(
    () =>
      setupConditionHint(
        currentSetup,
        activeBike?.setups ?? [],
        weather?.trailHint ?? null
      ),
    [currentSetup, activeBike, weather]
  );

  const heroReason = useMemo(() => {
    if (!todayRoute) return null;
    const parts = [...todayRoute.reasons];
    if (weather?.trailHint) {
      parts[0] = `${trailHintLabel(weather.trailHint)}${
        weather.current?.temperature_2m != null
          ? `, ${Math.round(weather.current.temperature_2m)} °C`
          : ""
      } · ${parts[0]}`;
    }
    return parts.slice(0, 2).join(" — ");
  }, [todayRoute, weather]);

  const initials = avatarInitials(displayName);

  const startWithTodayRoute = useCallback(() => {
    if (!todayRoute) return;
    setActiveRoute(activeRouteFromSuggestion(todayRoute));
    router.push("/ride");
  }, [todayRoute, setActiveRoute, router]);

  const startFreeride = useCallback(() => {
    clearActiveRoute();
    router.push("/ride");
  }, [clearActiveRoute, router]);

  const ridesOnSetup = useMemo(() => {
    if (!currentSetup || !activeBike) return 0;
    return rides.filter(
      (r) => r.bikeId === activeBike.id && r.setupId === currentSetup.id
    ).length;
  }, [rides, currentSetup, activeBike]);

  const setupAgeDays = useMemo(() => {
    if (!currentSetup) return null;
    const ms = Date.now() - new Date(currentSetup.createdAt).getTime();
    return Math.max(0, Math.floor(ms / (1000 * 60 * 60 * 24)));
  }, [currentSetup]);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center justify-between gap-3">
        <BikeChip className="min-w-0 flex-1" />
        <Link
          href="/profile"
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface-elevated text-sm font-semibold text-accent"
          aria-label="Profil"
        >
          {initials}
        </Link>
      </header>

      <div>
        <h1 className="text-2xl font-bold tracking-tight">
          {greetingLine(displayName)}
        </h1>
        <p className="text-sm text-text-secondary">AetherRide</p>
      </div>

      {authChecked && !displayName && (
        <Link
          href="/profile"
          className="rounded-xl border border-border bg-surface px-3 py-2 text-sm text-text-secondary"
        >
          Sync nur mit Login — im Profil anmelden
        </Link>
      )}

      {/* HEUTE PASST */}
      {activeBike && todayRoute ? (
        <section className="rounded-2xl border border-accent/40 bg-surface p-4">
          <div className="mb-1 flex items-center justify-between gap-2">
            <span className="text-xs font-semibold uppercase tracking-wide text-accent">
              Heute passt
            </span>
            {weather && (
              <span className="inline-flex items-center gap-1 text-xs text-text-secondary">
                <CloudSun className="h-3.5 w-3.5" />
                {trailHintLabel(weather.trailHint)}
                {weather.current?.temperature_2m != null
                  ? ` · ${Math.round(weather.current.temperature_2m)}°`
                  : ""}
              </span>
            )}
          </div>
          <h2 className="text-xl font-bold">{todayRoute.name}</h2>
          <p className="mt-1 tabular-nums text-sm text-text-secondary">
            {todayRoute.distanceFromOriginKm != null
              ? `~${todayRoute.distanceFromOriginKm} km entfernt · `
              : ""}
            {todayRoute.distanceKm} km · {todayRoute.elevationM} hm ·{" "}
            {Math.floor(todayRoute.durationMin / 60)}:
            {(todayRoute.durationMin % 60).toString().padStart(2, "0")} h
            {todayRoute.mtbScale !== "—" ? ` · ${todayRoute.mtbScale}` : ""}
          </p>
          <div className="mt-2 text-accent">
            <ElevationStrip
              elevationM={todayRoute.elevationM}
              distanceKm={todayRoute.distanceKm}
              estimated
            />
          </div>
          {heroReason && (
            <p className="mt-2 text-sm text-text-secondary leading-snug">
              Weil: {heroReason}
            </p>
          )}
          {activeBike.isEbike && (
            <div
              className={`mt-2 rounded-xl px-3 py-2 text-xs ${
                rangeTight
                  ? "bg-warning/10 text-warning"
                  : "bg-primary/15 text-text-secondary"
              }`}
            >
              {heroRange ? (
                <>
                  <span className="font-medium text-foreground">
                    Reichweite {heroRange.kmLow}–{heroRange.kmHigh} km
                  </span>
                  {boschLive?.soc != null && (
                    <span> · Akku {boschLive.soc}%</span>
                  )}
                  {rangeTight
                    ? ` — Tour ${todayRoute.distanceKm} km ist eng`
                    : ` · Tour ${todayRoute.distanceKm} km passt`}
                </>
              ) : (
                <span>
                  Reichweitenprognose mit Pro — Tour {todayRoute.distanceKm} km
                </span>
              )}
            </div>
          )}
          <EvidenceSheet title="Begründung ansehen" className="mt-2">
            <ul className="list-disc space-y-1 pl-4">
              {todayRoute.reasons.map((r) => (
                <li key={r}>{r}</li>
              ))}
              {weather?.attribution && <li>{weather.attribution}</li>}
              {todayRoute.rangeNote && <li>{todayRoute.rangeNote}</li>}
            </ul>
          </EvidenceSheet>
          <div className="mt-3 flex gap-2">
            <Link
              href={`/discover?route=${todayRoute.id}`}
              className="flex flex-1 items-center justify-center gap-1 rounded-xl border border-border py-2.5 text-sm font-medium"
            >
              Route ansehen <ChevronRight className="h-4 w-4" />
            </Link>
            <button
              type="button"
              onClick={startWithTodayRoute}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
            >
              <Play className="h-4 w-4 fill-current" /> Losfahren
            </button>
          </div>
        </section>
      ) : activeBike ? (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <p className="text-sm text-text-secondary mb-3">
            Noch kein passender Routenvorschlag — in Discover entdecken.
          </p>
          <Link
            href="/discover"
            className="inline-flex items-center gap-1 text-sm font-medium text-accent"
          >
            Route wählen <ChevronRight className="h-4 w-4" />
          </Link>
        </section>
      ) : null}

      {/* Dein Bike */}
      {activeBike ? (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <p className="mt-1 text-xs text-text-secondary">
            DEIN BIKE
          </p>
          <div className="mt-1 flex items-start justify-between">
            <div className="flex items-center gap-3">
              {activeBike.photoUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={activeBike.photoUrl}
                  alt=""
                  className="h-12 w-12 rounded-xl object-cover"
                />
              ) : (
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/30 text-accent">
                  <Bike className="h-6 w-6" />
                </div>
              )}
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="text-lg font-semibold">{activeBike.name}</h2>
                  <span
                    className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                      ready === "ready"
                        ? "bg-success/15 text-success"
                        : "bg-warning/15 text-warning"
                    }`}
                  >
                    {ready === "ready" ? "Bereit" : "Wartung"}
                  </span>
                </div>
                <p className="text-sm text-text-secondary">
                  {bikeTypeLabel(activeBike.type)}
                  {activeBike.year ? ` · ${activeBike.year}` : ""}
                </p>
                {alerts[0] && (
                  <p className="mt-0.5 text-xs text-warning">{alerts[0].title}</p>
                )}
              </div>
            </div>
            <div className="flex flex-col items-end gap-1">
              <Link
                href="/garage"
                className="flex items-center gap-1 text-sm text-accent"
              >
                Garage <ChevronRight className="h-4 w-4" />
              </Link>
            </div>
          </div>

          {currentSetup && (
            <div className="mt-3 space-y-2">
              <div className="flex items-center justify-between gap-2">
                <span className="text-sm">
                  <span className="text-text-secondary">Setup </span>
                  <span className="font-medium">„{currentSetup.label}“</span>
                </span>
                <span className="text-xs text-text-secondary">
                  {setupAgeDays != null ? `seit ${setupAgeDays} Tagen` : ""}
                  {ridesOnSetup > 0 ? ` · ${ridesOnSetup} Rides` : ""}
                </span>
              </div>
              <SetupFingerprint setup={currentSetup} />
            </div>
          )}

          {setupHint && (
            <div className="mt-3 rounded-xl border border-warning/30 bg-warning/10 px-3 py-2 text-sm">
              <p>{setupHint.message}</p>
              {setupHint.suggestedSetupId && activeBike && (
                <button
                  type="button"
                  className="mt-2 text-xs font-semibold text-accent"
                  onClick={() =>
                    setCurrentSetup(activeBike.id, setupHint.suggestedSetupId!)
                  }
                >
                  Auf „{setupHint.suggestedLabel}“ wechseln
                </button>
              )}
              <EvidenceSheet title="Warum?" className="mt-1">
                {setupHint.reasoning}
              </EvidenceSheet>
            </div>
          )}

          {boschConnected && boschLive && (
            <div className="mt-3 rounded-xl bg-primary/20 px-3 py-2">
              <div className="mb-1.5 text-[10px] font-medium uppercase tracking-wide text-warning">
                Simulation — kein echtes Bosch LDI
              </div>
              <div className="flex items-center gap-4">
                <Zap className="h-5 w-5 text-accent" />
                <div className="grid flex-1 grid-cols-3 gap-2 text-center text-sm">
                  <div>
                    <div className="text-lg font-semibold tabular-nums">
                      {boschLive.soc}%
                    </div>
                    <div className="text-xs text-text-secondary">Akku (Sim.)</div>
                  </div>
                  <div>
                    <div className="text-lg font-semibold tabular-nums">
                      {boschLive.odometer}
                    </div>
                    <div className="text-xs text-text-secondary">km gesamt</div>
                  </div>
                  <div>
                    <div className="text-xs font-medium text-warning">
                      Web-Simulator
                    </div>
                    <div className="text-xs text-text-secondary">kein BLE</div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </section>
      ) : (
        <section className="rounded-2xl border border-border bg-surface p-6 text-center">
          <h2 className="text-lg font-semibold">Lege dein erstes Bike an</h2>
          <p className="mt-2 text-sm text-text-secondary">
            Katalog, Basis oder Import — danach startet der Companion und
            passende Teile.
          </p>
          <div className="mt-4 grid gap-2 text-left sm:grid-cols-3">
            {(
              [
                ["catalog", "Katalog", "OEM-Teile vorgefüllt"],
                ["basic", "Basis", "Schnell anlegen"],
                ["import", "Import", "km später übernehmen"],
              ] as const
            ).map(([mode, title, desc]) => (
              <Link
                key={mode}
                href={`/garage?wizard=${mode}`}
                className="rounded-xl border border-border bg-surface-elevated p-3"
              >
                <div className="text-sm font-medium">{title}</div>
                <div className="mt-1 text-xs text-text-secondary">{desc}</div>
              </Link>
            ))}
          </div>
          <p className="mt-4 text-xs text-text-secondary">
            Danach zeigt Home, was als Nächstes passt.
          </p>
        </section>
      )}

      <div className="flex flex-col gap-2">
        <button
          type="button"
          onClick={() => {
            if (activeRoute) {
              router.push("/ride");
              return;
            }
            if (todayRoute) {
              startWithTodayRoute();
              return;
            }
            startFreeride();
          }}
          className="flex items-center justify-center gap-3 rounded-2xl bg-accent py-4 text-lg font-semibold text-white shadow-lg shadow-accent/25 transition hover:bg-accent-hover active:scale-[0.98]"
        >
          <Play className="h-6 w-6 fill-current" />
          {activeRoute
            ? `${activeRoute.name} starten`
            : todayRoute
              ? `${todayRoute.name} starten`
              : "Freifahren starten"}
        </button>
        {(activeRoute || todayRoute) && (
          <button
            type="button"
            onClick={startFreeride}
            className="rounded-xl border border-border py-2.5 text-sm font-medium text-text-secondary"
          >
            Ohne Route freifahren
          </button>
        )}
      </div>

      {/* max. 2 Wartung */}
      {alerts.length > 0 && (
        <section className="flex flex-col gap-2">
          {alerts.map((a) => (
            <div
              key={a.id}
              className="rounded-xl border border-border bg-surface px-3 py-3"
            >
              <div className="flex items-start gap-2">
                <AlertTriangle
                  className={`mt-0.5 h-4 w-4 shrink-0 ${
                    a.severity === "overdue" ? "text-error" : "text-warning"
                  }`}
                />
                <div className="min-w-0 flex-1">
                  <Link href={a.href} className="block">
                    <div className="text-sm font-medium">{a.title}</div>
                    <div className="text-xs text-text-secondary">{a.detail}</div>
                  </Link>
                  <EvidenceSheet title="Warum?" className="mt-1">
                    <p>{a.reasoning}</p>
                    <p className="mt-1">Quelle: {a.sourceLabel}</p>
                  </EvidenceSheet>
                </div>
              </div>
            </div>
          ))}
        </section>
      )}

      {/* Spec 4.7.1: maximal eine Empfehlung */}
      {primaryTip?.kind === "rec" && (
        <section className="rounded-xl border border-border bg-surface p-3">
          <div className="text-xs font-semibold uppercase tracking-wide text-accent">
            Tipp für dich
          </div>
          <div className="mt-1 text-sm font-medium">{primaryTip.rec.title}</div>
          <p className="mt-1 text-sm text-text-secondary">
            {primaryTip.rec.content}
          </p>
          <EvidenceSheet title="Warum?" className="mt-2">
            {primaryTip.rec.reasoning}
          </EvidenceSheet>
          {primaryTip.rec.type === "product" && (
            <Link
              href={shopHref({
                productId: primaryTip.rec.relatedProductId,
                job: "replace",
              })}
              className="mt-2 inline-flex items-center gap-1 text-xs font-medium text-accent"
            >
              Im Shop prüfen <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          )}
        </section>
      )}
      {primaryTip?.kind === "shop" && (
        <Link
          href={shopHref({
            productId: primaryTip.shop.product.id,
            job: "replace",
          })}
          className="flex gap-3 rounded-xl border border-border bg-surface p-3 transition hover:border-accent/40"
        >
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-accent/15 text-accent">
            <ShoppingBag className="h-4 w-4" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-xs font-semibold uppercase tracking-wide text-accent">
              Tipp für dich
            </div>
            <div className="mt-0.5 text-sm font-medium leading-snug">
              {primaryTip.shop.product.name}
            </div>
            <p className="mt-1 text-xs text-text-secondary">
              {primaryTip.shop.triggeringDataPoint} · ab{" "}
              {primaryTip.shop.product.priceEur} €
            </p>
          </div>
        </Link>
      )}

      {lastRide && (
        <Link
          href={`/post-ride?id=${lastRide.id}`}
          className="rounded-2xl border border-border bg-surface p-4 transition hover:border-accent/40"
        >
          <div className="mb-3 flex items-center justify-between">
            <h3 className="flex items-center gap-2 font-semibold">
              <TrendingUp className="h-4 w-4 text-accent" />
              Letzter Ride
            </h3>
            <span className="text-xs text-text-secondary">
              {new Date(lastRide.startTime).toLocaleDateString("de-DE")}
            </span>
          </div>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div>
              <div className="text-xl font-bold tabular-nums">
                {formatDistance(lastRide.distanceM)}
              </div>
              <div className="text-xs text-text-secondary">Distanz</div>
            </div>
            <div>
              <div className="text-xl font-bold tabular-nums">
                {lastRide.elevationGainM} m
              </div>
              <div className="text-xs text-text-secondary">Höhenmeter</div>
            </div>
            <div>
              <div className="text-xl font-bold tabular-nums text-accent">
                {lastRide.summaryMetrics.flowScore}
              </div>
              <div className="text-xs text-text-secondary">Flow</div>
            </div>
          </div>
          <p className="mt-2 text-center text-xs text-accent">
            Analyse öffnen · {formatDuration(lastRide.durationSec)}
          </p>
        </Link>
      )}
    </div>
  );
}
