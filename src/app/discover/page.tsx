"use client";

import { useCallback, useEffect, useMemo, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Bookmark,
  Compass,
  Crosshair,
  MapPin,
  Mountain,
  Navigation,
  Play,
  Route,
  Zap,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import {
  getSuggestionById,
  suggestRoutes,
  type RouteSuggestion,
} from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView, type MapMarker } from "@/components/MapView";
import {
  profileForBikeCategory,
  ROUTING_PROFILES,
  type ClientRouteResult,
  type RoutingProfile,
} from "@/lib/routing/profiles";
import {
  activeRouteFromEngine,
  activeRouteFromSuggestion,
} from "@/lib/routing/activeRoute";
import {
  DEFAULT_ROUTE_FILTERS,
  filterRouteSuggestions,
  type RouteFilterState,
} from "@/lib/routing/routeFilters";
import { buildDemoGeometry } from "@/lib/routing/demoGeometry";
import { RouteCard } from "@/components/discover/RouteCard";
import { FilterChips } from "@/components/discover/FilterChips";
import { RouteDetail } from "@/components/discover/RouteDetail";
import type { SavedRoute } from "@/types/route";
import type { OutdooractiveTour } from "@/lib/geo/outdooractive";
import type { TrailforksPin } from "@/lib/geo/trailCondition";
import {
  adoptTour,
  computePointToPoint,
  computeQuickOptions,
  emptyDraft,
  endOf,
  geometryFromTourCenter,
  setEnd,
  setStart,
  snapToTour,
  startOf,
  type BaseTour,
  type PlanDraft,
  type PlanMode,
  type QuickOption,
} from "@/lib/routing/planDraft";

type SheetMode = "quick" | "plan" | "tours";

const FALLBACK_CENTER: [number, number] = [8.2, 48.0];

function suggestionToTour(r: RouteSuggestion): BaseTour {
  return {
    id: r.id,
    name: r.name,
    provider: "seed",
    geometry: buildDemoGeometry(r.id, r.distanceKm),
    distanceKm: r.distanceKm,
    elevationM: r.elevationM,
    durationMin: r.durationMin,
    mtbScale: r.mtbScale,
    surface: r.surface,
    reasons: r.reasons,
    matchScore: r.matchScore,
    loop: r.loop,
  };
}

function oaToTour(t: OutdooractiveTour): BaseTour {
  const km = t.lengthKm ?? 20;
  return {
    id: t.id,
    name: t.title,
    provider: "outdooractive",
    geometry: geometryFromTourCenter(t.id, t.center, km),
    distanceKm: km,
    elevationM: t.elevationM,
    durationMin: t.durationMin,
    mtbScale: t.difficulty,
    attribution: "© Outdooractive",
    center: t.center,
    url: t.url,
  };
}

function DiscoverPageInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const highlightRouteId = searchParams.get("route");

  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const privacyZones = useAppStore((s) => s.privacyZones);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const boschLive = useAppStore((s) => s.boschLive);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const consents = useAppStore((s) => s.consents);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const isRouteSaved = useAppStore((s) => s.isRouteSaved);

  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const routingProfile = useMemo(
    () => profileForBikeCategory(activeBike?.category || "mtb_enduro"),
    [activeBike?.category]
  );

  const [sheetMode, setSheetMode] = useState<SheetMode>("quick");
  const [minutes, setMinutes] = useState(
    profile.fitnessIndicators.avgRideDurationMin || 90
  );
  const [filters, setFilters] = useState<RouteFilterState>(DEFAULT_ROUTE_FILTERS);
  const [detailId, setDetailId] = useState<string | null>(highlightRouteId);
  const [userPos, setUserPos] = useState<[number, number] | null>(null);
  const [mapCenter, setMapCenter] =
    useState<[number, number]>(FALLBACK_CENTER);
  const [draft, setDraft] = useState<PlanDraft>(() =>
    emptyDraft(routingProfile, FALLBACK_CENTER)
  );
  const [pickTarget, setPickTarget] = useState<"start" | "end" | null>(null);
  const [routingBusy, setRoutingBusy] = useState(false);
  const [routingMsg, setRoutingMsg] = useState<string | null>(null);
  const [quickOptions, setQuickOptions] = useState<QuickOption[]>([]);
  const [quickBusy, setQuickBusy] = useState(false);
  const [previewTour, setPreviewTour] = useState<BaseTour | null>(null);
  const [oaTours, setOaTours] = useState<OutdooractiveTour[]>([]);
  const [oaAttr, setOaAttr] = useState<string | null>(null);
  const [oaWarning, setOaWarning] = useState<string | null>(null);
  const [tfPins, setTfPins] = useState<TrailforksPin[]>([]);
  const [tfDisclaimer, setTfDisclaimer] = useState<string | null>(null);
  const [manualProfile, setManualProfile] = useState<RoutingProfile | null>(
    null
  );

  const activeProfile = manualProfile ?? routingProfile;

  const heatmapConsent =
    consents.find((c) => c.purpose === "heatmap_contribution")?.granted ??
    false;

  const range = useMemo(() => {
    if (!activeBike?.isEbike || !rangePro) return undefined;
    return estimateRange({
      bike: activeBike,
      profile,
      calibration: calibration ?? undefined,
      socPercent: boschLive?.soc ?? 87,
    });
  }, [activeBike, profile, calibration, boschLive, rangePro]);

  const routes = useMemo(() => {
    if (!activeBike) return [];
    return suggestRoutes({
      bike: activeBike,
      profile,
      availableMinutes: minutes,
      rangeKmHigh: range?.kmHigh,
    });
  }, [activeBike, profile, minutes, range]);

  const filtered = useMemo(
    () => filterRouteSuggestions(routes, filters),
    [routes, filters]
  );

  const detailRoute = useMemo(() => {
    if (!detailId || !activeBike) return null;
    return (
      getSuggestionById(detailId, {
        bike: activeBike,
        profile,
        availableMinutes: minutes,
        rangeKmHigh: range?.kmHigh,
      }) ??
      routes.find((r) => r.id === detailId) ??
      null
    );
  }, [detailId, activeBike, profile, minutes, range, routes]);

  const origin = userPos ?? mapCenter;

  useEffect(() => {
    if (highlightRouteId) {
      setDetailId(highlightRouteId);
      setSheetMode("tours");
    }
  }, [highlightRouteId]);

  useEffect(() => {
    setDraft((d) => ({ ...d, profile: activeProfile }));
  }, [activeProfile]);

  useEffect(() => {
    let cancelled = false;
    if (typeof navigator !== "undefined" && navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          if (cancelled) return;
          const p: [number, number] = [
            pos.coords.longitude,
            pos.coords.latitude,
          ];
          setUserPos(p);
          setMapCenter(p);
          setDraft((d) => setStart(d, p, "Meine Position"));
        },
        () => undefined,
        { timeout: 8000, maximumAge: 30 * 60 * 1000 }
      );
    }
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/outdooractive?type=tour")
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        if (data?.provider === "outdooractive") {
          setOaTours(Array.isArray(data.tours) ? data.tours : []);
          setOaAttr(data.attribution ?? null);
          setOaWarning(data.warning ?? null);
        }
      })
      .catch(() => undefined);

    void fetch("/api/trailforks")
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        setTfPins(Array.isArray(data.pins) ? data.pins : []);
        setTfDisclaimer(data.disclaimer ?? null);
      })
      .catch(() => undefined);

    return () => {
      cancelled = true;
    };
  }, []);

  const refreshQuick = useCallback(async () => {
    setQuickBusy(true);
    setRoutingMsg(null);
    try {
      const opts = await computeQuickOptions(origin, activeProfile, minutes);
      setQuickOptions(opts);
      if (!opts.length) {
        setRoutingMsg(
          "Keine Quick-Routen — Planer nutzen oder Filter prüfen."
        );
      } else {
        setDraft((d) => ({
          ...setStart(
            { ...d, mode: "quick" as PlanMode, profile: activeProfile },
            origin,
            "Hier"
          ),
          computed: opts[0].result,
          label: opts[0].label,
        }));
        setPreviewTour(null);
      }
    } finally {
      setQuickBusy(false);
    }
  }, [origin, activeProfile, minutes]);

  useEffect(() => {
    if (sheetMode !== "quick") return;
    void refreshQuick();
  }, [sheetMode, refreshQuick]);

  const openDetail = useCallback(
    (id: string) => {
      setDetailId(id);
      router.replace(`/discover?route=${id}`, { scroll: false });
    },
    [router]
  );

  const closeDetail = useCallback(() => {
    setDetailId(null);
    router.replace("/discover", { scroll: false });
  }, [router]);

  const startWithSuggestion = useCallback(
    (r: RouteSuggestion) => {
      setActiveRoute(activeRouteFromSuggestion(r));
      router.push("/ride");
    },
    [setActiveRoute, router]
  );

  const startWithComputed = useCallback(
    (name: string, result: ClientRouteResult) => {
      setActiveRoute(activeRouteFromEngine(name, result));
      router.push("/ride");
    },
    [setActiveRoute, router]
  );

  const toggleSave = useCallback(
    (r: RouteSuggestion | SavedRoute) => {
      if (isRouteSaved(r.id)) unsaveRoute(r.id);
      else saveRoute(r);
    },
    [isRouteSaved, saveRoute, unsaveRoute]
  );

  const saveCurrentDraft = useCallback(() => {
    if (!draft.computed) return;
    const id = `saved-${Date.now()}`;
    const entry: SavedRoute = {
      id,
      name: draft.label || draft.baseTour?.name || "Geplante Route",
      distanceKm: Math.round((draft.computed.distanceM / 1000) * 10) / 10,
      elevationM: Math.round(draft.computed.distanceM * 0.03),
      durationMin: Math.round(draft.computed.durationS / 60),
      mtbScale: draft.baseTour?.mtbScale,
      surface: draft.baseTour?.surface,
      reasons: draft.baseTour?.reasons,
      savedAt: new Date().toISOString(),
      source: draft.mode === "tour" || draft.mode === "hybrid" ? "import" : "engine",
      geometry: draft.computed.geometry,
      waypoints: draft.waypoints.map((w) => ({
        role: w.role,
        lngLat: w.lngLat,
        label: w.label,
      })),
    };
    saveRoute(entry);
  }, [draft, saveRoute]);

  const runPlanRoute = async () => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const withProfile = { ...draft, profile: activeProfile, mode: "point_to_point" as const };
      const result = await computePointToPoint(withProfile);
      if (!result) {
        setRoutingMsg("Route konnte nicht berechnet werden — Start und Ziel setzen.");
        return;
      }
      setDraft({
        ...withProfile,
        computed: result,
        label: "Geplante Route",
        baseTour: undefined,
        hybrid: undefined,
      });
      setPreviewTour(null);
      setRoutingMsg(
        `${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min · ${result.engine}`
      );
    } finally {
      setRoutingBusy(false);
    }
  };

  const previewBaseTour = (tour: BaseTour) => {
    setPreviewTour(tour);
    const adopted = adoptTour(tour, activeProfile);
    setDraft({
      mode: "tour",
      profile: activeProfile,
      waypoints: [
        {
          id: "start",
          role: "start",
          lngLat: (tour.geometry?.coordinates[0] as [number, number]) ?? origin,
          label: "Tour-Start",
        },
      ],
      baseTour: tour,
      hybrid: { strategy: "adopt" },
      computed: adopted,
      label: tour.name,
    });
    if (tour.center) setMapCenter(tour.center);
  };

  const runHybridSnap = async (tour: BaseTour) => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const result = await snapToTour(origin, tour, activeProfile);
      if (!result) {
        setRoutingMsg("Hybrid-Snap fehlgeschlagen");
        return;
      }
      setPreviewTour(tour);
      const tourCoords = (tour.geometry?.coordinates ??
        result.geometry.coordinates) as [number, number][];
      const tourEnd =
        tourCoords.length > 0
          ? tourCoords[tourCoords.length - 1]
          : origin;
      setDraft({
        mode: "hybrid",
        profile: activeProfile,
        waypoints: [
          { id: "start", role: "start", lngLat: origin, label: "Hier" },
          {
            id: "end",
            role: "end",
            lngLat: tourEnd,
            label: "Tour-Ende",
          },
        ],
        baseTour: tour,
        hybrid: { strategy: "snap" },
        computed: result,
        label: `${tour.name} (von hier)`,
      });
      setRoutingMsg(
        `Hybrid · ${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min`
      );
      setSheetMode("tours");
    } finally {
      setRoutingBusy(false);
    }
  };

  const onMapClick = (lngLat: [number, number]) => {
    if (!pickTarget) return;
    if (pickTarget === "start") {
      setDraft((d) => setStart(d, lngLat, "Start (Karte)"));
      setMapCenter(lngLat);
    } else {
      setDraft((d) => setEnd(d, lngLat, "Ziel (Karte)"));
    }
    setPickTarget(null);
    setSheetMode("plan");
  };

  const markers: MapMarker[] = useMemo(() => {
    const m: MapMarker[] = [];
    const s = startOf(draft);
    const e = endOf(draft);
    if (s) m.push({ id: "start", lngLat: s, color: "#43A047", label: "Start" });
    if (e) m.push({ id: "end", lngLat: e, color: "#E53935", label: "Ziel" });
    return m;
  }, [draft]);

  const activeGeometry = draft.computed?.geometry ?? null;
  const secondaryGeometry = previewTour?.geometry ?? null;

  if (detailRoute) {
    return (
      <div className="flex flex-col gap-4 p-4 pt-6">
        <RouteDetail
          route={detailRoute}
          saved={isRouteSaved(detailRoute.id)}
          range={range}
          rangePro={rangePro}
          isEbike={!!activeBike?.isEbike}
          heatmapConsent={heatmapConsent}
          rides={rides}
          privacyZones={privacyZones.map((z) => ({
            lat: z.lat,
            lng: z.lng,
            radiusM: z.radiusM,
          }))}
          onBack={closeDetail}
          onStart={() => startWithSuggestion(detailRoute)}
          onToggleSave={() => toggleSave(detailRoute)}
        />
        <div className="flex flex-col gap-2">
          <button
            type="button"
            disabled={routingBusy}
            onClick={() => void runHybridSnap(suggestionToTour(detailRoute))}
            className="rounded-xl border border-accent/40 bg-accent/10 py-2.5 text-sm font-semibold text-accent"
          >
            Von hier starten (Hybrid-Snap)
          </button>
        </div>
      </div>
    );
  }

  const statsLine = draft.computed
    ? `${(draft.computed.distanceM / 1000).toFixed(1)} km · ${Math.round(draft.computed.durationS / 60)} min · ${draft.computed.engine}`
    : null;

  return (
    <div className="flex min-h-[calc(100dvh-5rem)] flex-col">
      {/* Dach */}
      <header className="shrink-0 space-y-2 border-b border-border px-4 pb-3 pt-5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h1 className="text-xl font-bold tracking-tight">Discover</h1>
            <p className="text-xs text-text-secondary">
              {activeBike
                ? `${activeBike.name} · ${bikeCategoryLabel(activeBike.category)}`
                : "Kein Bike aktiv"}
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              if (userPos) {
                setMapCenter(userPos);
                setDraft((d) => setStart(d, userPos, "Meine Position"));
              }
            }}
            className="flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium text-text-secondary"
          >
            <Crosshair className="h-3.5 w-3.5" />
            {userPos ? "Hier" : "Ort…"}
          </button>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <label className="flex items-center gap-1.5 rounded-lg bg-surface-elevated px-2 py-1 text-[11px]">
            <span className="text-text-secondary">Zeit</span>
            <input
              type="range"
              min={45}
              max={240}
              step={15}
              value={minutes}
              onChange={(e) => setMinutes(Number(e.target.value))}
              className="w-24"
            />
            <span className="font-medium tabular-nums">{minutes} min</span>
          </label>
          <select
            value={activeProfile}
            onChange={(e) =>
              setManualProfile(e.target.value as RoutingProfile)
            }
            className="rounded-lg border border-border bg-surface px-2 py-1 text-[11px]"
          >
            {Object.values(ROUTING_PROFILES).map((p) => (
              <option key={p.id} value={p.id}>
                {p.label}
              </option>
            ))}
          </select>
        </div>
      </header>

      {/* Karte */}
      <div className="relative min-h-[42vh] flex-1">
        <MapView
          className="absolute inset-0 rounded-none"
          center={mapCenter}
          zoom={11}
          route={activeGeometry}
          secondaryRoute={
            secondaryGeometry &&
            secondaryGeometry !== activeGeometry
              ? secondaryGeometry
              : null
          }
          markers={markers}
          interactiveSelect={pickTarget !== null}
          onMapClick={onMapClick}
          fitRoute={Boolean(activeGeometry)}
        />
        {pickTarget && (
          <div className="absolute left-3 right-3 top-3 rounded-xl bg-black/75 px-3 py-2 text-center text-xs text-white">
            Tippe auf die Karte für{" "}
            {pickTarget === "start" ? "Start" : "Ziel"}
            <button
              type="button"
              className="ml-2 underline"
              onClick={() => setPickTarget(null)}
            >
              Abbrechen
            </button>
          </div>
        )}
        {statsLine && (
          <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between gap-2 rounded-xl bg-black/70 px-3 py-2 text-xs text-white">
            <span className="truncate">
              {draft.label ? `${draft.label} · ` : ""}
              {statsLine}
            </span>
            <div className="flex shrink-0 gap-1.5">
              <button
                type="button"
                onClick={saveCurrentDraft}
                className="rounded-lg bg-white/15 px-2 py-1"
                aria-label="Speichern"
              >
                <Bookmark className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                onClick={() =>
                  draft.computed &&
                  startWithComputed(
                    draft.label || "Geplante Route",
                    draft.computed
                  )
                }
                className="flex items-center gap-1 rounded-lg bg-accent px-2.5 py-1 font-semibold"
              >
                <Play className="h-3.5 w-3.5 fill-current" /> Los
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Sheet */}
      <div className="shrink-0 border-t border-border bg-background">
        <div className="grid grid-cols-3 gap-1 p-2">
          {(
            [
              ["quick", "Schnell", Zap],
              ["plan", "Planen", Navigation],
              ["tours", "Touren", Route],
            ] as const
          ).map(([id, label, Icon]) => (
            <button
              key={id}
              type="button"
              onClick={() => setSheetMode(id)}
              className={`flex items-center justify-center gap-1.5 rounded-lg py-2.5 text-xs font-medium ${
                sheetMode === id
                  ? "bg-accent text-white"
                  : "bg-surface-elevated text-text-secondary"
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              {label}
            </button>
          ))}
        </div>

        <div className="max-h-[38vh] overflow-y-auto px-3 pb-4">
          {routingMsg && (
            <p className="mb-2 text-[11px] text-text-secondary">{routingMsg}</p>
          )}

          {sheetMode === "quick" && (
            <div className="flex flex-col gap-2">
              <p className="text-[11px] text-text-secondary">
                Geroutete Optionen ab deiner Position · {minutes} min Budget
              </p>
              {quickBusy && (
                <p className="text-sm text-text-secondary">Berechne…</p>
              )}
              {!quickBusy && quickOptions.length === 0 && (
                <div className="rounded-xl border border-border p-4 text-center text-sm text-text-secondary">
                  Keine Quick-Route —{" "}
                  <button
                    type="button"
                    className="font-medium text-accent"
                    onClick={() => setSheetMode("plan")}
                  >
                    Planer öffnen
                  </button>
                </div>
              )}
              <div className="flex gap-2 overflow-x-auto pb-1">
                {quickOptions.map((q) => (
                  <button
                    key={q.id}
                    type="button"
                    onClick={() => {
                      setDraft((d) => ({
                        ...setStart(
                          { ...d, mode: "quick", profile: activeProfile },
                          origin,
                          "Hier"
                        ),
                        computed: q.result,
                        label: q.label,
                        baseTour: undefined,
                      }));
                      setPreviewTour(null);
                    }}
                    className={`min-w-[9.5rem] shrink-0 rounded-xl border p-3 text-left ${
                      draft.label === q.label
                        ? "border-accent bg-accent/10"
                        : "border-border bg-surface"
                    }`}
                  >
                    <div className="text-sm font-semibold">{q.label}</div>
                    <div className="mt-1 text-[11px] text-text-secondary">
                      {(q.result.distanceM / 1000).toFixed(1)} km ·{" "}
                      {Math.round(q.result.durationS / 60)} min
                    </div>
                    <div className="mt-1 text-[10px] text-text-secondary">
                      {q.reason}
                    </div>
                  </button>
                ))}
              </div>
              <button
                type="button"
                disabled={quickBusy}
                onClick={() => void refreshQuick()}
                className="rounded-xl border border-border py-2 text-xs font-medium"
              >
                Neu berechnen
              </button>
            </div>
          )}

          {sheetMode === "plan" && (
            <div className="flex flex-col gap-3">
              <p className="text-[11px] text-text-secondary">
                Start und Ziel setzen · Tap auf Karte oder Buttons
              </p>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setPickTarget("start")}
                  className={`rounded-xl border px-3 py-2.5 text-left text-xs ${
                    pickTarget === "start"
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  <div className="flex items-center gap-1 font-medium">
                    <MapPin className="h-3.5 w-3.5 text-green-500" /> Start
                  </div>
                  <div className="mt-0.5 truncate text-text-secondary">
                    {startOf(draft)
                      ? `${startOf(draft)![1].toFixed(3)}, ${startOf(draft)![0].toFixed(3)}`
                      : "Tippen…"}
                  </div>
                </button>
                <button
                  type="button"
                  onClick={() => setPickTarget("end")}
                  className={`rounded-xl border px-3 py-2.5 text-left text-xs ${
                    pickTarget === "end"
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  <div className="flex items-center gap-1 font-medium">
                    <MapPin className="h-3.5 w-3.5 text-red-500" /> Ziel
                  </div>
                  <div className="mt-0.5 truncate text-text-secondary">
                    {endOf(draft)
                      ? `${endOf(draft)![1].toFixed(3)}, ${endOf(draft)![0].toFixed(3)}`
                      : "Tippen…"}
                  </div>
                </button>
              </div>
              <button
                type="button"
                onClick={() => {
                  if (userPos) {
                    setDraft((d) => setStart(d, userPos, "Meine Position"));
                  }
                }}
                className="text-left text-[11px] font-medium text-accent"
              >
                Start = meine Position
              </button>
              <button
                type="button"
                disabled={routingBusy || !startOf(draft) || !endOf(draft)}
                onClick={() => void runPlanRoute()}
                className="w-full rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-40"
              >
                {routingBusy ? "Wird berechnet…" : "Route berechnen"}
              </button>
            </div>
          )}

          {sheetMode === "tours" && (
            <div className="flex flex-col gap-3">
              <FilterChips
                minutes={minutes}
                onMinutes={setMinutes}
                filters={filters}
                onChange={setFilters}
              />

              {activeBike?.isEbike && range && (
                <div className="rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-xs">
                  Reichweite {range.kmLow}–{range.kmHigh} km
                </div>
              )}

              <h3 className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
                Für dein Bike
              </h3>
              {filtered.length === 0 ? (
                <p className="text-sm text-text-secondary">
                  Keine Tour in der Nähe der Filter — Planer öffnen.
                </p>
              ) : (
                filtered.map((r) => (
                  <div key={r.id} className="space-y-1.5">
                    <RouteCard
                      route={r}
                      highlighted={
                        highlightRouteId === r.id || previewTour?.id === r.id
                      }
                      saved={isRouteSaved(r.id)}
                      onOpen={() => {
                        previewBaseTour(suggestionToTour(r));
                        openDetail(r.id);
                      }}
                      onStart={() => {
                        previewBaseTour(suggestionToTour(r));
                        startWithSuggestion(r);
                      }}
                      onToggleSave={() => toggleSave(r)}
                    />
                    <div className="flex gap-2 px-1">
                      <button
                        type="button"
                        className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                        onClick={() => previewBaseTour(suggestionToTour(r))}
                      >
                        Vorschau
                      </button>
                      <button
                        type="button"
                        disabled={routingBusy}
                        className="flex-1 rounded-lg border border-accent/40 py-1.5 text-[11px] font-medium text-accent"
                        onClick={() => void runHybridSnap(suggestionToTour(r))}
                      >
                        Von hier
                      </button>
                    </div>
                  </div>
                ))
              )}

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                <Compass className="h-3.5 w-3.5" /> Outdooractive
              </h3>
              {oaWarning && (
                <p className="text-[11px] text-warning">{oaWarning}</p>
              )}
              {oaTours.map((t) => {
                const tour = oaToTour(t);
                return (
                  <article
                    key={t.id}
                    className="rounded-xl border border-border bg-surface p-3"
                  >
                    <div className="text-sm font-medium">{t.title}</div>
                    <p className="text-[11px] text-text-secondary">
                      {[
                        t.difficulty,
                        t.lengthKm != null ? `${t.lengthKm} km` : null,
                        t.source === "demo" ? "Demo" : null,
                      ]
                        .filter(Boolean)
                        .join(" · ")}
                    </p>
                    <div className="mt-2 flex gap-2">
                      <button
                        type="button"
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => previewBaseTour(tour)}
                      >
                        Vorschau
                      </button>
                      <button
                        type="button"
                        disabled={routingBusy}
                        className="rounded-lg border border-accent/40 px-2.5 py-1.5 text-[11px] text-accent"
                        onClick={() => void runHybridSnap(tour)}
                      >
                        Von hier
                      </button>
                      {t.url && (
                        <a
                          href={t.url}
                          target="_blank"
                          rel="noreferrer"
                          className="ml-auto self-center text-[11px] text-accent"
                        >
                          OA →
                        </a>
                      )}
                    </div>
                  </article>
                );
              })}
              {oaAttr && (
                <p className="text-[10px] text-text-secondary">{oaAttr}</p>
              )}

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                <Mountain className="h-3.5 w-3.5" /> Trailforks
              </h3>
              <p className="text-[11px] text-text-secondary">
                {tfDisclaimer ?? "Attribution — kein Geometrie-Mirror."}
              </p>
              {tfPins.slice(0, 5).map((p) => (
                <div
                  key={p.id}
                  className="flex items-center justify-between rounded-xl border border-border px-3 py-2 text-xs"
                >
                  <div>
                    <div className="font-medium">{p.name}</div>
                    <div className="text-text-secondary">
                      {p.difficulty ?? "—"} · {p.conditionLabel}
                    </div>
                  </div>
                  <a
                    href={p.openUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-accent"
                  >
                    TF →
                  </a>
                </div>
              ))}

              <h3 className="mt-2 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                Gespeichert
              </h3>
              {savedRoutes.length === 0 ? (
                <p className="text-sm text-text-secondary">
                  Noch nichts gespeichert.
                </p>
              ) : (
                savedRoutes.map((r) => (
                  <article
                    key={r.id}
                    className="rounded-xl border border-border bg-surface p-3"
                  >
                    <h4 className="text-sm font-semibold">{r.name}</h4>
                    <p className="text-[11px] text-text-secondary">
                      {r.distanceKm} km · {r.elevationM} hm · {r.durationMin}{" "}
                      min
                      {r.geometry ? " · mit Track" : ""}
                    </p>
                    <div className="mt-2 flex gap-2">
                      <button
                        type="button"
                        onClick={() => unsaveRoute(r.id)}
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                      >
                        Entfernen
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          if (r.geometry) {
                            startWithComputed(r.name, {
                              distanceM: r.distanceKm * 1000,
                              durationS: r.durationMin * 60,
                              geometry: r.geometry,
                              engine: "saved",
                              profile: activeProfile,
                            });
                            return;
                          }
                          const suggestion = activeBike
                            ? getSuggestionById(r.id, {
                                bike: activeBike,
                                profile,
                                availableMinutes: minutes,
                                rangeKmHigh: range?.kmHigh,
                              })
                            : null;
                          if (suggestion) startWithSuggestion(suggestion);
                          else {
                            setActiveRoute({
                              id: r.id,
                              name: r.name,
                              distanceKm: r.distanceKm,
                              elevationM: r.elevationM,
                              durationMin: r.durationMin,
                              mtbScale: r.mtbScale,
                              surface: r.surface,
                              reasons: r.reasons,
                              geometry: buildDemoGeometry(r.id, r.distanceKm),
                              source: "suggestion",
                              setAt: new Date().toISOString(),
                            });
                            router.push("/ride");
                          }
                        }}
                        className="flex flex-1 items-center justify-center gap-1 rounded-lg bg-accent py-1.5 text-[11px] font-semibold text-white"
                      >
                        <Play className="h-3.5 w-3.5 fill-current" /> Losfahren
                      </button>
                    </div>
                  </article>
                ))
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function DiscoverPage() {
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center text-sm text-text-secondary">
          Discover wird geladen…
        </div>
      }
    >
      <DiscoverPageInner />
    </Suspense>
  );
}
