"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { hofSkyLine, isSkyWet } from "@/lib/home/hofSky";
import {
  hofGateDurationMin,
  hofGateHasLoop,
  hofGateId,
  hofGateTitle,
  pickHofGate,
} from "@/lib/home/hofGate";
import { hofSportLabel } from "@/lib/home/hofSportLabel";
import { residentMeta, rideReturnForBike } from "@/lib/home/rideReturn";
import { berlinSixtyMinLoopSuggestions } from "@/lib/discover/berlinLoops";
import { hasCommunity } from "@/lib/community/tourCommunity";
import { getMaintenanceSummary, lastRideForBike } from "@/lib/maintenance/summary";
import { useHofLocation } from "@/hooks/useHofLocation";
import { useHofTitle } from "@/hooks/useHofTitle";
import { useAppStore } from "@/store/useAppStore";
import { Watch } from "lucide-react";
import { HofWatchCard } from "./HofWatchCard";
import { cn } from "@/lib/utils";

type WeatherPayload = {
  current?: { temperature_2m?: number };
  trailHint?: string;
};

export function HofStand() {
  const title = useHofTitle();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const rides = useAppStore((s) => s.rides);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const { geo, resolved: geoResolved } = useHofLocation();

  const active =
    bikes.find((b) => b.id === activeBikeId) || bikes[0] || null;
  const others = bikes.filter((b) => active && b.id !== active.id);

  const ret = active
    ? rideReturnForBike({ bikeId: active.id, rides })
    : { kind: "neverOut" as const };
  const justBack = ret.kind === "justBack";

  const [weather, setWeather] = useState<WeatherPayload | null>(null);
  const [weatherResolved, setWeatherResolved] = useState(false);
  const [neighborCount, setNeighborCount] = useState<number | null>(null);

  useEffect(() => {
    if (!geoResolved) return;
    if (!geo) {
      setWeatherResolved(true);
      setWeather(null);
      return;
    }
    let cancelled = false;
    const q = new URLSearchParams({
      lat: String(geo.lat),
      lon: String(geo.lng),
    });
    void fetch(`/api/weather?${q}`)
      .then(async (r) => {
        const j = (await r.json()) as WeatherPayload & { error?: string };
        if (cancelled) return;
        if (!r.ok) {
          setWeather(null);
          return;
        }
        setWeather(j);
      })
      .catch(() => {
        if (!cancelled) setWeather(null);
      })
      .finally(() => {
        if (!cancelled) setWeatherResolved(true);
      });
    return () => {
      cancelled = true;
    };
  }, [geo, geoResolved]);

  const loops = useMemo(
    () =>
      geo
        ? berlinSixtyMinLoopSuggestions([geo.lng, geo.lat])
        : berlinSixtyMinLoopSuggestions(),
    [geo]
  );

  const gate = useMemo(
    () =>
      pickHofGate({
        loops,
        saved: savedRoutes,
        lat: geo?.lat,
        lng: geo?.lng,
        trailsWet: weather?.trailHint === "wet_likely",
      }),
    [loops, savedRoutes, geo, weather?.trailHint]
  );

  const gateId = hofGateId(gate);

  useEffect(() => {
    if (!gateId || justBack) {
      setNeighborCount(null);
      return;
    }
    let cancelled = false;
    void fetch(`/api/community/tour?tourId=${encodeURIComponent(gateId)}`)
      .then(async (r) => {
        if (!r.ok) return null;
        return r.json();
      })
      .then((j) => {
        if (cancelled || !j) return;
        const counts = {
          reviewCount: Number(j.reviewCount) || 0,
          photoCount: Number(j.photoCount) || 0,
          averageRating: null,
        };
        if (!hasCommunity(counts)) {
          setNeighborCount(null);
          return;
        }
        setNeighborCount(counts.reviewCount + counts.photoCount);
      })
      .catch(() => {
        if (!cancelled) setNeighborCount(null);
      });
    return () => {
      cancelled = true;
    };
  }, [gateId, justBack]);

  const sky =
    weatherResolved || geoResolved
      ? geo && weather?.current?.temperature_2m != null
        ? hofSkyLine(weather.trailHint, weather.current.temperature_2m)
        : weatherResolved
          ? HOF_COPY.skyUnknown
          : ""
      : "";

  const care = useMemo(() => {
    if (!active) return null;
    const last = lastRideForBike(rides, active.id);
    const summary = getMaintenanceSummary(active, intervals, {
      lastRideAt: last?.startTime,
      lastRideDistanceKm: last ? last.distanceM / 1000 : null,
    });
    if (summary.status !== "overdue" && summary.status !== "due_soon") {
      return null;
    }
    const label = summary.topItem?.shortLabel ?? "Pflege";
    return {
      href: summary.href,
      text: HOF_COPY.careInWorkshop(label),
      overdue: summary.status === "overdue",
    };
  }, [active, intervals, rides]);

  const primaryHref = active
    ? "/discover?mode=rideOut"
    : "/garage?wizard=basic";
  const primaryLabel = active
    ? justBack
      ? HOF_COPY.rideOutAgain
      : HOF_COPY.rideOut
    : HOF_COPY.parkBike;
  const primaryIsRideOut = Boolean(active);
  const secondaryHref = active
    ? `/garage?bike=${encodeURIComponent(active.id)}`
    : "/discover?mode=rideOut";
  const secondaryLabel = active ? HOF_COPY.openBike : HOF_COPY.rideWithoutBike;

  return (
    <div className="relative">
      <div
        className={cn(
          "px-5 py-4 lg:px-10 lg:py-8",
          sky
            ? isSkyWet(weather?.trailHint)
              ? "bg-primary/25"
              : "bg-primary/15"
            : "bg-primary/10"
        )}
      >
        <div className="mx-auto w-full max-w-2xl lg:max-w-3xl">
          <div className="flex items-start justify-between gap-3">
            <h1
              data-testid="hof-title"
              className="text-2xl font-extrabold tracking-tight text-chrome lg:text-4xl"
            >
              {title}
            </h1>
            <Link
              href="/download"
              title={HOF_COPY.watchBar}
              aria-label={HOF_COPY.watchBar}
              data-testid="hof-watch-bar"
              className="mt-1 shrink-0 rounded-full p-2 pr-3 text-text-secondary hover:bg-surface-elevated hover:text-chrome mr-[max(0.75rem,env(safe-area-inset-right,0px))]"
            >
              <Watch className="h-[22px] w-[22px]" strokeWidth={1.75} />
            </Link>
          </div>
          {sky ? (
            <p
              data-testid="hof-sky"
              className="mt-2 text-[13px] font-semibold text-text-secondary lg:text-base"
            >
              {sky}
            </p>
          ) : null}
        </div>
      </div>

      <div className="mx-auto w-full max-w-2xl px-5 pb-12 pt-5 lg:max-w-3xl lg:px-10 lg:pb-16 lg:pt-8">

      {active ? (
        <section className="mb-4">
          <Link
            href={`/garage?bike=${encodeURIComponent(active.id)}`}
            className="block overflow-hidden rounded-2xl border border-border bg-surface"
          >
            {active.photoUrl ? (
              // User-captured data URLs / arbitrary hosts — not next/image remote.
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={active.photoUrl}
                alt=""
                className="h-48 w-full object-cover lg:h-80"
              />
            ) : (
              <div className="flex h-48 items-center justify-center bg-surface-elevated lg:h-80">
                <ResidentMark name={active.name} />
              </div>
            )}
          </Link>
          <h2 className="mt-3 truncate text-xl font-extrabold">{active.name}</h2>
          <p
            data-testid="hof-resident-meta"
            className="text-[13px] text-text-secondary"
          >
            {residentMeta({
              sport: hofSportLabel(active.category),
              ret,
            })}
          </p>
          {others.length > 0 ? (
            <div className="mt-3 flex flex-wrap gap-2">
              {others.map((b) => (
                <button
                  key={b.id}
                  type="button"
                  onClick={() => setActiveBike(b.id)}
                  className="rounded-full border border-border px-3 py-1.5 text-xs font-semibold text-text-secondary hover:border-chrome hover:text-chrome"
                >
                  {HOF_COPY.bringForward(b.name)}
                </button>
              ))}
            </div>
          ) : null}
        </section>
      ) : (
        <section className="mb-4">
          <div className="flex h-40 items-center justify-center rounded-2xl border border-border lg:h-72">
            <EmptyStandMark />
          </div>
          <h2
            data-testid="hof-empty-stand"
            className="mt-3 text-xl font-extrabold"
          >
            {HOF_COPY.emptyStand}
          </h2>
          <p className="text-[13px] text-text-secondary">{HOF_COPY.noBikeHere}</p>
        </section>
      )}

      {care ? (
        <Link
          href={care.href}
          className={cn(
            "mb-4 block text-[13px] font-semibold",
            care.overdue ? "text-error" : "text-warning"
          )}
        >
          {care.text}
        </Link>
      ) : null}

      {!justBack ? (
        <GateCard
          pickTitle={
            hofGateHasLoop(gate) ? hofGateTitle(gate) : HOF_COPY.noHonestLoop
          }
          durationMin={hofGateHasLoop(gate) ? hofGateDurationMin(gate) : 0}
          hasLoop={hofGateHasLoop(gate)}
          honesty={gate.honesty}
          href={
            gateId
              ? `/discover?route=${encodeURIComponent(gateId)}`
              : "/discover"
          }
          neighbors={neighborCount}
        />
      ) : null}

      <Link
        href={primaryHref}
        data-testid="hof-ride-out"
        className={cn(
          "mt-8 flex h-[52px] items-center justify-center rounded-xl text-base font-extrabold lg:mt-10 lg:h-14",
          primaryIsRideOut
            ? "bg-accent text-white hover:bg-accent-hover"
            : "bg-chrome text-background hover:bg-chrome/90"
        )}
      >
        {primaryLabel}
      </Link>
      <div className="mt-2 text-center">
        <Link
          href={secondaryHref}
          className="text-sm font-medium text-text-secondary hover:text-chrome"
        >
          {secondaryLabel}
        </Link>
      </div>

      <div className="mt-6 lg:mt-8">
        <HofWatchCard />
      </div>
      </div>
    </div>
  );
}

