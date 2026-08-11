"use client";

import { useCallback, useEffect, useMemo, useRef, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Bookmark,
  Compass,
  Crosshair,
  Mountain,
  Navigation,
  Play,
  Route,
  Zap,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import {
  getSuggestionById,
  listAllRouteSuggestions,
  categoryForRoutingProfile,
  type RouteSuggestion,
} from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { BikeChip } from "@/components/BikeChip";
import {
  profileForBikeCategory,
  ROUTING_PROFILES,
  DEFAULT_DISCOVER_PROFILE,
  type ClientRouteResult,
  type RoutingProfile,
} from "@/lib/routing/profiles";
import {
  consumerRoutingNotice,
  showRoutingDebugUi,
  type RoutingStatusPayload,
} from "@/lib/routing/routingStatus";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";
import {
  activeRouteFromEngine,
  activeRouteFromSuggestion,
} from "@/lib/routing/activeRoute";
import { parseGpx } from "@/lib/import/gpx";
import {
  DEFAULT_ROUTE_FILTERS,
  filterRouteSuggestions,
  sportFilterFromProfile,
  type RouteFilterState,
  type SportFilter,
} from "@/lib/routing/routeFilters";
import { demoCenterLngLat } from "@/lib/routing/demoGeometry";
import { RouteCard } from "@/components/discover/RouteCard";
import { FilterChips } from "@/components/discover/FilterChips";
import { RouteDetail } from "@/components/discover/RouteDetail";
import { OfflinePacksPanel } from "@/components/discover/OfflinePacksPanel";
import {
  bboxAround,
  fetchCommunityHeatmap,
} from "@/lib/heatmap/client";
import type { HeatmapResult } from "@/lib/routing/heatmaps";
import type { SavedRoute } from "@/types/route";
import type { OutdooractiveTour } from "@/lib/geo/outdooractive";
import type { TrailforksPin } from "@/lib/geo/trailCondition";
import {
  adoptTour,
  addVia,
  attachTrailToDraft,
  computePointToPoint,
  computeQuickOptions,
  emptyDraft,
  endOf,
  orderedWaypoints,
  removeWaypoint,
  setEnd,
  setStart,
  snapToTourParts,
  startOf,
  type BaseTour,
  type PlanDraft,
  type PlanMode,
  type QuickOption,
} from "@/lib/routing/planDraft";
import { buildDiscoverMapLayers } from "@/lib/routing/discoverMapLayers";
import { trailsNear, type TrailSegment } from "@/lib/routing/trailSegments";
import { NearMeRouteCard } from "@/components/explore/NearMeRouteCard";
import {
  BERLIN_DEFAULT_CENTER,
  DEMO_CITY_CHIPS,
} from "@/lib/discover/berlinLoops";
import {
  curatedP0CatalogSuggestions,
  curatedSixtyMinLoopSuggestions,
} from "@/lib/discover/curatedP0Seeds";
import { allowDemoContent } from "@/lib/config/allowDemoContent";

type SheetMode = "quick" | "plan" | "tours";

const FALLBACK_CENTER: [number, number] = [8.2, 48.0];
/** Abort stuck „Berechne…“ so Quick always recovers to seeds + retry. */
const QUICK_TIMEOUT_MS = 5000;
/** Seeds beyond this are „not useful nearby“ → show Demo-Stadt chips. */
const USEFUL_LOOP_RADIUS_KM = 50;

function suggestionToTour(r: RouteSuggestion): BaseTour {
  return {
    id: r.id,
    name: r.name,
    provider: "seed",
    geometry: null,
    distanceKm: r.distanceKm,
    elevationM: r.elevationM,
    durationMin: r.durationMin,
    mtbScale: r.mtbScale,
    surface: r.surface,
    reasons: r.reasons,
    matchScore: r.matchScore,
    loop: r.loop,
    center: demoCenterLngLat(r.id),
  };
}

function oaToTour(t: OutdooractiveTour): BaseTour {
  const km = t.lengthKm ?? 20;
  const hasLiveGeom = Boolean(t.geometry && t.geometry.length >= 2);
  return {
    id: t.id,
    name: t.title,
    provider: "outdooractive",
    geometry: hasLiveGeom
      ? { type: "LineString", coordinates: t.geometry! }
      : null,
    distanceKm: km,
    elevationM: t.elevationM,
    durationMin: t.durationMin,
    mtbScale: t.difficulty,
    attribution: hasLiveGeom
      ? "© Outdooractive"
      : "© Outdooractive · Tour-Idee (keine API-Geometry)",
    center: t.center,
    url: t.url,
  };
}

function DiscoverPageInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const highlightRouteId = searchParams.get("route");
  const sportParam = searchParams.get("sport") as SportFilter | null;
  const latParam = searchParams.get("lat");
  const lngParam = searchParams.get("lng");
  const minutesParam = searchParams.get("minutes");
  const lensParam = searchParams.get("lens");
  const queryMinutes = (() => {
    const raw = minutesParam ?? (lensParam === "60" ? "60" : null);
    if (!raw) return null;
    const n = Number(raw);
    return Number.isFinite(n) && n > 0 && n <= 600 ? Math.round(n) : null;
  })();
  const queryCenter = (() => {
    if (!latParam || !lngParam) return null;
    const lat = Number(latParam);
    const lng = Number(lngParam);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
    return [lng, lat] as [number, number];
  })();

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
  const routeCollections = useAppStore((s) => s.routeCollections);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const addRouteToCollection = useAppStore((s) => s.addRouteToCollection);
  const [collectionName, setCollectionName] = useState("");
  const gpxInputRef = useRef<HTMLInputElement | null>(null);
  const addrInputRef = useRef<HTMLInputElement | null>(null);
  const [addrQuery, setAddrQuery] = useState("");
  const [addrTarget, setAddrTarget] = useState<"start" | "end">("start");
  const [addrHits, setAddrHits] = useState<
    { label: string; lat: number; lng: number }[]
  >([]);
  const [addrBusy, setAddrBusy] = useState(false);
  const [locationStatus, setLocationStatus] = useState<string>(
    queryCenter
      ? "Standort: Deep-Link"
      : "Standort wird ermittelt… — oder Ort tippen"
  );

  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const routingProfile = useMemo(
    () =>
      activeBike
        ? profileForBikeCategory(activeBike.category)
        : DEFAULT_DISCOVER_PROFILE,
    [activeBike]
  );

  const [sheetMode, setSheetMode] = useState<SheetMode>("quick");
  const [minutes, setMinutes] = useState(
    () => queryMinutes ?? 60
  );
  const [filters, setFilters] = useState<RouteFilterState>(() => ({
    ...DEFAULT_ROUTE_FILTERS,
    // Primary lens ~60 = Rundkurs honesty (parity with Flutter _loopOnly).
    loopOnly: (queryMinutes ?? 60) === 60,
    sport:
      sportParam &&
      [
        "all",
        "mtb",
        "road",
        "gravel",
        "urban",
        "ebike",
        "touring",
        "hiking",
      ].includes(sportParam)
        ? sportParam
        : "all",
  }));
  const [detailId, setDetailId] = useState<string | null>(highlightRouteId);
  const [userPos, setUserPos] = useState<[number, number] | null>(null);
  const [mapCenter, setMapCenter] = useState<[number, number]>(
    () => queryCenter ?? BERLIN_DEFAULT_CENTER ?? FALLBACK_CENTER
  );
  const [draft, setDraft] = useState<PlanDraft>(() =>
    emptyDraft(
      routingProfile,
      queryCenter ?? BERLIN_DEFAULT_CENTER ?? FALLBACK_CENTER
    )
  );
  const [pickTarget, setPickTarget] = useState<"start" | "end" | "via" | null>(
    null
  );
  const [routingBusy, setRoutingBusy] = useState(false);
  const [routingMsg, setRoutingMsg] = useState<string | null>(null);
  const [quickOptions, setQuickOptions] = useState<QuickOption[]>([]);
  const [quickBusy, setQuickBusy] = useState(false);
  const [quickTimedOut, setQuickTimedOut] = useState(false);
  const [quickRateLimited, setQuickRateLimited] = useState(false);
  const quickAbortRef = useRef<AbortController | null>(null);
  const quickDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const quickTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [previewTour, setPreviewTour] = useState<BaseTour | null>(null);
  const [oaTours, setOaTours] = useState<OutdooractiveTour[]>([]);
  const [oaAttr, setOaAttr] = useState<string | null>(null);
  const [oaWarning, setOaWarning] = useState<string | null>(null);
  const [tfPins, setTfPins] = useState<TrailforksPin[]>([]);
  const [tfDisclaimer, setTfDisclaimer] = useState<string | null>(null);
  const [manualProfile, setManualProfile] = useState<RoutingProfile | null>(
    null
  );
  const [showTrails, setShowTrails] = useState(true);
  const [selectedTrailId, setSelectedTrailId] = useState<string | null>(null);
  const [routingNotice, setRoutingNotice] = useState<string | null>(null);
  const [communityHeat, setCommunityHeat] = useState<HeatmapResult | null>(
    null
  );
  const [heatmapNote, setHeatmapNote] = useState<string | null>(null);
  const planDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const activeProfile = manualProfile ?? routingProfile;
  const categoryHint = categoryForRoutingProfile(activeProfile);

  const heatmapConsent =
    consents.find((c) => c.purpose === "heatmap_contribution")?.granted ??
    false;

  // Community-Heatmap um Kartenmitte (k≥5 Server-Filter). Debounce per ~0.05°.
  const heatBboxKey = `${(mapCenter[0] * 20).toFixed(0)}:${(mapCenter[1] * 20).toFixed(0)}`;
  useEffect(() => {
    let cancelled = false;
    const t = setTimeout(() => {
      const [lng, lat] = mapCenter;
      void fetchCommunityHeatmap(bboxAround(lng, lat)).then((r) => {
        if (cancelled) return;
        if (r == null) {
          setCommunityHeat(null);
          // Debug/demo chrome — fail-closed in prod unless SHOW_ROUTING_DEBUG=1
          setHeatmapNote(
            showRoutingDebugUi() ? "Community-Heatmap offline" : null
          );
          return;
        }
        setCommunityHeat(r);
        setHeatmapNote(
          showRoutingDebugUi()
            ? r.coldStart
              ? r.disclaimer
              : `${r.segments.length} Community-Segmente · ${r.disclaimer}`
            : r.coldStart
              ? null
              : `${r.segments.length} Community-Segmente`
        );
      });
    }, 400);
    return () => {
      cancelled = true;
      clearTimeout(t);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- keyed by quantized center
  }, [heatBboxKey]);

  const range = useMemo(() => {
    if (!activeBike?.isEbike || !rangePro) return undefined;
    return estimateRange({
      bike: activeBike,
      profile,
      calibration: calibration ?? undefined,
      socPercent: boschLive?.soc ?? 87,
    });
  }, [activeBike, profile, calibration, boschLive, rangePro]);

  const origin = userPos ?? mapCenter;

  /** Honest ~60 loops only (#35 curated P0 + loop honesty); nearby cards. */
  const sixtyMinLoops = useMemo(() => {
    const all = curatedSixtyMinLoopSuggestions(origin).filter((r) => r.loop);
    return all.filter(
      (r) => (r.distanceFromOriginKm ?? 9999) <= USEFUL_LOOP_RADIUS_KM
    );
  }, [origin]);
  const hasUsefulNearbyLoops = sixtyMinLoops.length > 0;

  const routes = useMemo(() => {
    const catalog = listAllRouteSuggestions({
      bike: activeBike,
      categoryHint,
      profile,
      availableMinutes: minutes,
      rangeKmHigh: range?.kmHigh,
      near: origin,
    });
    // Curated P0 Berlin/RN always available — not depend on ALLOW_DEMO_CONTENT.
    return catalog.length > 0 ? catalog : curatedP0CatalogSuggestions(origin);
  }, [activeBike, categoryHint, profile, minutes, range, origin]);

  const filtered = useMemo(
    () => filterRouteSuggestions(routes, filters),
    [routes, filters]
  );

  const nearbyRoutes = useMemo(
    () => filtered.filter((r) => (r.distanceFromOriginKm ?? 9999) <= 120),
    [filtered]
  );
  const fartherRoutes = useMemo(
    () => filtered.filter((r) => (r.distanceFromOriginKm ?? 9999) > 120),
    [filtered]
  );

  const detailRoute = useMemo(() => {
    if (!detailId) return null;
    const fromCatalog =
      getSuggestionById(detailId, {
        bike: activeBike,
        categoryHint,
        profile,
        availableMinutes: minutes,
        rangeKmHigh: range?.kmHigh,
        near: origin,
      }) ??
      routes.find((r) => r.id === detailId) ??
      curatedP0CatalogSuggestions(origin).find((r) => r.id === detailId) ??
      null;
    return fromCatalog;
  }, [detailId, activeBike, categoryHint, profile, minutes, range, routes, origin]);

  const nearbyTrails = useMemo(
    () => trailsNear(origin, 0.5),
    [origin]
  );

  const mapLayers: MapRouteLayer[] = useMemo(() => {
    const base = buildDiscoverMapLayers({
      draft,
      quickOptions,
      activeQuickId: quickOptions.find((q) => q.label === draft.label)?.id,
      trails: nearbyTrails,
      showTrails: showTrails && sheetMode === "tours",
    });
    const heat: MapRouteLayer[] = (communityHeat?.segments ?? [])
      .filter((s) => s.visible && s.coordinates.length >= 2)
      .slice(0, 40)
      .map((s) => ({
        id: s.id,
        role: "trail" as const,
        geometry: {
          type: "LineString" as const,
          coordinates: s.coordinates,
        },
        color: "#E65100",
        width: 5 + s.intensity * 7,
        opacity: 0.22 + s.intensity * 0.35,
      }));
    return [...heat, ...base];
  }, [
    draft,
    quickOptions,
    nearbyTrails,
    showTrails,
    sheetMode,
    communityHeat,
  ]);

  useEffect(() => {
    if (highlightRouteId) {
      setDetailId(highlightRouteId);
      setSheetMode("tours");
    }
  }, [highlightRouteId]);

  useEffect(() => {
    if (queryMinutes != null) setMinutes(queryMinutes);
  }, [queryMinutes]);

  useEffect(() => {
    if (!queryCenter) return;
    setMapCenter(queryCenter);
    setDraft((d) => setStart(d, queryCenter, "Deep-Link Ort"));
  }, [queryCenter]);

  // Deep-Link ?sport=road|gravel|mtb|… setzt Filter + Profil
  useEffect(() => {
    if (!sportParam) return;
    const allowed: SportFilter[] = [
      "all",
      "mtb",
      "road",
      "gravel",
      "urban",
      "ebike",
      "touring",
      "hiking",
    ];
    if (!allowed.includes(sportParam)) return;
    setFilters((f) => ({ ...f, sport: sportParam }));
    if (sportParam === "road") setManualProfile("road");
    else if (sportParam === "gravel") setManualProfile("gravel");
    else if (sportParam === "mtb") setManualProfile("mtb_allmountain");
    else if (sportParam === "urban") setManualProfile("urban");
    else if (sportParam === "ebike") setManualProfile("emtb");
    else if (sportParam === "touring") setManualProfile("ebike");
    else if (sportParam === "hiking") setManualProfile("hiking");
    setSheetMode("tours");
  }, [sportParam]);

  useEffect(() => {
    // Q-BAR-DIS-01: Demo / UNVERIFIED / Routing-Key chrome only when debug=1.
    if (!showRoutingDebugUi()) return;
    let cancelled = false;
    void fetch("/api/routing/status")
      .then((r) => r.json())
      .then((data: RoutingStatusPayload) => {
        if (!cancelled) setRoutingNotice(consumerRoutingNotice(data.notice));
      })
      .catch(() => {
        // Never invent a consumer notice on fetch failure.
        if (!cancelled) setRoutingNotice(null);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    setDraft((d) => ({ ...d, profile: activeProfile }));
  }, [activeProfile]);

  const focusPlanAddress = useCallback((status: string) => {
    setRoutingMsg(status);
    setLocationStatus(status);
    setSheetMode("plan");
    setAddrTarget("start");
    requestAnimationFrame(() => {
      addrInputRef.current?.focus();
    });
  }, []);

  /** ~60 primary lens keeps Rundkurs honesty on (Flutter parity). */
  const setMinutesLens = useCallback((m: number) => {
    setMinutes(m);
    if (m === 60) {
      setFilters((f) => (f.loopOnly ? f : { ...f, loopOnly: true }));
    }
  }, []);

  const applyDemoCity = useCallback(
    (name: string, lat: number, lng: number) => {
      const center: [number, number] = [lng, lat];
      setUserPos(null);
      setMapCenter(center);
      setMinutes(60);
      // Demo-Stadt = ~60 Rundkurs-Lens (parity with Flutter _applyDemoCity).
      setFilters((f) => ({ ...f, loopOnly: true }));
      setDraft((d) => setStart(d, center, name));
      setLocationStatus(`Demo-Region: ${name}`);
      setRoutingMsg(`Demo-Region: ${name} · 60 min Rundkurse`);
      setSheetMode("quick");
      setQuickTimedOut(false);
    },
    []
  );

  useEffect(() => {
    let cancelled = false;
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      const t = setTimeout(() => {
        if (!cancelled && !queryCenter) {
          setLocationStatus(
            "Standort nicht verfügbar — Demo-Stadt oder Adresse"
          );
        }
      }, 0);
      return () => {
        cancelled = true;
        clearTimeout(t);
      };
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (cancelled) return;
        const p: [number, number] = [
          pos.coords.longitude,
          pos.coords.latitude,
        ];
        setUserPos(p);
        // Deep-Link lat/lng wins over auto GPS for initial map center.
        if (!queryCenter) {
          setMapCenter(p);
          setDraft((d) => setStart(d, p, "Meine Position"));
          setLocationStatus("Standort: GPS");
        } else {
          setLocationStatus("Standort: Deep-Link (GPS verfügbar)");
        }
      },
      () => {
        if (cancelled) return;
        if (!queryCenter) {
          setLocationStatus(
            "Standort verweigert — Demo-Stadt wählen oder Adresse suchen"
          );
        }
      },
      { timeout: 8000, maximumAge: 30 * 60 * 1000 }
    );
    return () => {
      cancelled = true;
    };
  }, [queryCenter]);

  useEffect(() => {
    let cancelled = false;
    const [lng, lat] = userPos ?? mapCenter;
    const qs = new URLSearchParams({
      type: "tour",
      lat: String(lat),
      lon: String(lng),
    });
    void fetch(`/api/outdooractive?${qs}`)
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        if (data?.provider === "outdooractive") {
          const tours = Array.isArray(data.tours) ? data.tours : [];
          // Demo OA examples only when allowDemoContent; live tours always.
          setOaTours(
            allowDemoContent()
              ? tours
              : tours.filter((t: OutdooractiveTour) => t.source !== "demo")
          );
          setOaAttr(data.attribution ?? null);
          // Unconfigured / demo warnings — fail-closed unless debug UI on.
          setOaWarning(
            showRoutingDebugUi() || allowDemoContent()
              ? (data.warning ?? null)
              : null
          );
        }
      })
      .catch(() => undefined);

    const tfQs = new URLSearchParams({
      lat: String(lat),
      lon: String(lng),
    });
    void fetch(`/api/trailforks?${tfQs}`)
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        setTfPins(Array.isArray(data.pins) ? data.pins : []);
        const disc = data.disclaimer ?? null;
        // Beispiel-Pin / partnership-pending chrome only with debug or demo.
        const isDemoChrome =
          typeof disc === "string" &&
          (disc.includes("Beispiel") || disc.includes("ausstehend"));
        setTfDisclaimer(
          !disc || !isDemoChrome || showRoutingDebugUi() || allowDemoContent()
            ? disc
            : null
        );
      })
      .catch(() => undefined);

    return () => {
      cancelled = true;
    };
  }, [userPos, mapCenter]);

  const refreshQuick = useCallback(
    async (opts?: { force?: boolean; limit?: number }) => {
      quickAbortRef.current?.abort();
      if (quickTimeoutRef.current) clearTimeout(quickTimeoutRef.current);
      const ac = new AbortController();
      quickAbortRef.current = ac;
      setQuickBusy(true);
      setQuickTimedOut(false);
      setRoutingMsg(null);
      let timedOut = false;
      quickTimeoutRef.current = setTimeout(() => {
        timedOut = true;
        ac.abort();
        setQuickBusy(false);
        setQuickTimedOut(true);
        setRoutingMsg(
          "Berechnung zu langsam — ~60-Min Seeds unten, oder erneut versuchen."
        );
      }, QUICK_TIMEOUT_MS);
      try {
        const { options, rateLimited, fromCache } = await computeQuickOptions(
          origin,
          activeProfile,
          minutes,
          {
            limit: opts?.limit ?? 1,
            force: opts?.force,
            signal: ac.signal,
            allowApprox: true,
          }
        );
        if (timedOut || ac.signal.aborted) return;
        setQuickOptions(options);
        setQuickRateLimited(rateLimited);
        if (!options.length) {
          setQuickTimedOut(true);
          setRoutingMsg(
            "Keine Quick-Routen — Seeds unten oder Planer nutzen."
          );
        } else {
          if (rateLimited) {
            setRoutingMsg(
              "Routing-Limit erreicht — Näherungen angezeigt. Später neu berechnen."
            );
          } else if (fromCache) {
            setRoutingMsg(null);
          }
          setDraft((d) => ({
            ...setStart(
              { ...d, mode: "quick" as PlanMode, profile: activeProfile },
              origin,
              "Hier"
            ),
            computed: options[0].result,
            label: options[0].label,
          }));
          setPreviewTour(null);
        }
      } catch {
        if (!timedOut) {
          setQuickTimedOut(true);
          setRoutingMsg(
            "Quick-Routing fehlgeschlagen — Seeds unten, oder erneut versuchen."
          );
        }
      } finally {
        if (quickTimeoutRef.current) {
          clearTimeout(quickTimeoutRef.current);
          quickTimeoutRef.current = null;
        }
        if (!timedOut) setQuickBusy(false);
      }
    },
    [origin, activeProfile, minutes]
  );

  useEffect(() => {
    if (sheetMode !== "quick") return;
    if (quickDebounceRef.current) clearTimeout(quickDebounceRef.current);
    quickDebounceRef.current = setTimeout(() => {
      void refreshQuick({ limit: 1 });
    }, 600);
    return () => {
      if (quickDebounceRef.current) clearTimeout(quickDebounceRef.current);
      quickAbortRef.current?.abort();
    };
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
    async (r: RouteSuggestion) => {
      try {
        const res = await fetch(
          `/api/tours/geometry?id=${encodeURIComponent(r.id)}`
        );
        if (res.ok) {
          const j = await res.json();
          if (j?.geometry?.coordinates?.length >= 2) {
            setActiveRoute(
              activeRouteFromSuggestion(r, j.geometry, j.steps)
            );
            router.push("/ride");
            return;
          }
        }
      } catch {
        /* pin-only */
      }
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
    const distanceKm =
      Math.round((draft.computed.distanceM / 1000) * 10) / 10;
    // Real/sanitized seed ascent only — never invent hm from geometry/distance.
    const elevationM =
      sanitizeElevationM(draft.baseTour?.elevationM, distanceKm) ?? 0;
    const entry: SavedRoute = {
      id,
      name: draft.label || draft.baseTour?.name || "Geplante Route",
      distanceKm,
      elevationM,
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
      layers: draft.layers
        ? {
            approach: draft.layers.approach,
            tour: draft.layers.tour,
            trail: draft.layers.trail,
          }
        : undefined,
    };
    saveRoute(entry);
  }, [draft, saveRoute]);

  const importGpxFile = useCallback(
    async (file: File | null) => {
      if (!file) return;
      const text = await file.text();
      const parsed = parseGpx(text, file.name.replace(/\.gpx$/i, ""));
      if (!parsed) {
        setRoutingMsg("GPX ungültig oder zu wenige Punkte");
        return;
      }
      const entry: SavedRoute = {
        id: `import-${Date.now()}`,
        name: parsed.name,
        distanceKm: Math.round(parsed.distanceKm * 10) / 10,
        elevationM: Math.round(parsed.elevationM),
        durationMin: parsed.durationMin,
        savedAt: new Date().toISOString(),
        source: "import",
        geometry: {
          type: "LineString",
          coordinates: parsed.coordinates,
        },
      };
      saveRoute(entry);
      setSheetMode("tours");
      setRoutingMsg(
        `GPX importiert: ${parsed.name} · ${parsed.distanceKm.toFixed(1)} km`
      );
    },
    [saveRoute]
  );

  const searchAddress = useCallback(async () => {
    const q = addrQuery.trim();
    if (q.length < 2) {
      setAddrHits([]);
      return;
    }
    setAddrBusy(true);
    try {
      const [lon, lat] = userPos ?? mapCenter;
      const res = await fetch(
        `/api/geocode?q=${encodeURIComponent(q)}&limit=5&lat=${lat}&lon=${lon}`
      );
      const data = (await res.json()) as {
        hits?: { label: string; lat: number; lng: number }[];
        error?: string;
      };
      if (!res.ok) {
        setAddrHits([]);
        setRoutingMsg(data.error ?? `Adresssuche fehlgeschlagen (${res.status})`);
        return;
      }
      setAddrHits(data.hits ?? []);
      if (!data.hits?.length) setRoutingMsg(`Keine Treffer für „${q}“`);
    } catch {
      setRoutingMsg("Adresssuche fehlgeschlagen");
    } finally {
      setAddrBusy(false);
    }
  }, [addrQuery, userPos, mapCenter]);

  useEffect(() => {
    if (addrQuery.trim().length < 2) {
      setAddrHits([]);
      return;
    }
    const t = window.setTimeout(() => {
      void searchAddress();
    }, 350);
    return () => window.clearTimeout(t);
  }, [addrQuery, searchAddress]);

  const loadSavedRoute = useCallback(
    (r: SavedRoute) => {
      if (r.geometry) {
        const profile = activeProfile;
        const waypoints =
          r.waypoints?.map((w, i) => ({
            id: `${w.role}-${i}`,
            role: w.role,
            lngLat: w.lngLat,
            label: w.label,
          })) ?? [];
        setDraft({
          mode: r.layers?.approach || r.layers?.tour || r.layers?.trail
            ? "hybrid"
            : waypoints.length >= 2
              ? "point_to_point"
              : "tour",
          profile,
          waypoints,
          computed: {
            distanceM: r.distanceKm * 1000,
            durationS: r.durationMin * 60,
            geometry: r.geometry,
            engine: "saved",
            profile,
          },
          label: r.name,
          layers: r.layers,
        });
        setSheetMode("plan");
        setPreviewTour(null);
        setRoutingMsg("Gespeicherte Route geladen");
        return;
      }
      const suggestion = getSuggestionById(r.id, {
        bike: activeBike,
        categoryHint,
        profile,
        availableMinutes: minutes,
        rangeKmHigh: range?.kmHigh,
      });
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
          geometry: null,
          source: "suggestion",
          setAt: new Date().toISOString(),
        });
        router.push("/ride");
      }
    },
    [
      activeBike,
      activeProfile,
      categoryHint,
      minutes,
      profile,
      range?.kmHigh,
      router,
      setActiveRoute,
      startWithSuggestion,
    ]
  );

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
        layers: undefined,
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
    const pin =
      tour.center ??
      (tour.geometry?.coordinates[0] as [number, number] | undefined) ??
      origin;
    if (!tour.geometry || tour.geometry.coordinates.length < 2) {
      setDraft({
        mode: "tour",
        profile: activeProfile,
        waypoints: [
          {
            id: "start",
            role: "start",
            lngLat: pin,
            label: "Tour-Ort",
          },
        ],
        baseTour: tour,
        hybrid: { strategy: "adopt" },
        computed: null,
        label: `${tour.name} (Idee)`,
        layers: undefined,
      });
      setMapCenter(pin);
      setRoutingMsg(
        "Nur Ortspunkt — kein Track. In Planen + Ziel oder Live-Routing."
      );
      return;
    }
    const adopted = adoptTour(tour, activeProfile);
    setDraft({
      mode: "tour",
      profile: activeProfile,
      waypoints: [
        {
          id: "start",
          role: "start",
          lngLat: (tour.geometry.coordinates[0] as [number, number]) ?? origin,
          label: "Tour-Start",
        },
      ],
      baseTour: tour,
      hybrid: { strategy: "adopt" },
      computed: adopted,
      label: tour.name,
      layers: { tour: adopted.geometry },
    });
    if (tour.center) setMapCenter(tour.center);
    setRoutingMsg(null);
  };

  const adoptIntoPlanMode = (tour: BaseTour) => {
    const coords = (tour.geometry?.coordinates ?? []) as [number, number][];
    const pin = tour.center ?? origin;
    if (coords.length < 2) {
      setPreviewTour(null);
      setDraft({
        mode: "point_to_point",
        profile: activeProfile,
        waypoints: [
          {
            id: "start",
            role: "start",
            lngLat: pin,
            label: "Tour-Ort",
          },
        ],
        computed: null,
        label: `${tour.name} (Plan)`,
        baseTour: tour,
        hybrid: undefined,
        layers: undefined,
      });
      setSheetMode("plan");
      setMapCenter(pin);
      setRoutingMsg(
        `In Planen: ${tour.name} — Ziel setzen, dann Route berechnen (kein Track).`
      );
      return;
    }
    const startLngLat = coords[0] as [number, number];
    const endLngLat = coords[coords.length - 1] as [number, number];
    const adopted = adoptTour(tour, activeProfile);
    setPreviewTour(null);
    setDraft({
      mode: "point_to_point",
      profile: activeProfile,
      waypoints: [
        {
          id: "start",
          role: "start",
          lngLat: startLngLat,
          label: "Tour-Start",
        },
        {
          id: "end",
          role: "end",
          lngLat: endLngLat,
          label: "Tour-Ende",
        },
      ],
      computed: adopted,
      label: `${tour.name} (Plan)`,
      baseTour: undefined,
      hybrid: undefined,
      layers: undefined,
    });
    setSheetMode("plan");
    setRoutingMsg(`In Planen: ${tour.name} — Start/Ziel editierbar`);
    if (tour.center) setMapCenter(tour.center);
  };

  const runHybridSnap = async (tour: BaseTour) => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const parts = await snapToTourParts(origin, tour, activeProfile);
      if (!parts) {
        setRoutingMsg("Hybrid-Snap fehlgeschlagen");
        return;
      }
      const { merged: result, approach, tour: tourPart } = parts;
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
        layers: {
          approach: approach?.geometry,
          tour: tourPart.geometry,
        },
      });
      setRoutingMsg(
        `Hybrid · ${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min`
      );
      setSheetMode("tours");
    } finally {
      setRoutingBusy(false);
    }
  };

  const attachTrail = async (
    trail: TrailSegment,
    mode: "append" | "via_chain"
  ) => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const next = await attachTrailToDraft(draft, trail, mode, origin);
      if (!next) {
        setRoutingMsg("Trail konnte nicht verbunden werden");
        return;
      }
      setDraft(next);
      setSelectedTrailId(trail.id);
      setRoutingMsg(
        next.computed
          ? `${trail.name} · ${(next.computed.distanceM / 1000).toFixed(1)} km`
          : `${trail.name} eingefügt`
      );
    } finally {
      setRoutingBusy(false);
    }
  };

  const schedulePlanRecompute = useCallback(
    (nextDraft: PlanDraft) => {
      setDraft(nextDraft);
      if (planDebounceRef.current) clearTimeout(planDebounceRef.current);
      planDebounceRef.current = setTimeout(() => {
        void (async () => {
          if (!startOf(nextDraft) || !endOf(nextDraft)) return;
          setRoutingBusy(true);
          try {
            const result = await computePointToPoint({
              ...nextDraft,
              profile: activeProfile,
            });
            if (result) {
              setDraft((d) => ({
                ...d,
                mode: "point_to_point",
                computed: result,
                label: d.label || "Geplante Route",
                layers: undefined,
              }));
              setRoutingMsg(
                `${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min`
              );
            }
          } finally {
            setRoutingBusy(false);
          }
        })();
      }, 700);
    },
    [activeProfile]
  );

  const applyAddressHit = useCallback(
    (hit: { label: string; lat: number; lng: number }) => {
      const lngLat: [number, number] = [hit.lng, hit.lat];
      setDraft((prev) => {
        const next =
          addrTarget === "end"
            ? setEnd(prev, lngLat, hit.label)
            : setStart(prev, lngLat, hit.label);
        schedulePlanRecompute(next);
        return next;
      });
      setAddrHits([]);
      setAddrQuery(hit.label);
      setMapCenter([hit.lng, hit.lat]);
      setRoutingMsg(`${addrTarget === "end" ? "Ziel" : "Start"}: ${hit.label}`);
    },
    [addrTarget, schedulePlanRecompute]
  );

  const onMapClick = (lngLat: [number, number]) => {
    if (!pickTarget) return;
    setDraft((prev) => {
      let next = prev;
      if (pickTarget === "start") {
        next = setStart(prev, lngLat, "Start (Karte)");
        setMapCenter(lngLat);
      } else if (pickTarget === "end") {
        next = setEnd(prev, lngLat, "Ziel (Karte)");
      } else {
        next = addVia(prev, lngLat);
      }
      schedulePlanRecompute(next);
      return next;
    });
    setPickTarget(null);
    setSheetMode("plan");
  };

  const markers: MapMarker[] = useMemo(() => {
    const m: MapMarker[] = [];
    let viaIdx = 0;
    for (const w of orderedWaypoints(draft)) {
      if (w.role === "start") {
        m.push({ id: w.id, lngLat: w.lngLat, color: "#43A047", label: "S" });
      } else if (w.role === "end") {
        m.push({ id: w.id, lngLat: w.lngLat, color: "#E53935", label: "Z" });
      } else {
        viaIdx += 1;
        m.push({
          id: w.id,
          lngLat: w.lngLat,
          color: "#FFB300",
          label: String(viaIdx),
        });
      }
    }
    const ideaCenter = draft.baseTour?.center;
    const noTrack =
      !draft.baseTour?.geometry ||
      (draft.baseTour.geometry.coordinates?.length ?? 0) < 2;
    if (
      ideaCenter &&
      noTrack &&
      (draft.label?.includes("(Idee)") ||
        draft.label?.includes("(Plan)") ||
        !draft.computed)
    ) {
      const already = m.some(
        (x) =>
          Math.abs(x.lngLat[0] - ideaCenter[0]) < 1e-6 &&
          Math.abs(x.lngLat[1] - ideaCenter[1]) < 1e-6
      );
      if (!already) {
        m.push({
          id: "tour-idea",
          lngLat: ideaCenter,
          color: "#78909C",
          label: "Idee",
        });
      }
    }
    return m;
  }, [draft]);

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
          onStart={() => void startWithSuggestion(detailRoute)}
          onToggleSave={() => toggleSave(detailRoute)}
          onAdoptIntoPlan={() => {
            adoptIntoPlanMode(suggestionToTour(detailRoute));
            closeDetail();
          }}
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
    ? `${(draft.computed.distanceM / 1000).toFixed(1)} km · ${Math.round(draft.computed.durationS / 60)} min`
    : null;
  const debugRoutingNotice = consumerRoutingNotice(routingNotice);

  return (
    <div className="flex min-h-[calc(100dvh-3.5rem)] flex-col lg:h-[calc(100dvh-4rem)] lg:flex-row lg:overflow-hidden">
      {/*
        Desktop: Side-Panel links + Vollkarte rechts (Komoot/RWGPS-Muster).
        Mobile: Karte oben, Panel unten.
      */}
      <aside className="order-2 flex min-h-0 flex-col border-t border-border bg-background lg:order-1 lg:w-[min(26rem,40vw)] lg:shrink-0 lg:border-r lg:border-t-0">
        {/* Dach */}
        <header className="shrink-0 space-y-2 border-b border-border px-4 pb-3 pt-4 lg:pt-5">
          {debugRoutingNotice && (
            <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
              {debugRoutingNotice}
            </p>
          )}
          {heatmapNote && (
            <p className="rounded-lg border border-orange-500/20 bg-orange-500/5 px-2.5 py-1.5 text-[11px] text-text-secondary">
              Beliebt: {heatmapNote}
              {!heatmapConsent && (
                <>
                  {" "}
                  · Eigene Beiträge unter Privatsphäre
                </>
              )}
            </p>
          )}
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1">
              <h1 className="text-xl font-bold tracking-tight">Touren</h1>
              <p className="text-xs text-text-secondary">
                {activeBike
                  ? `${activeBike.name} · ${bikeCategoryLabel(activeBike.category)}`
                  : "MTB · Gravel · Rennrad · City · E-Bike — Bike optional"}
              </p>
            </div>
            <div className="flex shrink-0 flex-col items-end gap-2">
              <BikeChip />
              <button
                type="button"
                onClick={() => {
                  if (userPos) {
                    setMapCenter(userPos);
                    setDraft((d) => setStart(d, userPos, "Meine Position"));
                    setLocationStatus("Standort: GPS");
                    setRoutingMsg("Standort: GPS — Karte zentriert");
                    return;
                  }
                  if (
                    typeof navigator === "undefined" ||
                    !navigator.geolocation
                  ) {
                    focusPlanAddress(
                      "Standort nicht verfügbar — Adresse suchen oder Demo-Stadt wählen"
                    );
                    return;
                  }
                  setLocationStatus("Standort wird ermittelt…");
                  setRoutingMsg("Standort wird ermittelt…");
                  navigator.geolocation.getCurrentPosition(
                    (pos) => {
                      const p: [number, number] = [
                        pos.coords.longitude,
                        pos.coords.latitude,
                      ];
                      setUserPos(p);
                      setMapCenter(p);
                      setDraft((d) => setStart(d, p, "Meine Position"));
                      setLocationStatus("Standort: GPS");
                      setRoutingMsg("Standort: GPS");
                    },
                    () => {
                      focusPlanAddress(
                        "Standort verweigert — Adresse suchen oder Demo-Stadt wählen"
                      );
                    },
                    { timeout: 8000, maximumAge: 30 * 60 * 1000 }
                  );
                }}
                className="flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium text-text-secondary"
                aria-describedby="discover-location-status"
              >
                <Crosshair className="h-3.5 w-3.5" />
                {userPos ? "Hier" : "Ort…"}
              </button>
            </div>
          </div>
          <p
            id="discover-location-status"
            className="text-[11px] text-text-secondary"
            role="status"
            aria-live="polite"
          >
            {locationStatus}
          </p>
          <div className="flex flex-wrap items-center gap-2">
            <label className="flex items-center gap-1.5 rounded-lg bg-surface-elevated px-2 py-1 text-[11px]">
              <span className="text-text-secondary">Zeit</span>
              <input
                type="range"
                min={45}
                max={240}
                step={15}
                value={minutes}
                onChange={(e) => setMinutesLens(Number(e.target.value))}
                className="w-24"
              />
              <span className="font-medium tabular-nums">{minutes} min</span>
            </label>
          </div>
          {/* Sport-Chips — Parität zur Flutter-App */}
          <div className="flex gap-1.5 overflow-x-auto pb-0.5 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {(
              [
                "mtb_allmountain",
                "gravel",
                "road",
                "urban",
                "emtb",
                "ebike",
                "mtb_enduro",
              ] as RoutingProfile[]
            ).map((pid) => {
              const p = ROUTING_PROFILES[pid];
              const selected = activeProfile === pid;
              return (
                <button
                  key={pid}
                  type="button"
                  onClick={() => {
                    setManualProfile(pid);
                    setFilters((f) => ({
                      ...f,
                      sport: sportFilterFromProfile(pid),
                    }));
                  }}
                  className={`shrink-0 rounded-full border px-2.5 py-1 text-[11px] font-semibold transition ${
                    selected
                      ? "border-accent bg-accent/15 text-accent"
                      : "border-border bg-surface text-text-secondary hover:border-accent/40"
                  }`}
                >
                  {p.label}
                </button>
              );
            })}
          </div>
        </header>

        <div className="grid shrink-0 grid-cols-3 gap-1 border-b border-border p-2">
          {(
            [
              ["quick", "In der Nähe", Zap],
              ["plan", "Planen", Navigation],
              ["tours", "Katalog", Route],
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

        <div className="max-h-[38vh] min-h-0 flex-1 overflow-y-auto px-3 pb-4 pt-2 lg:max-h-none">
          {routingMsg && (
            <p className="mb-2 text-[11px] text-text-secondary">{routingMsg}</p>
          )}

          {sheetMode === "quick" && (
            <div className="flex flex-col gap-2">
              <div className="rounded-xl border border-accent/25 bg-accent/5 p-3">
                <p className="text-xs font-semibold text-foreground">
                  In deiner Nähe · {ROUTING_PROFILES[activeProfile].label}
                </p>
                <p className="mt-0.5 text-[11px] text-text-secondary">
                  Live-Route ab Standort oder Kartenmitte — MTB, Gravel, Rennrad,
                  City oder E-Bike.
                </p>
                <div className="mt-2">
                  <NearMeRouteCard
                    center={userPos ?? mapCenter}
                    profile={activeProfile}
                    defaultKm={Math.max(10, Math.round(minutes / 4))}
                  />
                </div>
              </div>
              <p className="text-[11px] text-text-secondary">
                Vorschläge · {minutes} min · {ROUTING_PROFILES[activeProfile].label}
              </p>
              {quickBusy && (
                <p className="text-sm text-text-secondary" role="status">
                  Berechne…
                </p>
              )}
              {quickTimedOut && !quickBusy && (
                <div className="rounded-xl border border-border bg-surface-elevated p-3 text-sm text-text-secondary">
                  <p>
                    Live-Vorschläge nicht rechtzeitig — Seeds bleiben sichtbar.
                  </p>
                  <button
                    type="button"
                    className="mt-2 text-xs font-semibold text-accent"
                    onClick={() => void refreshQuick({ force: true, limit: 1 })}
                  >
                    Erneut versuchen
                  </button>
                </div>
              )}
              {!quickBusy && !quickTimedOut && quickOptions.length === 0 && (
                <div className="rounded-xl border border-border p-4 text-center text-sm text-text-secondary">
                  Keine Live-Vorschläge — Seeds unten, Standort erlauben oder{" "}
                  <button
                    type="button"
                    className="font-medium text-accent"
                    onClick={() =>
                      focusPlanAddress("Adresse suchen — Start setzen")
                    }
                  >
                    Planen öffnen
                  </button>
                </div>
              )}
              <div className="flex gap-2 overflow-x-auto pb-1">
                {quickOptions.map((q) => {
                  const distKm =
                    Math.round((q.result.distanceM / 1000) * 10) / 10;
                  return (
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
                        {/* No synthetic hm from distance/geometry */}
                        {formatDistanceElevation(distKm, null)} ·{" "}
                        {Math.round(q.result.durationS / 60)} min
                      </div>
                      <div className="mt-1 text-[10px] text-text-secondary">
                        {q.reason}
                      </div>
                    </button>
                  );
                })}
              </div>
              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={quickBusy}
                  onClick={() => void refreshQuick({ force: true, limit: 1 })}
                  className="flex-1 rounded-xl border border-border py-2 text-xs font-medium"
                >
                  Neu berechnen
                </button>
                {quickOptions.length < 3 && (
                  <button
                    type="button"
                    disabled={quickBusy || quickRateLimited}
                    onClick={() =>
                      void refreshQuick({
                        limit: Math.min(3, Math.max(1, quickOptions.length) + 1),
                      })
                    }
                    className="flex-1 rounded-xl border border-border py-2 text-xs font-medium disabled:opacity-40"
                  >
                    Weitere Option
                  </button>
                )}
              </div>
              {quickRateLimited && (
                <p className="text-[11px] text-warning">
                  GraphHopper-Minutenlimit — warte kurz oder nutze den Planer
                  sparsam.
                </p>
              )}

              {/* Always-on ~60 Min — #35 curated P0 Berlin/RN + honest loops only */}
              <h3 className="mt-3 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                ~60 Min Rundkurse
              </h3>
              <p className="text-[11px] text-text-secondary">
                Tempelhofer, Rhein-Neckar & kuratierte Feierabend-Loops —
                unabhängig vom Live-Routing.
              </p>
              {hasUsefulNearbyLoops ? (
                <div className="flex flex-col gap-2">
                  {sixtyMinLoops.map((r) => (
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
                          void startWithSuggestion(r);
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
                          className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                          onClick={() =>
                            adoptIntoPlanMode(suggestionToTour(r))
                          }
                        >
                          In Planen
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="mt-2 rounded-xl border border-border bg-surface-elevated p-3">
                  <p className="text-xs font-semibold text-foreground">
                    Keine Rundkurse in der Nähe
                  </p>
                  <p className="mt-0.5 text-[11px] text-text-secondary">
                    Keine ehrlichen Loops (Start≈Ziel) hier — Demo-Stadt wählen
                    oder Ort ändern. Keine A→B-Touren als Füllung.
                  </p>
                  <button
                    type="button"
                    className="mt-2 w-full rounded-lg bg-accent py-2 text-xs font-semibold text-white"
                    onClick={() =>
                      focusPlanAddress("Ort ändern — Stadt oder Adresse suchen")
                    }
                  >
                    Ort ändern
                  </button>
                  <p className="mt-2 text-[11px] font-semibold text-text-secondary">
                    Demo-Stadt
                  </p>
                  <div className="mt-1.5 flex flex-wrap gap-1.5">
                    {DEMO_CITY_CHIPS.map((c) => (
                      <button
                        key={c.name}
                        type="button"
                        onClick={() => applyDemoCity(c.name, c.lat, c.lng)}
                        className="rounded-lg border border-border bg-surface px-2.5 py-1 text-[11px] font-medium"
                      >
                        {c.name}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {sheetMode === "plan" && (
            <div className="flex flex-col gap-3">
              <p className="text-[11px] text-text-secondary">
                Adresse suchen oder auf die Karte tippen
              </p>
              <div className="flex gap-2">
                <select
                  value={addrTarget}
                  onChange={(e) =>
                    setAddrTarget(e.target.value as "start" | "end")
                  }
                  className="rounded-lg border border-border bg-surface-elevated px-2 text-xs"
                >
                  <option value="start">Start</option>
                  <option value="end">Ziel</option>
                </select>
                <input
                  ref={addrInputRef}
                  value={addrQuery}
                  onChange={(e) => setAddrQuery(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") void searchAddress();
                  }}
                  aria-label={
                    addrTarget === "end" ? "Ziel-Adresse" : "Start-Adresse"
                  }
                  placeholder="z. B. Wiesloch"
                  className="min-w-0 flex-1 rounded-lg border border-border bg-surface-elevated px-2 py-1.5 text-xs"
                />
                <button
                  type="button"
                  disabled={addrBusy}
                  onClick={() => void searchAddress()}
                  className="rounded-lg border border-border px-2 text-xs font-medium"
                >
                  Suchen
                </button>
              </div>
              {addrHits.length > 0 && (
                <ul className="max-h-28 overflow-auto rounded-lg border border-border">
                  {addrHits.map((h) => (
                    <li key={`${h.label}-${h.lat}`}>
                      <button
                        type="button"
                        className="w-full px-2 py-1.5 text-left text-[11px] hover:bg-surface-elevated"
                        onClick={() => applyAddressHit(h)}
                      >
                        {h.label}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              <div className="grid grid-cols-3 gap-2">
                <button
                  type="button"
                  onClick={() => setPickTarget("start")}
                  className={`rounded-xl border px-2 py-2 text-left text-[11px] ${
                    pickTarget === "start"
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  Start tippen
                </button>
                <button
                  type="button"
                  onClick={() => setPickTarget("via")}
                  className={`rounded-xl border px-2 py-2 text-left text-[11px] ${
                    pickTarget === "via"
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  + Via
                </button>
                <button
                  type="button"
                  onClick={() => setPickTarget("end")}
                  className={`rounded-xl border px-2 py-2 text-left text-[11px] ${
                    pickTarget === "end"
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  Ziel tippen
                </button>
              </div>
              <ul className="flex flex-col gap-1.5">
                {orderedWaypoints(draft).map((w, i) => (
                  <li
                    key={w.id}
                    className="flex items-center justify-between rounded-lg border border-border px-2.5 py-1.5 text-xs"
                  >
                    <span>
                      {w.role === "start"
                        ? "S"
                        : w.role === "end"
                          ? "Z"
                          : i}
                      {" · "}
                      {w.label ?? w.role} · {w.lngLat[1].toFixed(3)},{" "}
                      {w.lngLat[0].toFixed(3)}
                    </span>
                    {w.role === "via" && (
                      <button
                        type="button"
                        className="text-text-secondary"
                        onClick={() =>
                          schedulePlanRecompute(removeWaypoint(draft, w.id))
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
                onClick={() => {
                  if (userPos) {
                    schedulePlanRecompute(
                      setStart(draft, userPos, "Meine Position")
                    );
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
              <div className="flex items-center justify-between gap-2">
                <h3 className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
                  Wege in der Nähe
                </h3>
                <label className="flex items-center gap-1.5 text-[11px] text-text-secondary">
                  <input
                    type="checkbox"
                    checked={showTrails}
                    onChange={(e) => setShowTrails(e.target.checked)}
                  />
                  Overlay
                </label>
              </div>
              {nearbyTrails.length === 0 ? (
                <p className="text-[11px] text-text-secondary">
                  Keine OSM-Wege hier — Karte verschieben oder unter „In der Nähe“
                  eine Live-Route bauen.
                </p>
              ) : (
                nearbyTrails.map((t) => (
                  <article
                    key={t.id}
                    className={`rounded-xl border p-3 ${
                      selectedTrailId === t.id
                        ? "border-accent bg-accent/10"
                        : "border-border bg-surface"
                    }`}
                  >
                    <div className="text-sm font-medium">{t.name}</div>
                    <p className="text-[11px] text-text-secondary">
                      {t.difficulty ?? "—"} · {t.provider}
                    </p>
                    <div className="mt-2 flex flex-wrap gap-2">
                      <button
                        type="button"
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => {
                          setSelectedTrailId(t.id);
                          setShowTrails(true);
                          setMapCenter(t.center);
                        }}
                      >
                        Anzeigen
                      </button>
                      <button
                        type="button"
                        disabled={routingBusy}
                        className="rounded-lg border border-accent/40 px-2.5 py-1.5 text-[11px] text-accent"
                        onClick={() => void attachTrail(t, "append")}
                      >
                        Anhängen
                      </button>
                      <button
                        type="button"
                        disabled={routingBusy}
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => void attachTrail(t, "via_chain")}
                      >
                        Als Via
                      </button>
                    </div>
                  </article>
                ))
              )}

              <FilterChips
                minutes={minutes}
                onMinutes={setMinutesLens}
                filters={filters}
                onChange={(next) => {
                  setFilters(next);
                  // Disziplin-Chip steuert Routing-Profil (wenn nicht „Alle“)
                  if (next.sport === "road") setManualProfile("road");
                  else if (next.sport === "gravel") setManualProfile("gravel");
                  else if (next.sport === "mtb") setManualProfile("mtb_allmountain");
                  else if (next.sport === "urban") setManualProfile("urban");
                  else if (next.sport === "ebike") setManualProfile("emtb");
                  else if (next.sport === "touring") setManualProfile("ebike");
                  else if (next.sport === "hiking") setManualProfile("hiking");
                }}
                profile={activeProfile}
              />

              {activeBike?.isEbike && range && (
                <div className="rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-xs">
                  Reichweite {range.kmLow}–{range.kmHigh} km
                </div>
              )}

              <h3 className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
                Vom Standort ({nearbyRoutes.length}
                {fartherRoutes.length ? ` · +${fartherRoutes.length} weiter` : ""}
                )
              </h3>
              <p className="text-[11px] text-text-secondary">
                Sortiert nach Nähe zu{" "}
                {userPos ? "deiner Position" : "Kartenmitte"} (
                {origin[1].toFixed(2)}°N, {origin[0].toFixed(2)}°E)
              </p>
              {routes.some((r) => r.id.startsWith("seed-")) &&
                !routes.some((r) => !r.id.startsWith("seed-")) && (
                <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
                  Offline-Fallback: Berlin 60-Min Rundkurse (inkl. Tempelhofer),
                  Katalog leer.
                </p>
              )}
              {filtered.length === 0 ? (
                <div className="rounded-xl border border-border bg-surface-elevated p-3">
                  <p className="text-sm font-semibold text-foreground">
                    {filters.loopOnly
                      ? "Keine Rundkurse in der Nähe"
                      : "Keine Tour bei diesen Filtern"}
                  </p>
                  <p className="mt-0.5 text-xs text-text-secondary">
                    {filters.loopOnly
                      ? "Nur echte Loops (Start≈Ziel) — keine A→B-Touren als Füllung. Filter lockern oder Ort ändern."
                      : "Filter lockern oder Planer öffnen."}
                  </p>
                  {filters.loopOnly && (
                    <button
                      type="button"
                      className="mt-2 rounded-lg border border-border px-3 py-1.5 text-xs font-medium"
                      onClick={() =>
                        setFilters((f) => ({ ...f, loopOnly: false }))
                      }
                    >
                      Rundkurs-Filter aus
                    </button>
                  )}
                </div>
              ) : (
                <>
                  {nearbyRoutes.map((r) => (
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
                          void startWithSuggestion(r);
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
                        <button
                          type="button"
                          className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                          onClick={() =>
                            adoptIntoPlanMode(suggestionToTour(r))
                          }
                        >
                          In Planen
                        </button>
                      </div>
                    </div>
                  ))}
                  {fartherRoutes.length > 0 && (
                    <>
                      <h3 className="mt-3 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                        Weitere Regionen ({fartherRoutes.length})
                      </h3>
                      {fartherRoutes.map((r) => (
                        <div key={r.id} className="space-y-1.5">
                          <RouteCard
                            route={r}
                            highlighted={
                              highlightRouteId === r.id ||
                              previewTour?.id === r.id
                            }
                            saved={isRouteSaved(r.id)}
                            onOpen={() => {
                              previewBaseTour(suggestionToTour(r));
                              openDetail(r.id);
                            }}
                            onStart={() => {
                              previewBaseTour(suggestionToTour(r));
                              void startWithSuggestion(r);
                            }}
                            onToggleSave={() => toggleSave(r)}
                          />
                          <div className="flex gap-2 px-1">
                            <button
                              type="button"
                              className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                              onClick={() =>
                                previewBaseTour(suggestionToTour(r))
                              }
                            >
                              Vorschau
                            </button>
                            <button
                              type="button"
                              disabled={routingBusy}
                              className="flex-1 rounded-lg border border-accent/40 py-1.5 text-[11px] font-medium text-accent"
                              onClick={() =>
                                void runHybridSnap(suggestionToTour(r))
                              }
                            >
                              Von hier
                            </button>
                            <button
                              type="button"
                              className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                              onClick={() =>
                                adoptIntoPlanMode(suggestionToTour(r))
                              }
                            >
                              In Planen
                            </button>
                          </div>
                        </div>
                      ))}
                    </>
                  )}
                </>
              )}

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                <Compass className="h-3.5 w-3.5" /> Outdooractive ({oaTours.length})
              </h3>
              {oaWarning && (
                <p className="text-[11px] text-warning">{oaWarning}</p>
              )}
              {oaTours.length === 0 && (
                <p className="text-[11px] text-text-secondary">
                  Keine OA-Touren in der Kartenregion.
                </p>
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
                        t.source === "demo" ? "Beispiel" : null,
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
                      <button
                        type="button"
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => adoptIntoPlanMode(tour)}
                      >
                        In Planen
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
                <Mountain className="h-3.5 w-3.5" /> Trailforks ({tfPins.length})
              </h3>
              <p className="text-[11px] text-text-secondary">
                {tfDisclaimer ?? "Attribution — kein Geometrie-Mirror."}
              </p>
              {tfPins.map((p) => (
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
              <div className="mb-2 flex flex-wrap gap-2">
                <input
                  ref={gpxInputRef}
                  type="file"
                  accept=".gpx,application/gpx+xml,text/xml"
                  className="hidden"
                  onChange={(e) => {
                    void importGpxFile(e.target.files?.[0] ?? null);
                    e.target.value = "";
                  }}
                />
                <button
                  type="button"
                  onClick={() => gpxInputRef.current?.click()}
                  className="rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium"
                >
                  GPX importieren
                </button>
              </div>
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
                      {formatDistanceElevation(
                        r.distanceKm,
                        sanitizeElevationM(r.elevationM, r.distanceKm)
                      )}{" "}
                      · {r.durationMin} min
                      {r.source === "import" ? " · Import" : ""}
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
                      {routeCollections.length > 0 && (
                        <label className="flex items-center gap-1 text-[11px]">
                          <span className="sr-only">Sammlung</span>
                          <select
                            className="max-w-[7rem] rounded-lg border border-border bg-surface px-1 py-1.5"
                            defaultValue=""
                            onChange={(e) => {
                              const id = e.target.value;
                              if (!id) return;
                              addRouteToCollection(id, r.id);
                              e.target.value = "";
                            }}
                          >
                            <option value="" disabled>
                              + Sammlung
                            </option>
                            {routeCollections.map((c) => (
                              <option key={c.id} value={c.id}>
                                {c.name}
                              </option>
                            ))}
                          </select>
                        </label>
                      )}
                      <button
                        type="button"
                        onClick={() => loadSavedRoute(r)}
                        className="flex flex-1 items-center justify-center gap-1 rounded-lg bg-accent py-1.5 text-[11px] font-semibold text-white"
                      >
                        <Play className="h-3.5 w-3.5 fill-current" /> In App
                      </button>
                    </div>
                  </article>
                ))
              )}

              <h3 className="mt-4 text-xs font-semibold uppercase tracking-wide text-text-secondary">
                Sammlungen
              </h3>
              <p className="mb-2 text-[11px] text-text-secondary">
                Lokale Ordner — kein Social-Feed.
              </p>
              <div className="mb-2 flex gap-2">
                <input
                  value={collectionName}
                  onChange={(e) => setCollectionName(e.target.value)}
                  placeholder="Name"
                  className="flex-1 rounded-lg border border-border bg-surface-elevated px-2 py-1.5 text-xs"
                />
                <button
                  type="button"
                  onClick={() => {
                    createRouteCollection(collectionName);
                    setCollectionName("");
                  }}
                  className="rounded-lg bg-accent px-2.5 py-1.5 text-[11px] font-semibold text-white"
                >
                  Anlegen
                </button>
              </div>
              {routeCollections.length === 0 ? (
                <p className="text-sm text-text-secondary">Noch keine Sammlung.</p>
              ) : (
                routeCollections.map((c) => (
                  <div
                    key={c.id}
                    className="rounded-xl border border-border bg-surface px-3 py-2 text-sm"
                  >
                    <span className="font-semibold">{c.name}</span>
                    <span className="ml-2 text-[11px] text-text-secondary">
                      {c.routeIds.length} Routen
                    </span>
                  </div>
                ))
              )}

              <OfflinePacksPanel className="mt-4" />
            </div>
          )}
        </div>
      </aside>

      {/* Karte — Desktop full height, Mobile oben */}
      <div className="relative order-1 min-h-[42vh] flex-1 lg:order-2 lg:min-h-0">
        <MapView
          className="absolute inset-0 rounded-none"
          center={mapCenter}
          zoom={11}
          routes={mapLayers}
          markers={markers}
          interactiveSelect={pickTarget !== null}
          onMapClick={onMapClick}
          onRouteClick={(id) => {
            if (id.startsWith("alt-")) {
              const qid = id.replace("alt-", "");
              const q = quickOptions.find((x) => x.id === qid);
              if (q) {
                setDraft((d) => ({
                  ...setStart(
                    { ...d, mode: "quick", profile: activeProfile },
                    origin,
                    "Hier"
                  ),
                  computed: q.result,
                  label: q.label,
                  layers: undefined,
                }));
                setSheetMode("quick");
              }
            }
            if (id.startsWith("trail-")) {
              setSelectedTrailId(id.replace("trail-", ""));
              setShowTrails(true);
              setSheetMode("tours");
            }
          }}
          fitRoute={Boolean(draft.computed)}
        />
        {pickTarget && (
          <div className="absolute left-3 right-3 top-3 z-10 rounded-xl bg-black/75 px-3 py-2 text-center text-xs text-white lg:left-auto lg:right-3 lg:max-w-sm">
            Tippe auf die Karte für{" "}
            {pickTarget === "start"
              ? "Start"
              : pickTarget === "end"
                ? "Ziel"
                : "Via"}
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
          <div className="absolute bottom-3 left-3 right-3 z-10 flex items-center justify-between gap-2 rounded-xl bg-black/70 px-3 py-2 text-xs text-white lg:left-auto lg:right-3 lg:max-w-md">
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
                <Play className="h-3.5 w-3.5 fill-current" /> In App
              </button>
            </div>
          </div>
        )}
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
