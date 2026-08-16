"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useHofCopy } from "@/hooks/useHofCopy";
import { hofSkyLine, isSkyWet } from "@/lib/home/hofSky";
import {
  formatHofGateAway,
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
import { HofWatchCard } from "./HofWatchCard";
import { HofTafel } from "./HofTafel";
import { HofCornerTools } from "@/components/app/HofCornerTools";
import { buildHofTafel } from "@/lib/tours/tourAkte";
import { useCommunityStore } from "@/store/useCommunityStore";
import {
  listedRideGroups,
  useRideGroupStore,
} from "@/store/useRideGroupStore";
import { cn } from "@/lib/utils";

type WeatherPayload = {
  current?: { temperature_2m?: number };
  trailHint?: string;
};

export function HofStand() {
  const copy = useHofCopy();

  const title = useHofTitle();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const rides = useAppStore((s) => s.rides);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const groups = useRideGroupStore((s) => s.groups);
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
        preferred: active?.category ?? null,
      }),
    [loops, savedRoutes, geo, weather?.trailHint, active?.category]
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
        ? hofSkyLine(weather.trailHint, weather.current.temperature_2m, copy)
        : weatherResolved
          ? copy.skyUnknown
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
    const label = summary.topItem?.shortLabel ?? copy.careFallback;
    return {
      href: summary.href,
      text: copy.careInWorkshop(label),
      overdue: summary.status === "overdue",
    };
  }, [active, intervals, rides, copy]);

  const group = listedRideGroups(groups)[0];
  const tafel = useMemo(
    () =>
      buildHofTafel({
        care,
        savedRoutes,
        myReviews,
        group: group
          ? {
              text: `${copy.groupAtGate} · ${group.title}`,
              href: "/library",
            }
          : null,
      }),
    [care, savedRoutes, myReviews, group]
  );

  const primaryHref = active
    ? "/discover?mode=rideOut"
    : "/garage?wizard=basic";
  const primaryLabel = active
    ? justBack
      ? copy.rideOutAgain
      : copy.rideOut
    : copy.parkBike;
  const secondaryHref = active
    ? `/garage?bike=${encodeURIComponent(active.id)}`
    : "/discover?mode=rideOut";
  const secondaryLabel = active ? copy.openBike : copy.rideWithoutBike;

  return (
    <div className="relative bg-sage/10">
      <div
        className={cn(
          "px-5 py-4 lg:px-10 lg:py-8",
          sky
            ? isSkyWet(weather?.trailHint)
              ? "bg-sage/40"
              : "bg-sage/30"
            : "bg-sage/20"
        )}
      >
        <div className="mx-auto w-full max-w-2xl lg:max-w-3xl">
          <div className="flex items-start justify-between gap-3">
            <h1
              data-testid="hof-title"
              className="min-w-0 text-2xl font-extrabold tracking-tight text-chrome lg:text-4xl"
            >
              {title}
            </h1>
            <HofCornerTools className="md:hidden" />
          </div>
          {sky ? (
            <p
              data-testid="hof-sky"
              className="mt-2 text-[13px] font-semibold text-sage lg:text-base"
            >
              {sky}
            </p>
          ) : null}

          {active ? (
            <section className="mt-5">
              {active.photoUrl ? (
                <Link
                  href={`/garage?bike=${encodeURIComponent(active.id)}`}
                  className="mb-3 block overflow-hidden rounded-2xl border border-border bg-surface"
                >
                  {/* User-captured data URLs / arbitrary hosts — not next/image remote. */}
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={active.photoUrl}
                    alt=""
                    className="h-28 w-full object-cover lg:h-44"
                  />
                </Link>
              ) : (
                <div data-testid="hof-parked-mark" className="mb-2">
                  <ParkedMark />
                </div>
              )}
              <h2 className="truncate text-xl font-extrabold">
                <Link
                  href={`/garage?bike=${encodeURIComponent(active.id)}`}
                  className="hover:text-chrome"
                >
                  {active.name}
                </Link>
              </h2>
              {ret.rideId ? (
                <Link
                  href={`/post-ride?id=${encodeURIComponent(ret.rideId)}`}
                  data-testid="hof-resident-meta"
                  className="mt-0.5 flex items-start gap-2 text-[13px] font-semibold text-chrome hover:underline"
                >
                  <span className="min-w-0 flex-1">
                    {residentMeta({
                      sport: hofSportLabel(
                        active.category,
                        active.isEbike ||
                          active.components.some(
                            (c) => c.slot === "motor" && !c.removedAt
                          )
                      ),
                      ret,
                      copy,
                    })}
                  </span>
                  <span className="shrink-0 text-xs font-semibold text-text-secondary no-underline">
                    {copy.whatCameIn}
                  </span>
                </Link>
              ) : (
                <p
                  data-testid="hof-resident-meta"
                  className="mt-0.5 text-[13px] text-text-secondary"
                >
                  {residentMeta({
                    sport: hofSportLabel(
                      active.category,
                      active.isEbike ||
                        active.components.some(
                          (c) => c.slot === "motor" && !c.removedAt
                        )
                    ),
                    ret,
                    copy,
                  })}
                </p>
              )}
              {others.length > 0 ? (
                <div className="mt-3 flex flex-wrap gap-2">
                  {others.map((b) => (
                    <button
                      key={b.id}
                      type="button"
                      onClick={() => setActiveBike(b.id)}
                      className="rounded-full border border-border px-3 py-1.5 text-xs font-semibold text-text-secondary hover:border-chrome hover:text-chrome"
                    >
                      {copy.bringForward(b.name)}
                    </button>
                  ))}
                </div>
              ) : null}
            </section>
          ) : (
            <section className="mt-5">
              <div className="flex h-28 items-center justify-center rounded-2xl border border-border lg:h-44">
                <EmptyStandMark />
              </div>
              <h2
                data-testid="hof-empty-stand"
                className="mt-3 text-xl font-extrabold"
              >
                {copy.emptyStand}
              </h2>
              <p className="text-[13px] text-text-secondary">
                {copy.noBikeHere}
              </p>
            </section>
          )}
        </div>
      </div>

      <div className="mx-auto w-full max-w-2xl px-5 pb-12 pt-4 lg:max-w-3xl lg:px-10 lg:pb-16 lg:pt-6">
      <HofTafel items={tafel} />

      {!justBack ? (
        <GateCard
          pickTitle={
            hofGateHasLoop(gate) ? hofGateTitle(gate) : copy.noHonestLoop
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
          awayKm={gate.distanceKm}
        />
      ) : null}

      <HofWatchCard />

      <Link
        href={primaryHref}
        data-testid="hof-ride-out"
        className={cn(
          "mt-4 flex h-[52px] items-center justify-center rounded-xl text-base font-extrabold lg:mt-6 lg:h-14",
          active
            ? "bg-chrome text-on-accent hover:bg-chrome/90"
            : "bg-foreground text-background hover:bg-foreground/90",
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
  awayKm,
}: {
  pickTitle: string;
  durationMin: number;
  hasLoop: boolean;
  honesty: "loop" | "wetClosed" | "none";
  href: string;
  neighbors: number | null;
  awayKm?: number;
}) {
  const copy = useHofCopy();
  if (honesty === "none" && !hasLoop) {
    return (
      <Link
        href="/discover"
        className="mt-4 block py-2 text-[13px] font-semibold text-text-secondary hover:text-chrome"
      >
        {copy.openTours}
      </Link>
    );
  }

  const line = hasLoop
    ? `${pickTitle} · ${copy.loopDuration(durationMin)}`
    : copy.noHonestLoop;
  const away = formatHofGateAway(awayKm, {
    near: copy.gateAwayNear,
    km: copy.gateAwayKm,
  });

  return (
    <Link
      href={href}
      data-testid="hof-gate"
      className="mt-4 block rounded-2xl border border-border p-3"
    >
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {copy.atGate}
      </p>
      <p className="mt-1 text-[15px] font-bold">{line}</p>
      {away ? (
        <p data-testid="hof-gate-away" className="mt-0.5 text-xs text-text-secondary">
          {away}
        </p>
      ) : null}
      {neighbors != null && neighbors > 0 ? (
        <p className="mt-0.5 text-xs text-text-secondary">
          {copy.communityNotes(neighbors)}
        </p>
      ) : null}
    </Link>
  );
}

function ParkedMark() {
  return (
    <svg width="128" height="56" viewBox="0 0 88 40" aria-hidden>
      <g
        className="text-sage"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <circle cx="19" cy="25" r="9" />
        <circle cx="69" cy="25" r="9" />
        <path d="M19 25 L37 25 L32 8 L60 9 L69 25 L37 25 L60 9" />
        <path d="M53 5 H70" />
      </g>
      <g
        className="text-text-secondary"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
      >
        <line x1="8" y1="38" x2="80" y2="38" />
        <line x1="44" y1="38" x2="44" y2="16" />
      </g>
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
