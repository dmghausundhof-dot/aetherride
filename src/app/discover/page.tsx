"use client";

import { useCallback, useEffect, useMemo, useRef, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
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
import { BikeOverlayLegend } from "@/components/BikeOverlayLegend";
import { BikeChip } from "@/components/BikeChip";
import {
  profileForBikeCategory,
  DEFAULT_DISCOVER_PROFILE,
  isRideProfileId,
  profileLabel,
  discoverNavProfile,
  discoverProfileMenuForSports,
  navSessionForBike,
  sessionCostingForBike,
  suggestedApproachKind,
  approachCostingForBike,
  trailFitsBikeCategory,
  type ClientRouteResult,
  type RoutingProfile,
  type ApproachKind,
} from "@/lib/routing/profiles";
import {
  overlayFamilyForBike,
  overlayExploreAllClasses,
  type BikeOverlayClass,
} from "@/lib/routing/bikeOverlayClass";
import { detailOverlayRegionIdForPoint } from "@/lib/coverage/dachRegions";
import { chooseOnlineBikeOverlay } from "@/lib/map/onlineCycleMesh";
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
import { getPublicTour } from "@/lib/catalog/publicTours";
import {
  DEFAULT_ROUTE_FILTERS,
  filterRouteSuggestions,
  sportFilterFromProfile,
  type RouteFilterState,
  type SportFilter,
} from "@/lib/routing/routeFilters";
import { demoCenterLngLat } from "@/lib/routing/demoGeometry";
import { RouteCard } from "@/components/discover/RouteCard";
import { DiscoverExploreChrome } from "@/components/discover/DiscoverExploreChrome";
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
  adoptTrailToDraft,
  computeQuickOptions,
  emptyDraft,
  endOf,
  orderedWaypoints,
  removeWaypoint,
  resolvePointToPointDraft,
  routeResultMessage,
  setEnd,
  setStart,
  snapToTourParts,
  startOf,
  type BaseTour,
  type PlanDraft,
  type PlanMode,
  type QuickOption,
} from "@/lib/routing/planDraft";
import { snapPointOntoTrails, viaMaySnapOntoTrail } from "@/lib/routing/snapTrailCorridor";
import { normalizePlaceKind } from "@/lib/community/placesMerger";
import { httpsAppLink, rideOpenPath } from "@/lib/web/appLinks";
import {
  fetchEndpointElevations,
  trailAccessHaversineKm,
} from "@/lib/routing/trailAccess";
import { buildDiscoverMapLayers } from "@/lib/routing/discoverMapLayers";
import { type TrailSegment } from "@/lib/routing/trailSegments";
import {
  BIKE_OVERLAY_VECTOR_MAX_ZOOM,
  osmTrailToSegment,
  overlayHitToSegment,
  trailHighwayLabelDe,
  trailSurfaceLabelDe,
  type OverlayWayHit,
} from "@/lib/routing/overlayHit";
import { NearMeRouteCard } from "@/components/explore/NearMeRouteCard";
import { AddRouteForm } from "@/components/library/AddRouteForm";
import {
  isLocalDiscoverZoom,
  isPlaceholderMapCenter,
  resolveAddRouteStart,
  WEB_DISCOVER_FALLBACK,
} from "@/lib/library/addRouteStart";
import {
  readDiscoverViewport,
  writeDiscoverViewport,
} from "@/lib/library/discoverViewport";
import { prefetchTourCommunityCounts } from "@/components/community/TourCommunityChip";
import {
  DEMO_CITY_CHIPS,
} from "@/lib/discover/berlinLoops";
import {
  curatedP0CatalogSuggestions,
  curatedSixtyMinLoopSuggestions,
} from "@/lib/discover/curatedP0Seeds";
import {
  pickNearbyThenFill,
  TOUR_COVERAGE_NEARBY_KM,
} from "@/lib/discover/tourCoverage";
import {
  filterHonestLoopSuggestions,
  isOutAndBackQuickOption,
  sanitizeDraftForRundkurs,
} from "@/lib/discover/loopHonesty";
import {
  aroundKmDisplay,
  countActiveRouteFilters,
  matchesExploreQuery,
} from "@/lib/discover/discoverExploreChrome";
import { RideOutChoice } from "@/components/discover/RideOutChoice";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";
import {
  DISCOVER_PIN_DE,
  DISCOVER_STATUS_DE,
  discoverDraftLabel,
  discoverHighwayLabel,
  discoverPinLabel,
  discoverStatus,
  discoverSurfaceLabel,
  discoverUi,
} from "@/lib/i18n/discoverUi";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import {
  filterSavedByVisibility,
  visibilityOf,
} from "@/lib/tours/routeVisibility";

type SheetMode = "quick" | "plan" | "tours";

