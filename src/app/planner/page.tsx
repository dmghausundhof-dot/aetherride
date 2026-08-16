"use client";

/**
 * Desktop-first Route Planner — Vollseite (Phase B).
 * Navigation bleibt in der App (/ride = App-CTA).
 */
import { Suspense, useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Bookmark,
  Crosshair,
  Navigation,
  Play,
  Smartphone,
} from "lucide-react";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { useAppStore } from "@/store/useAppStore";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";
import {
  ROUTING_PROFILES,
  DEFAULT_DISCOVER_PROFILE,
  DISCOVER_PROFILE_CHIPS,
  profileForBikeCategory,
  discoverNavProfile,
  sessionCostingForBike,
  type ClientRouteResult,
  type RoutingProfile,
} from "@/lib/routing/profiles";
import {
  addVia,
  computePointToPoint,
  emptyDraft,
  endOf,
  orderedWaypoints,
  removeWaypoint,
  routeResultMessage,
  setEnd,
  setStart,
  startOf,
  type PlanDraft,
} from "@/lib/routing/planDraft";
import { activeRouteFromEngine } from "@/lib/routing/activeRoute";
import { getPublicTour } from "@/lib/catalog/publicTours";
import type { SavedRoute } from "@/types/route";
import { RoutingStatusBanner } from "@/components/routing/RoutingStatusBanner";
import { NearMeRouteCard } from "@/components/explore/NearMeRouteCard";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHofCopy } from "@/hooks/useHofCopy";
import {
  DISCOVER_PIN_DE,
  discoverPinLabel,
  discoverUi,
} from "@/lib/i18n/discoverUi";
import {
  PLANNER_STATUS_DE,
  plannerCopy,
  plannerStatus,
} from "@/lib/i18n/plannerCopy";

const FALLBACK: [number, number] = [8.4, 48.5];

