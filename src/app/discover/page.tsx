"use client";

import { useCallback, useEffect, useMemo, useRef, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import {
  Loader2,
  X,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { useCommunityStore } from "@/store/useCommunityStore";
import {
  getSuggestionById,
  listAllRouteSuggestions,
  categoryForRoutingProfile,
  type RouteSuggestion,
} from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import {
  coveragePlacePoiKind,
  pinGlyphForCategory,
} from "@/lib/map/mapPinSvg";
import { browseTourPinText } from "@/lib/map/browseTourPinLabel";
import { placeTourPoiStops, browseCoveragePinText } from "@/lib/map/tourPoiStops";
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
import { fitTourLine } from "@/lib/tours/tourLine";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { suggestionFromPublicTour } from "@/lib/catalog/publicTourSuggestion";
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
import {
  PlanWaypointEditor,
  type PlanAddrSlot,
} from "@/components/discover/PlanWaypointEditor";
import { PlanRouteInsight } from "@/components/discover/PlanRouteInsight";
import { PlanAdaptBanner } from "@/components/discover/PlanAdaptBanner";
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
  applyBrowseMapPin,
  applyPlanMapLongPress,
  applyPlanMapTap,
  attachTrailToDraft,
  adoptTrailToDraft,
  computeQuickOptions,
  computeLoopOptions,
  emptyDraft,
  endOf,
  orderedWaypoints,
  resolvePointToPointDraft,
  routeResultMessage,
  setEnd,
  setStart,
  shouldHideDiscoverTourRibbon,
  discoverSelectedTourLine,
  draftHasDiscoverTourPreview,
  snapToTourParts,
  startOf,
  swapStartEnd,
  moveWaypoint,
  setWaypoint,
  updateWaypointLabel,
  insertViaAlong,
  isClosedLoop,
  planDistanceTicks,
  planDistanceTicksMinZoom,
  planPinAlongMeters,
  planReshapeHandles,
  planShapeRouteId,
  planViaMapCaption,
  planMapShowsRoutingWait,
  planMapHistoryFabsVisible,
  planMapAdaptingHintOnMap,
  planParkedFingerClearsWhenIdle,
  planMapDestWaitHintOnMap,
  planMapDestWaitCopy,
  planMapStopHintVisible,
  PLAN_STOP_HINT_MS,
  planLineCoachShouldShow,
  planRibbonLegendKinds,
  planEditorSheetRecedes,
  type BaseTour,
  type PlanDraft,
  type PlanMode,
  type QuickOption,
} from "@/lib/routing/planDraft";
import { pointAlongRoute } from "@/lib/routing/routeProgress";
import { warmupLiveRouting } from "@/lib/routing/warmupClient";
import { snapPointOntoTrails, trailIsCorridorEligible, trailsForViaSnap, viaMaySnapOntoTrail } from "@/lib/routing/snapTrailCorridor";
import {
  fetchPublicRideGroups,
  isCloudFail,
} from "@/lib/community/rideGroupCloud";
import { groupMeetPinsOnExplore } from "@/lib/community/rideGroupMap";
import type { RideGroup } from "@/lib/community/types";
import { httpsAppLink, rideOpenPath } from "@/lib/web/appLinks";
import {
  fetchEndpointElevations,
  trailAccessHaversineKm,
} from "@/lib/routing/trailAccess";
import {
  buildDiscoverMapLayers,
  buildPlanGradeOverlayLayers,
} from "@/lib/routing/discoverMapLayers";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";
import { lineWithApiElevation } from "@/lib/routing/elevationAttach";
import {
  lastPlanDestChipName,
  lastPlanDestShouldOffer,
  lastPlanDestWorthRemembering,
  loadLastPlanDest,
  loadLastPlanDestDismissed,
  saveLastPlanDest,
  dismissLastPlanDest,
  type LastPlanDest,
} from "@/lib/routing/lastPlanDest";
import {
  emptyPlanHistory,
  planEditKey,
  pushPlanHistory,
  redoPlanHistory,
  undoPlanHistory,
} from "@/lib/routing/planHistory";
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
import { MappeEmpty } from "@/components/tours/MappeEmpty";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { SavedMappeTile } from "@/components/tours/SavedMappeTile";
import { mappeSourceChip } from "@/lib/tours/mappeList";
import {
  formatMappeDay,
  joinMappeCaption,
  lastRideForSavedRoute,
  latestConditionTag,
} from "@/lib/tours/tourAkte";
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
import { profileAllowsOsmRoundTrip } from "@/lib/routing/osmRoundTrip";
import {
  loopJustificationReasons,
  surfaceFromLoopWarnings,
} from "@/lib/routing/loopReasons";
import {
  aroundKmDisplay,
  countActiveRouteFilters,
  matchesExploreQuery,
  shouldFlyExploreToPlace,
  shouldOfferExplorePlaceHits,
} from "@/lib/discover/discoverExploreChrome";
import { AroundYouLoopCta } from "@/components/discover/AroundYouLoopCta";
import {
  shouldFlyToPlace,
  shouldOfferPlaceHits,
} from "@/lib/discover/browsePlaceSearch";
import {
  beginNavigateIntent,
  discoverRundkursActive,
  placeHitAppliesAsDestination,
  shouldForceLoopOnlyFromNearMe,
  type NavigatePlaceHit,
} from "@/lib/discover/navigateWorkflow";
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
import { isPlaceholderPlanLabel } from "@/lib/geocode/photonFeature";
import {
  pushPlanAddrRecent,
  readPlanAddrRecents,
  writePlanAddrRecents,
} from "@/lib/geocode/planAddrRecents";
import { platzCopy } from "@/lib/i18n/platzCopy";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import {
  filterSavedByVisibility,
  stimmenTourIdOf,
  visibilityOf,
} from "@/lib/tours/routeVisibility";

type SheetMode = "quick" | "plan" | "tours";

const FALLBACK_CENTER: [number, number] = WEB_DISCOVER_FALLBACK;
/** Abort stuck „Berechne…“ so Quick always recovers to seeds + retry. */
const QUICK_TIMEOUT_MS = 5000;
const LOOP_TIMEOUT_MS = 22000;
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

function PlanRibbonLegend({
  layers,
  copy,
  kinds,
}: {
  layers: MapRouteLayer[];
  copy: ReturnType<typeof discoverUi>;
  kinds?: string[];
}) {
  const roles = new Set(layers.map((l) => l.role));
  const keys = new Set(kinds ?? []);
  const items: { color: string; label: string }[] = [];
  if (roles.has("paved") || keys.has("asphalt")) {
    items.push({ color: "#5C8FBF", label: copy.surfaceAsphalt });
  }
  if (roles.has("gravel") || keys.has("gravel")) {
    items.push({ color: "#E0B04A", label: copy.surfaceSchotter });
  }
  if (roles.has("unpaved") || keys.has("trail")) {
    items.push({ color: "#C47B3A", label: copy.surfaceNatur });
  }
  if (keys.has("unknown")) {
    items.push({ color: "#FF6A00", label: copy.planMapUnknown });
  }
  if (roles.has("steep") || keys.has("steep")) {
    items.push({ color: "#C2410C", label: copy.planMapSteep });
  }
  if (!items.length) return null;
  return (
    <div className="absolute bottom-16 left-[max(0.75rem,var(--safe-left))] z-20 flex max-w-[min(22rem,calc(100%-5.5rem))] flex-wrap items-center gap-x-2.5 gap-y-1 rounded-full border border-black/10 bg-[#F4F1EC]/90 px-2.5 py-1.5 shadow-md max-[419px]:max-w-[min(22rem,calc(100%-5.5rem))] max-[419px]:gap-x-1.5">
      {items.map((it) => (
        <span
          key={it.label}
          title={it.label}
          className="flex items-center gap-1 text-[10px] font-semibold text-[#1A120C]"
        >
          <span
            className="inline-block h-2 w-2 rounded-full"
            style={{ background: it.color }}
          />
          <span className="max-[419px]:sr-only">{it.label}</span>
        </span>
      ))}
    </div>
  );
}

function DiscoverPageInner() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const d = discoverUi(lang);
  const g = platzCopy(lang);
  const stimme = catalogCopy(lang).stimmen;
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
  const asGroup = searchParams.get("asGroup") === "1";
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
  const myReviews = useCommunityStore((s) => s.myReviews);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const isRouteSaved = useAppStore((s) => s.isRouteSaved);
  const routeCollections = useAppStore((s) => s.routeCollections);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const [collectionName, setCollectionName] = useState("");
  const gpxInputRef = useRef<HTMLInputElement | null>(null);
  const addrInputRef = useRef<HTMLInputElement | null>(null);
  const [addrQuery, setAddrQuery] = useState("");
  const [addrTarget, setAddrTarget] = useState<PlanAddrSlot>("start");
  const [placeHits, setPlaceHits] = useState<NavigatePlaceHit[]>([]);
  const [lastPlace, setLastPlace] = useState<NavigatePlaceHit | null>(null);
  const [addrHits, setAddrHits] = useState<
    { label: string; lat: number; lng: number }[]
  >([]);
  const [addrBusy, setAddrBusy] = useState(false);
  const [addrRecents, setAddrRecents] = useState<
    { label: string; lat: number; lng: number }[]
  >([]);
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
    // Nur wenn der Hof ~60 schickt — Discover selbst startet ohne stillen Rundkurs.
    loopOnly: queryMinutes === 60,
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
  const [elevHoverKm, setElevHoverKm] = useState<number | null>(null);
  const [planElev, setPlanElev] = useState<ElevationProfile | null>(null);
  const [planCoach, setPlanCoach] = useState(false);
  const [planToast, setPlanToast] = useState<string | null>(null);
  const planToastTimer = useRef<number | null>(null);
  const [stopHintAt, setStopHintAt] = useState<[number, number] | null>(null);
  const [stopHintLabel, setStopHintLabel] = useState<string | null>(null);
  const stopHintTimer = useRef<number | null>(null);

  const clearStopHint = useCallback(() => {
    setStopHintAt(null);
    setStopHintLabel(null);
    if (stopHintTimer.current) {
      window.clearTimeout(stopHintTimer.current);
      stopHintTimer.current = null;
    }
  }, []);

  const showStopHint = useCallback(
    (at: [number, number], label: string) => {
      setStopHintAt(at);
      setStopHintLabel(label);
      if (stopHintTimer.current) window.clearTimeout(stopHintTimer.current);
      stopHintTimer.current = window.setTimeout(() => {
        setStopHintAt(null);
        setStopHintLabel(null);
        stopHintTimer.current = null;
      }, PLAN_STOP_HINT_MS);
    },
    []
  );
  const draftRef = useRef<PlanDraft>(emptyDraft(routingProfile));
  draftRef.current = draft;
  const [routingBusy, setRoutingBusy] = useState(false);
  const [shapeDragging, setShapeDragging] = useState(false);
  const [planShaped, setPlanShaped] = useState(false);
  const [destConfirmPulse, setDestConfirmPulse] = useState(false);
  const destPulseTimer = useRef<number | null>(null);
  const pulseDestConfirm = useCallback(
    (toast?: string) => {
      setDestConfirmPulse(true);
      if (toast) {
        setPlanToast(toast);
        if (planToastTimer.current) window.clearTimeout(planToastTimer.current);
        planToastTimer.current = window.setTimeout(() => setPlanToast(null), 1600);
      }
      if (destPulseTimer.current != null) {
        window.clearTimeout(destPulseTimer.current);
      }
      destPulseTimer.current = window.setTimeout(() => {
        setDestConfirmPulse(false);
        destPulseTimer.current = null;
      }, 1600);
    },
    []
  );
  const [savedLastDest, setSavedLastDest] = useState<LastPlanDest | null>(null);
  const [lastDestDismissed, setLastDestDismissed] = useState<LastPlanDest | null>(
    null
  );
  const [routingMsg, setRoutingMsg] = useState<string | null>(null);
  const [quickOptions, setQuickOptions] = useState<QuickOption[]>([]);
  const [quickBusy, setQuickBusy] = useState(false);
  const [quickTimedOut, setQuickTimedOut] = useState(false);
  const [quickRateLimited, setQuickRateLimited] = useState(false);
  /** NearMe dropdown — Rundkurs suppresses out-and-back Quick pads. */
  const [nearMeRouteMode, setNearMeRouteMode] = useState<
    "loop" | "point_to_point"
  >("loop");
  const [loopSeed, setLoopSeed] = useState(1);
  const [loopBusy, setLoopBusy] = useState(false);
  const [loopMsg, setLoopMsg] = useState<string | null>(null);
  const [aroundYouApplied, setAroundYouApplied] = useState(false);
  const [loopKm, setLoopKm] = useState<number | null>(null);
  const [loopMin, setLoopMin] = useState<number | null>(null);
  const loopAbortRef = useRef<AbortController | null>(null);
  const quickAbortRef = useRef<AbortController | null>(null);
  const quickDebounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const quickTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [previewTour, setPreviewTour] = useState<BaseTour | null>(null);
  const [highlightPoiId, setHighlightPoiId] = useState<string | null>(null);
  const [tourGeomById, setTourGeomById] = useState<
    Record<string, GeoJSON.LineString>
  >({});
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
  const [publicMeetGroups, setPublicMeetGroups] = useState<RideGroup[]>([]);
  const [valhallaLive, setValhallaLive] = useState(false);
  const [lastSavedId, setLastSavedId] = useState<string | null>(null);
  const [manualProfile, setManualProfile] = useState<RoutingProfile | null>(
    null
  );
  const [exploreQuery, setExploreQuery] = useState("");
  const [exploreNameFilter, setExploreNameFilter] = useState("");
  const [exploreHits, setExploreHits] = useState<
    { label: string; lat: number; lng: number }[]
  >([]);
  const [browseAnchor, setBrowseAnchor] = useState<[number, number] | null>(
    null
  );
  const [browseAnchorLabel, setBrowseAnchorLabel] = useState<string | null>(
    null
  );
  const [showTrails, setShowTrails] = useState(true);
  const [bikeOverlayOn, setBikeOverlayOn] = useState(true);
  const [bikeOverlayExtra, setBikeOverlayExtra] = useState<BikeOverlayClass[]>(
    () => [...overlayExploreAllClasses]
  );
  const [farmTracksOn, setFarmTracksOn] = useState(true);
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
  const planRecomputeRef = useRef<
    (next: PlanDraft, opts?: { history?: boolean }) => void
  >(() => {});
  const planHistoryRef = useRef(emptyPlanHistory());
  const [planCanUndo, setPlanCanUndo] = useState(false);
  const [planCanRedo, setPlanCanRedo] = useState(false);
  const lastPlaceRef = useRef<NavigatePlaceHit | null>(null);

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
  const aroundKm = aroundKmDisplay(filters.maxAwayKm ?? null);

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

  useEffect(() => {
    try {
      setPlanCoach(
        planLineCoachShouldShow(
          localStorage.getItem("flowline.planLineCoach.v1")
        )
      );
      setFarmTracksOn(localStorage.getItem("flowline.farmTracks.v1") !== "0");
    } catch {
      setPlanCoach(true);
    }
  }, []);

  useEffect(() => {
    if (planParkedFingerClearsWhenIdle(routingBusy)) setPlanShaped(false);
  }, [routingBusy]);

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

  const origin = browseAnchor ?? userPos ?? mapCenter;
  useEffect(() => {
    warmupLiveRouting(planCosting, origin, {
      hasStart: Boolean(startOf(draft)),
      hasEnd: Boolean(endOf(draft)),
    });
  }, [origin, planCosting, draft]);
  const addRouteStart = useMemo(() => {
    const vp = readDiscoverViewport();
    const persisted = vp ? ([vp.lng, vp.lat] as [number, number]) : null;
    const map =
      isLocalDiscoverZoom(mapZoom) && !isPlaceholderMapCenter(mapCenter)
        ? mapCenter
        : persisted;
    return resolveAddRouteStart({ gps: userPos, map });
  }, [userPos, mapCenter, mapZoom]);

  /** Rundkurs-Linse oder NearMe — NearMe nur auf der Quick-Schiene. */
  const rundkursActive = discoverRundkursActive({
    loopOnly: filters.loopOnly,
    nearMeRouteMode,
    sheetMode,
  });
  const suppressOutAndBackQuick = rundkursActive;
  const aroundYouEnabled =
    profileAllowsOsmRoundTrip(activeProfile) && garageSession !== "gravity";

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
        matchesExploreQuery(r, exploreNameFilter)
      ),
    [routes, honestyFilters, exploreNameFilter]
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
  const meetPins = useMemo(() => {
    const tours = [...nearbyRoutes, ...routes];
    return groupMeetPinsOnExplore({
      groups: publicMeetGroups,
      memberGroupIds: [],
      centerFor: (group) => {
        const tour = tours.find(
          (r) => r.id === group.catalogTourId || r.id === group.savedRouteId,
        );
        const center = tour?.center;
        if (!center || center.length < 2) return null;
        return { lat: center[1], lng: center[0] };
      },
    });
  }, [publicMeetGroups, nearbyRoutes, routes]);
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
      suggestionFromPublicTour(detailId) ??
      null;
    return fromCatalog;
  }, [detailId, activeBike, categoryHint, profile, minutes, range, routes, origin]);

  const selectedTourId =
    previewTour?.id ?? detailId ?? highlightRouteId ?? null;

  const selectedTourSuggestion = useMemo(() => {
    if (!selectedTourId) return null;
    return (
      nearbyRoutes.find((r) => r.id === selectedTourId) ??
      sixtyMinLoops.find((r) => r.id === selectedTourId) ??
      routes.find((r) => r.id === selectedTourId) ??
      detailRoute ??
      null
    );
  }, [
    selectedTourId,
    nearbyRoutes,
    sixtyMinLoops,
    routes,
    detailRoute,
  ]);

  const selectedTourGeometry = useMemo((): GeoJSON.LineString | null => {
    const hideRibbon = shouldHideDiscoverTourRibbon({
      planning: sheetMode === "plan",
      hasStart: Boolean(startOf(draft)),
      hasEnd: Boolean(endOf(draft)),
    });
    return discoverSelectedTourLine({
      draft,
      hideRibbon,
      previewing: Boolean(previewTour) || Boolean(detailId),
      cached: selectedTourId ? tourGeomById[selectedTourId] ?? null : null,
    });
  }, [draft, selectedTourId, tourGeomById, sheetMode, previewTour, detailId]);

  useEffect(() => {
    const end = endOf(draft);
    if (!end) return;
    const origin = startOf(draft) ?? userPos;
    if (
      !lastPlanDestWorthRemembering({
        destLat: end[1],
        destLng: end[0],
        originLat: origin?.[1],
        originLng: origin?.[0],
      })
    ) {
      return;
    }
    const raw = orderedWaypoints(draft)
      .find((w) => w.role === "end")
      ?.label?.trim();
    const skip =
      !raw ||
      raw === d.onMapPlace ||
      raw === DISCOVER_PIN_DE.planned ||
      raw === DISCOVER_PIN_DE.endMap;
    saveLastPlanDest({
      lat: end[1],
      lng: end[0],
      label: skip ? undefined : raw,
    });
    setSavedLastDest({
      lat: end[1],
      lng: end[0],
      label: skip ? undefined : raw,
    });
    setLastDestDismissed(null);
    if (!skip && raw) {
      setAddrRecents((prev) => {
        const next = pushPlanAddrRecent(
          { label: raw, lat: end[1], lng: end[0] },
          prev,
        );
        writePlanAddrRecents(next);
        return next;
      });
    }
  }, [draft, userPos, d.onMapPlace]);

  useEffect(() => {
    if (!highlightPoiId) return;
    const t = window.setTimeout(() => setHighlightPoiId(null), 3000);
    return () => window.clearTimeout(t);
  }, [highlightPoiId]);

  useEffect(() => {
    const tour = selectedTourSuggestion;
    if (!tour?.poiStops?.length || tour.durationMin <= 0) return;
    if (selectedTourGeometry) return;
    const hideRibbon = shouldHideDiscoverTourRibbon({
      planning: sheetMode === "plan",
      hasStart: Boolean(startOf(draft)),
      hasEnd: Boolean(endOf(draft)),
    });
    if (
      hideRibbon &&
      !previewTour &&
      !detailId &&
      !draftHasDiscoverTourPreview(draft)
    ) {
      return;
    }
    let cancelled = false;
    const profile = profileForBikeCategory(tour.category);
    const load = async () => {
      const byId = await fetch(
        `/api/tours/geometry?id=${encodeURIComponent(tour.id)}&profile=${encodeURIComponent(profile)}`
      );
      if (cancelled) return;
      let geom: GeoJSON.LineString | undefined;
      if (byId.ok) {
        const j = (await byId.json()) as { geometry?: GeoJSON.LineString };
        geom = j.geometry;
      } else if (tour.center) {
        const q = new URLSearchParams({
          lat: String(tour.center[1]),
          lng: String(tour.center[0]),
          mode: tour.loop ? "loop" : "point_to_point",
          distanceKm: String(tour.distanceKm),
          profile,
          label: tour.name,
        });
        const near = await fetch(`/api/tours/geometry?${q}`);
        if (!near.ok) return;
        const j = (await near.json()) as { geometry?: GeoJSON.LineString };
        geom = j.geometry;
      }
      if (cancelled || !geom?.coordinates || geom.coordinates.length < 2) return;
      setTourGeomById((prev) =>
        prev[tour.id] ? prev : { ...prev, [tour.id]: geom! }
      );
    };
    void load().catch(() => {
      /* pin-only — skip POIs without track */
    });
    return () => {
      cancelled = true;
    };
  }, [
    selectedTourSuggestion,
    selectedTourGeometry,
    sheetMode,
    draft,
    previewTour,
    detailId,
  ]);

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
    const mapRundkurs =
      rundkursActive && draft.mode !== "point_to_point";
    const mapDraft = mapRundkurs
      ? sanitizeDraftForRundkurs(draft)
      : draft;
    const mapQuick = suppressOutAndBackQuick ? [] : quickOptions;
    const base = buildDiscoverMapLayers({
      draft: mapDraft,
      quickOptions: mapQuick,
      activeQuickId: mapQuick.find((q) => q.label === mapDraft.label)?.id,
      trails: trailsForMap,
      showTrails: sheetMode === "tours" && trailsForMap.length > 0,
      rundkursOnly: mapRundkurs,
      rideProfileId: null,
      staleActive: routingBusy,
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
    const line = (mapDraft.computed?.geometry?.coordinates ?? []) as
      | [number, number][]
      | [];
    const grade =
      sheetMode === "plan" &&
      planElev &&
      line.length >= 2 &&
      planElev.points.length >= 2
        ? buildPlanGradeOverlayLayers({
            line,
            elevM: planElev.points
              .filter((p) => p.elevM != null && Number.isFinite(p.elevM))
              .map((p) => p.elevM as number),
            distKm: planElev.points
              .filter((p) => p.elevM != null && Number.isFinite(p.elevM))
              .map((p) => p.distKm),
            surfaceBands: planElev.surfaceBands,
          })
        : [];
    return [...heat, ...base, ...grade];
  }, [
    draft,
    quickOptions,
    suppressOutAndBackQuick,
    rundkursActive,
    nearbyTrails,
    trailsForMap,
    sheetMode,
    communityHeat,
    routingBusy,
    planElev,
  ]);

  const planFitPoints = useMemo((): [number, number][] | undefined => {
    if (holdMapFit || draft.computed) return undefined;
    const a = startOf(draft);
    const b = endOf(draft);
    if (!a || !b) return undefined;
    return [a, b];
  }, [holdMapFit, draft]);

  useEffect(() => {
    if (highlightRouteId) {
      setDetailId(highlightRouteId);
      setSheetMode("tours");
    }
  }, [highlightRouteId]);

  useEffect(() => {
    let cancelled = false;
    void fetchPublicRideGroups().then((out) => {
      if (cancelled || isCloudFail(out)) return;
      setPublicMeetGroups(out.groups);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const stored = readPlanAddrRecents();
    const last = loadLastPlanDest();
    setSavedLastDest(last);
    setLastDestDismissed(loadLastPlanDestDismissed());
    const label = last?.label?.trim() ?? "";
    if (last && label) {
      const merged = pushPlanAddrRecent(
        { label, lat: last.lat, lng: last.lng },
        stored,
      );
      writePlanAddrRecents(merged);
      setAddrRecents(merged);
    } else {
      setAddrRecents(stored);
    }
  }, []);

  useEffect(() => {
    if (modeParam === "rideOut") setRideOutChoice(true);
  }, [modeParam]);

  useEffect(() => {
    if (sheetParam === "plan" || panelParam === "plan") {
      setSheetMode("plan");
      setAddrTarget("end");
      setPickTarget("end");
    }
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
          setLocationStatus(DISCOVER_STATUS_DE.locGps);
        } else {
          setLocationStatus(DISCOVER_STATUS_DE.locDeepGps);
        }
        setDraft((d) => {
          if (startOf(d)) return d;
          const next = setStart(d, p, DISCOVER_PIN_DE.myPos);
          if (endOf(next)) {
            queueMicrotask(() =>
              planRecomputeRef.current(next, { history: false })
            );
          } else if (!queryCenter) {
            queueMicrotask(() => setMapCenter(p));
          }
          return next;
        });
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

  const generateAroundYou = useCallback(
    async (next = false) => {
      if (!profileAllowsOsmRoundTrip(activeProfile)) {
        setLoopMsg(d.aroundYouSport);
        return;
      }
      loopAbortRef.current?.abort();
      const ac = new AbortController();
      loopAbortRef.current = ac;
      const seed = next ? loopSeed + 1 : loopSeed;
      setLoopBusy(true);
      setLoopMsg(null);
      const timer = window.setTimeout(() => ac.abort(), LOOP_TIMEOUT_MS);
      try {
        const { option, error } = await computeLoopOptions(
          origin,
          activeProfile,
          minutes,
          { seed, signal: ac.signal, lang }
        );
        if (ac.signal.aborted) return;
        if (!option) {
          setLoopMsg(
            error === "profile" ? d.aroundYouSport : d.aroundYouFail
          );
          return;
        }
        setLoopSeed(seed);
        setAroundYouApplied(true);
        setLoopKm(option.result.distanceM / 1000);
        setLoopMin(Math.round(option.result.durationS / 60));
        setHoldMapFit(false);
        setDraft((dr) => ({
          ...setStart(
            { ...dr, mode: "quick", profile: activeProfile },
            origin,
            DISCOVER_PIN_DE.here
          ),
          computed: { ...option.result, loop: true },
          label: d.aroundYouLoop,
          baseTour: undefined,
        }));
        setPreviewTour(null);
        setLoopMsg(d.aroundYouHint);
      } catch {
        if (!ac.signal.aborted) setLoopMsg(d.aroundYouFail);
      } finally {
        window.clearTimeout(timer);
        setLoopBusy(false);
      }
    },
    [
      activeProfile,
      d.aroundYouFail,
      d.aroundYouHint,
      d.aroundYouLoop,
      d.aroundYouSport,
      lang,
      loopSeed,
      minutes,
      origin,
    ]
  );

  // NearMe Route=Rundkurs hält den Quick-Filter — nicht das Navigieren.
  useEffect(() => {
    if (
      !shouldForceLoopOnlyFromNearMe({
        nearMeRouteMode,
        sheetMode,
      })
    ) {
      return;
    }
    setFilters((f) => (f.loopOnly ? f : { ...f, loopOnly: true }));
  }, [nearMeRouteMode, sheetMode]);

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

  const flashTourPoi = useCallback(
    (poiId: string) => {
      setHighlightPoiId(poiId);
      if (!selectedTourId) return;
      if (detailId !== selectedTourId) openDetail(selectedTourId);
    },
    [selectedTourId, detailId, openDetail]
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
    async (r: RouteSuggestion | SavedRoute) => {
      if (isRouteSaved(r.id)) {
        unsaveRoute(r.id);
        return;
      }
      const existing =
        "geometry" in r && r.geometry?.coordinates?.length
          ? r.geometry.coordinates
          : null;
      let coords = existing;
      if (!coords || coords.length < 2) {
        try {
          const res = await fetch(
            `/api/tours/geometry?id=${encodeURIComponent(r.id)}`,
          );
          if (res.ok) {
            const j = (await res.json()) as {
              geometry?: GeoJSON.LineString | null;
            };
            const raw = j?.geometry?.coordinates;
            if (raw && raw.length >= 2) coords = raw;
          }
        } catch {
          /* pin-only merken */
        }
      }
      if (coords && coords.length >= 2) {
        const live = draft.computed?.geometry?.coordinates;
        const reuseProfile =
          live &&
          live.length === coords.length &&
          live[0]?.[0] === coords[0]?.[0] &&
          live[0]?.[1] === coords[0]?.[1]
            ? planElev
            : null;
        const withEle = await lineWithApiElevation(coords, reuseProfile);
        saveRoute({
          id: r.id,
          name: r.name,
          distanceKm: r.distanceKm,
          elevationM: r.elevationM,
          durationMin: r.durationMin,
          mtbScale: "mtbScale" in r ? r.mtbScale : undefined,
          surface: "surface" in r ? r.surface : undefined,
          reasons: r.reasons,
          savedAt: new Date().toISOString(),
          source: "source" in r ? r.source : "suggestion",
          geometry: { type: "LineString", coordinates: withEle },
          waypoints: "waypoints" in r ? r.waypoints : undefined,
          layers: "layers" in r ? r.layers : undefined,
        });
        return;
      }
      saveRoute(r);
    },
    [draft.computed?.geometry?.coordinates, isRouteSaved, planElev, saveRoute, unsaveRoute],
  );

  const saveCurrentDraft = useCallback(async () => {
    if (!draft.computed) return;
    const id = `saved-${Date.now()}`;
    const distanceKm =
      Math.round((draft.computed.distanceM / 1000) * 10) / 10;
    // Real/sanitized seed ascent only — never invent hm from geometry/distance.
    const catalogHm = sanitizeElevationM(
      draft.baseTour?.elevationM,
      distanceKm,
    );
    const apiHm =
      planElev && planElev.source !== "demo"
        ? sanitizeElevationM(planElev.totalClimbM, distanceKm)
        : null;
    const elevationM = catalogHm ?? apiHm ?? 0;
    const withEle = await lineWithApiElevation(
      draft.computed.geometry.coordinates,
      planElev,
    );
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
      geometry: {
        type: "LineString",
        coordinates: withEle,
      },
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
    if (asGroup) {
      const url = new URL(window.location.href);
      url.searchParams.delete("asGroup");
      window.history.replaceState({}, "", `${url.pathname}${url.search}`);
      router.push(`/library?groupCreate=${encodeURIComponent(id)}`);
    }
  }, [asGroup, draft, planElev, router, saveRoute]);

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
        loop: fitTourLine(parsed.coordinates)?.loop === true,
        geometry: {
          type: "LineString",
          coordinates: parsed.coordinates,
        },
      };
      saveRoute(entry);
      if (asGroup) {
        const url = new URL(window.location.href);
        url.searchParams.delete("asGroup");
        window.history.replaceState({}, "", `${url.pathname}${url.search}`);
        router.push(`/library?groupCreate=${encodeURIComponent(entry.id)}`);
        return;
      }
      setSheetMode("tours");
      setRoutingMsg(
        `GPX importiert: ${parsed.name} · ${parsed.distanceKm.toFixed(1)} km`
      );
    },
    [asGroup, router, saveRoute]
  );

  const searchGeocode = useCallback(
    async (q: string) => {
      const trimmed = q.trim();
      if (trimmed.length < 2) return [];
      const [lon, lat] = browseAnchor ?? userPos ?? mapCenter;
      const res = await fetch(
        `/api/geocode?q=${encodeURIComponent(trimmed)}&limit=5&lat=${lat}&lon=${lon}`
      );
      const data = (await res.json()) as {
        hits?: { label: string; lat: number; lng: number }[];
        error?: string;
      };
      if (!res.ok) {
        throw new Error(
          data.error ?? `Adresssuche fehlgeschlagen (${res.status})`
        );
      }
      return data.hits ?? [];
    },
    [browseAnchor, userPos, mapCenter]
  );

  const searchAddress = useCallback(async () => {
    const q = addrQuery.trim();
    if (q.length < 2) {
      setAddrHits([]);
      return;
    }
    setAddrBusy(true);
    try {
      const hits = await searchGeocode(q);
      setAddrHits(hits);
      if (!hits.length) setRoutingMsg(`Keine Treffer für „${q}“`);
    } catch (e) {
      setAddrHits([]);
      setRoutingMsg(
        e instanceof Error ? e.message : DISCOVER_STATUS_DE.geocodeFail
      );
    } finally {
      setAddrBusy(false);
    }
  }, [addrQuery, searchGeocode]);

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

  const rememberAddrRecent = useCallback(
    (hit: { label: string; lat: number; lng: number }) => {
      setAddrRecents((prev) => {
        const next = pushPlanAddrRecent(hit, prev);
        writePlanAddrRecents(next);
        return next;
      });
    },
    []
  );

  const flyExplorePlace = useCallback(
    (hit: { label: string; lat: number; lng: number }) => {
      lastPlaceRef.current = hit;
      setLastPlace(hit);
      const center: [number, number] = [hit.lng, hit.lat];
      setBrowseAnchor(center);
      setBrowseAnchorLabel(hit.label);
      setHoldMapFit(true);
      setMapCenter(center);
      setExploreQuery(hit.label);
      setExploreNameFilter("");
      setExploreHits([]);
      rememberAddrRecent(hit);
    },
    [rememberAddrRecent]
  );

  const submitExploreSearch = useCallback(async () => {
    const q = exploreQuery.trim();
    if (q.length < 2) return;
    const names = filtered.map((r) => r.name);
    if (!shouldFlyExploreToPlace(q, names) && exploreHits.length > 1) {
      return;
    }
    if (exploreHits[0]) {
      flyExplorePlace(exploreHits[0]);
      return;
    }
    try {
      const hits = await searchGeocode(q);
      if (hits[0]) flyExplorePlace(hits[0]);
    } catch {
      setRoutingMsg(DISCOVER_STATUS_DE.geocodeFail);
    }
  }, [exploreQuery, exploreHits, filtered, flyExplorePlace, searchGeocode]);

  useEffect(() => {
    if (!shouldOfferExplorePlaceHits(exploreQuery)) {
      setExploreHits([]);
      return;
    }
    const q = exploreQuery.trim();
    const t = window.setTimeout(() => {
      void searchGeocode(q)
        .then((hits) => setExploreHits(hits.slice(0, 5)))
        .catch(() => setExploreHits([]));
    }, 350);
    return () => window.clearTimeout(t);
  }, [exploreQuery, searchGeocode]);

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
      void fillPlaceholderLabels(next);
      setPreviewTour(null);
      setRoutingMsg(routeResultMessage(next.computed));
    } finally {
      setRoutingBusy(false);
    }
  };

  const previewBaseTour = (tour: BaseTour) => {
    setHoldMapFit(false);
    setHighlightPoiId(null);
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
      const next: PlanDraft = {
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
      };
      setPreviewTour(null);
      setDraft(next);
      setSheetMode("plan");
      setMapCenter(pin);
      setRoutingMsg(
        `In Planen: ${tour.name} — Ziel auf der Karte oder als Adresse setzen (kein Track).`
      );
      void fillPlaceholderLabels(next);
      return;
    }
    const startLngLat = coords[0] as [number, number];
    const endLngLat = coords[coords.length - 1] as [number, number];
    const adopted = adoptTour(tour, activeProfile);
    const next: PlanDraft = {
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
      baseTour: tour,
      hybrid: undefined,
      layers: undefined,
    };
    setPreviewTour(null);
    setSheetMode("plan");
    setRoutingMsg(`In Planen: ${tour.name} — Start/Ziel editierbar`);
    if (tour.center) setMapCenter(tour.center);
    void fillPlaceholderLabels(next);
    planRecomputeRef.current(next);
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
    (nextDraft: PlanDraft, opts?: { history?: boolean }) => {
      if (opts?.history !== false) {
        const from = draftRef.current;
        if (planEditKey(from) !== planEditKey(nextDraft)) {
          planHistoryRef.current = pushPlanHistory(planHistoryRef.current, from);
          setPlanCanUndo(true);
          setPlanCanRedo(false);
        }
      }
      setDraft(nextDraft);
      if (planDebounceRef.current) clearTimeout(planDebounceRef.current);
      planDebounceRef.current = setTimeout(() => {
        void (async () => {
          if (!startOf(nextDraft) || !endOf(nextDraft)) return;
          setRoutingBusy(true);
          setRoutingMsg(d.computingRoute);
          try {
            const next = await resolvePointToPointDraft(
              { ...nextDraft, profile: planCosting },
              {
                trails: nearbyTrails.filter(trailIsCorridorEligible),
                origin: userPos ?? origin,
              }
            );
            if (next?.computed) {
              setDraft({ ...next, profile: activeProfile });
              void fillPlaceholderLabels(next);
              setRoutingMsg(routeResultMessage(next.computed));
            }
          } finally {
            setRoutingBusy(false);
          }
        })();
      }, 450);
    },
    [activeProfile, planCosting, origin, nearbyTrails, userPos, d.computingRoute]
  );
  planRecomputeRef.current = schedulePlanRecompute;

  const commitPlanEdit = useCallback(
    (next: PlanDraft) => {
      const viaBefore = draftRef.current.waypoints.filter(
        (w) => w.role === "via"
      ).length;
      const viaAfter = next.waypoints.filter((w) => w.role === "via").length;
      schedulePlanRecompute(next);
      if (viaAfter <= viaBefore) return;
      const lastVia = orderedWaypoints(next)
        .filter((w) => w.role === "via")
        .at(-1);
      if (lastVia) {
        showStopHint(lastVia.lngLat, d.planStopSetHint);
      }
      if (planCoach) {
        try {
          localStorage.setItem(
            "flowline.planLineCoach.v1",
            String(Date.now())
          );
        } catch {
          /* ignore */
        }
        setPlanCoach(false);
      }
    },
    [d.planStopSetHint, planCoach, schedulePlanRecompute, showStopHint]
  );

  const undoPlanEdit = useCallback(() => {
    const next = undoPlanHistory(planHistoryRef.current, draftRef.current);
    if (!next) return;
    planHistoryRef.current = next.history;
    setPlanCanUndo(next.history.past.length > 0);
    setPlanCanRedo(next.history.future.length > 0);
    setPlanToast(null);
    clearStopHint();
    setPlanShaped(false);
    if (planDebounceRef.current) clearTimeout(planDebounceRef.current);
    setDraft(next.draft);
    if (next.draft.computed && startOf(next.draft) && endOf(next.draft)) {
      setRoutingBusy(false);
      setRoutingMsg(routeResultMessage(next.draft.computed));
      return;
    }
    schedulePlanRecompute(next.draft, { history: false });
  }, [clearStopHint, schedulePlanRecompute]);

  const redoPlanEdit = useCallback(() => {
    const next = redoPlanHistory(planHistoryRef.current, draftRef.current);
    if (!next) return;
    planHistoryRef.current = next.history;
    setPlanCanUndo(next.history.past.length > 0);
    setPlanCanRedo(next.history.future.length > 0);
    setPlanToast(null);
    clearStopHint();
    setPlanShaped(false);
    if (planDebounceRef.current) clearTimeout(planDebounceRef.current);
    setDraft(next.draft);
    if (next.draft.computed && startOf(next.draft) && endOf(next.draft)) {
      setRoutingBusy(false);
      setRoutingMsg(routeResultMessage(next.draft.computed));
      return;
    }
    schedulePlanRecompute(next.draft, { history: false });
  }, [clearStopHint, schedulePlanRecompute]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const t = e.target;
      if (t instanceof HTMLElement) {
        const tag = t.tagName;
        if (
          tag === "INPUT" ||
          tag === "TEXTAREA" ||
          tag === "SELECT" ||
          t.isContentEditable
        ) {
          return;
        }
      }
      if (sheetMode !== "plan") return;
      if (!(e.metaKey || e.ctrlKey)) return;
      const z = e.key === "z" || e.key === "Z";
      const y = e.key === "y" || e.key === "Y";
      if (z && e.shiftKey) {
        e.preventDefault();
        redoPlanEdit();
      } else if (z) {
        e.preventDefault();
        undoPlanEdit();
      } else if (y) {
        e.preventDefault();
        redoPlanEdit();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [sheetMode, undoPlanEdit, redoPlanEdit]);

  const reverseLngLat = useCallback(
    async (lngLat: [number, number]) => {
      try {
        const res = await fetch(
          `/api/geocode?lat=${lngLat[1]}&lon=${lngLat[0]}&lang=${lang}`
        );
        if (!res.ok) return null;
        const data = (await res.json()) as { hits?: { label?: string }[] };
        return data.hits?.[0]?.label?.trim() || null;
      } catch {
        return null;
      }
    },
    [lang]
  );

  const fillPlaceholderLabels = useCallback(
    async (next: PlanDraft) => {
      const placeholders = [
        DISCOVER_PIN_DE.startMap,
        DISCOVER_PIN_DE.endMap,
        DISCOVER_PIN_DE.here,
        DISCOVER_PIN_DE.tourStart,
        DISCOVER_PIN_DE.tourEnd,
        DISCOVER_PIN_DE.tourPlace,
        d.onMapPlace,
      ];
      for (const w of next.waypoints) {
        if (w.label === DISCOVER_PIN_DE.myPos) continue;
        if (!isPlaceholderPlanLabel(w.label, placeholders)) continue;
        const name = await reverseLngLat(w.lngLat);
        if (!name) continue;
        setDraft((prev) => updateWaypointLabel(prev, w.id, name));
      }
    },
    [d.onMapPlace, reverseLngLat]
  );

  const planProfileKey = `${sheetMode}:${activeProfile}:${planCosting}`;
  const lastPlanProfileKey = useRef<string | null>(null);
  useEffect(() => {
    if (sheetMode !== "plan") {
      lastPlanProfileKey.current = planProfileKey;
      return;
    }
    if (lastPlanProfileKey.current === planProfileKey) return;
    lastPlanProfileKey.current = planProfileKey;
    setDraft((d) => {
      if (!startOf(d) || !endOf(d)) return { ...d, profile: activeProfile };
      const next = { ...d, profile: activeProfile };
      schedulePlanRecompute(next);
      return next;
    });
  }, [planProfileKey, sheetMode, activeProfile, schedulePlanRecompute]);

  const applyAddressHit = useCallback(
    (hit: { label: string; lat: number; lng: number }) => {
      const lngLat: [number, number] = [hit.lng, hit.lat];
      setLastPlace(hit);
      setDraft((prev) => {
        let next: PlanDraft;
        if (addrTarget === "end") next = setEnd(prev, lngLat, hit.label);
        else if (addrTarget === "start") next = setStart(prev, lngLat, hit.label);
        else if (prev.waypoints.some((w) => w.id === addrTarget)) {
          next = setWaypoint(prev, addrTarget, lngLat, hit.label);
        } else {
          next = addVia(prev, lngLat, hit.label);
        }
        commitPlanEdit(next);
        return next;
      });
      setAddrHits([]);
      setPlaceHits([]);
      setAddrQuery(hit.label);
      rememberAddrRecent(hit);
      setMapCenter([hit.lng, hit.lat]);
      setRoutingMsg(
        addrTarget === "end"
          ? `${d.end}: ${hit.label}`
          : addrTarget === "start"
            ? `${d.start}: ${hit.label}`
            : `${d.addStop}: ${hit.label}`
      );
    },
    [addrTarget, commitPlanEdit, d.addStop, d.end, d.start, rememberAddrRecent]
  );

  const applyPlaceHit = useCallback(
    (hit: NavigatePlaceHit) => {
      lastPlaceRef.current = hit;
      setLastPlace(hit);
      setExploreQuery(hit.label);
      setPlaceHits([]);
      setMapCenter([hit.lng, hit.lat]);
      if (placeHitAppliesAsDestination(sheetMode)) {
        setAddrTarget("end");
        setAddrQuery(hit.label);
        setDraft((prev) => {
          const next = setEnd(prev, [hit.lng, hit.lat], hit.label);
          schedulePlanRecompute(next);
          return next;
        });
        setRoutingMsg(`Ziel: ${hit.label}`);
        return;
      }
      setRoutingMsg(`Ort: ${hit.label}`);
    },
    [sheetMode, schedulePlanRecompute]
  );

  const searchChromePlaces = useCallback(async (q: string) => {
    if (!shouldOfferPlaceHits(q)) {
      setPlaceHits((cur) => (cur.length === 0 ? cur : []));
      return;
    }
    const [lon, lat] = userPos ?? mapCenter;
    try {
      const res = await fetch(
        `/api/geocode?q=${encodeURIComponent(q)}&limit=5&lat=${lat}&lon=${lon}`
      );
      const data = (await res.json()) as { hits?: NavigatePlaceHit[] };
      if (!res.ok) {
        setPlaceHits((cur) => (cur.length === 0 ? cur : []));
        return;
      }
      setPlaceHits(data.hits ?? []);
    } catch {
      setPlaceHits((cur) => (cur.length === 0 ? cur : []));
    }
  }, [userPos, mapCenter]);

  useEffect(() => {
    if (!shouldOfferPlaceHits(exploreQuery)) {
      setPlaceHits((cur) => (cur.length === 0 ? cur : []));
      return;
    }
    const t = window.setTimeout(() => {
      void searchChromePlaces(exploreQuery);
    }, 420);
    return () => window.clearTimeout(t);
  }, [exploreQuery, searchChromePlaces]);

  const submitChromeSearch = useCallback(() => {
    const q = exploreQuery.trim();
    if (q.length < 2) return;
    const first = placeHits[0];
    if (first && shouldFlyToPlace({ query: q, visibleTourNames: filtered.map((r) => r.name) })) {
      applyPlaceHit(first);
      return;
    }
    if (first) applyPlaceHit(first);
  }, [exploreQuery, placeHits, filtered, applyPlaceHit]);

  const beginNavigate = useCallback(() => {
    const intent = beginNavigateIntent({
      hasEnd: Boolean(endOf(draft)),
      lastPlace: lastPlaceRef.current ?? lastPlace,
      pendingHits: placeHits,
    });
    setSheetMode("plan");
    setAddrTarget(intent.addrTarget);
    setPickTarget(intent.pickTarget);
    let next = { ...draft, mode: "point_to_point" as const };
    const start = startOf(next);
    if (userPos && (!start || isPlaceholderMapCenter(start))) {
      next = setStart(next, userPos, DISCOVER_PIN_DE.myPos);
    }
    if (intent.destination) {
      next = setEnd(
        next,
        [intent.destination.lng, intent.destination.lat],
        intent.destination.label
      );
      setAddrQuery(intent.destination.label);
      setMapCenter([intent.destination.lng, intent.destination.lat]);
      setLastPlace(intent.destination);
      schedulePlanRecompute(next);
    } else {
      setDraft(next);
    }
    requestAnimationFrame(() => {
      addrInputRef.current?.focus();
    });
  }, [draft, lastPlace, placeHits, userPos, schedulePlanRecompute]);

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

  const onMapLongPress = (lngLat: [number, number]) => {
    if (pickTarget) {
      onMapClick(lngLat);
      return;
    }
    const trails = trailsForViaSnap(liveOsmTrails);
    const snapVia = (p: [number, number]) => snapPointOntoTrails(p, trails);
    const tourPreviewOnMap = Boolean(
      previewTour || detailId
    );
    if (sheetMode === "plan") {
      setDraft((prev) => {
        const line = (prev.computed?.geometry?.coordinates ?? []) as
          | [number, number][]
          | undefined;
        const next = applyPlanMapLongPress(prev, lngLat, {
          gps: userPos,
          picking: pickTarget,
          startLabel: d.onMapPlace,
          endLabel: d.onMapPlace,
          myPosLabel: DISCOVER_PIN_DE.myPos,
          snapVia,
          line,
          zoom: mapZoom,
          tourPreviewOnMap: Boolean(
            tourPreviewOnMap ||
              prev.baseTour ||
              prev.layers?.tour ||
              prev.mode === "tour"
          ),
        });
        setHoldMapFit(false);
        commitPlanEdit(next);
        void fillPlaceholderLabels(next);
        return next;
      });
      pulseDestConfirm();
      setPickTarget(null);
      return;
    }
    setDraft((prev) => {
      const next = applyBrowseMapPin(prev, lngLat, {
        gps: userPos,
        startLabel: d.onMapPlace,
        endLabel: d.onMapPlace,
        myPosLabel: DISCOVER_PIN_DE.myPos,
        snapVia,
        tourPreviewOnMap: Boolean(
          tourPreviewOnMap ||
            prev.baseTour ||
            prev.layers?.tour ||
            prev.mode === "tour"
        ),
      });
      if (!startOf(prev) && !userPos) setMapCenter(lngLat);
      setHoldMapFit(false);
      commitPlanEdit(next);
      void fillPlaceholderLabels(next);
      return next;
    });
    setPreviewTour(null);
    setDetailId(null);
    setPickTarget(null);
    setSheetMode("plan");
    pulseDestConfirm();
  };

  const onMapClick = (lngLat: [number, number], mods?: { alt?: boolean }) => {
    if (!pickTarget && sheetMode !== "plan") return;
    const trails = trailsForViaSnap(liveOsmTrails);
    setDraft((prev) => {
      const line = (prev.computed?.geometry?.coordinates ?? []) as
        | [number, number][]
        | undefined;
      const next = applyPlanMapTap(prev, lngLat, {
        gps: userPos,
        picking: pickTarget,
        startLabel: d.onMapPlace,
        endLabel: d.onMapPlace,
        myPosLabel: DISCOVER_PIN_DE.myPos,
        snapVia: (p) => snapPointOntoTrails(p, trails),
        line,
        zoom: mapZoom,
        forceEnd: Boolean(mods?.alt),
        routingBusy,
        tourPreviewOnMap: Boolean(
          previewTour ||
            detailId ||
            prev.baseTour ||
            prev.layers?.tour ||
            prev.mode === "tour"
        ),
      });
      if (pickTarget === "start") setMapCenter(lngLat);
      setHoldMapFit(false);
      commitPlanEdit(next);
      void fillPlaceholderLabels(next);
      return next;
    });
    setPreviewTour(null);
    setDetailId(null);
    setPickTarget(null);
    setSheetMode("plan");
    if (mods?.alt) pulseDestConfirm();
  };

  const lastDestOffer = lastPlanDestShouldOffer({
    saved: savedLastDest,
    dismissed: lastDestDismissed,
    hasEnd: Boolean(endOf(draft)),
    gpsLat: userPos?.[1],
    gpsLng: userPos?.[0],
    viewLat: mapCenter[1],
    viewLng: mapCenter[0],
  });

  const markers: MapMarker[] = useMemo(() => {
    const m: MapMarker[] = [];
    let viaIdx = 0;
    for (const w of orderedWaypoints(draft)) {
      if (w.role === "start") {
        m.push({
          id: w.id,
          lngLat: w.lngLat,
          color: "#2E7D32",
          kind: "start",
          draggable: sheetMode === "plan",
        });
      } else if (w.role === "end") {
        const destBusy =
          routingBusy ||
          destConfirmPulse ||
          (Boolean(endOf(draft)) && !startOf(draft));
        if (destBusy) {
          m.push({
            id: "end-glow",
            lngLat: w.lngLat,
            color: "#FFE0B2",
            kind: "halo",
            pulse: true,
          });
        }
        m.push({
          id: w.id,
          lngLat: w.lngLat,
          color: "#FF6A00",
          kind: "finish",
          draggable: sheetMode === "plan",
          pulse: destBusy,
          caption: sheetMode === "plan" ? d.end : undefined,
        });
      } else {
        viaIdx += 1;
        m.push({
          id: w.id,
          lngLat: w.lngLat,
          color: "#FF6A00",
          kind: "via",
          label: String(viaIdx),
          caption:
            planViaMapCaption(w.label, [d.onMapPlace, d.viaN(viaIdx)]) ??
            undefined,
          draggable: sheetMode === "plan",
        });
      }
    }
    const planLine = (draft.computed?.geometry?.coordinates ?? []) as
      | [number, number][]
      | [];
    if (
      sheetMode === "plan" &&
      planLine.length >= 2 &&
      startOf(draft) &&
      endOf(draft)
    ) {
      const vias = orderedWaypoints(draft)
        .filter((w) => w.role === "via")
        .map((w) => w.lngLat);
      const handles = planReshapeHandles({
        line: planLine,
        vias,
        zoom: mapZoom,
      });
      handles.forEach((h, i) => {
        m.push({
          id: `shape-handle-${i}`,
          lngLat: [h.lng, h.lat],
          color: "#FF6A00",
          kind: "circle",
          draggable: true,
        });
      });
      const tickAvoid = [
        ...planPinAlongMeters(planLine, vias),
        ...handles.map((h) => h.alongM),
      ];
      if (!shapeDragging) {
        for (const t of planDistanceTicks({
          line: planLine,
          zoom: mapZoom,
          minZoom: planDistanceTicksMinZoom(
            draft.computed?.distanceM ?? 0
          ),
          avoidAlongM: tickAvoid,
        })) {
          m.push({
            id: `shape-tick-${t.km}-${t.lng}`,
            lngLat: [t.lng, t.lat],
            kind: "halo",
            label: `${t.km} km`,
          });
        }
      }
    }
    if (
      (aroundYouApplied || draft.computed?.loop) &&
      planLine.length >= 4
    ) {
      const mid = planLine[Math.floor(planLine.length / 2)];
      if (mid) {
        m.push({
          id: "loop-uncertain",
          lngLat: mid,
          kind: "halo",
          label: d.aroundYouUncertainShort,
        });
      }
    }
    const hideTourPins = shouldHideDiscoverTourRibbon({
      planning: sheetMode === "plan",
      hasStart: Boolean(startOf(draft)),
      hasEnd: Boolean(endOf(draft)),
    });
    const ideaCenter = draft.baseTour?.center;
    const noTrack =
      !draft.baseTour?.geometry ||
      (draft.baseTour.geometry.coordinates?.length ?? 0) < 2;
    if (
      !hideTourPins &&
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
          color: "#5C6B73",
          kind: "tour",
          label: "Idee",
        });
      }
    }
    const pinIds = new Set(m.map((x) => `${x.lngLat[0].toFixed(4)},${x.lngLat[1].toFixed(4)}`));
    for (const r of hideTourPins ? [] : nearbyRoutes) {
      if (!r.center) continue;
      const selected =
        previewTour?.id === r.id ||
        detailId === r.id ||
        highlightRouteId === r.id;
      const at =
        selected && selectedTourGeometry?.coordinates?.[0]
          ? (selectedTourGeometry.coordinates[0] as [number, number])
          : r.center;
      const key = `${at[0].toFixed(4)},${at[1].toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      m.push({
        id: `tour-${r.id}`,
        lngLat: at,
        color: r.loop ? "#FF6A00" : "#2A2E32",
        kind: "tour",
        glyph: pinGlyphForCategory(r.category),
        label: browseTourPinText({
          durationMin: r.durationMin,
          selected,
          zoom: mapZoom,
          name: r.name,
        }),
      });
    }
    const tourPois = placeTourPoiStops({
      stops: selectedTourSuggestion?.poiStops,
      durationMin: selectedTourSuggestion?.durationMin ?? 0,
      geometry: selectedTourGeometry,
      zoom: mapZoom,
      selectedId: highlightPoiId,
    });
    for (const p of tourPois) {
      const key = `${p.lngLat[0].toFixed(4)},${p.lngLat[1].toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      m.push({
        id: `poi-${p.id}`,
        lngLat: p.lngLat,
        kind: "poi",
        poiKind: p.poiKind,
        selected: p.selected,
        label: p.label,
      });
    }
    for (const p of googlePlaces.slice(0, 10)) {
      const key = `${p.lng.toFixed(4)},${p.lat.toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      const poiKind = coveragePlacePoiKind(p.kind);
      m.push({
        id: `place-${p.id}`,
        lngLat: [p.lng, p.lat],
        ...(poiKind
          ? { kind: "poi" as const, poiKind }
          : { color: "#5E35B1" }),
        selected: highlightPoiId === `place-${p.id}`,
        label: browseCoveragePinText(p.name, mapZoom),
      });
    }
    for (const p of meetPins) {
      const key = `${p.lng.toFixed(4)},${p.lat.toFixed(4)}`;
      if (pinIds.has(key)) continue;
      pinIds.add(key);
      const label = p.label.length > 12 ? `${p.label.slice(0, 11)}…` : p.label;
      m.push({
        id: p.placeId,
        lngLat: [p.lng, p.lat],
        color: "#E65100",
        kind: "meet",
        label,
      });
    }
    return m;
  }, [
    draft,
    sheetMode,
    routingBusy,
    destConfirmPulse,
    d.end,
    d.onMapPlace,
    nearbyRoutes,
    googlePlaces,
    meetPins,
    mapZoom,
    previewTour,
    detailId,
    highlightRouteId,
    selectedTourSuggestion,
    selectedTourGeometry,
    highlightPoiId,
    shapeDragging,
    aroundYouApplied,
    d.aroundYouUncertainShort,
    d.viaN,
  ]);

  const statsLine = draft.computed
    ? `${(draft.computed.distanceM / 1000).toFixed(1)} km · ${Math.round(draft.computed.durationS / 60)} min${
        aroundYouApplied || draft.computed.loop
          ? ` · ${d.aroundYouUncertainShort}`
          : ""
      }`
    : null;
  const debugRoutingNotice = consumerRoutingNotice(routingNotice);

  const aroundYouCtaProps = {
    busy: loopBusy,
    applied: aroundYouApplied,
    km: loopKm,
    minutes: loopMin,
    message: loopMsg,
    cta: d.aroundYouCta,
    another: d.aroundYouAnother,
    busyLabel: d.aroundYouBusy,
    hint: d.aroundYouHint,
    stats:
      loopKm != null && loopMin != null
        ? d.aroundYouStats(loopKm.toFixed(1), loopMin)
        : undefined,
    uncertain: d.aroundYouUncertainShort,
    reasons:
      aroundYouApplied && loopMin != null
        ? loopJustificationReasons({
            durationMin: loopMin,
            targetMin: minutes,
            surface: surfaceFromLoopWarnings(
              draft.computed?.warnings ?? []
            ),
            lang,
          })
        : undefined,
    onGenerate: (next: boolean) => void generateAroundYou(next),
  };
  const aroundYouBlock = aroundYouEnabled ? (
    <AroundYouLoopCta {...aroundYouCtaProps} />
  ) : null;
  const aroundYouCompact = aroundYouEnabled ? (
    <AroundYouLoopCta {...aroundYouCtaProps} compact />
  ) : null;
  const adaptingOnMap = planMapAdaptingHintOnMap({
    routingBusy,
    hasLiveLine: Boolean(draft.computed),
    hasFinger: planShaped,
  });
  const destWaitOnMap = planMapDestWaitHintOnMap({
    editorActive: sheetMode === "plan",
    routingBusy,
    hasStart: Boolean(startOf(draft)),
    hasEnd: Boolean(endOf(draft)),
    fingerHint: adaptingOnMap,
    destConfirm: destConfirmPulse,
    hasLiveLine: Boolean(draft.computed),
  });
  const waitOnMap = adaptingOnMap || destWaitOnMap;
  const destWaitCopy = planMapDestWaitCopy({
    hasStart: Boolean(startOf(draft)),
    hasLiveLine: Boolean(draft.computed),
  });
  const waitHidesChrome =
    adaptingOnMap || (destWaitOnMap && Boolean(startOf(draft)));
  const stopHintOnMap = planMapStopHintVisible({
    hasStopAt: Boolean(stopHintAt),
    waitHintOnMap: waitOnMap,
    rubberBand: shapeDragging,
  });
  const waitHintLabel = waitOnMap
    ? adaptingOnMap
      ? d.routingAdapts
      : destWaitOnMap && stopHintLabel === d.lastDestApplied
        ? stopHintLabel
        : destWaitCopy === "waitingGps"
          ? d.destSetWaitingGps
          : destWaitCopy === "firstAb"
            ? d.endSetComputing
            : d.routingAdapts
    : stopHintOnMap
      ? stopHintLabel ?? d.planStopSetHint
      : null;
  const mapHintOnMap = waitOnMap || stopHintOnMap;
  const sheetRecedes = planEditorSheetRecedes({
    rubberBand: shapeDragging,
    adapting: waitHidesChrome,
  });
  const routingWaitBanner = planMapShowsRoutingWait({
    editorActive: sheetMode === "plan",
    routingBusy,
    hasStart: Boolean(startOf(draft)),
    hasEnd: Boolean(endOf(draft)),
  });
  const historyFabsOnMap = planMapHistoryFabsVisible({
    editorActive: sheetMode === "plan",
    hasHistory: planCanUndo || planCanRedo,
    mapHintOnMap,
    rubberBand: shapeDragging,
    coachVisible: planCoach,
    routingWaitBanner,
  });

  return (
    <div className="flex min-h-[calc(100dvh-var(--hof-header-h)-var(--hof-tab-h))] flex-col lg:h-[calc(100dvh-var(--hof-header-h))] lg:flex-row lg:overflow-hidden">
      {/*
        Desktop: Side-Panel links + Vollkarte rechts (Komoot/RWGPS-Muster).
        Mobile: Karte oben, Panel unten.
      */}
      <aside className="order-2 flex min-h-0 flex-col border-t border-border bg-background lg:order-1 lg:w-[min(26rem,40vw)] lg:shrink-0 lg:border-r lg:border-t-0">
        {/* Dach */}
        <header className={`shrink-0 space-y-2 border-b border-border px-4 ${sheetMode === "plan" && sheetRecedes ? "max-lg:space-y-0 max-lg:pb-2 max-lg:pt-2" : "pb-3 pt-4 lg:pt-5"}`}>
          {debugRoutingNotice && !(sheetMode === "plan" && sheetRecedes) && (
            <p className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary">
              {discoverStatus(debugRoutingNotice, lang)}
            </p>
          )}
          {heatmapNote && !(sheetMode === "plan" && sheetRecedes) && (
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
          {sheetMode === "plan" ? (
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setSheetMode("tours")}
                className="grid h-10 w-10 shrink-0 place-items-center rounded-full border border-border bg-surface"
                aria-label={d.back}
              >
                <X className="h-4 w-4" />
              </button>
              <div className={`min-w-0 flex-1 ${sheetRecedes ? "max-lg:hidden" : ""}`}>
                <h1 className="text-xl font-bold tracking-tight">
                  {copy.mapSheetPlan}
                </h1>
                <p className="truncate text-xs text-text-secondary">
                  {activeBike
                    ? `${activeBike.name} · ${bikeCategoryLabel(activeBike.category)}`
                    : d.osmOptional}
                </p>
              </div>
              <div className={sheetRecedes ? "max-lg:hidden" : ""}>
                <BikeChip />
              </div>
            </div>
          ) : (
            <>
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
                    setBrowseAnchor(null);
                    setBrowseAnchorLabel(null);
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
                <ChromeGlyph name="locate" size={14} current className="text-text-secondary" />
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
              setExploreNameFilter(q);
              if (sheetMode !== "plan" && q.trim().length >= 2) {
                setSheetMode("tours");
              }
            }}
            onSearchSubmit={() => {
              if (sheetMode === "plan") submitChromeSearch();
              else void submitExploreSearch();
            }}
            placeHits={sheetMode === "plan" ? placeHits : exploreHits}
            recents={addrRecents}
            onPlaceHit={(hit) => {
              lastPlaceRef.current = hit;
              setLastPlace(hit);
              if (placeHitAppliesAsDestination(sheetMode)) applyPlaceHit(hit);
              else flyExplorePlace(hit);
            }}
            browsePlace={
              browseAnchor
                ? { label: browseAnchorLabel ?? d.mapArea }
                : null
            }
            onPlanRoute={beginNavigate}
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
            onOfflineMaps={() => {
              setSheetMode("tours");
              requestAnimationFrame(() => {
                document
                  .getElementById("offline-packs")
                  ?.scrollIntoView({ behavior: "smooth", block: "start" });
              });
            }}
          />
            </>
          )}
        </header>

        {!detailRoute && sheetMode !== "plan" && (
        <div
          role="tablist"
          aria-label={copy.mapTitle}
          className="grid shrink-0 grid-cols-3 gap-1 border-b border-border p-2"
        >
          {(
            [
              ["quick", copy.mapSheetNear, "locate"],
              ["plan", copy.mapSheetPlan, "nav"],
              ["tours", copy.mapSheetTours, "platz"],
            ] as const
          ).map(([id, label, mark]) => {
            const on = sheetMode === id;
            return (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={on}
                data-testid={`discover-sheet-${id}`}
                onClick={() => {
                  if (asGroup && id !== "plan") {
                    const url = new URL(window.location.href);
                    url.searchParams.delete("asGroup");
                    window.history.replaceState(
                      {},
                      "",
                      `${url.pathname}${url.search}`
                    );
                  }
                  if (id === "plan") beginNavigate();
                  else setSheetMode(id);
                }}
                className={`flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs font-bold ${
                  on
                    ? "bg-chrome text-on-accent"
                    : "border border-border bg-surface text-foreground"
                }`}
              >
                <ChromeGlyph name={mark} size={14} current />
                {label}
              </button>
            );
          })}
        </div>
        )}

        <div className={`${sheetMode === "plan" ? (sheetRecedes ? "max-h-0 overflow-hidden" : "max-h-[56vh]") : "max-h-[38vh]"} min-h-0 flex-1 overflow-y-auto px-3 pb-4 pt-2 transition-[max-height] duration-200 ease-out lg:max-h-none`}>
          {routingMsg && (
            <p
              data-testid="discover-routing-msg"
              className="mb-2 text-[11px] text-text-secondary"
            >
              {discoverStatus(routingMsg, lang)}
            </p>
          )}

          {detailRoute ? (
            <div className="flex flex-col gap-2">
              <RouteDetail
                route={detailRoute}
                saved={isRouteSaved(detailRoute.id)}
                range={range}
                rangePro={rangePro}
                isEbike={!!activeBike?.isEbike}
                heatmapConsent={heatmapConsent}
                highlightPoiId={highlightPoiId}
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
                hideMiniMap
                geometry={selectedTourGeometry}
                onSelectPoi={setHighlightPoiId}
              />
              <button
                type="button"
                disabled={routingBusy}
                onClick={() => void runHybridSnap(suggestionToTour(detailRoute))}
                className="rounded-xl border border-chrome/40 bg-chrome/10 py-2.5 text-sm font-semibold text-chrome"
              >
                {d.fromHereStart}
              </button>
            </div>
          ) : (
            <>
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
                <>
                  <p className="text-[11px] text-text-secondary">
                    {d.loopActiveHint}
                  </p>
                  {aroundYouBlock}
                </>
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
                  {suppressOutAndBackQuick ? null : aroundYouCompact}
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
              {draft.baseTour ? (
                <PlanAdaptBanner
                  tour={draft.baseTour}
                  copy={d}
                  compact={Boolean(draft.computed)}
                />
              ) : null}
              {lastDestOffer ? (
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    className="rounded-full border border-border bg-surface px-3 py-1.5 text-[12px] font-medium"
                    onClick={() => {
                      const last = lastDestOffer;
                      if (!last) return;
                      let next = setEnd(
                        draft,
                        [last.lng, last.lat],
                        last.label?.trim() || d.onMapPlace
                      );
                      if (!startOf(next) && userPos) {
                        next = setStart(next, userPos, DISCOVER_PIN_DE.myPos);
                      }
                      commitPlanEdit(next);
                      pulseDestConfirm();
                      showStopHint(
                        [last.lng, last.lat],
                        d.lastDestApplied
                      );
                    }}
                  >
                    {lastDestOffer.label?.trim()
                      ? d.lastDestChip(lastPlanDestChipName(lastDestOffer.label))
                      : d.lastDestChipGeneric}
                  </button>
                  <button
                    type="button"
                    className="flex h-8 w-8 items-center justify-center rounded-full border border-border text-text-secondary"
                    aria-label={d.lastDestChipGeneric}
                    onClick={() => {
                      dismissLastPlanDest(lastDestOffer);
                      setLastDestDismissed(lastDestOffer);
                    }}
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                </div>
              ) : null}
              <PlanWaypointEditor
                draft={draft}
                copy={d}
                addrQuery={addrQuery}
                addrTarget={addrTarget}
                addrHits={addrHits}
                addrBusy={addrBusy}
                pickTarget={pickTarget}
                routingBusy={routingBusy || shapeDragging}
                userPos={userPos}
                recents={addrRecents}
                onAddrQuery={setAddrQuery}
                onAddrTarget={setAddrTarget}
                onApplyHit={applyAddressHit}
                onDraft={commitPlanEdit}
                onSwap={() => commitPlanEdit(swapStartEnd(draft))}
                onPick={setPickTarget}
                onMyLocation={() => {
                  if (userPos) {
                    commitPlanEdit(
                      setStart(draft, userPos, DISCOVER_PIN_DE.myPos)
                    );
                  }
                }}
                onUndo={undoPlanEdit}
                onRedo={redoPlanEdit}
                canUndo={planCanUndo}
                canRedo={planCanRedo}
              />
              <button
                type="button"
                data-testid="discover-compute-route"
                disabled={routingBusy || !startOf(draft) || !endOf(draft)}
                onClick={() => void runPlanRoute()}
                className="w-full rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
              >
                {routingBusy ? d.computingRoute : d.computeRoute}
              </button>
              {draft.computed ? (
                <>
                <PlanRouteInsight
                  geometry={draft.computed.geometry}
                  distanceM={draft.computed.distanceM}
                  durationS={draft.computed.durationS}
                  looped={isClosedLoop(draft)}
                  copy={d}
                  hoverKm={elevHoverKm}
                  onHoverKm={setElevHoverKm}
                  onPickKm={(km) => {
                    if (shapeDragging) return;
                    const line = (draft.computed?.geometry?.coordinates ??
                      []) as [number, number][];
                    if (line.length < 2) return;
                    const distKm = (draft.computed?.distanceM ?? 0) / 1000;
                    if (distKm > 0.1 && (km < 0.04 || km > distKm - 0.04)) {
                      return;
                    }
                    commitPlanEdit(
                      insertViaAlong(draft, pointAlongRoute(line, km * 1000), {
                        line,
                        label: d.viaAddr,
                      })
                    );
                  }}
                  onProfile={setPlanElev}
                  adapting={shapeDragging}
                />
                {valhallaLive ? (
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
                    onClick={() => {
                      const next = { ...draft, variant: id };
                      commitPlanEdit(next);
                    }}
                    className={`rounded-full border px-2.5 py-1 text-[11px] ${
                      (draft.variant ?? "planned") === id
                        ? "border-chrome bg-chrome/10"
                        : "border-border bg-surface"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
                ) : (
                  <p className="text-[11px] text-text-secondary">
                    {d.variantValhallaOnly}
                  </p>
                )}
                <p className="text-[11px] text-text-secondary">
                  {d.tapLineVia}
                </p>
                </>
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
                    <>
                  {aroundYouCompact}
                      <button
                        type="button"
                        className="mt-2 rounded-lg border border-border px-3 py-1.5 text-xs font-medium"
                        onClick={() =>
                          setFilters((f) => ({ ...f, loopOnly: false }))
                        }
                      >
                        {d.loopFilterOff}
                      </button>
                    </>
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
                <ChromeGlyph name="karte" size={14} /> {d.outdooractive(oaTours.length)}
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
                <ChromeGlyph name="elevation" size={14} /> {d.trailforks(tfPins.length)}
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

              <h3 className="mt-2 flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-secondary">
                <MappeGlyph name="mappe" size={16} />
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
                <MappeEmpty
                  compact
                  title={g.mappeEmptyTitle}
                  hint={d.mappeEmpty}
                />
              ) : mappeRoutes.length === 0 ? (
                <div className="rounded-2xl border border-dashed border-border p-4 text-center">
                  <p className="text-sm text-text-secondary">{d.mappeFilterEmpty}</p>
                  <button
                    type="button"
                    className="mt-2 text-xs font-semibold text-accent"
                    onClick={() =>
                      setFilters((f) => ({ ...f, visibility: "all_mine" }))
                    }
                  >
                    {d.mappeShowAll}
                  </button>
                </div>
              ) : (
                <ul className="space-y-2.5">
                  {mappeRoutes.map((r) => {
                    const last = lastRideForSavedRoute(rides, r);
                    const bikeName = bikes.find(
                      (b) => b.id === (last?.bikeId ?? r.preferredBikeId),
                    )?.name;
                    const tag = latestConditionTag(
                      myReviews,
                      stimmenTourIdOf(r),
                    );
                    return (
                      <SavedMappeTile
                        key={r.id}
                        route={r}
                        visLabel={
                          visibilityOf(r) === "shared"
                            ? d.shared
                            : d.privateTour
                        }
                        loopLabel={g.loopTag}
                        noTrackLabel={g.noTrackLabel}
                        caption={joinMappeCaption([
                          bikeName ? g.riddenWith(bikeName) : null,
                          last
                            ? g.lastRidden(formatMappeDay(last.startTime))
                            : null,
                        ])}
                        sourceChip={mappeSourceChip(r.source, {
                          import: g.sourceImport,
                          planned: g.sourcePlanned,
                          recorded: g.sourceRecorded,
                        })}
                        conditionLabel={
                          tag ? stimme.tagLabel(tag) : undefined
                        }
                        akteLabel={copy.akteMein}
                        removeLabel={d.remove}
                        rideLabel={g.goRide}
                        onOpen={() => loadSavedRoute(r)}
                        onAkte={() =>
                          router.push(
                            `/library?akte=${encodeURIComponent(r.id)}`,
                          )
                        }
                        onRemove={() => unsaveRoute(r.id)}
                        onGoRide={() => loadSavedRoute(r)}
                      />
                    );
                  })}
                </ul>
              )}

              <h3 className="mt-4 flex items-center gap-1.5 text-xs font-semibold tracking-wide text-text-secondary">
                <MappeGlyph name="collection" size={16} />
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
                    className="flex items-center gap-2 rounded-xl border border-border bg-surface px-3 py-2 text-sm"
                  >
                    <MappeGlyph name="collection" size={16} />
                    <span className="font-semibold">{c.name}</span>
                    <span className="ml-2 text-[11px] text-text-secondary">
                      {d.routesCount(c.routeIds.length)}
                    </span>
                  </div>
                ))
              )}

              <OfflinePacksPanel id="offline-packs" className="mt-4" />
            </div>
          )}
            </>
          )}
        </div>
        {sheetMode === "plan" && draft.computed ? (
          <div className={`shrink-0 border-t border-border px-3 py-3 ${sheetRecedes ? "max-lg:hidden" : ""}`}>
            <p className="mb-2 text-[12px] font-semibold text-text-secondary">
              {(draft.computed.distanceM / 1000).toFixed(
                draft.computed.distanceM < 10_000 ? 1 : 0
              )}{" "}
              km · {Math.round(draft.computed.durationS / 60)} min
            </p>
            <div className="flex gap-2">
            <button
              type="button"
              onClick={saveCurrentDraft}
              className="flex-1 rounded-xl border border-border py-2.5 text-sm font-semibold"
            >
              {d.save}
            </button>
            <button
              type="button"
              onClick={() =>
                startWithComputed(
                  draft.label || DISCOVER_PIN_DE.planned,
                  draft.computed!
                )
              }
              className="flex-[2] rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent"
            >
              {d.startInApp}
            </button>
            </div>
            <p className="mt-2 text-[11px] text-text-secondary">
              {d.browserPlanOnly}
            </p>
          </div>
        ) : sheetMode === "plan" && startOf(draft) && !endOf(draft) ? (
          <div className={`shrink-0 border-t border-border px-3 py-3 ${sheetRecedes ? "max-lg:hidden" : ""}`}>
            <button
              type="button"
              onClick={() => {
                setPickTarget("end");
                setAddrTarget("end");
                requestAnimationFrame(() => {
                  document.getElementById("plan-end")?.focus();
                  document
                    .getElementById("plan-end")
                    ?.scrollIntoView({ block: "nearest" });
                });
              }}
              className="w-full rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent"
            >
              {d.setEndCta}
            </button>
          </div>
        ) : sheetMode === "plan" && !startOf(draft) ? (
          <div className={`shrink-0 border-t border-border px-3 py-3 ${sheetRecedes ? "max-lg:hidden" : ""}`}>
            <button
              type="button"
              onClick={() => {
                if (userPos) {
                  schedulePlanRecompute(
                    setStart(draft, userPos, DISCOVER_PIN_DE.myPos)
                  );
                  setPickTarget("end");
                  setAddrTarget("end");
                  requestAnimationFrame(() => {
                    document.getElementById("plan-end")?.focus();
                    document
                      .getElementById("plan-end")
                      ?.scrollIntoView({ block: "nearest" });
                  });
                  return;
                }
                setPickTarget("start");
                setAddrTarget("start");
                requestAnimationFrame(() => {
                  document.getElementById("plan-start")?.focus();
                  document
                    .getElementById("plan-start")
                    ?.scrollIntoView({ block: "nearest" });
                });
              }}
              className="w-full rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent"
            >
              {userPos ? d.startMyPos : d.tapStart}
            </button>
          </div>
        ) : null}
      </aside>

      {/* Karte — Desktop full height, Mobile oben */}
      <div className="relative order-1 min-h-[42vh] flex-1 lg:order-2 lg:min-h-0">
        <MapView
          className="absolute inset-0 rounded-none"
          center={mapCenter}
          zoom={13}
          routes={mapLayers}
          markers={markers}
          showUserLocation
          interactiveSelect={pickTarget !== null || sheetMode === "plan"}
          bikeOverlayUrl={bikeOverlaySpec?.url ?? null}
          bikeOverlayKind={bikeOverlaySpec?.kind ?? "pmtiles"}
          bikeOverlayFamily={bikeOverlayFamily}
          bikeOverlayVisible={bikeOverlayOn}
          bikeOverlayExtraOn={bikeOverlayExtra}
          bikeOverlayRideProfileId={null}
          bikeOverlayMinZoom={bikeOverlaySpec?.overlayKind === "ways" ? 10 : 5}
          hideFarmTracks={!farmTracksOn}
          onViewChange={(view) => {
            setMapCenter(view.center);
            setMapZoom(view.zoom);
            writeDiscoverViewport(view);
          }}
          onMapClick={onMapClick}
          onMapLongPress={onMapLongPress}
          onOverlayClick={(hit) => void onOverlayWayClick(hit)}
          onZoomChange={setMapZoom}
          shapeInteractive={
            sheetMode === "plan" &&
            Boolean(startOf(draft) && endOf(draft) && draft.computed)
          }
          shapeAnchors={
            sheetMode === "plan" &&
            startOf(draft) &&
            endOf(draft) &&
            draft.computed?.geometry?.coordinates &&
            draft.computed.geometry.coordinates.length >= 2
              ? {
                  start: startOf(draft)!,
                  end: endOf(draft)!,
                  vias: orderedWaypoints(draft)
                    .filter((w) => w.role === "via")
                    .map((w) => ({ id: w.id, lngLat: w.lngLat })),
                  line: draft.computed.geometry.coordinates as [
                    number,
                    number,
                  ][],
                }
              : null
          }
          onShapeHover={setElevHoverKm}
          onShapeDragging={(active) => {
            setShapeDragging(active);
            if (active) clearStopHint();
          }}
          hoverKm={sheetMode === "plan" ? elevHoverKm : null}
          snapShapeFinger={(ll) =>
            snapPointOntoTrails(ll, trailsForViaSnap(liveOsmTrails))
          }
          adaptingLabel={waitHintLabel}
          adaptingUndoLabel={mapHintOnMap && planCanUndo ? d.planUndo : null}
          onAdaptingUndo={
            mapHintOnMap && planCanUndo ? () => undoPlanEdit() : undefined
          }
          adaptingAt={
            destWaitOnMap
              ? endOf(draft)
              : stopHintOnMap
                ? stopHintAt
                : null
          }
          onMarkerClick={(id) => {
            if (
              id === "end-glow" ||
              id === "elev-cursor" ||
              id.startsWith("shape-handle") ||
              id.startsWith("shape-tick")
            ) {
              return;
            }
            if (id.startsWith("poi-")) {
              flashTourPoi(id.slice("poi-".length));
              return;
            }
            if (id.startsWith("place-")) {
              const placeId = id.slice("place-".length);
              const place = googlePlaces.find((p) => p.id === placeId);
              if (!place) return;
              const plateKind = coveragePlacePoiKind(place.kind);
              if (plateKind && plateKind !== "place") {
                setHighlightPoiId(`place-${place.id}`);
                return;
              }
              const trails = trailsForViaSnap(liveOsmTrails);
              const point: [number, number] = [place.lng, place.lat];
              const snapped = viaMaySnapOntoTrail(place.name)
                ? snapPointOntoTrails(point, trails)
                : point;
              setDraft((prev) => {
                const line = (prev.computed?.geometry?.coordinates ?? []) as
                  | [number, number][]
                  | undefined;
                const next =
                  startOf(prev) && endOf(prev)
                    ? insertViaAlong(prev, snapped, {
                        line,
                        label: place.name,
                      })
                    : addVia(prev, snapped, place.name);
                commitPlanEdit(next);
                return next;
              });
              setRoutingMsg(`${d.placeOnRoute}: ${place.name}`);
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
          onMarkerDragEnd={(id, lngLat) => {
            if (sheetMode !== "plan") return;
            if (
              id === "elev-cursor" ||
              id.startsWith("tour-") ||
              id.startsWith("place-") ||
              id.startsWith("meet-") ||
              id.startsWith("shape-tick")
            ) {
              return;
            }
            setPlanShaped(true);
            if (id.startsWith("shape-handle")) {
              const line = (draft.computed?.geometry?.coordinates ?? []) as
                | [number, number][]
                | undefined;
              const next = insertViaAlong(draft, lngLat, {
                line,
                label: d.onMapPlace,
              });
              commitPlanEdit(next);
              void fillPlaceholderLabels(next);
              return;
            }
            const next = moveWaypoint(draft, id, lngLat);
            commitPlanEdit(next);
            void fillPlaceholderLabels(next);
          }}
          onRouteClick={(id, lngLat) => {
            if (
              lngLat &&
              startOf(draft) &&
              endOf(draft) &&
              planShapeRouteId(id) &&
              pickTarget !== "start" &&
              pickTarget !== "end"
            ) {
              setPlanShaped(true);
              const line = (draft.computed?.geometry?.coordinates ?? []) as
                | [number, number][]
                | undefined;
              const next = insertViaAlong(draft, lngLat, {
                  line,
                  label: d.onMapPlace,
                });
              setSheetMode("plan");
              commitPlanEdit(next);
              void fillPlaceholderLabels(next);
              setPickTarget(null);
              return;
            }
            if (sheetMode === "plan" && lngLat && (pickTarget === "start" || pickTarget === "end")) {
              onMapClick(lngLat);
              return;
            }
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
              (rundkursActive && draft.mode !== "point_to_point"
                ? sanitizeDraftForRundkurs(draft)
                : draft
              ).computed
            )
          }
          fitPoints={planFitPoints}
        />
        {routingWaitBanner && !waitOnMap ? (
          <div
            data-testid="plan-routing-wait"
            className="absolute bottom-28 left-[max(0.75rem,var(--safe-left))] z-20 flex max-w-[min(24rem,calc(100%-5.5rem))] items-center gap-2 rounded-2xl border border-white/10 bg-[#1A120C]/92 px-3 py-2 text-white shadow-lg"
          >
            <Loader2 className="h-4 w-4 shrink-0 animate-spin text-[#FFB080]" />
            <p className="min-w-0 flex-1 text-[12px] font-medium leading-snug">
              {draft.computed ? d.routingAdapts : d.endSetComputing}
            </p>
            {planCanUndo ? (
              <button
                type="button"
                className="shrink-0 text-[11px] font-semibold text-[#FFB080]"
                onClick={() => {
                  setPlanToast(null);
                  undoPlanEdit();
                }}
              >
                {d.planUndo}
              </button>
            ) : null}
          </div>
        ) : planToast && sheetMode === "plan" ? (
          <div className="absolute bottom-28 left-[max(0.75rem,var(--safe-left))] z-20 flex max-w-[min(24rem,calc(100%-5.5rem))] items-center gap-2 rounded-2xl border border-white/10 bg-[#1A120C]/92 px-3 py-2 text-white shadow-lg">
            <p className="min-w-0 flex-1 text-[12px] font-medium leading-snug">
              {planToast}
            </p>
            <button
              type="button"
              className="shrink-0 text-[11px] font-semibold text-[#FFB080]"
              onClick={() => {
                setPlanToast(null);
                undoPlanEdit();
              }}
            >
              {d.planUndo}
            </button>
          </div>
        ) : null}
        {planCoach &&
        sheetMode === "plan" &&
        draft.computed &&
        !planToast &&
        !routingBusy &&
        !shapeDragging ? (
          <div className="absolute top-20 left-[max(0.75rem,var(--safe-left))] right-[max(3.25rem,var(--safe-right))] z-20 max-w-[min(28rem,calc(100%-4rem))] rounded-2xl border border-[#FF6A00]/35 bg-[#1A120C]/94 px-3 py-2.5 text-white shadow-lg [@media(max-height:700px)]:px-2.5 [@media(max-height:700px)]:py-1.5 [@media(max-height:640px)]:px-2 [@media(max-height:640px)]:py-1">
            <div className="flex items-start justify-between gap-2">
              <p className="text-[12px] font-medium leading-snug [@media(max-height:700px)]:text-[11px] [@media(max-height:640px)]:text-[10px]">
                {draft.baseTour ? (
                  d.planLineCoachAdopt
                ) : (
                  <>
                    <span className="[@media(max-height:700px)]:hidden">
                      {d.planLineCoach}
                    </span>
                    <span className="hidden [@media(max-height:700px)]:inline">
                      {d.planLineCoachShort}
                    </span>
                  </>
                )}
              </p>
              <button
                type="button"
                className="shrink-0 text-[11px] font-semibold text-[#FFB080]"
                onClick={() => {
                  try {
                    localStorage.setItem(
                      "flowline.planLineCoach.v1",
                      String(Date.now())
                    );
                  } catch {
                    /* ignore */
                  }
                  setPlanCoach(false);
                }}
              >
                {d.planLineCoachOk}
              </button>
            </div>
          </div>
        ) : null}
        {sheetMode === "plan" &&
        draft.computed &&
        !planToast &&
        !routingBusy &&
        !shapeDragging &&
        !planCoach ? (
          <PlanRibbonLegend
            layers={mapLayers}
            copy={d}
            kinds={planRibbonLegendKinds({
              bands: planElev?.surfaceBands,
              hasSteep: mapLayers.some((l) => l.role === "steep"),
            })}
          />
        ) : null}
        {((userPos && !waitHidesChrome) || historyFabsOnMap) ? (
          <div className="absolute bottom-16 right-[max(0.75rem,var(--safe-right))] z-20 flex flex-col-reverse items-center gap-2">
            {userPos && !waitHidesChrome ? (
              <button
                type="button"
                className="flex h-11 w-11 items-center justify-center rounded-full border border-border bg-surface text-chrome shadow-md"
                aria-label={browseAnchor ? d.backToGps : d.startMyPos}
                onClick={() => {
                  if (browseAnchor) {
                    setBrowseAnchor(null);
                    setBrowseAnchorLabel(null);
                  }
                  setHoldMapFit(true);
                  setMapCenter(userPos);
                  setRoutingMsg(DISCOVER_STATUS_DE.locGpsCentered);
                }}
              >
                <ChromeGlyph name="locate" size={20} current />
              </button>
            ) : null}
            {historyFabsOnMap && planCanUndo ? (
              <button
                type="button"
                data-testid="plan-map-undo"
                className="flex h-10 w-10 items-center justify-center rounded-full border border-border bg-surface text-chrome shadow-md"
                aria-label={d.planUndo}
                onClick={() => undoPlanEdit()}
              >
                <ChromeGlyph name="undo" size={16} current />
              </button>
            ) : null}
            {historyFabsOnMap && planCanRedo ? (
              <button
                type="button"
                data-testid="plan-map-redo"
                className="flex h-10 w-10 items-center justify-center rounded-full border border-border bg-surface text-chrome shadow-md"
                aria-label={d.planRedo}
                onClick={() => redoPlanEdit()}
              >
                <ChromeGlyph name="redo" size={16} current />
              </button>
            ) : null}
          </div>
        ) : null}
        <div className="absolute left-[max(0.75rem,var(--safe-left))] top-3 z-10">
          <BikeOverlayLegend
            family={bikeOverlayFamily}
            visible={bikeOverlayOn}
            extraOn={bikeOverlayExtra}
            rideProfileId={null}
            hasOverlayData={Boolean(bikeOverlaySpec)}
            overlayKind={bikeOverlaySpec?.overlayKind ?? "mesh"}
            farmTracksOn={farmTracksOn}
            onToggleFarmTracks={
              (bikeOverlaySpec?.overlayKind ?? "mesh") === "ways"
                ? () => {
                    if (!bikeOverlayOn) {
                      setBikeOverlayOn(true);
                      if (!farmTracksOn) {
                        setFarmTracksOn(true);
                        try {
                          localStorage.setItem("flowline.farmTracks.v1", "1");
                        } catch {
                          /* ignore */
                        }
                      }
                      return;
                    }
                    setFarmTracksOn((v) => {
                      const next = !v;
                      try {
                        localStorage.setItem(
                          "flowline.farmTracks.v1",
                          next ? "1" : "0"
                        );
                      } catch {
                        /* ignore */
                      }
                      return next;
                    });
                  }
                : undefined
            }
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
                  : d.addStop
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
        {statsLine && sheetMode !== "plan" && (
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
                <ChromeGlyph name="merken" size={14} current />
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
                <ChromeGlyph name="play" size={14} current /> {d.startInApp}
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