const FALLBACK_CENTER: [number, number] = WEB_DISCOVER_FALLBACK;
/** Abort stuck „Berechne…“ so Quick always recovers to seeds + retry. */
const QUICK_TIMEOUT_MS = 5000;
/** Seeds beyond this are „not useful nearby“ → Demo-Stadt chips (Coverage füllt). */
const USEFUL_LOOP_RADIUS_KM = TOUR_COVERAGE_NEARBY_KM;

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
  const copy = useHofCopy();
  const lang = useChromeLang();
  const d = discoverUi(lang);
  const chrome = webChrome(lang);

  const router = useRouter();
  const searchParams = useSearchParams();
  const highlightRouteId = searchParams.get("route");
  const tourParam = searchParams.get("tour");
  const sportParam = searchParams.get("sport") as SportFilter | null;
  const latParam = searchParams.get("lat");
  const lngParam = searchParams.get("lng");
  const minutesParam = searchParams.get("minutes");
  const lensParam = searchParams.get("lens");
  const modeParam = searchParams.get("mode");
  const sheetParam = searchParams.get("sheet");
  const panelParam = searchParams.get("panel");
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
  const preferredSport = useAppStore((s) => s.preferredSport);
  const preferredSports = useAppStore((s) => s.preferredSports);
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
      ? DISCOVER_STATUS_DE.locDeep
      : DISCOVER_STATUS_DE.locWaitOrTap
  );

  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const routingProfile = useMemo(
    () =>
      discoverNavProfile(
        activeBike
          ? profileForBikeCategory(activeBike.category)
          : DEFAULT_DISCOVER_PROFILE
      ),
    [activeBike]
  );
  const garageSession = navSessionForBike(activeBike?.category ?? "");

  const [sheetMode, setSheetMode] = useState<SheetMode>("quick");
  const [rideOutChoice, setRideOutChoice] = useState(
    () => modeParam === "rideOut"
  );
  const [justRide, setJustRide] = useState(false);
  const [minutes, setMinutes] = useState(
    () => queryMinutes ?? 60
  );
  const [filters, setFilters] = useState<RouteFilterState>(() => ({
    ...DEFAULT_ROUTE_FILTERS,
    // D-60-LOOP-FILTER-01 (web): ~60 lens = Rundkurs honesty.
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
  const mappeRoutes = useMemo(
    () =>
      filterSavedByVisibility(savedRoutes, filters.visibility ?? "all_mine"),
    [savedRoutes, filters.visibility]
  );
  const [detailId, setDetailId] = useState<string | null>(highlightRouteId);
  const [userPos, setUserPos] = useState<[number, number] | null>(null);
  const [mapCenter, setMapCenter] = useState<[number, number]>(
    () => queryCenter ?? FALLBACK_CENTER
  );
  /** GPS/Hier: Karte auf Standort halten — kein Fit auf Tour-Start. */
  const [holdMapFit, setHoldMapFit] = useState(false);
  const [mapZoom, setMapZoom] = useState(13);
  const bikeOverlaySpec = useMemo(() => {
    const env = process.env.NEXT_PUBLIC_BIKE_OVERLAY_URL?.trim();
    if (env) {
      const kind = env.includes(".geojson") ? "geojson" : "pmtiles";
      return {
        url: env,
        kind: kind as "pmtiles" | "geojson",
        overlayKind: "ways" as const,
      };
    }
    const [lng, lat] = mapCenter;
    const choice = chooseOnlineBikeOverlay({
      regionId: detailOverlayRegionIdForPoint(lng, lat),
      lng,
      lat,
      zoom: mapZoom,
    });
    if (!choice.url) return null;
    return {
      url: choice.url,
      kind: "pmtiles" as const,
      overlayKind: choice.kind === "ways" ? ("ways" as const) : ("mesh" as const),
    };
  }, [mapCenter, mapZoom]);
  const [draft, setDraft] = useState<PlanDraft>(() =>
    emptyDraft(
      routingProfile,
      queryCenter ?? FALLBACK_CENTER
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
  /** NearMe dropdown — Rundkurs suppresses out-and-back Quick pads. */
  const [nearMeRouteMode, setNearMeRouteMode] = useState<
    "loop" | "point_to_point"
  >("loop");
  const quickAbortRef = useRef<AbortController | null>(null);
  const quickDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const quickTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [previewTour, setPreviewTour] = useState<BaseTour | null>(null);
  const [oaTours, setOaTours] = useState<OutdooractiveTour[]>([]);
  const [oaAttr, setOaAttr] = useState<string | null>(null);
  const [oaWarning, setOaWarning] = useState<string | null>(null);
  const [tfPins, setTfPins] = useState<TrailforksPin[]>([]);
  const [tfDisclaimer, setTfDisclaimer] = useState<string | null>(null);
  const [googlePlaces, setGooglePlaces] = useState<
    Array<{
      id: string;
      name: string;
      kind: string;
      lat: number;
      lng: number;
      mapsUrl: string;
    }>
  >([]);
  const [googlePlacesWarning, setGooglePlacesWarning] = useState<string | null>(
    null
  );
  const [valhallaLive, setValhallaLive] = useState(false);
  const [lastSavedId, setLastSavedId] = useState<string | null>(null);
  const [manualProfile, setManualProfile] = useState<RoutingProfile | null>(
    null
  );
  const [exploreQuery, setExploreQuery] = useState("");
  const [showTrails, setShowTrails] = useState(true);
  const [bikeOverlayOn, setBikeOverlayOn] = useState(true);
  const [bikeOverlayExtra, setBikeOverlayExtra] = useState<BikeOverlayClass[]>(
    () => [...overlayExploreAllClasses]
  );
  const [selectedTrailId, setSelectedTrailId] = useState<string | null>(null);
  const [liveOsmTrails, setLiveOsmTrails] = useState<TrailSegment[]>([]);
  const [liveOsmStatus, setLiveOsmStatus] = useState<
    "idle" | "loading" | "empty" | "error"
  >("idle");
  const [overlaySheet, setOverlaySheet] = useState<TrailSegment | null>(null);
  const [routingNotice, setRoutingNotice] = useState<string | null>(null);
  const [communityHeat, setCommunityHeat] = useState<HeatmapResult | null>(
    null
  );
  const [heatmapNote, setHeatmapNote] = useState<string | null>(null);
  const planDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const activeProfile = discoverNavProfile(manualProfile ?? routingProfile);
  const planCosting = sessionCostingForBike(activeBike?.category, activeProfile);
  const categoryHint = categoryForRoutingProfile(activeProfile);
  const rideProfileId = isRideProfileId(activeProfile) ? activeProfile : null;
  // Overlay-Familie folgt dem Navi-Profil (Chip nur bei ≥2, sonst Filter-Sheet).
  const bikeOverlayFamily = overlayFamilyForBike(activeProfile);
  const navProfileMenu = useMemo(
    () =>
      discoverProfileMenuForSports({
        primary: preferredSport ?? activeBike?.category ?? null,
        sports: [...preferredSports, ...bikes.map((b) => b.category)],
      }),
    [preferredSport, preferredSports, activeBike, bikes]
  );
  const activeFilterCount = countActiveRouteFilters(filters, minutes);
  const aroundKm = aroundKmDisplay(filters.maxDistanceKm);

  const applyRouteFilters = useCallback(
    (next: RouteFilterState) => {
      setFilters(next);
      if (next.sport === filters.sport) return;
      if (next.sport === "road") setManualProfile("road");
      else if (next.sport === "gravel") setManualProfile("gravel");
      else if (next.sport === "mtb") {
        if (
          activeProfile === "mtb_allmountain" ||
          activeProfile === "emtb"
        ) {
          return;
        }
        setManualProfile("mtb_allmountain");
      } else if (next.sport === "urban") setManualProfile("urban");
      else if (next.sport === "ebike") setManualProfile("emtb");
      else if (next.sport === "touring") setManualProfile("ebike");
      else if (next.sport === "hiking") setManualProfile("hiking");
    },
    [filters.sport, activeProfile]
  );

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
            showRoutingDebugUi() ? DISCOVER_STATUS_DE.heatmapOffline : null
          );
          return;
        }
        setCommunityHeat(r);
        setHeatmapNote(
          showRoutingDebugUi()
            ? r.coldStart
              ? r.disclaimer
              : `${d.heatSegments(r.segments.length)} · ${r.disclaimer}`
            : r.coldStart
              ? null
              : d.heatSegments(r.segments.length)
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
  const addRouteStart = useMemo(() => {
    const persisted = readDiscoverViewport()?.lngLat ?? null;
    const map =
      isLocalDiscoverZoom(mapZoom) && !isPlaceholderMapCenter(mapCenter)
        ? mapCenter
        : persisted;
    return resolveAddRouteStart({ gps: userPos, map });
  }, [userPos, mapCenter, mapZoom]);

  /** Rundkurs lens or NearMe Route=Rundkurs → honesty on ALL sources. */
  const rundkursActive = filters.loopOnly || nearMeRouteMode === "loop";
  const suppressOutAndBackQuick = rundkursActive;

  const routes = useMemo(() => {
    const catalog = listAllRouteSuggestions({
      bike: activeBike,
      categoryHint,
      profile,
      availableMinutes: minutes,
      rangeKmHigh: range?.kmHigh,
      near: origin,
    });
    const curated = curatedP0CatalogSuggestions(origin);
    const byId = new Map<string, RouteSuggestion>();
    for (const r of [...catalog, ...curated]) {
      if (!byId.has(r.id)) byId.set(r.id, r);
    }
    const base = [...byId.values()];
    return rundkursActive ? filterHonestLoopSuggestions(base) : base;
  }, [
    activeBike,
    categoryHint,
    profile,
    minutes,
    range,
    origin,
    rundkursActive,
  ]);

  const honestyFilters = useMemo(
    () => ({
      ...filters,
      loopOnly: rundkursActive ? true : filters.loopOnly,
    }),
    [filters, rundkursActive]
  );

  const filtered = useMemo(
    () =>
      filterRouteSuggestions(routes, honestyFilters).filter((r) =>
        matchesExploreQuery(r, exploreQuery)
      ),
    [routes, honestyFilters, exploreQuery]
  );

  /**
   * D-60-LOOP-FILTER-01: ~60 Min Rundkurse rail — same loopHonesty as filter
   * (is_loop / start≈end ≤300 m; never Spree Alltagsrunde / A→B badge).
   */
  const sixtyMinLoops = useMemo(() => {
    const curated = curatedSixtyMinLoopSuggestions(origin);
    const fromCatalog = routes.filter(
      (r) => r.durationMin >= 45 && r.durationMin <= 75
    );
    const byId = new Map<string, (typeof curated)[number]>();
    for (const r of [...curated, ...fromCatalog]) {
      if (!byId.has(r.id)) byId.set(r.id, r);
    }
    return pickNearbyThenFill(
      filterHonestLoopSuggestions([...byId.values()])
        .filter((r) => r.loop === true),
      (r) => r.distanceFromOriginKm ?? 9999,
      { nearbyKm: USEFUL_LOOP_RADIUS_KM }
    );
  }, [origin, routes]);
  const hasUsefulNearbyLoops = sixtyMinLoops.length > 0;

  const nearbyRoutes = useMemo(
    () =>
      pickNearbyThenFill(
        filtered,
        (r) => r.distanceFromOriginKm ?? 9999,
        { nearbyKm: 120 }
      ),
    [filtered]
  );
  const fartherRoutes = useMemo(() => {
    const ids = new Set(nearbyRoutes.map((r) => r.id));
    return filtered.filter((r) => !ids.has(r.id)).slice(0, 8);
  }, [filtered, nearbyRoutes]);

  useEffect(() => {
    void prefetchTourCommunityCounts(
      [...nearbyRoutes, ...sixtyMinLoops].map((r) => r.id)
    );
  }, [nearbyRoutes, sixtyMinLoops]);

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

  const nearbyTrails = liveOsmTrails;
  const overlayActive = Boolean(bikeOverlaySpec && bikeOverlayOn);
  const trailsForMap = useMemo(() => {
    const wantWays = bikeOverlaySpec ? bikeOverlayOn : showTrails;
    if (!wantWays) return [];
    if (overlayActive && mapZoom <= BIKE_OVERLAY_VECTOR_MAX_ZOOM) return [];
    if (overlayActive) return nearbyTrails.filter((t) => t.hasOsmName);
    return nearbyTrails;
  }, [
    bikeOverlaySpec,
    bikeOverlayOn,
    showTrails,
    overlayActive,
    mapZoom,
    nearbyTrails,
  ]);

  const mapLayers: MapRouteLayer[] = useMemo(() => {
    // Rundkurs: never paint out-and-back Quick / non-closed A→B on the map.
    const mapDraft = rundkursActive
      ? sanitizeDraftForRundkurs(draft)
      : draft;
    const mapQuick = suppressOutAndBackQuick ? [] : quickOptions;
    const base = buildDiscoverMapLayers({
      draft: mapDraft,
      quickOptions: mapQuick,
      activeQuickId: mapQuick.find((q) => q.label === mapDraft.label)?.id,
      trails: trailsForMap,
      showTrails: sheetMode === "tours" && trailsForMap.length > 0,
      rundkursOnly: rundkursActive,
      rideProfileId: null,
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
    suppressOutAndBackQuick,
    rundkursActive,
    nearbyTrails,
    trailsForMap,
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
    if (modeParam === "rideOut") setRideOutChoice(true);
  }, [modeParam]);

  useEffect(() => {
    if (sheetParam === "plan" || panelParam === "plan") setSheetMode("plan");
    if (sheetParam === "tours" || panelParam === "tours") setSheetMode("tours");
  }, [sheetParam, panelParam]);

  useEffect(() => {
    if (!tourParam) return;
    const tour = getPublicTour(tourParam);
    if (!tour) return;
    setMapCenter(tour.center);
    setSheetMode("plan");
    setDraft((d) => ({
      ...setStart(d, tour.center, tour.name),
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
  }, [tourParam]);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/routing/status")
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data) return;
        setValhallaLive(data.valhalla === true);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (queryMinutes != null) setMinutes(queryMinutes);
  }, [queryMinutes]);

  useEffect(() => {
    if (!queryCenter) return;
    setMapCenter(queryCenter);
    setDraft((d) => setStart(d, queryCenter, DISCOVER_PIN_DE.deepLink));
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
            DISCOVER_STATUS_DE.locNoneDemo
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
          setDraft((d) => setStart(d, p, DISCOVER_PIN_DE.myPos));
          setLocationStatus(DISCOVER_STATUS_DE.locGps);
        } else {
          setLocationStatus(DISCOVER_STATUS_DE.locDeepGps);
        }
      },
      () => {
        if (cancelled) return;
        if (!queryCenter) {
          setLocationStatus(
            DISCOVER_STATUS_DE.locDeniedDemo
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
    setLiveOsmStatus("loading");
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

    const cov = new URLSearchParams({
      lat: String(lat),
      lng: String(lng),
      bike: bikeOverlayFamily,
    });
    void fetch(`/api/coverage?${cov}`)
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        const places = Array.isArray(data.places) ? data.places : [];
        setGooglePlaces(
          places.map(
            (p: {
              id?: string;
              name?: string;
              kind?: string;
              lat?: number;
              lng?: number;
              mapsUrl?: string;
            }) => ({
              id: String(p.id ?? ""),
              name: String(p.name ?? ""),
              kind: String(p.kind ?? "other"),
              lat: Number(p.lat),
              lng: Number(p.lng),
              mapsUrl: String(p.mapsUrl ?? ""),
            })
          ).filter(
            (p: { id: string; name: string; lat: number; lng: number }) =>
              p.id && p.name && Number.isFinite(p.lat) && Number.isFinite(p.lng)
          )
        );
        const gw = data.google?.warning as string | undefined;
        setGooglePlacesWarning(
          gw && (showRoutingDebugUi() || allowDemoContent()) ? gw : null
        );
        const covTrails = Array.isArray(data.trails) ? data.trails : [];
        const mapped = covTrails
          .map((t: Parameters<typeof osmTrailToSegment>[0]) => osmTrailToSegment(t))
          .filter((t: TrailSegment | null): t is TrailSegment => t != null);
        if (mapped.length > 0) {
          setLiveOsmTrails(mapped);
          setLiveOsmStatus("idle");
        } else {
          void fetch(
            `/api/osm-trails?lat=${encodeURIComponent(String(lat))}&lon=${encodeURIComponent(String(lng))}&radiusKm=8`
          )
            .then(async (tr) => {
              if (cancelled || !tr.ok) {
                if (!cancelled) {
                  setLiveOsmTrails([]);
                  setLiveOsmStatus("empty");
                }
                return;
              }
              const body = await tr.json();
              const live = (Array.isArray(body.trails) ? body.trails : [])
                .map((t: Parameters<typeof osmTrailToSegment>[0]) =>
                  osmTrailToSegment(t)
                )
                .filter((t: TrailSegment | null): t is TrailSegment => t != null);
              if (cancelled) return;
              setLiveOsmTrails(live);
              setLiveOsmStatus(live.length ? "idle" : "empty");
            })
            .catch(() => {
              if (!cancelled) {
                setLiveOsmTrails([]);
                setLiveOsmStatus("error");
              }
            });
        }
      })
      .catch(() => {
        if (cancelled) return;
        void fetch(
          `/api/osm-trails?lat=${encodeURIComponent(String(lat))}&lon=${encodeURIComponent(String(lng))}&radiusKm=8`
        )
          .then(async (tr) => {
            if (cancelled || !tr.ok) {
              if (!cancelled) {
                setLiveOsmTrails([]);
                setLiveOsmStatus("error");
              }
              return;
            }
            const body = await tr.json();
            const live = (Array.isArray(body.trails) ? body.trails : [])
              .map((t: Parameters<typeof osmTrailToSegment>[0]) =>
                osmTrailToSegment(t)
              )
              .filter((t: TrailSegment | null): t is TrailSegment => t != null);
            if (cancelled) return;
            setLiveOsmTrails(live);
            setLiveOsmStatus(live.length ? "idle" : "empty");
          })
          .catch(() => {
            if (!cancelled) {
              setLiveOsmTrails([]);
              setLiveOsmStatus("error");
            }
          });
      });

    return () => {
      cancelled = true;
    };
  }, [userPos, mapCenter, bikeOverlayFamily]);

  const refreshQuick = useCallback(
    async (opts?: { force?: boolean; limit?: number }) => {
      // D-60-LOOP-FILTER-01: Rundkurs → never pad with out-and-back Quick.
      if (suppressOutAndBackQuick) {
        quickAbortRef.current?.abort();
        setQuickOptions([]);
        setQuickBusy(false);
        setQuickTimedOut(false);
        setDraft((d) => sanitizeDraftForRundkurs(d));
        return;
      }
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
          DISCOVER_STATUS_DE.calcSlow
        );
      }, QUICK_TIMEOUT_MS);
      try {
        if (garageSession === "gravity") {
          setQuickOptions([]);
          setQuickBusy(false);
          setQuickTimedOut(false);
          setDraft((d) => sanitizeDraftForRundkurs(d));
          return;
        }
        const { options, rateLimited, fromCache } = await computeQuickOptions(
          origin,
          activeProfile,
          minutes,
          {
            limit: opts?.limit ?? 1,
            force: opts?.force,
            signal: ac.signal,
            allowApprox: true,
            allowOutAndBack: !suppressOutAndBackQuick,
          }
        );
        if (timedOut || ac.signal.aborted) return;
        // Defense: never keep out-and-back cards even if caller raced.
        const next = options.filter((q) => !isOutAndBackQuickOption(q));
        setQuickOptions(next);
        setQuickRateLimited(rateLimited);
        if (!next.length) {
          setQuickTimedOut(true);
          setRoutingMsg(
            DISCOVER_STATUS_DE.noQuick
          );
          setDraft((d) => sanitizeDraftForRundkurs({ ...d, mode: "quick" }));
        } else {
          if (rateLimited) {
            setRoutingMsg(
              DISCOVER_STATUS_DE.rateLimit
            );
          } else if (fromCache) {
            setRoutingMsg(null);
          }
          setDraft((d) => ({
            ...setStart(
              { ...d, mode: "quick" as PlanMode, profile: activeProfile },
              origin,
              DISCOVER_PIN_DE.here
            ),
            computed: next[0].result,
            label: next[0].label,
          }));
          setPreviewTour(null);
        }
      } catch {
        if (!timedOut) {
          setQuickTimedOut(true);
          setRoutingMsg(
            DISCOVER_STATUS_DE.quickFail
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
    [origin, activeProfile, minutes, suppressOutAndBackQuick, garageSession]
  );

  // NearMe Route=Rundkurs keeps Discover loop filter on (all list sources).
  useEffect(() => {
    if (nearMeRouteMode !== "loop") return;
    setFilters((f) => (f.loopOnly ? f : { ...f, loopOnly: true }));
  }, [nearMeRouteMode]);

  useEffect(() => {
    if (sheetMode !== "quick") return;
    if (suppressOutAndBackQuick) {
      quickAbortRef.current?.abort();
      setQuickOptions([]);
      setQuickBusy(false);
      setDraft((d) => sanitizeDraftForRundkurs(d));
      return;
    }
    if (quickDebounceRef.current) clearTimeout(quickDebounceRef.current);
    quickDebounceRef.current = setTimeout(() => {
      void refreshQuick({ limit: 1 });
    }, 600);
    return () => {
      if (quickDebounceRef.current) clearTimeout(quickDebounceRef.current);
      quickAbortRef.current?.abort();
    };
  }, [sheetMode, refreshQuick, suppressOutAndBackQuick]);

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
      name: draft.label || draft.baseTour?.name || DISCOVER_PIN_DE.planned,
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
    setLastSavedId(id);
  }, [draft, saveRoute]);

  const importGpxFile = useCallback(
    async (file: File | null) => {
      if (!file) return;
      const text = await file.text();
      const parsed = parseGpx(text, file.name.replace(/\.gpx$/i, ""));
      if (!parsed) {
        setRoutingMsg(DISCOVER_STATUS_DE.gpxBad);
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
      setRoutingMsg(DISCOVER_STATUS_DE.geocodeFail);
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
        setRoutingMsg(DISCOVER_STATUS_DE.savedLoaded);
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
      const withProfile = { ...draft, profile: planCosting, mode: "point_to_point" as const };
      const next = await resolvePointToPointDraft(withProfile, {
        trails: nearbyTrails,
        origin,
      });
      if (!next?.computed) {
        setRoutingMsg(DISCOVER_STATUS_DE.needStartEnd);
        return;
      }
      setDraft({
        ...next,
        profile: activeProfile,
        label: next.label || DISCOVER_PIN_DE.planned,
        baseTour: next.attachedTrailId ? next.baseTour : undefined,
      });
      setPreviewTour(null);
      setRoutingMsg(routeResultMessage(next.computed));
    } finally {
      setRoutingBusy(false);
    }
  };

  const previewBaseTour = (tour: BaseTour) => {
    setHoldMapFit(false);
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
            label: DISCOVER_PIN_DE.tourPlace,
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
        DISCOVER_STATUS_DE.pinOnly
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
          label: DISCOVER_PIN_DE.tourStart,
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
            label: DISCOVER_PIN_DE.tourPlace,
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
          label: DISCOVER_PIN_DE.tourStart,
        },
        {
          id: "end",
          role: "end",
          lngLat: endLngLat,
          label: DISCOVER_PIN_DE.tourEnd,
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
      const parts = await snapToTourParts(origin, tour, planCosting);
      if (!parts) {
        setRoutingMsg(DISCOVER_STATUS_DE.hybridFail);
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
          { id: "start", role: "start", lngLat: origin, label: DISCOVER_PIN_DE.here },
          {
            id: "end",
            role: "end",
            lngLat: tourEnd,
            label: DISCOVER_PIN_DE.tourEnd,
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
    mode: "append" | "via_chain",
    kind?: ApproachKind
  ) => {
    const cat = activeBike?.category ?? "urban";
    if (!trailFitsBikeCategory(cat, trail.difficulty)) {
      setRoutingMsg(d.trailUnsuitable(bikeCategoryLabel(cat)));
      return;
    }
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const coords = (trail.geometry.coordinates ?? []) as [number, number][];
      const orient = garageSession === "gravity";
      let startElev: number | null = null;
      let endElev: number | null = null;
      if (orient && coords.length >= 2) {
        const elev = await fetchEndpointElevations(
          coords[0],
          coords[coords.length - 1]
        );
        startElev = elev.startM;
        endElev = elev.endM;
      }
      const distKm =
        coords.length < 2
          ? 1
          : Math.min(
              trailAccessHaversineKm(
                origin[1],
                origin[0],
                coords[0][1],
                coords[0][0]
              ),
              trailAccessHaversineKm(
                origin[1],
                origin[0],
                coords[coords.length - 1][1],
                coords[coords.length - 1][0]
              )
            );
      const accessKind: ApproachKind =
        kind ??
        suggestedApproachKind({ session: garageSession, distanceKm: distKm });
      const orientOpts = {
        orientDownhill: orient,
        startElevM: startElev,
        endElevM: endElev,
      };
      const next =
        accessKind === "atStart"
          ? adoptTrailToDraft(draft, trail, origin, orientOpts)
          : await attachTrailToDraft(draft, trail, mode, origin, {
              ...orientOpts,
              accessProfile: approachCostingForBike(cat, accessKind),
            });
      if (!next) {
        setRoutingMsg(DISCOVER_STATUS_DE.trailFail);
        return;
      }
      setDraft({ ...next, profile: activeProfile });
      setSelectedTrailId(trail.id);
      setRoutingMsg(
        next.computed
          ? `${trail.name} · ${routeResultMessage(next.computed)}`
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
            const next = await resolvePointToPointDraft(
              { ...nextDraft, profile: planCosting },
              { trails: nearbyTrails, origin }
            );
            if (next?.computed) {
              setDraft({ ...next, profile: activeProfile });
              setRoutingMsg(routeResultMessage(next.computed));
            }
          } finally {
            setRoutingBusy(false);
          }
        })();
      }, 700);
    },
    [activeProfile, planCosting, origin, nearbyTrails]
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

  const onOverlayWayClick = useCallback(
    async (hit: OverlayWayHit) => {
      let seg = overlayHitToSegment(hit);
      const known = liveOsmTrails.find((t) => t.id === hit.id);
      if (known) {
        seg = {
          ...seg,
          ...known,
          geometry:
            known.geometry.coordinates.length >= seg.geometry.coordinates.length
              ? known.geometry
              : seg.geometry,
        };
      }
      if (!seg.surface || seg.geometry.coordinates.length < 2) {
        try {
          const r = await fetch(`/api/osm-trails?way=${encodeURIComponent(hit.osmId)}`);
          if (r.ok) {
            const body = await r.json();
            const full = osmTrailToSegment(body.trails?.[0]);
            if (full) seg = { ...seg, ...full };
          }
        } catch {
          /* sheet still works without surface */
        }
      }
      setSelectedTrailId(seg.id);
      setOverlaySheet(seg);
      setShowTrails(true);
      setSheetMode("tours");
      setLiveOsmTrails((cur) =>
        cur.some((t) => t.id === seg.id) ? cur : [seg, ...cur]
      );
    },
    [liveOsmTrails]
  );

  const onMapClick = (lngLat: [number, number]) => {
    if (!pickTarget) return;
    const trails = liveOsmTrails.map(
      (t) => t.geometry.coordinates as [number, number][]
    );
    const snapped =
      pickTarget === "via" ? snapPointOntoTrails(lngLat, trails) : lngLat;
    setDraft((prev) => {
      let next = prev;
      if (pickTarget === "start") {
        next = setStart(prev, lngLat, DISCOVER_PIN_DE.startMap);
        setMapCenter(lngLat);
      } else if (pickTarget === "end") {
        next = setEnd(prev, lngLat, DISCOVER_PIN_DE.endMap);
      } else {
        next = addVia(prev, snapped);
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
    const pinIds = new Set(m.map((x) => `${x.lngLat[0].toFixed(4)},${x.lngLat[1].toFixed(4)}`));
    for (const r of nearbyRoutes) {
      if (!r.center) continue;
      const key = `${r.center[0].toFixed(4)},${r.center[1].toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      m.push({
        id: `tour-${r.id}`,
        lngLat: r.center,
        color: r.loop ? "#26A69A" : "#78909C",
        label: "T",
      });
    }
    for (const p of googlePlaces.slice(0, 10)) {
      const key = `${p.lng.toFixed(4)},${p.lat.toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      m.push({
        id: `place-${p.id}`,
        lngLat: [p.lng, p.lat],
        color: "#5E35B1",
        label: d.placeKind(normalizePlaceKind(p.kind)),
      });
    }
    return m;
  }, [draft, nearbyRoutes, googlePlaces, d]);

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
            className="rounded-xl border border-chrome/40 bg-chrome/10 py-2.5 text-sm font-semibold text-chrome"
          >
            {d.fromHereStart}
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
    <div className="flex min-h-[calc(100dvh-var(--hof-header-h)-var(--hof-tab-h))] flex-col lg:h-[calc(100dvh-var(--hof-header-h))] lg:flex-row lg:overflow-hidden">
      {/*
        Desktop: Side-Panel links + Vollkarte rechts (Komoot/RWGPS-Muster).
        Mobile: Karte oben, Panel unten.
      */}
      <aside className="order-2 flex min-h-0 flex-col border-t border-border bg-background lg:order-1 lg:w-[min(26rem,40vw)] lg:shrink-0 lg:border-r lg:border-t-0">
        {/* Dach */}
        <header className="shrink-0 space-y-2 border-b border-border px-4 pb-3 pt-4 lg:pt-5">
          {debugRoutingNotice && (
            <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
              {discoverStatus(debugRoutingNotice, lang)}
            </p>
          )}
          {heatmapNote && (
            <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
              {d.heatmapPrefix}{heatmapNote}
              {!heatmapConsent && (
                <>
                  {" "}
                  {d.heatmapOwn}
                </>
              )}
            </p>
          )}
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0 flex-1">
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {copy.mapKicker}
              </p>
              <h1 className="text-xl font-bold tracking-tight">
                {copy.mapTitle}
              </h1>
              <p className="text-xs text-text-secondary">
                {activeBike
                  ? `${activeBike.name} · ${bikeCategoryLabel(activeBike.category)}`
                  : d.osmOptional}
              </p>
            </div>
            <div className="flex shrink-0 flex-col items-end gap-2">
              <BikeChip />
              <button
                type="button"
                onClick={() => {
                  const goHere = (p: [number, number]) => {
                    setHoldMapFit(true);
                    setUserPos(p);
                    setMapCenter(p);
                    setLocationStatus(DISCOVER_STATUS_DE.locGps);
                    setRoutingMsg(DISCOVER_STATUS_DE.locGpsCentered);
                  };
                  if (userPos) {
                    goHere(userPos);
                    return;
                  }
                  if (
                    typeof navigator === "undefined" ||
                    !navigator.geolocation
                  ) {
                    focusPlanAddress(
                      DISCOVER_STATUS_DE.locNoneAddr
                    );
                    return;
                  }
                  setLocationStatus(DISCOVER_STATUS_DE.locWait);
                  setRoutingMsg(DISCOVER_STATUS_DE.locWait);
                  navigator.geolocation.getCurrentPosition(
                    (pos) => {
                      goHere([pos.coords.longitude, pos.coords.latitude]);
                    },
                    () => {
                      focusPlanAddress(
                        DISCOVER_STATUS_DE.locDeniedAddr
                      );
                    },
                    { timeout: 8000, maximumAge: 30 * 60 * 1000 }
                  );
                }}
                className="flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium text-text-secondary"
                aria-describedby="discover-location-status"
              >
                <Crosshair className="h-3.5 w-3.5" />
                {userPos ? d.hereBtn : d.placeEllipsis}
              </button>
            </div>
          </div>
          <p
            id="discover-location-status"
            className="text-[11px] text-text-secondary"
            role="status"
            aria-live="polite"
          >
            {discoverStatus(locationStatus, lang)}
          </p>
          {rideOutChoice ? (
            <RideOutChoice
              onJustRide={() => {
                setRideOutChoice(false);
                setJustRide(true);
                setSheetMode("quick");
              }}
              onShowTours={() => {
                setRideOutChoice(false);
                setJustRide(false);
                setSheetMode("tours");
              }}
            />
          ) : null}
          {justRide ? (
            <p
              data-testid="hof-just-ride"
              className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-[12px] text-text-secondary"
            >
              {copy.mapJustRideHint}{" "}
              <Link href="/download" className="font-semibold text-chrome hover:underline">
                {chrome.loadApp}
              </Link>
            </p>
          ) : null}
          <DiscoverExploreChrome
            searchQuery={exploreQuery}
            onSearchQuery={(q) => {
              setExploreQuery(q);
              if (q.trim().length >= 2) setSheetMode("tours");
            }}
            onPlanRoute={() => {
              setSheetMode("plan");
            }}
            aroundKm={aroundKm}
            filterCount={activeFilterCount}
            profileMenu={navProfileMenu}
            activeProfile={activeProfile}
            onProfile={(p) => {
              setManualProfile(p);
              setFilters((f) => ({
                ...f,
                sport: sportFilterFromProfile(p),
              }));
            }}
            minutes={minutes}
            onMinutes={setMinutesLens}
            filters={filters}
            onFilters={applyRouteFilters}
            routingProfile={activeProfile}
            resultCount={filtered.length}
          />
        </header>

        <div className="grid shrink-0 grid-cols-3 gap-1 border-b border-border p-2">
          {(
            [
              ["quick", copy.mapSheetNear, Zap],
              ["plan", copy.mapSheetPlan, Navigation],
              ["tours", copy.mapSheetTours, Route],
            ] as const
          ).map(([id, label, Icon]) => (
            <button
              key={id}
              type="button"
              onClick={() => setSheetMode(id)}
              className={`flex items-center justify-center gap-1.5 rounded-lg py-2.5 text-xs font-medium ${
                sheetMode === id
                  ? "bg-chrome text-on-accent"
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
            <p className="mb-2 text-[11px] text-text-secondary">{discoverStatus(routingMsg, lang)}</p>
          )}

          {sheetMode === "quick" && (
            <div className="flex flex-col gap-2">
              <div className="rounded-xl border border-chrome/25 bg-chrome/5 p-3">
                <p className="text-xs font-semibold text-foreground">
                  {d.nearbyTitle(profileLabel(activeProfile))}
                </p>
                <p className="mt-0.5 text-[11px] text-text-secondary">
                  {d.nearbyLiveHint}
                </p>
                <div className="mt-2">
                  <NearMeRouteCard
                    center={userPos ?? mapCenter}
                    profile={activeProfile}
                    defaultKm={Math.max(10, Math.round(minutes / 4))}
                    routeMode={nearMeRouteMode}
                    onRouteModeChange={setNearMeRouteMode}
                    onLoopPreview={(result, label) => {
                      setHoldMapFit(false);
                      setDraft((d) => ({
                        ...setStart(
                          { ...d, mode: "quick", profile: activeProfile },
                          origin,
                          DISCOVER_PIN_DE.here
                        ),
                        computed: result,
                        label,
                        baseTour: undefined,
                      }));
                      setPreviewTour(null);
                      setQuickOptions([]);
                    }}
                  />
                </div>
              </div>
              {suppressOutAndBackQuick ? (
                <p className="text-[11px] text-text-secondary">
                  {d.loopActiveHint}
                </p>
              ) : (
                <>
                  <p className="text-[11px] text-text-secondary">
                    {d.suggestions(minutes, profileLabel(activeProfile))}
                  </p>
                  {quickBusy && (
                    <p className="text-sm text-text-secondary" role="status">
                      {d.computing}
                    </p>
                  )}
                  {quickTimedOut && !quickBusy && (
                    <div className="rounded-xl border border-border bg-surface-elevated p-3 text-sm text-text-secondary">
                      <p>
                        {d.quickTimeout}
                      </p>
                      <button
                        type="button"
                        className="mt-2 text-xs font-semibold text-chrome"
                        onClick={() =>
                          void refreshQuick({ force: true, limit: 1 })
                        }
                      >
                        {d.retry}
                      </button>
                    </div>
                  )}
                  {!quickBusy &&
                    !quickTimedOut &&
                    quickOptions.length === 0 && (
                      <div className="rounded-xl border border-border p-4 text-center text-sm text-text-secondary">
                        {d.noLive}
                        <button
                          type="button"
                          className="font-medium text-chrome"
                          onClick={() =>
                            focusPlanAddress(
                              DISCOVER_STATUS_DE.searchStart
                            )
                          }
                        >
                          {d.openPlan}
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
                                {
                                  ...d,
                                  mode: "quick",
                                  profile: activeProfile,
                                },
                                origin,
                                DISCOVER_PIN_DE.here
                              ),
                              computed: q.result,
                              label: q.label,
                              baseTour: undefined,
                            }));
                            setPreviewTour(null);
                          }}
                          className={`min-w-[9.5rem] shrink-0 rounded-xl border p-3 text-left ${
                            draft.label === q.label
                              ? "border-chrome bg-chrome/10"
                              : "border-border bg-surface"
                          }`}
                        >
                          <div className="text-sm font-semibold">{q.label}</div>
                          <div className="mt-1 text-[11px] text-text-secondary">
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
                      onClick={() =>
                        void refreshQuick({ force: true, limit: 1 })
                      }
                      className="flex-1 rounded-xl border border-border py-2 text-xs font-medium"
                    >
                      {d.recompute}
                    </button>
                    {quickOptions.length < 3 && (
                      <button
                        type="button"
                        disabled={quickBusy || quickRateLimited}
                        onClick={() =>
                          void refreshQuick({
                            limit: Math.min(
                              3,
                              Math.max(1, quickOptions.length) + 1
                            ),
                          })
                        }
                        className="flex-1 rounded-xl border border-border py-2 text-xs font-medium disabled:opacity-40"
                      >
                        {d.moreOption}
                      </button>
                    )}
                  </div>
                  {quickRateLimited && (
                    <p className="text-[11px] text-warning">
                      {d.ghMinuteLimit}
                    </p>
                  )}
                </>
              )}

              {/* Always-on ~60 Min — #35 curated P0 Berlin/RN + honest loops only */}
              <h3 className="mt-3 text-xs font-semibold tracking-wide text-text-secondary">
                {d.sixtyTitle}
              </h3>
              <p className="text-[11px] text-text-secondary">
                {d.sixtyLead}
              </p>
              {hasUsefulNearbyLoops ? (
                <div className="flex flex-col gap-2">
                  {sixtyMinLoops.map((r) => (
                    <div key={r.id} className="space-y-1.5">
                      <RouteCard
                        // Belt: never render A→B under this rail title.
                        route={{ ...r, loop: true }}
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
                          {d.preview}
                        </button>
                        <button
                          type="button"
                          className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                          onClick={() =>
                            adoptIntoPlanMode(suggestionToTour(r))
                          }
                        >
                          {d.intoPlan}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="mt-2 rounded-xl border border-border bg-surface-elevated p-3">
                  <p className="text-xs font-semibold text-foreground">
                    {d.noLoopsNearby}
                  </p>
                  <p className="mt-0.5 text-[11px] text-text-secondary">
                    {d.noHonestHere}
                  </p>
                  <button
                    type="button"
                    className="mt-2 w-full rounded-xl bg-chrome py-2 text-xs font-semibold text-on-accent"
                    onClick={() =>
                      focusPlanAddress(DISCOVER_STATUS_DE.changePlace)
                    }
                  >
                    {d.changePlaceBtn}
                  </button>
                  <p className="mt-2 text-[11px] font-semibold text-text-secondary">
                    {d.demoCity}
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
                {d.planHint}
              </p>
              <div className="flex gap-2">
                <select
                  value={addrTarget}
                  onChange={(e) =>
                    setAddrTarget(e.target.value as "start" | "end")
                  }
                  className="rounded-lg border border-border bg-surface-elevated px-2 text-xs"
                >
                  <option value="start">{d.start}</option>
                  <option value="end">{d.end}</option>
                </select>
                <input
                  ref={addrInputRef}
                  value={addrQuery}
                  onChange={(e) => setAddrQuery(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") void searchAddress();
                  }}
                  aria-label={
                    addrTarget === "end" ? d.endAddr : d.startAddr
                  }
                  placeholder={d.addrPlaceholder}
                  className="min-w-0 flex-1 rounded-lg border border-border bg-surface-elevated px-2 py-1.5 text-xs"
                />
                <button
                  type="button"
                  disabled={addrBusy}
                  onClick={() => void searchAddress()}
                  className="rounded-lg border border-border px-2 text-xs font-medium"
                >
                  {d.search}
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
                      ? "border-chrome bg-chrome/10"
                      : "border-border bg-surface"
                  }`}
                >
                  {d.tapStart}
                </button>
                <button
                  type="button"
                  onClick={() => setPickTarget("via")}
                  className={`rounded-xl border px-2 py-2 text-left text-[11px] ${
                    pickTarget === "via"
                      ? "border-chrome bg-chrome/10"
                      : "border-border bg-surface"
                  }`}
                >
                  {d.tapVia}
                </button>
                <button
                  type="button"
                  onClick={() => setPickTarget("end")}
                  className={`rounded-xl border px-2 py-2 text-left text-[11px] ${
                    pickTarget === "end"
                      ? "border-chrome bg-chrome/10"
                      : "border-border bg-surface"
                  }`}
                >
                  {d.tapEnd}
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
                        ? d.startAbbr
                        : w.role === "end"
                          ? d.endAbbr
                          : i}
                      {" · "}
                      {discoverPinLabel(w.label, lang) || w.role} · {w.lngLat[1].toFixed(3)},{" "}
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
                      setStart(draft, userPos, DISCOVER_PIN_DE.myPos)
                    );
                  }
                }}
                className="text-left text-[11px] font-medium text-chrome"
              >
                {d.startMyPos}
              </button>
              <button
                type="button"
                disabled={routingBusy || !startOf(draft) || !endOf(draft)}
                onClick={() => void runPlanRoute()}
                className="w-full rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
              >
                {routingBusy ? d.computingRoute : d.computeRoute}
              </button>
              <div className="flex flex-wrap gap-1.5">
                {(
                  [
                    ["planned", d.variantPlanned],
                    ["flatter", d.variantFlatter],
                    ["unpaved", d.variantUnpaved],
                  ] as const
                ).map(([id, label]) => (
                  <button
                    key={id}
                    type="button"
                    disabled={!valhallaLive && id !== "planned"}
                    onClick={() => {
                      const next = { ...draft, variant: id };
                      schedulePlanRecompute(next);
                    }}
                    className={`rounded-full border px-2.5 py-1 text-[11px] ${
                      (draft.variant ?? "planned") === id
                        ? "border-chrome bg-chrome/10"
                        : "border-border bg-surface"
                    } disabled:opacity-40`}
                  >
                    {label}
                  </button>
                ))}
              </div>
              {!valhallaLive ? (
                <p className="text-[11px] text-text-secondary">
                  {d.variantValhallaOnly}
                </p>
              ) : null}
            </div>
          )}

          {sheetMode === "tours" && (
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-2">
                <h3 className="text-xs font-semibold tracking-wide text-text-secondary">
                  {d.waysNearby}
                </h3>
                <label className="flex items-center gap-1.5 text-[11px] text-text-secondary">
                  <input
                    type="checkbox"
                    checked={bikeOverlaySpec ? bikeOverlayOn : showTrails}
                    onChange={(e) => {
                      const on = e.target.checked;
                      if (bikeOverlaySpec) setBikeOverlayOn(on);
                      else setShowTrails(on);
                    }}
                  />
                  {d.overlay}
                </label>
              </div>
              {liveOsmStatus === "loading" && nearbyTrails.length === 0 ? (
                <p className="text-[11px] text-text-secondary">
                  {d.osmLoading}
                </p>
              ) : nearbyTrails.length === 0 ? (
                <p className="text-[11px] text-text-secondary">
                  {liveOsmStatus === "error"
                    ? d.osmError
                    : d.osmEmpty}
                </p>
              ) : (
                nearbyTrails.map((t) => (
                  <article
                    key={t.id}
                    className={`rounded-xl border p-3 ${
                      selectedTrailId === t.id
                        ? "border-chrome bg-chrome/10"
                        : "border-border bg-surface"
                    }`}
                  >
                    <div className="text-sm font-medium">{t.name}</div>
                    <p className="text-[11px] text-text-secondary">
                      {[
                        t.difficulty ?? d.difficultyOpen,
                        discoverHighwayLabel(trailHighwayLabelDe(t.highway), lang),
                        discoverSurfaceLabel(trailSurfaceLabelDe(t.surface), lang),
                        "OSM",
                      ]
                        .filter(Boolean)
                        .join(" · ")}
                    </p>
                    <div className="mt-2 flex flex-wrap gap-2">
                      <button
                        type="button"
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => {
                          setSelectedTrailId(t.id);
                          setOverlaySheet(t);
                          setMapCenter(t.center);
                        }}
                      >
                        {d.show}
                      </button>
                      {garageSession === "gravity" ? (
                        <button
                          type="button"
                          disabled={routingBusy}
                          className="rounded-lg border border-chrome/40 px-2.5 py-1.5 text-[11px] text-chrome"
                          onClick={() => void attachTrail(t, "append", "auto")}
                        >
                          {d.approachByCar}
                        </button>
                      ) : (
                        <>
                          <button
                            type="button"
                            disabled={routingBusy}
                            className="rounded-lg border border-chrome/40 px-2.5 py-1.5 text-[11px] text-chrome"
                            onClick={() => void attachTrail(t, "append")}
                          >
                            {d.append}
                          </button>
                          <button
                            type="button"
                            disabled={routingBusy}
                            className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                            onClick={() => void attachTrail(t, "via_chain")}
                          >
                            {d.intoNav}
                          </button>
                        </>
                      )}
                      {t.url && (
                        <a
                          href={t.url}
                          target="_blank"
                          rel="noreferrer"
                          className="self-center text-[11px] text-chrome"
                        >
                          OSM →
                        </a>
                      )}
                    </div>
                  </article>
                ))
              )}

              {activeBike?.isEbike && range && (
                <div className="rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-xs">
                  {d.rangeLine(range.kmLow, range.kmHigh)}
                </div>
              )}

              <h3 className="text-xs font-semibold tracking-wide text-text-secondary">
                {d.fromLocation(nearbyRoutes.length, fartherRoutes.length)}
              </h3>
              <p className="text-[11px] text-text-secondary">
                {d.sortedNear(userPos ? d.sortedByYou : d.sortedByMap)} (
                {origin[1].toFixed(2)}°N, {origin[0].toFixed(2)}°E)
              </p>
              {routes.some((r) => r.id.startsWith("seed-")) &&
                !routes.some((r) => !r.id.startsWith("seed-")) && (
                <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
                  {d.offlineFallback}
                </p>
              )}
              {filtered.length === 0 ? (
                <div className="rounded-xl border border-border bg-surface-elevated p-3">
                  <p className="text-sm font-semibold text-foreground">
                    {filters.loopOnly
                      ? d.noLoopsNearby
                      : d.noToursFilter}
                  </p>
                  <p className="mt-0.5 text-xs text-text-secondary">
                    {filters.loopOnly
                      ? d.loosenLoop
                      : d.loosenOrPlan}
                  </p>
                  {filters.loopOnly && (
                    <button
                      type="button"
                      className="mt-2 rounded-lg border border-border px-3 py-1.5 text-xs font-medium"
                      onClick={() =>
                        setFilters((f) => ({ ...f, loopOnly: false }))
                      }
                    >
                      {d.loopFilterOff}
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
                          {d.preview}
                        </button>
                        <button
                          type="button"
                          disabled={routingBusy}
                          className="flex-1 rounded-lg border border-chrome/40 py-1.5 text-[11px] font-medium text-chrome"
                          onClick={() => void runHybridSnap(suggestionToTour(r))}
                        >
                          {d.fromHere}
                        </button>
                        <button
                          type="button"
                          className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                          onClick={() =>
                            adoptIntoPlanMode(suggestionToTour(r))
                          }
                        >
                          {d.intoPlan}
                        </button>
                      </div>
                    </div>
                  ))}
                  {fartherRoutes.length > 0 && (
                    <>
                      <h3 className="mt-3 text-xs font-semibold tracking-wide text-text-secondary">
                        {d.fartherRegions(fartherRoutes.length)}
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
                              {d.preview}
                            </button>
                            <button
                              type="button"
                              disabled={routingBusy}
                              className="flex-1 rounded-lg border border-chrome/40 py-1.5 text-[11px] font-medium text-chrome"
                              onClick={() =>
                                void runHybridSnap(suggestionToTour(r))
                              }
                            >
                              {d.fromHere}
                            </button>
                            <button
                              type="button"
                              className="flex-1 rounded-lg border border-border py-1.5 text-[11px] font-medium"
                              onClick={() =>
                                adoptIntoPlanMode(suggestionToTour(r))
                              }
                            >
                              {d.intoPlan}
                            </button>
                          </div>
                        </div>
                      ))}
                    </>
                  )}
                </>
              )}

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-secondary">
                <Compass className="h-3.5 w-3.5" /> {d.outdooractive(oaTours.length)}
              </h3>
              {googlePlacesWarning && (
                <p className="text-[11px] text-text-secondary">
                  Google Places: {googlePlacesWarning}
                </p>
              )}
              {googlePlaces.length > 0 && (
                <p className="text-[11px] text-text-secondary">
                  {d.googlePois(googlePlaces.length)}
                </p>
              )}
              {oaTours.length === 0 && (
                <p className="text-[11px] text-text-secondary">
                  {d.noOa}
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
                        t.source === "demo" ? d.example : null,
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
                        {d.preview}
                      </button>
                      <button
                        type="button"
                        disabled={routingBusy}
                        className="rounded-lg border border-chrome/40 px-2.5 py-1.5 text-[11px] text-chrome"
                        onClick={() => void runHybridSnap(tour)}
                      >
                        {d.fromHere}
                      </button>
                      <button
                        type="button"
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                        onClick={() => adoptIntoPlanMode(tour)}
                      >
                        {d.intoPlan}
                      </button>
                      {t.url && (
                        <a
                          href={t.url}
                          target="_blank"
                          rel="noreferrer"
                          className="ml-auto self-center text-[11px] text-chrome"
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

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-secondary">
                <Mountain className="h-3.5 w-3.5" /> {d.trailforks(tfPins.length)}
              </h3>
              <p className="text-[11px] text-text-secondary">
                {tfDisclaimer ?? d.tfFallback}
              </p>
              {tfPins.map((p) => (
                <div
                  key={p.id}
                  className="flex items-center justify-between rounded-xl border border-border px-3 py-2 text-xs"
                >
                  <div>
                    <div className="font-medium">{p.name}</div>
                    <div className="text-text-secondary">
                      {p.difficulty ?? "Trailforks"}
                    </div>
                  </div>
                  <a
                    href={p.openUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-chrome"
                  >
                    TF →
                  </a>
                </div>
              ))}

              <h3 className="mt-2 text-xs font-semibold tracking-wide text-text-secondary">
                {d.mappeHeading}
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
                  {d.importGpx}
                </button>
                <AddRouteForm
                  compact
                  defaultStart={addRouteStart?.lngLat ?? null}
                  startSource={addRouteStart?.source ?? null}
                />
              </div>
              {savedRoutes.length === 0 ? (
                <p className="text-sm text-text-secondary">
                  {d.mappeEmpty}
                </p>
              ) : mappeRoutes.length === 0 ? (
                <p className="text-sm text-text-secondary">
                  {d.mappeFilterEmpty}
                </p>
              ) : (
                mappeRoutes.map((r) => (
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
                      {r.source === "import" ? ` · ${d.importTag}` : ""}
                      {r.geometry ? ` · ${d.withTrack}` : ""}
                      {visibilityOf(r) === "shared"
                        ? ` · ${d.shared}`
                        : ` · ${d.privateTour}`}
                    </p>
                    <div className="mt-2 flex gap-2">
                      <button
                        type="button"
                        onClick={() => unsaveRoute(r.id)}
                        className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                      >
                        {d.remove}
                      </button>
                      {routeCollections.length > 0 && (
                        <label className="flex items-center gap-1 text-[11px]">
                          <span className="sr-only">{d.collectionsTitle}</span>
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
                              {d.plusCollection}
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
                        className="flex flex-1 items-center justify-center gap-1 rounded-xl bg-chrome py-1.5 text-[11px] font-semibold text-on-accent"
                      >
                        <Play className="h-3.5 w-3.5 fill-current" /> {copy.inTheApp}
                      </button>
                    </div>
                  </article>
                ))
              )}

              <h3 className="mt-4 text-xs font-semibold tracking-wide text-text-secondary">
                {d.collectionsTitle}
              </h3>
              <p className="mb-2 text-[11px] text-text-secondary">
                {d.collectionsLead}
              </p>
              <div className="mb-2 flex gap-2">
                <input
                  value={collectionName}
                  onChange={(e) => setCollectionName(e.target.value)}
                  placeholder={d.namePlaceholder}
                  className="flex-1 rounded-lg border border-border bg-surface-elevated px-2 py-1.5 text-xs"
                />
                <button
                  type="button"
                  onClick={() => {
                    createRouteCollection(collectionName);
                    setCollectionName("");
                  }}
                  className="rounded-xl bg-chrome px-2.5 py-1.5 text-[11px] font-semibold text-on-accent"
                >
                  {d.create}
                </button>
              </div>
              {routeCollections.length === 0 ? (
                <p className="text-sm text-text-secondary">{d.noCollection}</p>
              ) : (
                routeCollections.map((c) => (
                  <div
                    key={c.id}
                    className="rounded-xl border border-border bg-surface px-3 py-2 text-sm"
                  >
                    <span className="font-semibold">{c.name}</span>
                    <span className="ml-2 text-[11px] text-text-secondary">
                      {d.routesCount(c.routeIds.length)}
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
          zoom={13}
          routes={mapLayers}
          markers={markers}
          interactiveSelect={pickTarget !== null}
          bikeOverlayUrl={bikeOverlaySpec?.url ?? null}
          bikeOverlayKind={bikeOverlaySpec?.kind ?? "pmtiles"}
          bikeOverlayFamily={bikeOverlayFamily}
          bikeOverlayVisible={bikeOverlayOn}
          bikeOverlayExtraOn={bikeOverlayExtra}
          bikeOverlayRideProfileId={null}
          bikeOverlayMinZoom={bikeOverlaySpec?.overlayKind === "ways" ? 10 : 5}
          onViewChange={(view) => {
            setMapCenter(view.center);
            setMapZoom(view.zoom);
            writeDiscoverViewport(view);
          }}
          onMapClick={onMapClick}
          onOverlayClick={(hit) => void onOverlayWayClick(hit)}
          onZoomChange={setMapZoom}
          onMarkerClick={(id) => {
            if (id.startsWith("place-")) {
              const placeId = id.slice("place-".length);
              const place = googlePlaces.find((p) => p.id === placeId);
              if (!place) return;
              const trails = liveOsmTrails.map(
                (t) => t.geometry.coordinates as [number, number][]
              );
              const point: [number, number] = [place.lng, place.lat];
              const snapped = viaMaySnapOntoTrail(place.name)
                ? snapPointOntoTrails(point, trails)
                : point;
              setDraft((prev) => {
                const next = addVia(prev, snapped, place.name);
                schedulePlanRecompute(next);
                return next;
              });
              setSheetMode("plan");
              setPickTarget(null);
              return;
            }
            if (!id.startsWith("tour-")) return;
            const tourId = id.slice("tour-".length);
            const r =
              nearbyRoutes.find((x) => x.id === tourId) ??
              routes.find((x) => x.id === tourId);
            if (!r) return;
            previewBaseTour(suggestionToTour(r));
            openDetail(r.id);
            setSheetMode("tours");
          }}
          onRouteClick={(id) => {
            if (id.startsWith("alt-")) {
              const qid = id.replace("alt-", "");
              const q = quickOptions.find((x) => x.id === qid);
              if (q) {
                setDraft((d) => ({
                  ...setStart(
                    { ...d, mode: "quick", profile: activeProfile },
                    origin,
                    DISCOVER_PIN_DE.here
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
          fitRoute={
            !holdMapFit &&
            Boolean(
              (rundkursActive ? sanitizeDraftForRundkurs(draft) : draft)
                .computed
            )
          }
        />
        <div className="absolute left-[max(0.75rem,var(--safe-left))] top-3 z-10">
          <BikeOverlayLegend
            family={bikeOverlayFamily}
            visible={bikeOverlayOn}
            extraOn={bikeOverlayExtra}
            rideProfileId={null}
            hasOverlayData={Boolean(bikeOverlaySpec)}
            overlayKind={bikeOverlaySpec?.overlayKind ?? "mesh"}
            onToggleVisible={() => setBikeOverlayOn((v) => !v)}
            onToggleClass={(cls) => {
              setBikeOverlayOn(true);
              setBikeOverlayExtra((cur) =>
                cur.includes(cls)
                  ? cur.filter((c) => c !== cls)
                  : [...cur, cls]
              );
            }}
          />
        </div>
        {overlaySheet && (
          <div className="absolute bottom-14 left-[max(0.75rem,var(--safe-left))] right-[max(0.75rem,var(--safe-right))] z-20 rounded-xl border border-border bg-surface p-3 shadow-lg lg:left-auto lg:right-[max(0.75rem,var(--safe-right))] lg:max-w-sm">
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="text-sm font-semibold">{overlaySheet.name}</div>
                <p className="text-[11px] text-text-secondary">
                  {[
                    overlaySheet.difficulty ?? d.difficultyOpen,
                    discoverHighwayLabel(trailHighwayLabelDe(overlaySheet.highway), lang),
                    discoverSurfaceLabel(trailSurfaceLabelDe(overlaySheet.surface), lang),
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
              </div>
              <button
                type="button"
                className="text-[11px] text-text-secondary"
                onClick={() => setOverlaySheet(null)}
              >
                {d.close}
              </button>
            </div>
            {garageSession === "gravity" ? (
              <p className="mt-1 text-[11px] text-text-secondary">
                {d.trailGravityHint}
              </p>
            ) : null}
            <div className="mt-2 flex flex-wrap gap-2">
              {!trailFitsBikeCategory(
                activeBike?.category ?? "urban",
                overlaySheet.difficulty
              ) ? (
                <p className="text-[11px] text-text-secondary">
                  {d.trailUnsuitable(
                    bikeCategoryLabel(activeBike?.category ?? "urban")
                  )}
                </p>
              ) : garageSession === "gravity" ? (
                <>
                  <button
                    type="button"
                    disabled={routingBusy}
                    className="rounded-lg border border-chrome/40 px-2.5 py-1.5 text-[11px] text-chrome"
                    onClick={() => {
                      setOverlaySheet(null);
                      void attachTrail(overlaySheet, "append", "auto");
                    }}
                  >
                    {d.approachByCar}
                  </button>
                  <button
                    type="button"
                    disabled={routingBusy}
                    className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                    onClick={() => {
                      setOverlaySheet(null);
                      void attachTrail(overlaySheet, "append", "walk");
                    }}
                  >
                    {d.approachOnFoot}
                  </button>
                  <button
                    type="button"
                    disabled={routingBusy}
                    className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                    onClick={() => {
                      setOverlaySheet(null);
                      void attachTrail(overlaySheet, "append", "atStart");
                    }}
                  >
                    {d.atTrailStart}
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    disabled={routingBusy}
                    className="rounded-lg border border-chrome/40 px-2.5 py-1.5 text-[11px] text-chrome"
                    onClick={() => {
                      setOverlaySheet(null);
                      void attachTrail(overlaySheet, "append");
                    }}
                  >
                    {d.attachApproach}
                  </button>
                  <button
                    type="button"
                    disabled={routingBusy}
                    className="rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
                    onClick={() => {
                      setOverlaySheet(null);
                      void attachTrail(overlaySheet, "via_chain");
                    }}
                  >
                    {d.intoNav}
                  </button>
                </>
              )}
              {overlaySheet.url && (
                <a
                  href={overlaySheet.url}
                  target="_blank"
                  rel="noreferrer"
                  className="self-center text-[11px] text-chrome"
                >
                  OSM →
                </a>
              )}
            </div>
          </div>
        )}
        {pickTarget && (
          <div className="absolute left-[max(0.75rem,var(--safe-left))] right-[max(0.75rem,var(--safe-right))] top-3 z-10 rounded-xl bg-black/75 px-3 py-2 text-center text-xs text-white lg:left-auto lg:right-[max(0.75rem,var(--safe-right))] lg:max-w-sm">
            {d.tapFor(
              pickTarget === "start"
                ? d.start
                : pickTarget === "end"
                  ? d.end
                  : "Via"
            )}
            <button
              type="button"
              className="ml-2 underline"
              onClick={() => setPickTarget(null)}
            >
              {d.cancel}
            </button>
          </div>
        )}
        {statsLine && (
          <div className="absolute bottom-3 left-[max(0.75rem,var(--safe-left))] right-[max(0.75rem,var(--safe-right))] z-10 flex items-center justify-between gap-2 rounded-xl bg-black/70 px-3 py-2 text-xs text-white lg:left-auto lg:right-[max(0.75rem,var(--safe-right))] lg:max-w-md">
            <span className="truncate">
              {draft.label ? `${discoverDraftLabel(draft.label, lang)} · ` : ""}
              {statsLine}
            </span>
            <div className="flex shrink-0 gap-1.5">
              <button
                type="button"
                onClick={saveCurrentDraft}
                className="rounded-lg bg-white/15 px-2 py-1"
                aria-label={d.saveAria}
              >
                <Bookmark className="h-3.5 w-3.5" />
              </button>
              {lastSavedId ? (
                <a
                  href={httpsAppLink(rideOpenPath(lastSavedId))}
                  className="rounded-lg bg-white/15 px-2 py-1 text-[10px] font-semibold"
                >
                  {d.openNativeApp}
                </a>
              ) : null}
              <button
                type="button"
                onClick={() =>
                  draft.computed &&
                  startWithComputed(
                    draft.label || DISCOVER_PIN_DE.planned,
                    draft.computed
                  )
                }
                className="flex items-center gap-1 rounded-xl bg-chrome px-2.5 py-1 font-semibold text-on-accent"
              >
                <Play className="h-3.5 w-3.5 fill-current" /> {copy.inTheApp}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default function DiscoverPage() {
  const copy = useHofCopy();
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center text-sm text-text-secondary">
          {copy.mapLoading}
        </div>
      }
    >
      <DiscoverPageInner />
    </Suspense>
  );
}