function PlannerInner() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const ui = discoverUi(lang);
  const p = plannerCopy(lang);
  const router = useRouter();
  const searchParams = useSearchParams();
  const tourId = searchParams.get("tour");

  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);

  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const bikeProfile = discoverNavProfile(
    activeBike
      ? profileForBikeCategory(activeBike.category)
      : DEFAULT_DISCOVER_PROFILE
  );

  const [profile, setProfile] = useState<RoutingProfile>(bikeProfile);
  const [draft, setDraft] = useState<PlanDraft>(() =>
    emptyDraft(bikeProfile, FALLBACK)
  );
  const [pickTarget, setPickTarget] = useState<"start" | "end" | "via" | null>(
    null
  );
  const [mapCenter, setMapCenter] = useState<[number, number]>(FALLBACK);
  const [userPos, setUserPos] = useState<[number, number] | null>(null);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [addrQuery, setAddrQuery] = useState("");
  const [addrTarget, setAddrTarget] = useState<"start" | "end">("start");
  const [addrHits, setAddrHits] = useState<
    { label: string; lat: number; lng: number }[]
  >([]);
  const [addrBusy, setAddrBusy] = useState(false);
  const planDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (p) => {
        const pos: [number, number] = [p.coords.longitude, p.coords.latitude];
        setUserPos(pos);
        setMapCenter(pos);
      },
      () => {},
      { enableHighAccuracy: false, timeout: 8000 }
    );
  }, []);

  // ?tour= seed into planner as labeled start near pin
  useEffect(() => {
    if (!tourId) return;
    const tour = getPublicTour(tourId);
    if (!tour) return;
    setMapCenter(tour.center);
    setDraft((d) => ({
      ...setStart(d, tour.center, tour.name),
      profile,
      label: tour.name,
      baseTour: {
        id: tour.id,
        name: tour.name,
        provider: "seed",
        geometry: null,
        distanceKm: tour.distanceKm,
        elevationM: tour.elevationM,
        durationMin: tour.durationMin,
        mtbScale: tour.difficulty,
        surface: tour.surface,
        loop: tour.loop,
        center: tour.center,
      },
    }));
    setMsg(plannerCopy("de").tourIdeaLoaded(tour.name));
    // eslint-disable-next-line react-hooks/exhaustive-deps -- once per tourId
  }, [tourId]);

  const scheduleRecompute = useCallback(
    (next: PlanDraft) => {
      setDraft(next);
      if (planDebounceRef.current) clearTimeout(planDebounceRef.current);
      planDebounceRef.current = setTimeout(() => {
        void (async () => {
          if (!startOf(next) || !endOf(next)) return;
          setBusy(true);
          try {
            const result = await computePointToPoint({
              ...next,
              profile: sessionCostingForBike(activeBike?.category, profile),
            });
            if (result) {
              setDraft((d) => ({
                ...d,
                mode: "point_to_point",
                computed: result,
                label: d.label || DISCOVER_PIN_DE.planned,
                layers: undefined,
              }));
              setMsg(routeResultMessage(result));
            }
          } finally {
            setBusy(false);
          }
        })();
      }, 600);
    },
    [profile, activeBike?.category]
  );

  const onMapClick = (lngLat: [number, number]) => {
    if (!pickTarget) return;
    setDraft((prev) => {
      let next = prev;
      if (pickTarget === "start") {
        next = setStart(prev, lngLat, DISCOVER_PIN_DE.startMap);
        setMapCenter(lngLat);
      } else if (pickTarget === "end") {
        next = setEnd(prev, lngLat, DISCOVER_PIN_DE.endMap);
      } else {
        next = addVia(prev, lngLat);
      }
      scheduleRecompute({ ...next, profile });
      return next;
    });
    setPickTarget(null);
  };

  const searchAddress = async () => {
    if (!addrQuery.trim()) return;
    setAddrBusy(true);
    try {
      const q = new URLSearchParams({ q: addrQuery.trim() });
      const r = await fetch(`/api/geocode?${q}`);
      const j = await r.json();
      const hits = (j.hits ?? []) as {
        label: string;
        lat: number;
        lng: number;
      }[];
      setAddrHits(
        hits.slice(0, 6).map((h) => ({
          label: h.label || PLANNER_STATUS_DE.hitFallback,
          lat: Number(h.lat),
          lng: Number(h.lng),
        }))
      );
    } catch {
      setMsg(PLANNER_STATUS_DE.geocodeFail);
    } finally {
      setAddrBusy(false);
    }
  };

  const applyHit = (hit: { label: string; lat: number; lng: number }) => {
    const lngLat: [number, number] = [hit.lng, hit.lat];
    setDraft((prev) => {
      const next =
        addrTarget === "end"
          ? setEnd(prev, lngLat, hit.label)
          : setStart(prev, lngLat, hit.label);
      scheduleRecompute({ ...next, profile });
      return next;
    });
    setMapCenter(lngLat);
    setAddrHits([]);
    setAddrQuery(hit.label);
  };

  const runRoute = async () => {
    if (!startOf(draft) || !endOf(draft)) {
      setMsg(PLANNER_STATUS_DE.needStartEnd);
      return;
    }
    setBusy(true);
    try {
      const result = await computePointToPoint({ ...draft, profile });
      if (result) {
        setDraft((d) => ({
          ...d,
          computed: result,
          label: d.label || DISCOVER_PIN_DE.planned,
        }));
        setMsg(routeResultMessage(result));
      } else {
        setMsg(PLANNER_STATUS_DE.noRoute);
      }
    } finally {
      setBusy(false);
    }
  };

  const saveCurrent = () => {
    if (!draft.computed) return;
    const distanceKm =
      Math.round((draft.computed.distanceM / 1000) * 10) / 10;
    // Real/sanitized ascent only — never invent hm from geometry/distance.
    const elevationM =
      sanitizeElevationM(draft.baseTour?.elevationM, distanceKm) ?? 0;
    const entry: SavedRoute = {
      id: `saved-${Date.now()}`,
      name: draft.label || DISCOVER_PIN_DE.planned,
      distanceKm,
      elevationM,
      durationMin: Math.round(draft.computed.durationS / 60),
      surface: draft.baseTour?.surface,
      mtbScale: draft.baseTour?.mtbScale,
      savedAt: new Date().toISOString(),
      source: "engine",
      geometry: draft.computed.geometry,
      waypoints: draft.waypoints.map((w) => ({
        role: w.role,
        lngLat: w.lngLat,
        label: w.label,
      })),
    };
    saveRoute(entry);
    setMsg(PLANNER_STATUS_DE.inMappe);
  };

  const startInApp = (result: ClientRouteResult, name: string) => {
    setActiveRoute(activeRouteFromEngine(name, result));
    router.push("/ride");
  };

  const markers: MapMarker[] = useMemo(() => {
    const m: MapMarker[] = [];
    let via = 0;
    for (const w of orderedWaypoints(draft)) {
      if (w.role === "start")
        m.push({ id: w.id, lngLat: w.lngLat, color: "#43A047", label: ui.startAbbr });
      else if (w.role === "end")
        m.push({ id: w.id, lngLat: w.lngLat, color: "#E53935", label: ui.endAbbr });
      else {
        via += 1;
        m.push({
          id: w.id,
          lngLat: w.lngLat,
          color: "#FFB300",
          label: String(via),
        });
      }
    }
    return m;
  }, [draft, ui.endAbbr, ui.startAbbr]);

  const mapLayers: MapRouteLayer[] = useMemo(() => {
    if (!draft.computed?.geometry) return [];
    return [
      {
        id: "plan",
        role: "tour",
        geometry: draft.computed.geometry,
        color: "#FF6A00",
        width: 5,
        opacity: 0.9,
      },
    ];
  }, [draft.computed]);

  const stats = draft.computed
    ? `${(draft.computed.distanceM / 1000).toFixed(1)} km · ${Math.round(draft.computed.durationS / 60)} min`
    : null;

  return (
    <div className="flex h-[calc(100dvh-var(--hof-header-h)-var(--hof-tab-h))] flex-col lg:h-[calc(100dvh-var(--hof-header-h))] lg:flex-row">
      <aside className="order-2 flex max-h-[48vh] min-h-0 w-full flex-col border-t border-border bg-background lg:order-1 lg:max-h-none lg:w-[min(24rem,36vw)] lg:border-r lg:border-t-0">
        <header className="shrink-0 space-y-2 border-b border-border px-4 py-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {copy.plannerKicker}
              </p>
              <h1 className="text-lg font-bold">{copy.plannerTitle}</h1>
            </div>
            <Link
              href="/discover"
              className="text-xs font-medium text-chrome hover:underline"
            >
              {copy.mapTitle}
            </Link>
          </div>
          <p className="text-xs text-text-secondary">
            {copy.plannerHint}
          </p>
          <RoutingStatusBanner />
          <p className="text-[11px] text-text-secondary">
            {p.exploreLead}
            <Link href="/discover?panel=plan" className="text-chrome hover:underline">
              {copy.mapTitle} · {copy.plannerTitle}
            </Link>
            {" · "}
            Docs: <code className="text-[10px]">docs/explore-architecture.md</code>
          </p>
          <NearMeRouteCard
            center={userPos ?? mapCenter}
            profile={profile}
          />
          <label className="block text-[11px] text-text-secondary">
            {p.routingProfile}
            <select
              value={profile}
              onChange={(e) => {
                const p = e.target.value as RoutingProfile;
                setProfile(p);
                setDraft((d) => ({ ...d, profile: p }));
              }}
              className="mt-1 w-full rounded-lg border border-border bg-surface px-2 py-2 text-sm text-foreground"
            >
              {DISCOVER_PROFILE_CHIPS.map((id) => {
                const p = ROUTING_PROFILES[id];
                return (
                <option key={p.id} value={p.id}>
                  {p.label}
                </option>
                );
              })}
            </select>
          </label>
        </header>

        <div className="min-h-0 flex-1 space-y-3 overflow-y-auto px-4 py-3">
          <div className="flex gap-2">
            <select
              value={addrTarget}
              onChange={(e) =>
                setAddrTarget(e.target.value as "start" | "end")
              }
              className="rounded-lg border border-border bg-surface-elevated px-2 text-xs"
            >
              <option value="start">{ui.start}</option>
              <option value="end">{ui.end}</option>
            </select>
            <input
              value={addrQuery}
              onChange={(e) => setAddrQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") void searchAddress();
              }}
              placeholder={p.addrSearch}
              className="min-w-0 flex-1 rounded-lg border border-border bg-surface-elevated px-2 py-1.5 text-xs"
            />
            <button
              type="button"
              disabled={addrBusy}
              onClick={() => void searchAddress()}
              className="rounded-lg border border-border px-2 text-xs font-medium"
            >
              {p.ok}
            </button>
          </div>
          {addrHits.length > 0 && (
            <ul className="max-h-28 overflow-auto rounded-lg border border-border">
              {addrHits.map((h) => (
                <li key={`${h.label}-${h.lat}`}>
                  <button
                    type="button"
                    className="w-full px-2 py-1.5 text-left text-[11px] hover:bg-surface-elevated"
                    onClick={() => applyHit(h)}
                  >
                    {h.label === PLANNER_STATUS_DE.hitFallback
                      ? p.hitFallback
                      : h.label}
                  </button>
                </li>
              ))}
            </ul>
          )}

          <div className="grid grid-cols-3 gap-2">
            {(
              [
                ["start", ui.start],
                ["via", ui.tapVia],
                ["end", ui.end],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setPickTarget(id)}
                className={`rounded-xl border px-2 py-2 text-[11px] font-medium ${
                  pickTarget === id
                    ? "border-chrome bg-chrome/10 text-chrome"
                    : "border-border"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              if (!userPos) return;
              scheduleRecompute(
                setStart({ ...draft, profile }, userPos, DISCOVER_PIN_DE.myPos)
              );
              setMapCenter(userPos);
            }}
            className="flex items-center gap-1.5 text-[11px] font-medium text-chrome"
          >
            <Crosshair className="h-3.5 w-3.5" /> {ui.startMyPos}
          </button>

          <ul className="space-y-1">
            {orderedWaypoints(draft).map((w, i) => (
              <li
                key={w.id}
                className="flex items-center justify-between rounded-lg border border-border px-2 py-1.5 text-xs"
              >
                <span className="truncate">
                  {w.role === "start"
                    ? ui.startAbbr
                    : w.role === "end"
                      ? ui.endAbbr
                      : i}{" "}
                  ·{" "}
                  {w.label === "Start"
                    ? ui.start
                    : w.label === "Ziel"
                      ? ui.end
                      : discoverPinLabel(w.label, lang) || w.label || w.role}
                </span>
                {w.role === "via" && (
                  <button
                    type="button"
                    className="text-text-secondary"
                    onClick={() =>
                      scheduleRecompute(removeWaypoint(draft, w.id))
                    }
                  >
                    ✕
                  </button>
                )}
              </li>
            ))}
          </ul>

          <button
            type="button"
            disabled={busy || !startOf(draft) || !endOf(draft)}
            onClick={() => void runRoute()}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
          >
            <Navigation className="h-4 w-4" />
            {busy ? ui.computing : ui.computeRoute}
          </button>

          {msg && (
            <p className="text-[11px] text-text-secondary">
              {plannerStatus(msg, lang)}
            </p>
          )}

          {stats && (
            <div className="rounded-xl border border-chrome/30 bg-chrome/10 p-3">
              <p className="text-sm font-semibold tabular-nums">{stats}</p>
              {draft.label && (
                <p className="text-xs text-text-secondary">
                  {discoverPinLabel(draft.label, lang) || draft.label}
                </p>
              )}
              <div className="mt-3 flex gap-2">
                <button
                  type="button"
                  onClick={saveCurrent}
                  className="inline-flex flex-1 items-center justify-center gap-1 rounded-lg border border-border py-2 text-xs font-medium"
                >
                  <Bookmark className="h-3.5 w-3.5" /> {ui.save}
                </button>
                <button
                  type="button"
                  onClick={() =>
                    draft.computed &&
                    startInApp(
                      draft.computed,
                      draft.label || DISCOVER_PIN_DE.planned
                    )
                  }
                  className="inline-flex flex-1 items-center justify-center gap-1 rounded-xl bg-accent py-2 text-xs font-semibold text-on-accent"
                >
                  <Play className="h-3.5 w-3.5 fill-current" /> {ui.inApp}
                </button>
              </div>
            </div>
          )}

          <p className="flex items-start gap-2 rounded-lg border border-border bg-surface px-2 py-2 text-[11px] text-text-secondary">
            <Smartphone className="mt-0.5 h-3.5 w-3.5 shrink-0 text-chrome" />
            {p.navOffline}
          </p>
        </div>
      </aside>

      <div className="relative order-1 min-h-[42vh] flex-1 lg:order-2 lg:min-h-0">
        <MapView
          className="absolute inset-0"
          center={mapCenter}
          zoom={11}
          routes={mapLayers}
          markers={markers}
          interactiveSelect={pickTarget !== null}
          onMapClick={onMapClick}
          fitRoute={Boolean(draft.computed)}
        />
        {pickTarget && (
          <div className="absolute left-3 right-3 top-3 z-10 rounded-xl bg-black/75 px-3 py-2 text-center text-xs text-white lg:left-auto lg:right-3 lg:max-w-xs">
            {p.pickTap(
              pickTarget === "start"
                ? ui.start
                : pickTarget === "end"
                  ? ui.end
                  : p.via
            )}
            <button
              type="button"
              className="ml-2 underline"
              onClick={() => setPickTarget(null)}
            >
              {ui.cancel}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

export default function PlannerPage() {
  const copy = useHofCopy();
  return (
    <Suspense
      fallback={
        <div className="p-8 text-center text-sm text-text-secondary">
          {copy.mapLoading}
        </div>
      }
    >
      <PlannerInner />
    </Suspense>
  );
}
