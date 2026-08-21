"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { hofSkyLine, isSkyWet } from "@/lib/home/hofSky";
import {
  formatHofGateAway,
  hofGateDurationMin,
  hofGateEmptyTitle,
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
import { slotLabel } from "@/lib/catalog/slots";
import { bikeHealthLine, planDieBox } from "@/lib/garage/dieBox";
import { useHofLocation } from "@/hooks/useHofLocation";
import { useHofTitle } from "@/hooks/useHofTitle";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { WeatherGlyph } from "@/components/shared/WeatherGlyph";
import { HofTafel } from "./HofTafel";
import { HofCornerTools } from "@/components/app/HofCornerTools";
import { buildHofTafel, catalogTourIdOf } from "@/lib/tours/tourAkte";
import {
  confirmationsFromReviews,
  listingPatch,
  listingSnapshotOf,
  pickListingTafel,
  tickTourListing,
} from "@/lib/tours/tourListing";
import { useCommunityStore } from "@/store/useCommunityStore";
import {
  listedRideGroups,
  useRideGroupStore,
} from "@/store/useRideGroupStore";
import { cn } from "@/lib/utils";
import { HOF_TOKENS } from "@/lib/hof/tokens";
import { buildRideTelemetry } from "@/lib/ride/rideTelemetry";
import { RideTerrainPeek } from "@/components/ride/ActivitySparkline";
import { terrainCaption } from "@/lib/ride/terrainCaption";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import { RadEmptyStage } from "@/components/garage/RadEmptyStage";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import { radSilhouetteSrc } from "@/lib/garage/radMark";

type WeatherPayload = {
  current?: { temperature_2m?: number };
  trailHint?: string;
};

export function HofStand() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const telCopy = rideTelemetryCopy(lang);

  const title = useHofTitle();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const rides = useAppStore((s) => s.rides);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const updateSavedRoute = useAppStore((s) => s.updateSavedRoute);
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
  const lastRide = ret.rideId
    ? rides.find((r) => r.id === ret.rideId)
    : undefined;
  const lastTel = lastRide ? buildRideTelemetry(lastRide.track) : null;
  const healthLine = active
    ? bikeHealthLine({
        readiness: planDieBox({ bike: active }).readiness,
        odometerKm: active.totalOdometerKm,
        readyLabel: copy.workshopZoneReady,
        almostLabel: copy.workshopBoxAlmost,
        unknownLabel: copy.workshopBoxUnknown,
      })
    : null;

  const [weather, setWeather] = useState<WeatherPayload | null>(null);
  const [weatherResolved, setWeatherResolved] = useState(false);
  const [neighborCount, setNeighborCount] = useState<number | null>(null);
  const [listingTafel, setListingTafel] = useState<{
    text: string;
    href: string;
  } | null>(null);

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
    if (active?.category) {
      q.set("profile", profileForBikeCategory(active.category));
    }
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
  }, [geo, geoResolved, active?.category]);

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

  useEffect(() => {
    const now = new Date();
    const own: Array<{
      id: string;
      name: string;
      notice: "none" | "candidate" | "listed" | "reverted";
      confirmCount: number;
      candidateSince?: string | null;
    }> = [];
    for (const r of savedRoutes) {
      if (
        r.visibility !== "shared" &&
        r.listing !== "candidate" &&
        r.listing !== "listed" &&
        r.listing !== "reverted"
      ) {
        continue;
      }
      const catalog = catalogTourIdOf(r);
      const related = myReviews.filter(
        (rev) => rev.tourId === r.id || rev.tourId === catalog
      );
      const decision = tickTourListing({
        ...listingSnapshotOf(r),
        isCatalog: Boolean(catalog),
        confirmations: confirmationsFromReviews(related),
        now,
      });
      if (decision.changed) {
        updateSavedRoute(r.id, listingPatch(decision));
        if (decision.notice === "reverted") {
          void import("@/lib/community/tourShareRevoke").then((m) => {
            m.revokeTourShareLocally(r.id, decision.shareEpoch);
            void m.revokeTourShareOnServer(r.id, decision.shareEpoch);
          });
        }
      }
      own.push({
        id: r.id,
        name: r.name,
        notice: decision.notice,
        confirmCount: decision.confirmCount,
        candidateSince: decision.candidateSince,
      });
    }
    const text = pickListingTafel({ own });
    if (!text) {
      setListingTafel(null);
      return;
    }
    const hit =
      own.find((o) => o.notice === "reverted") ??
      own.find((o) => o.notice === "candidate") ??
      own.find((o) => o.notice === "listed");
    setListingTafel({
      text,
      href: hit
        ? `/library?akte=${encodeURIComponent(hit.id)}`
        : "/discover?sheet=tours",
    });
  }, [savedRoutes, myReviews, updateSavedRoute]);

  const noGps = geoResolved && !geo;
  const gpsHonesty = noGps ? copy.gpsUnknown : "";
  const sky = noGps
    ? ""
    : weatherResolved || geoResolved
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
    const label = summary.topItem
      ? slotLabel(summary.topItem.slot, lang)
      : copy.careFallback;
    return {
      href: summary.href,
      text: copy.careInWorkshop(label),
      overdue: summary.status === "overdue",
    };
  }, [active, intervals, rides, copy, lang]);

  const group = listedRideGroups(groups)[0];
  const tafel = useMemo(
    () =>
      buildHofTafel({
        care,
        listing: listingTafel,
        savedRoutes,
        myReviews,
        group: group
          ? {
              text: `${copy.groupAtGate} · ${group.title}`,
              href: "/library",
            }
          : null,
      }),
    [care, listingTafel, savedRoutes, myReviews, group]
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
              className="mt-2 flex items-center gap-2 text-[15px] font-bold lg:text-lg"
              style={{ color: HOF_TOKENS.sageOnDark }}
            >
              <WeatherGlyph
                hint={weather?.trailHint}
                offline={!weather && weatherResolved}
                size={18}
              />
              <span>{sky}</span>
            </p>
          ) : null}
          {gpsHonesty ? (
            <p
              data-testid="hof-gps-honesty"
              className="mt-2 text-xs font-semibold text-text-secondary"
            >
              {gpsHonesty}
            </p>
          ) : null}

          {active ? (
            <section className="mt-5">
              {active.photoUrl ? (
                <Link
                  href={`/garage?bike=${encodeURIComponent(active.id)}`}
                  className="mb-3 block overflow-hidden rounded-2xl border border-border bg-surface"
                >
                  <RadStandFrame
                    src={active.photoUrl}
                    alt=""
                    photo
                    heightClass="h-28 lg:h-44"
                  />
                </Link>
              ) : (
                <Link
                  href={`/garage?bike=${encodeURIComponent(active.id)}`}
                  data-testid="hof-parked-mark"
                  className="mb-3 block overflow-hidden rounded-2xl border border-border"
                >
                  <RadStandFrame
                    src={radSilhouetteSrc(active)}
                    alt=""
                    heightClass="h-28 lg:h-36"
                  />
                </Link>
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
              {healthLine ? (
                <Link
                  href={`/garage?bike=${encodeURIComponent(active.id)}`}
                  data-testid="hof-bike-health"
                  className="mt-1 block text-[13px] font-bold text-chrome"
                >
                  {healthLine}
                </Link>
              ) : null}
              {lastTel?.channels.elev && lastRide ? (
                <Link
                  href={
                    ret.rideId
                      ? `/post-ride?id=${encodeURIComponent(ret.rideId)}`
                      : "/activities"
                  }
                  className="mt-3 block"
                  data-testid="hof-ride-spark"
                >
                  <RideTerrainPeek
                    telemetry={lastTel}
                    caption={terrainCaption(lastTel, telCopy.hm)}
                  />
                </Link>
              ) : null}
              {others.length > 0 ? (
                <div className="mt-3 flex flex-wrap gap-2">
                  {others.map((b) => (
                    <button
                      key={b.id}
                      type="button"
                      onClick={() => setActiveBike(b.id)}
                      className="w-[7.5rem] overflow-hidden rounded-xl border border-border text-left hover:border-chrome"
                    >
                      <RadStandFrame
                        src={b.photoUrl || radSilhouetteSrc(b)}
                        alt=""
                        photo={Boolean(b.photoUrl)}
                        heightClass="h-12"
                      />
                      <span className="block truncate px-2 py-1.5 text-[11px] font-semibold">
                        {copy.bringForward(b.name)}
                      </span>
                    </button>
                  ))}
                </div>
              ) : null}
            </section>
          ) : (
            <section className="mt-5">
              <div className="overflow-hidden rounded-2xl border border-dashed border-border">
                <RadEmptyStage heightClass="h-28 lg:h-40" />
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

          {!justBack ? (
            <GateCard
              pickTitle={
                hofGateHasLoop(gate)
                  ? hofGateTitle(gate)
                  : hofGateEmptyTitle(gate.honesty, copy)
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
        </div>
      </div>

      <div className="mx-auto w-full max-w-2xl px-5 pb-12 pt-4 lg:max-w-3xl lg:px-10 lg:pb-16 lg:pt-6">
      <HofTafel items={tafel} />

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
      <HofWatchCard />
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
    : pickTitle;
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