function GateCard({
  pickTitle,
  durationMin,
  hasLoop,
  honesty,
  href,
  neighbors,
}: {
  pickTitle: string;
  durationMin: number;
  hasLoop: boolean;
  honesty: "loop" | "wetClosed" | "none";
  href: string;
  neighbors: number | null;
}) {
  if (honesty === "none" && !hasLoop) {
    return (
      <Link
        href="/discover"
        className="mt-4 block py-2 text-[13px] font-semibold text-text-secondary hover:text-chrome"
      >
        {HOF_COPY.openTours}
      </Link>
    );
  }

  const line = hasLoop
    ? `${pickTitle} · ${HOF_COPY.loopDuration(durationMin)}`
    : HOF_COPY.noHonestLoop;

  return (
    <Link
      href={href}
      data-testid="hof-gate"
      className="mt-4 block rounded-2xl border border-border p-3"
    >
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {HOF_COPY.atGate}
      </p>
      <p className="mt-1 text-[15px] font-bold">{line}</p>
      {neighbors != null && neighbors > 0 ? (
        <p className="mt-0.5 text-xs text-text-secondary">
          {HOF_COPY.communityNotes(neighbors)}
        </p>
      ) : null}
    </Link>
  );
}

function ResidentMark({ name }: { name: string }) {
  return (
    <svg width="200" height="72" viewBox="0 0 200 72" aria-hidden>
      <circle
        cx="40"
        cy="52"
        r="16"
        fill="none"
        stroke="currentColor"
        className="text-chrome"
        strokeWidth="2.4"
      />
      <circle cx="40" cy="52" r="3" className="fill-chrome" />
      <circle
        cx="132"
        cy="52"
        r="16"
        fill="none"
        stroke="currentColor"
        className="text-chrome"
        strokeWidth="2.4"
      />
      <circle cx="132" cy="52" r="3" className="fill-chrome" />
      <path
        d="M40 52 L68 22 H108 L132 52 M68 22 L58 52 M108 22 L96 8 H118"
        fill="none"
        stroke="currentColor"
        className="text-foreground"
        strokeWidth="2.4"
        strokeLinejoin="round"
      />
      <text
        x="100"
        y="14"
        textAnchor="middle"
        className="fill-text-secondary"
        fontSize="9"
        fontFamily="ui-sans-serif, system-ui"
      >
        {name}
      </text>
    </svg>
  );
}

function EmptyStandMark() {
  return (
    <svg width="120" height="48" viewBox="0 0 120 48" aria-hidden>
      <line
        x1="20"
        y1="40"
        x2="100"
        y2="40"
        stroke="currentColor"
        className="text-text-secondary"
        strokeWidth="2"
      />
      <line
        x1="60"
        y1="40"
        x2="60"
        y2="12"
        stroke="currentColor"
        className="text-text-secondary"
        strokeWidth="2"
      />
      <line
        x1="48"
        y1="12"
        x2="72"
        y2="12"
        stroke="currentColor"
        className="text-text-secondary"
        strokeWidth="2"
      />
    </svg>
  );
}
