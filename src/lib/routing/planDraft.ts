/**
 * Discover PlanDraft — einheitliches Modell für Schnell / A–B / Tour / Hybrid.
 */

import type { ClientRouteResult, RoutingProfile } from "@/lib/routing/profiles";
import { requestRoute, requestRouteDetailed, getProfile, isRideProfileId, accessCostingForRideProfile } from "@/lib/routing/profiles";
import { profileAllowsOsmRoundTrip } from "@/lib/routing/osmRoundTrip";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { buildDemoGeometry } from "@/lib/routing/demoGeometry";
import type { TrailSegment } from "@/lib/routing/trailSegments";
import {
  haversineM,
  lineLengthM,
  pointAlongRoute,
  projectOntoRoute,
} from "@/lib/routing/routeProgress";
import { HONESTY_FARM_TAIL_DE } from "@/lib/routing/graphhopperHints";
import type { NavStep } from "@/lib/routing/navSteps";
import { orientTrail } from "@/lib/routing/trailAccess";
import {
  osmSurfaceGroup,
  type OsmSurfaceGroup,
} from "@/lib/routing/osmSurfaceLabel";

export type QuickOption = {
  id: string;
  label: string;
  reason: string;
  result: ClientRouteResult;
};

export type ComputeQuickOptionsResult = {
  options: QuickOption[];
  rateLimited: boolean;
  fromCache: boolean;
};

const quickCache = new Map<string, QuickOption[]>();

function quickCacheKey(
  start: [number, number],
  profile: RoutingProfile,
  minutes: number
): string {
  // ~100 m grid — avoids refetch on tiny GPS jitter
  const lng = Math.round(start[0] * 1000) / 1000;
  const lat = Math.round(start[1] * 1000) / 1000;
  const bucket = Math.round(minutes / 15) * 15;
  return `${profile}|${lng},${lat}|${bucket}`;
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

/** Straight-line stand-in when engine is rate-limited / offline. */
export function approximateOutAndBack(
  start: [number, number],
  to: [number, number],
  profile: RoutingProfile,
  label: string
): ClientRouteResult {
  const mid: [number, number] = [
    (start[0] + to[0]) / 2,
    (start[1] + to[1]) / 2,
  ];
  const coordinates: [number, number][] = [start, mid, to, mid, start];
  const distM =
    Math.hypot(to[0] - start[0], to[1] - start[1]) * 111_000 * 2 * 1.15;
  return {
    distanceM: Math.round(distM),
    durationS: Math.round(distM / 4.5),
    geometry: { type: "LineString", coordinates },
    engine: "approx",
    profile,
    warnings: [
      `Näherung „${label}“ — Routing-API pausiert (Limit). Später neu berechnen.`,
    ],
  };
}

export type PlanMode = "quick" | "point_to_point" | "tour" | "hybrid";

export type WaypointRole = "start" | "via" | "end";

export type PlanWaypoint = {
  id: string;
  role: WaypointRole;
  lngLat: [number, number];
  label?: string;
};

export type TourProvider = "seed" | "outdooractive" | "gpx" | "saved" | "trailforks";

export type BaseTour = {
  id: string;
  name: string;
  provider: TourProvider;
  geometry: GeoJSON.LineString | null;
  attribution?: string;
  distanceKm?: number;
  elevationM?: number;
  durationMin?: number;
  mtbScale?: string;
  surface?: string;
  reasons?: [string, string, string];
  matchScore?: number;
  loop?: boolean;
  center?: [number, number];
  url?: string;
  photoUrl?: string;
};

export type HybridStrategy = "adopt" | "snap" | "replan";

export type PlanDraft = {
  mode: PlanMode;
  profile: RoutingProfile;
  waypoints: PlanWaypoint[];
  baseTour?: BaseTour;
  hybrid?: { strategy: HybridStrategy };
  computed?: ClientRouteResult | null;
  label?: string;
  /** planned | flatter | unpaved */
  variant?: "planned" | "flatter" | "unpaved";
  /** Separate geometries for map layers (hybrid / trail attach) */
  layers?: {
    approach?: GeoJSON.LineString;
    tour?: GeoJSON.LineString;
    trail?: GeoJSON.LineString;
  };
  attachedTrailId?: string;
};

export function emptyDraft(
  profile: RoutingProfile,
  start?: [number, number]
): PlanDraft {
  const waypoints: PlanWaypoint[] = start
    ? [{ id: "start", role: "start", lngLat: start, label: "Start" }]
    : [];
  return {
    mode: "point_to_point",
    profile,
    waypoints,
    computed: null,
  };
}

export function startOf(draft: PlanDraft): [number, number] | null {
  return draft.waypoints.find((w) => w.role === "start")?.lngLat ?? null;
}

export function endOf(draft: PlanDraft): [number, number] | null {
  return draft.waypoints.find((w) => w.role === "end")?.lngLat ?? null;
}

/** Hit slop for tapping the painted A–B ribbon (Komoot / AllTrails). */
export const DISCOVER_ROUTE_TAP_MAX_M = 64;

export function isAdoptedTourLine(engine?: string | null): boolean {
  return (engine ?? "").toLowerCase() === "tour-adopt";
}

/** Live A–B or an adopted catalog track the rider is customizing. */
export function isPlanCustomizableLine(opts: {
  engine?: string | null;
  coordinateCount: number;
}): boolean {
  if (opts.coordinateCount < 2) return false;
  if (isAdoptedTourLine(opts.engine)) return true;
  return !isDiscoverTourPreviewEngine(opts.engine);
}

export function isLiveStreetDiscoverLine(opts: {
  engine?: string | null;
  coordinateCount: number;
}): boolean {
  return isPlanCustomizableLine(opts);
}

function leftoverTourRibbonOnDraft(draft: PlanDraft): boolean {
  if (
    isAdoptedTourLine(draft.computed?.engine) &&
    startOf(draft) &&
    endOf(draft)
  ) {
    return false;
  }
  if (draft.mode === "tour") return true;
  if ((draft.layers?.tour?.coordinates?.length ?? 0) >= 2) return true;
  if ((draft.baseTour?.geometry?.coordinates?.length ?? 0) >= 2) return true;
  return isDiscoverTourPreviewEngine(draft.computed?.engine);
}

/** Catalog leftover wipes on the first dest pin — not after A+B in the editor. */
export function planLeftoverTourWipesOnTap(opts: {
  leftover: boolean;
  hasStart: boolean;
  hasEnd: boolean;
  picking?: PlanSlot | null;
}): boolean {
  if (!opts.leftover || opts.picking === "via") return false;
  if (opts.hasStart && opts.hasEnd) return false;
  return true;
}

/** While the engine is in flight, far taps stay vias — dest only via pick/Alt. */
export function planBusyBlocksDestReplace(opts: {
  routingBusy: boolean;
  hasStart: boolean;
  hasEnd: boolean;
  picking?: PlanSlot | null;
  forceEnd?: boolean;
}): boolean {
  if (!opts.routingBusy) return false;
  if (opts.forceEnd || opts.picking === "end" || opts.picking === "start") {
    return false;
  }
  return opts.hasStart && opts.hasEnd;
}

/** Keep the last honest street line while a reshape is in flight. */
export function shouldKeepStaleDiscoverLine(opts: {
  leftoverTourRibbon: boolean;
  liveStreetCoordinateCount: number;
  engine?: string | null;
}): boolean {
  if (opts.leftoverTourRibbon) return false;
  return isLiveStreetDiscoverLine({
    engine: opts.engine,
    coordinateCount: opts.liveStreetCoordinateCount,
  });
}

export function tapHitsDiscoverRouteLine(
  coordinates: [number, number][] | number[][] | null | undefined,
  lat: number,
  lng: number,
  maxM = DISCOVER_ROUTE_TAP_MAX_M
): boolean {
  if (!coordinates || coordinates.length < 2) return false;
  return projectOntoRoute(coordinates, lat, lng).crossTrackM <= maxM;
}

export function snapTapOntoDiscoverRoute(
  coordinates: [number, number][],
  lat: number,
  lng: number
): [number, number] {
  if (coordinates.length < 2) return [lng, lat];
  const p = projectOntoRoute(coordinates, lat, lng);
  return pointAlongRoute(coordinates, p.distanceAlongM);
}

export function shouldInsertViaOnDiscoverRouteTap(opts: {
  hasStart: boolean;
  hasEnd: boolean;
  hasLiveStreetLine: boolean;
  leftoverTourOnMap: boolean;
  pickingStart?: boolean;
}): boolean {
  if (opts.pickingStart) return false;
  if (!opts.hasStart || !opts.hasEnd) return false;
  if (!opts.hasLiveStreetLine) return false;
  if (opts.leftoverTourOnMap) return false;
  return true;
}

function clearTourLeftover(draft: PlanDraft): Pick<
  PlanDraft,
  "baseTour" | "hybrid" | "computed" | "layers" | "attachedTrailId" | "mode"
> {
  const leftoverRibbon = leftoverTourRibbonOnDraft(draft);
  const keepLine = shouldKeepStaleDiscoverLine({
    leftoverTourRibbon: leftoverRibbon,
    liveStreetCoordinateCount: draft.computed?.geometry?.coordinates?.length ?? 0,
    engine: draft.computed?.engine,
  });
  const tour = draft.baseTour;
  return {
    baseTour: tour
      ? {
          ...tour,
          geometry: leftoverRibbon ? null : tour.geometry,
        }
      : undefined,
    hybrid: leftoverRibbon ? undefined : draft.hybrid,
    computed: keepLine ? draft.computed : null,
    layers: leftoverRibbon ? undefined : draft.layers,
    attachedTrailId: leftoverRibbon ? undefined : draft.attachedTrailId,
    mode: draft.mode === "tour" ? "point_to_point" : draft.mode,
  };
}

export function setStart(
  draft: PlanDraft,
  lngLat: [number, number],
  label = "Start"
): PlanDraft {
  const rest = draft.waypoints.filter((w) => w.role !== "start");
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: [{ id: "start", role: "start", lngLat, label }, ...rest],
  };
}

export function setEnd(
  draft: PlanDraft,
  lngLat: [number, number],
  label = "Ziel"
): PlanDraft {
  const rest = draft.waypoints.filter((w) => w.role !== "end");
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: [...rest, { id: "end", role: "end", lngLat, label }],
  };
}

export function viasOf(draft: PlanDraft): [number, number][] {
  return draft.waypoints
    .filter((w) => w.role === "via")
    .map((w) => w.lngLat);
}

export function addVia(
  draft: PlanDraft,
  lngLat: [number, number],
  label?: string
): PlanDraft {
  const vias = draft.waypoints.filter((w) => w.role === "via");
  const start = draft.waypoints.filter((w) => w.role === "start");
  const end = draft.waypoints.filter((w) => w.role === "end");
  const via: PlanWaypoint = {
    id: `via-${Date.now()}`,
    role: "via",
    lngLat,
    label: label ?? `Via ${vias.length + 1}`,
  };
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: [...start, ...vias, via, ...end],
  };
}

/** Catalog/seed ribbon stays off while A–B is the map story. */
export function shouldHideDiscoverTourRibbon(opts: {
  planning: boolean;
  hasStart: boolean;
  hasEnd: boolean;
}): boolean {
  if (opts.hasEnd) return true;
  return opts.planning && opts.hasStart;
}

/** Seed / catalog / adopt — not a live A→B the rider just asked for. */
export function isDiscoverTourPreviewEngine(engine?: string | null): boolean {
  const e = (engine ?? "").toLowerCase();
  if (!e) return false;
  return (
    e === "tour-adopt" ||
    e === "tour-pin" ||
    e === "tour-track" ||
    e === "tour-routed" ||
    e === "osm-trail" ||
    e.includes("seed-loop") ||
    e.endsWith("+tour")
  );
}

export function draftHasDiscoverTourPreview(draft: PlanDraft): boolean {
  if (draft.mode === "tour") return true;
  if (draft.baseTour) return true;
  if ((draft.layers?.tour?.coordinates?.length ?? 0) >= 2) return true;
  return isDiscoverTourPreviewEngine(draft.computed?.engine);
}

/**
 * Track for selected-tour 3D plates. Catalog ovals can hide in A–B;
 * plates stay on a tour preview/adopt line, never on a rider-asked A–B.
 */
export function discoverSelectedTourLine(opts: {
  draft: PlanDraft;
  hideRibbon: boolean;
  previewing: boolean;
  cached?: GeoJSON.LineString | null;
}): GeoJSON.LineString | null {
  const fromDraft =
    opts.draft.layers?.tour ??
    opts.draft.baseTour?.geometry ??
    (draftHasDiscoverTourPreview(opts.draft)
      ? opts.draft.computed?.geometry
      : null) ??
    null;
  if (fromDraft?.coordinates && fromDraft.coordinates.length >= 2) {
    return fromDraft;
  }
  const cached = opts.cached;
  if (!cached?.coordinates || cached.coordinates.length < 2) return null;
  if (
    opts.hideRibbon &&
    !opts.previewing &&
    !draftHasDiscoverTourPreview(opts.draft)
  ) {
    return null;
  }
  return cached;
}

/**
 * Browse long-press / map pin: GPS → pin when the rider has a fix.
 * Never invent start at the panned map center.
 * After a tour preview/adopt, a new pin drops the tour and is the destination.
 */
export function applyBrowseMapPin(
  draft: PlanDraft,
  pin: [number, number],
  opts: {
    gps?: [number, number] | null;
    picking?: "start" | "end" | "via" | null;
    startLabel: string;
    endLabel: string;
    myPosLabel: string;
    snapVia?: (p: [number, number]) => [number, number];
    tourPreviewOnMap?: boolean;
  }
): PlanDraft {
  const gps = opts.gps ?? null;
  const hasStart = Boolean(startOf(draft));
  const hasEnd = Boolean(endOf(draft));
  const snap = opts.snapVia ?? ((p: [number, number]) => p);
  const leftover =
    Boolean(opts.tourPreviewOnMap) || draftHasDiscoverTourPreview(draft);
  if (opts.picking === "start") {
    return setStart(draft, pin, opts.startLabel);
  }
  if (opts.picking === "via") {
    return addVia(draft, snap(pin));
  }
  if (leftover && opts.picking !== "via") {
    const base = emptyDraft(draft.profile);
    const withStart = gps
      ? setStart(base, gps, opts.myPosLabel)
      : base;
    return setEnd(withStart, pin, opts.endLabel);
  }
  if (opts.picking === "end") {
    const next = !hasStart && gps ? setStart(draft, gps, opts.myPosLabel) : draft;
    return setEnd(next, pin, opts.endLabel);
  }
  if (!hasStart && !hasEnd) {
    if (gps) {
      return setEnd(setStart(draft, gps, opts.myPosLabel), pin, opts.endLabel);
    }
    return setEnd(draft, pin, opts.endLabel);
  }
  // Never invent a start at the pin. Dest-only stays dest until GPS arrives.
  const withoutVias: PlanDraft = {
    ...draft,
    waypoints: draft.waypoints.filter((w) => w.role !== "via"),
  };
  return setEnd(withoutVias, pin, opts.endLabel);
}

export function removeWaypoint(draft: PlanDraft, id: string): PlanDraft {
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: draft.waypoints.filter((w) => w.id !== id),
  };
}

export function orderedWaypoints(draft: PlanDraft): PlanWaypoint[] {
  const start = draft.waypoints.filter((w) => w.role === "start");
  const vias = draft.waypoints.filter((w) => w.role === "via");
  const end = draft.waypoints.filter((w) => w.role === "end");
  return [...start, ...vias, ...end];
}

export type PlanSlot = "start" | "end" | "via";

/** Next empty editor slot. After A+B, taps replace dest — via is a button. */
export function nextPlanSlot(draft: PlanDraft): PlanSlot {
  if (!startOf(draft)) return "start";
  return "end";
}

export function swapStartEnd(draft: PlanDraft): PlanDraft {
  const start = draft.waypoints.find((w) => w.role === "start");
  const end = draft.waypoints.find((w) => w.role === "end");
  if (!start && !end) return draft;
  const vias = draft.waypoints.filter((w) => w.role === "via").slice().reverse();
  const nextStart = end
    ? { ...end, id: "start", role: "start" as const }
    : undefined;
  const nextEnd = start
    ? { ...start, id: "end", role: "end" as const }
    : undefined;
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: [
      ...(nextStart ? [nextStart] : []),
      ...vias,
      ...(nextEnd ? [nextEnd] : []),
    ],
  };
}

const LOOP_CLOSE_M = 200;

export function isClosedLoop(
  draft: PlanDraft,
  toleranceM = LOOP_CLOSE_M
): boolean {
  const start = startOf(draft);
  const end = endOf(draft);
  if (!start || !end) return false;
  return haversineM(start[1], start[0], end[1], end[0]) <= toleranceM;
}

export function closeLoop(draft: PlanDraft, label = "Start"): PlanDraft {
  const start = draft.waypoints.find((w) => w.role === "start");
  if (!start) return draft;
  return setEnd(draft, start.lngLat, label);
}

export function moveWaypoint(
  draft: PlanDraft,
  id: string,
  lngLat: [number, number]
): PlanDraft {
  if (!draft.waypoints.some((w) => w.id === id)) return draft;
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: draft.waypoints.map((w) =>
      w.id === id ? { ...w, lngLat } : w
    ),
  };
}

/** Move a pin and optionally name it (search hit or reverse-geocode). */
export function setWaypoint(
  draft: PlanDraft,
  id: string,
  lngLat: [number, number],
  label?: string
): PlanDraft {
  const moved = moveWaypoint(draft, id, lngLat);
  if (label == null) return moved;
  return updateWaypointLabel(moved, id, label);
}

export function updateWaypointLabel(
  draft: PlanDraft,
  id: string,
  label: string
): PlanDraft {
  return {
    ...draft,
    waypoints: draft.waypoints.map((w) =>
      w.id === id ? { ...w, label } : w
    ),
  };
}

/**
 * Drag in the stacked list. First stays start, last stays end, middle = via.
 */
export function reorderWaypoints(
  draft: PlanDraft,
  fromIndex: number,
  toIndex: number
): PlanDraft {
  const ordered = orderedWaypoints(draft);
  if (
    fromIndex === toIndex ||
    fromIndex < 0 ||
    toIndex < 0 ||
    fromIndex >= ordered.length ||
    toIndex >= ordered.length
  ) {
    return draft;
  }
  const next = [...ordered];
  const [item] = next.splice(fromIndex, 1);
  next.splice(toIndex, 0, item);
  const remapped = next.map((w, i) => {
    if (next.length === 1 || i === 0) {
      return { ...w, id: "start", role: "start" as const };
    }
    if (i === next.length - 1) {
      return { ...w, id: "end", role: "end" as const };
    }
    return {
      ...w,
      id: w.role === "via" ? w.id : `via-${i}`,
      role: "via" as const,
    };
  });
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: remapped,
  };
}

/** Hit radius for “tap/drag the blue line” (Komoot-style) in metres. */
export const PLAN_VIA_ALONG_MAX_OFF_M = 90;

/** Join painted endpoints to pins when the engine stopped a few metres off. */
export const PLAN_LINE_PIN_JOIN_MAX_M = 35;

/**
 * Komoot: the ribbon meets the pin. Never a long crow-flies cut through a field.
 */
export function joinPlanLineToPins(
  line: [number, number][],
  opts: {
    start?: [number, number] | null;
    end?: [number, number] | null;
    maxJoinM?: number;
  }
): [number, number][] {
  if (line.length < 2) return line;
  const max = opts.maxJoinM ?? PLAN_LINE_PIN_JOIN_MAX_M;
  const out = line.map((c) => [c[0], c[1]] as [number, number]);
  const start = opts.start;
  if (start) {
    const gap = haversineM(start[1], start[0], out[0][1], out[0][0]);
    if (gap > 1.5 && gap <= max) out[0] = [start[0], start[1]];
  }
  const end = opts.end;
  if (end) {
    const last = out[out.length - 1]!;
    const gap = haversineM(end[1], end[0], last[1], last[0]);
    if (gap > 1.5 && gap <= max) out[out.length - 1] = [end[0], end[1]];
  }
  return out;
}

/** Farm-track trim dropped 40 m–1.2 km — move the pin onto the street. */
export const PLAN_STREET_SNAP_MIN_M = 40;
export const PLAN_STREET_SNAP_MAX_M = 1200;

export function routeHasFarmTrimWarning(
  warnings?: string[] | null
): boolean {
  return (warnings ?? []).some(
    (w) =>
      w === HONESTY_FARM_TAIL_DE || w.startsWith("Kein Weg bis zum Pin")
  );
}

export function snapPlanPinToStreetLine(
  pin: [number, number],
  street: [number, number],
  opts?: { minM?: number; maxM?: number }
): [number, number] | null {
  const d = haversineM(pin[1], pin[0], street[1], street[0]);
  const minM = opts?.minM ?? PLAN_STREET_SNAP_MIN_M;
  const maxM = opts?.maxM ?? PLAN_STREET_SNAP_MAX_M;
  if (d < minM || d > maxM) return null;
  return [street[0], street[1]];
}

export function applyFarmTrimPinSnap(opts: {
  start: [number, number];
  end: [number, number];
  line: [number, number][];
  warnings?: string[];
  startIsGps?: boolean;
}): {
  start: [number, number];
  end: [number, number];
  snappedStart: boolean;
  snappedEnd: boolean;
} {
  if (!routeHasFarmTrimWarning(opts.warnings) || opts.line.length < 2) {
    return {
      start: opts.start,
      end: opts.end,
      snappedStart: false,
      snappedEnd: false,
    };
  }
  const first = opts.line[0]!;
  const last = opts.line[opts.line.length - 1]!;
  let start = opts.start;
  let end = opts.end;
  let snappedStart = false;
  let snappedEnd = false;
  if (!opts.startIsGps) {
    const s = snapPlanPinToStreetLine(start, first);
    if (s) {
      start = s;
      snappedStart = true;
    }
  }
  const e = snapPlanPinToStreetLine(end, last);
  if (e) {
    end = e;
    snappedEnd = true;
  }
  return { start, end, snappedStart, snappedEnd };
}

export const PLAN_LINE_COACH_RETRY_MS = 14 * 86400000;

/** Mobile plan sheet: recede while the rubber-band is up (Komoot). Desktop ignores. */
export function planEditorSheetMaxVh(opts: { shaping: boolean }): number {
  return opts.shaping ? 0 : 56;
}

/** Rubber-band *and* the following recalc: map stays the editor. */
export function planEditorSheetRecedes(opts: {
  rubberBand: boolean;
  adapting: boolean;
}): boolean {
  return opts.rubberBand || opts.adapting;
}

/** Brief “stop set” chip at the new via — not while waiting/reshaping. */
export function planMapStopHintVisible(opts: {
  hasStopAt: boolean;
  waitHintOnMap: boolean;
  rubberBand: boolean;
}): boolean {
  return opts.hasStopAt && !opts.waitHintOnMap && !opts.rubberBand;
}

export const PLAN_STOP_HINT_MS = 3200;

export const PLAN_MAP_CHROME_FAB_COL_PX = 56;
export const PLAN_FINGER_HINT_BELOW_GAP = 16;
export const PLAN_FINGER_HINT_ABOVE_GAP = 12;
export const PLAN_FINGER_HINT_PAD = 8;

/** Place the adapting chip near the finger without covering locate/undo. */
export function planFingerHintPlacement(opts: {
  fingerX: number;
  fingerY: number;
  mapW: number;
  mapH: number;
  chipW: number;
  chipH: number;
  avoidRight?: number;
  avoidTop?: number;
  avoidBottom?: number;
  pad?: number;
  preferAbove?: boolean;
}): { left: number; top: number } {
  const pad = opts.pad ?? PLAN_FINGER_HINT_PAD;
  const avoidRight = opts.avoidRight ?? 0;
  const avoidTop = opts.avoidTop ?? 0;
  const avoidBottom = opts.avoidBottom ?? 0;
  const minLeft = pad;
  const maxLeft = Math.max(minLeft, opts.mapW - opts.chipW - pad - avoidRight);
  const left = Math.min(
    maxLeft,
    Math.max(minLeft, opts.fingerX - opts.chipW / 2)
  );
  const minTop = pad + avoidTop;
  const maxTop = Math.max(minTop, opts.mapH - opts.chipH - pad - avoidBottom);
  const below = opts.fingerY + PLAN_FINGER_HINT_BELOW_GAP;
  const above = opts.fingerY - opts.chipH - PLAN_FINGER_HINT_ABOVE_GAP;
  let top = opts.preferAbove ? above : below;
  if (!opts.preferAbove && top + opts.chipH > opts.mapH - pad - avoidBottom) {
    top = above;
  } else if (opts.preferAbove && top < minTop) {
    top = below;
  }
  if (maxTop < minTop) return { left, top: minTop };
  return {
    left,
    top: Math.min(maxTop, Math.max(minTop, top)),
  };
}

/** First visit, or 14 days after a timestamped dismiss. Legacy `"1"` stays off. */
export function planLineCoachShouldShow(
  raw: string | null,
  now = Date.now()
): boolean {
  if (!raw) return true;
  if (raw === "1") return false;
  const t = Number(raw);
  if (!Number.isFinite(t)) return false;
  return now - t >= PLAN_LINE_COACH_RETRY_MS;
}

/** Finger radius — tighter when zoomed in. Mirrors Dart `plannedRouteTapRadiusM`. */
export function plannedRouteTapRadiusM(zoom: number): number {
  const z = Math.min(18, Math.max(9, zoom));
  return Math.min(200, Math.max(28, 90 * Math.pow(2, 14 - z)));
}

/** Duplicate via within this many metres is ignored (second tap on same stop). */
export const PLAN_VIA_DUPLICATE_M = 40;

export function planViaIsDuplicate(
  vias: [number, number][],
  pin: [number, number],
  minM = PLAN_VIA_DUPLICATE_M
): boolean {
  return vias.some((v) => haversineM(v[1], v[0], pin[1], pin[0]) < minM);
}

function planRubberKeepSlice(
  line: [number, number][] | null | undefined,
  fromM: number,
  toM: number
): [number, number][] {
  if (!line || line.length < 2) return [];
  return planLineSlice(line, fromM, toM);
}

function planRubberJoin(
  keep: [number, number][],
  fallback: [number, number],
  finger: [number, number],
  tail: [number, number][],
  tailFallback: [number, number]
): [number, number][] {
  const out: [number, number][] = keep.length >= 2 ? [...keep] : [fallback];
  out.push(finger);
  if (tail.length >= 2) out.push(...tail);
  else out.push(tailFallback);
  return out;
}

/**
 * Rubber-band while dragging the line or a pin.
 * Geometry before the previous anchor and after the next stays on the live
 * line; only the edited span is a straight ghost through the finger.
 */
export function planRubberBandLngLat(opts: {
  start: [number, number];
  end: [number, number];
  vias: [number, number][];
  finger: [number, number];
  line?: [number, number][] | null;
  dragging?: "start" | "end" | "via" | "line";
  draggingViaIndex?: number | null;
}): [number, number][] {
  const vias = opts.vias;
  const line = opts.line;
  const lineLen = line && line.length >= 2 ? lineLengthM(line) : 0;
  if (opts.dragging === "start") {
    const next = vias[0] ?? opts.end;
    if (lineLen > 4) {
      const nextAlong = projectOntoRoute(line!, next[1], next[0]).distanceAlongM;
      const tail = planRubberKeepSlice(line, nextAlong, lineLen);
      return [opts.finger, ...(tail.length >= 2 ? tail : [next])];
    }
    return [opts.finger, next];
  }
  if (opts.dragging === "end") {
    const prev = vias.length ? vias[vias.length - 1]! : opts.start;
    if (lineLen > 4) {
      const prevAlong = projectOntoRoute(line!, prev[1], prev[0]).distanceAlongM;
      const head = planRubberKeepSlice(line, 0, prevAlong);
      return [...(head.length >= 2 ? head : [prev]), opts.finger];
    }
    return [prev, opts.finger];
  }
  let prev = opts.start;
  let next = opts.end;
  const skip = opts.draggingViaIndex;
  let prevAlong = 0;
  let nextAlong = lineLen > 0 ? lineLen : Number.POSITIVE_INFINITY;
  if (line && line.length >= 2) {
    const along = projectOntoRoute(line, opts.finger[1], opts.finger[0])
      .distanceAlongM;
    for (let i = 0; i < vias.length; i++) {
      if (skip != null && i === skip) continue;
      const a = projectOntoRoute(line, vias[i][1], vias[i][0]).distanceAlongM;
      if (a <= along && a >= prevAlong) {
        prevAlong = a;
        prev = vias[i];
      } else if (a > along && a < nextAlong) {
        nextAlong = a;
        next = vias[i];
      }
    }
  } else if (skip != null && skip >= 0 && skip < vias.length) {
    prev = skip === 0 ? opts.start : vias[skip - 1]!;
    next = skip === vias.length - 1 ? opts.end : vias[skip + 1]!;
  }
  if (lineLen > 4) {
    const cap = Number.isFinite(nextAlong) ? Math.min(nextAlong, lineLen) : lineLen;
    return planRubberJoin(
      planRubberKeepSlice(line, 0, prevAlong),
      prev,
      opts.finger,
      planRubberKeepSlice(line, cap, lineLen),
      next
    );
  }
  return [prev, opts.finger, next];
}

/** Compact km chip on the ribbon (Komoot distance ticks). */
export function planDragAlongLabelKm(alongM: number): string {
  if (!Number.isFinite(alongM) || alongM <= 0) return "0";
  const km = alongM / 1000;
  if (km < 0.1) return "0";
  if (km < 10) return km.toFixed(1);
  return String(Math.round(km));
}

/** Finger / hover chip — honest km along the live line, not the rubber-band. */
export function planShapeKmChip(alongM: number): string {
  return `${planDragAlongLabelKm(alongM)} km`;
}

/** Live-ribbon opacity while the rubber-band is up. Whisper-faint. */
export function planRibbonDimOpacity(base: number, dimmed: boolean): number {
  if (!dimmed) return Math.min(1, Math.max(0, base));
  return Math.min(0.07, Math.max(0.028, base * 0.045));
}

/** Grab discs recede with the ribbon but stay visible as hit targets. */
export function planGrabHandleOpacity(base: number, dimmed: boolean): number {
  if (!dimmed) return Math.min(1, Math.max(0, base));
  return Math.min(0.36, Math.max(0.14, base * 0.28));
}

/** Compact legend keys from OSM bands + optional steep flag.
 *  Unknown OSM (orange core) only when the gap is real, not a 20 m hole. */
export const PLAN_RIBBON_UNKNOWN_MIN_KM = 0.08;

export function planRibbonLegendKinds(opts: {
  bands?: { surface?: string | null; fromKm?: number; toKm?: number }[];
  hasSteep?: boolean;
  unknownMinKm?: number;
}): string[] {
  const kinds = new Set<string>();
  const min = opts.unknownMinKm ?? PLAN_RIBBON_UNKNOWN_MIN_KM;
  let unknownKm = 0;
  let unknownBare = false;
  for (const b of opts.bands ?? []) {
    const k = planSurfaceKind(b.surface);
    if (k) {
      kinds.add(k);
      continue;
    }
    const span = (b.toKm ?? Number.NaN) - (b.fromKm ?? Number.NaN);
    if (Number.isFinite(span) && span > 0) unknownKm += span;
    else unknownBare = true;
  }
  if (unknownKm >= min || (unknownBare && unknownKm === 0)) kinds.add("unknown");
  if (opts.hasSteep) kinds.add("steep");
  return [...kinds];
}

export const PLAN_RIBBON_GRAB_HALO_WIDTH = 36;

export function planRibbonAllowsGrab(opts: {
  editorActive: boolean;
  hasLiveStreetLine: boolean;
  approx: boolean;
}): boolean {
  return opts.editorActive && opts.hasLiveStreetLine && !opts.approx;
}

/** Map chip while A+B exist and the engine is in flight — not a 1.6 s flash. */
export function planMapShowsRoutingWait(opts: {
  editorActive: boolean;
  routingBusy: boolean;
  hasStart: boolean;
  hasEnd: boolean;
}): boolean {
  return (
    opts.editorActive && opts.routingBusy && opts.hasStart && opts.hasEnd
  );
}

/**
 * History FABs stay off while a map chip owns Undo (stop / wait / adapting)
 * or the fallback routing-wait banner is up. Redo lives only on the FABs —
 * it returns when the chip clears.
 */
export function planMapHistoryFabsVisible(opts: {
  editorActive: boolean;
  hasHistory: boolean;
  mapHintOnMap: boolean;
  rubberBand: boolean;
  coachVisible: boolean;
  routingWaitBanner?: boolean;
}): boolean {
  return (
    opts.editorActive &&
    opts.hasHistory &&
    !opts.mapHintOnMap &&
    !opts.rubberBand &&
    !opts.coachVisible &&
    !opts.routingWaitBanner
  );
}

/**
 * Browser Discover is plan-only (`browserPlanOnly`). "In App starten" must
 * persist the draft first so the ride bridge deep-links a library id — never
 * an ephemeral `engine-*` active route without save.
 * Mirror: Flutter `planStartRidePersistsDraft`.
 */
export function planWebStartInAppRequiresSave(opts: {
  hasComputed: boolean;
  /** Group-create handoff leaves Discover — skip ride bridge. */
  asGroup?: boolean;
}): boolean {
  return opts.hasComputed && !opts.asGroup;
}

/** Library ids hand off to the app; ephemeral engine ids do not. */
export function planWebRideHandoffId(
  savedId: string | null | undefined
): string | null {
  if (!savedId || savedId.startsWith("engine-")) return null;
  return savedId;
}

/**
 * Stable fingerprint of a planned line so Save + Start can reuse one library
 * id when the geometry has not changed.
 */
export function planDraftGeometryKey(opts: {
  coordinates: [number, number][] | null | undefined;
  viaCount?: number;
  distanceM?: number;
}): string | null {
  const c = opts.coordinates;
  if (!c || c.length < 2) return null;
  const a = c[0]!;
  const b = c[c.length - 1]!;
  const mid = c[Math.floor(c.length / 2)]!;
  const r = (n: number) => n.toFixed(5);
  return [
    String(c.length),
    String(opts.viaCount ?? 0),
    opts.distanceM != null ? String(Math.round(opts.distanceM)) : "",
    r(a[0]),
    r(a[1]),
    r(mid[0]),
    r(mid[1]),
    r(b[0]),
    r(b[1]),
  ].join("|");
}

/** Reuse last save when the live line still matches that fingerprint. */
export function planReuseSavedHandoffId(opts: {
  lastSavedId: string | null | undefined;
  lastSavedGeomKey: string | null | undefined;
  currentGeomKey: string | null | undefined;
}): string | null {
  if (!opts.currentGeomKey || !opts.lastSavedGeomKey) return null;
  if (opts.currentGeomKey !== opts.lastSavedGeomKey) return null;
  return planWebRideHandoffId(opts.lastSavedId);
}

/** Finger-chip while the engine reshapes an existing line (not the first A–B). */
export function planMapAdaptingHintOnMap(opts: {
  routingBusy: boolean;
  hasLiveLine: boolean;
  hasFinger: boolean;
}): boolean {
  return opts.routingBusy && opts.hasLiveLine && opts.hasFinger;
}

/**
 * Parked reshape finger (Web `planShaped` / Flutter `_planShapeHintAt`) lasts
 * only while that reshape is in flight — otherwise the next edit parks the
 * wait chip on a stale point.
 */
export function planParkedFingerClearsWhenIdle(routingBusy: boolean): boolean {
  return !routingBusy;
}

/**
 * Dest/stop wait pin wins over a parked reshape finger. Needed after undo
 * mid-recalc: finger flag clears but MapView may still hold lastShapeFinger.
 */
export function planMapHintAnchorLngLat(opts: {
  adaptingAt: [number, number] | null | undefined;
  parkedFinger: [number, number] | null | undefined;
}): [number, number] | null {
  return opts.adaptingAt ?? opts.parkedFinger ?? null;
}

/** First A→B (or dest confirm / GPS wait): chip at the dest pin.
 * Once a live line exists, the 1.6 s dest flash does not return to the chip. */
export function planMapDestWaitHintOnMap(opts: {
  editorActive: boolean;
  routingBusy: boolean;
  hasStart: boolean;
  hasEnd: boolean;
  fingerHint: boolean;
  destConfirm?: boolean;
  hasLiveLine?: boolean;
}): boolean {
  if (opts.fingerHint || !opts.editorActive || !opts.hasEnd) return false;
  if (opts.routingBusy && opts.hasStart) return true;
  if (!opts.hasStart) return true;
  if (!opts.destConfirm) return false;
  return !opts.hasLiveLine;
}

export type PlanMapDestWaitCopy = "adapting" | "firstAb" | "waitingGps";

export function planMapDestWaitCopy(opts: {
  hasStart: boolean;
  hasLiveLine: boolean;
}): PlanMapDestWaitCopy {
  if (!opts.hasStart) return "waitingGps";
  if (!opts.hasLiveLine) return "firstAb";
  return "adapting";
}

export function planFingerHintChipW(opts: {
  undo: boolean;
  firstAb: boolean;
}): number {
  if (opts.firstAb) return opts.undo ? 280 : 244;
  return opts.undo ? 228 : 176;
}

export const PLAN_LINE_GRAB_MOVE_PX = 8;

/** Hold on the ribbon → new dest (matches Flutter `kPlanLineHold`). */
export const PLAN_LINE_HOLD_MS = 450;

/** Any slip past this cancels hold→dest (before exclusive rubber). */
export const PLAN_LINE_HOLD_CANCEL_PX = 6;

/** Second finger = pinch/rotate, not a via. Yield the line grab. */
export function planLineGrabYieldsToPinch(pointerCount: number): boolean {
  return pointerCount >= 2;
}

/** One finger past the slop becomes an exclusive line pull (map pan off). */
export function planLineGrabBecomesExclusive(opts: {
  pointerCount: number;
  movePx: number;
  thresholdPx?: number;
}): boolean {
  const threshold = opts.thresholdPx ?? PLAN_LINE_GRAB_MOVE_PX;
  return opts.pointerCount === 1 && opts.movePx >= threshold;
}

/** Finger left the “still” zone — do not fire hold→new dest. */
export function planLineHoldCancelsOnMove(opts: {
  movePx: number;
  thresholdPx?: number;
}): boolean {
  const threshold = opts.thresholdPx ?? PLAN_LINE_HOLD_CANCEL_PX;
  return opts.movePx >= threshold;
}

export const PLAN_LINE_COACH_COMPACT_HEIGHT = 700;
export const PLAN_LINE_COACH_X_COMPACT_HEIGHT = 640;

export function planLineCoachIsCompact(height: number): boolean {
  return height < PLAN_LINE_COACH_COMPACT_HEIGHT;
}

export function planLineCoachIsXCompact(height: number): boolean {
  return height < PLAN_LINE_COACH_X_COMPACT_HEIGHT;
}

export function planLineCoachCopy(opts: {
  adopting: boolean;
  compact: boolean;
  full: string;
  short: string;
  adopt: string;
}): string {
  if (opts.adopting) return opts.adopt;
  return opts.compact ? opts.short : opts.full;
}

export const PLAN_RIBBON_LEGEND_COMPACT_WIDTH = 420;

export function planRibbonLegendCompact(width: number): boolean {
  return width < PLAN_RIBBON_LEGEND_COMPACT_WIDTH;
}

export const PLAN_CHEVRON_FRESH_MS = 1400;

export function planChevronIconOpacity(opts: {
  dimmed: boolean;
  fresh: boolean;
}): number {
  if (opts.dimmed) return 0;
  return opts.fresh ? 0.96 : 0.88;
}

/** Spacing between grab discs — denser when zoomed in (Komoot beads). */
export function planReshapeHandleStepM(zoom = 14): number {
  if (zoom >= 16) return 600;
  if (zoom >= 15) return 800;
  if (zoom >= 14) return 1100;
  if (zoom >= 13) return 1800;
  return 2800;
}

export function planReshapeHandleMax(zoom = 14): number {
  if (zoom >= 16) return 10;
  if (zoom >= 15) return 8;
  if (zoom >= 14) return 6;
  return 4;
}

/** Where grab discs sit — every few hundred metres, capped by zoom. */
export function planReshapeHandleFracs(lenM: number, zoom = 14): number[] {
  if (!(lenM > 0)) return [0.5];
  const step = planReshapeHandleStepM(zoom);
  const max = planReshapeHandleMax(zoom);
  const out: number[] = [];
  for (let a = step; a < lenM && out.length < max; a += step) {
    out.push(a / lenM);
  }
  return out.length ? out : [0.5];
}

/** Translucent discs on the live ribbon — drag off-path like AllTrails. */
export function planReshapeHandles(opts: {
  line: [number, number][];
  vias: [number, number][];
  maxHandles?: number;
  minFromEndM?: number;
  minFromViaM?: number;
  avoidAlongM?: number[];
  avoidM?: number;
  zoom?: number;
}): { lng: number; lat: number; alongM: number }[] {
  const line = opts.line;
  const len = lineLengthM(line);
  if (len < 280) return [];
  const zoom = opts.zoom ?? 14;
  const maxHandles = opts.maxHandles ?? planReshapeHandleMax(zoom);
  const minFromEndM = opts.minFromEndM ?? 180;
  const minFromViaM = opts.minFromViaM ?? 140;
  const avoidAlongM = opts.avoidAlongM ?? [];
  const avoidM = opts.avoidM ?? 160;
  const fracs = planReshapeHandleFracs(len, zoom);
  const out: { lng: number; lat: number; alongM: number }[] = [];
  for (const f of fracs) {
    if (out.length >= maxHandles) break;
    const along = len * f;
    if (along < minFromEndM || len - along < minFromEndM) continue;
    if (avoidAlongM.some((a) => Math.abs(a - along) < avoidM)) continue;
    const pt = pointAlongRoute(line, along);
    if (
      opts.vias.some((v) => haversineM(v[1], v[0], pt[1], pt[0]) < minFromViaM)
    ) {
      continue;
    }
    out.push({ lng: pt[0], lat: pt[1], alongM: along });
  }
  if (out.length === 0 && len >= 280) {
    const along = len * 0.5;
    const pt = pointAlongRoute(line, along);
    if (
      !opts.vias.some((v) => haversineM(v[1], v[0], pt[1], pt[0]) < minFromViaM)
    ) {
      out.push({ lng: pt[0], lat: pt[1], alongM: along });
    }
  }
  return out;
}

/** Long tours keep km-ticks for a closer zoom so the overview stays clean. */
export function planDistanceTicksMinZoom(distanceM: number): number {
  return distanceM >= 25000 ? 13 : 12;
}

export function planDistanceTicksVisible(
  zoom: number,
  minZoom = 12
): boolean {
  return zoom >= minZoom;
}

/** Spacing for km ticks: denser only when zoomed in (Komoot). */
export function planDistanceTickStepM(zoom: number): number {
  if (zoom >= 16) return 1000;
  if (zoom >= 14.5) return 2000;
  if (zoom >= 13) return 2500;
  return 5000;
}

export function planDistanceTickMax(zoom: number): number {
  if (zoom >= 16) return 10;
  if (zoom >= 14.5) return 8;
  if (zoom >= 13) return 6;
  return 4;
}

/** Along-metres of pins on the live line — keep ticks off vias / handles. */
export function planPinAlongMeters(
  line: [number, number][],
  pins: [number, number][]
): number[] {
  if (line.length < 2) return [];
  return pins.map((p) => projectOntoRoute(line, p[1], p[0]).distanceAlongM);
}

/**
 * Named via under the number. Skip generic “on map” / “Via 1” placeholders.
 */
export function planViaMapCaption(
  label?: string | null,
  placeholders: string[] = []
): string | null {
  const t = (label ?? "").trim();
  if (!t) return null;
  const lower = t.toLowerCase();
  for (const p of placeholders) {
    const q = p.trim().toLowerCase();
    if (q && lower === q) return null;
  }
  if (
    /^(punkt auf der karte|point on the map|point sur la carte|punto sulla mappa|punt op de kaart)$/i.test(
      t
    )
  ) {
    return null;
  }
  if (/^(zwischenstopp|stopp|stop|via|waypoint)\s*\d*$/i.test(t)) return null;
  if (/^\d{1,2}$/.test(t)) return null;
  if (t.length > 22) return `${t.slice(0, 20)}…`;
  return t;
}

/** Sparse km labels on the live ribbon (Komoot: only when zoomed in). */
export function planDistanceTicks(opts: {
  line: [number, number][];
  everyM?: number;
  maxTicks?: number;
  minFromEndM?: number;
  avoidAlongM?: number[];
  avoidM?: number;
  zoom?: number;
  minZoom?: number;
}): { lng: number; lat: number; km: string; alongM: number }[] {
  const zoom = opts.zoom ?? 14;
  const minZoom = opts.minZoom ?? 12;
  if (!planDistanceTicksVisible(zoom, minZoom)) return [];
  const line = opts.line;
  const everyM = opts.everyM ?? planDistanceTickStepM(zoom);
  const minFromEndM = opts.minFromEndM ?? 1200;
  const maxTicks = opts.maxTicks ?? planDistanceTickMax(zoom);
  const avoidAlongM = opts.avoidAlongM ?? [];
  const avoidM = opts.avoidM ?? 180;
  const len = lineLengthM(line);
  if (len < everyM + minFromEndM) return [];
  const out: { lng: number; lat: number; km: string; alongM: number }[] = [];
  for (
    let along = everyM;
    along <= len - minFromEndM && out.length < maxTicks;
    along += everyM
  ) {
    if (along < minFromEndM) continue;
    if (avoidAlongM.some((a) => Math.abs(a - along) < avoidM)) continue;
    const pt = pointAlongRoute(line, along);
    out.push({
      lng: pt[0],
      lat: pt[1],
      km: planDragAlongLabelKm(along),
      alongM: along,
    });
  }
  return out;
}

export function planWaypointsFingerprint(draft: PlanDraft): string {
  return draft.waypoints
    .map(
      (w) => `${w.role}:${w.lngLat[0].toFixed(5)},${w.lngLat[1].toFixed(5)}`
    )
    .join("|");
}

/** One snapshot per user edit. Engine recomputes do not belong on this stack. */
export function pushPlanUndo(
  stack: PlanDraft[],
  prev: PlanDraft,
  next: PlanDraft,
  max = 20
): PlanDraft[] {
  if (planWaypointsFingerprint(prev) === planWaypointsFingerprint(next)) {
    return stack;
  }
  return [...stack, prev].slice(-max);
}

export function planElevSegmentSteep(opts: {
  fromM: number;
  toM: number;
  distM: number;
  steepPct?: number;
}): boolean {
  if (!(opts.distM > 1)) return false;
  const grade = ((opts.toM - opts.fromM) / opts.distM) * 100;
  return Math.abs(grade) > (opts.steepPct ?? 8);
}

const PLAN_UNPAVED_SURFACES = new Set([
  "gravel",
  "fine_gravel",
  "pebblestone",
  "compacted",
  "unpaved",
  "dirt",
  "ground",
  "earth",
  "grass",
  "sand",
  "path",
  "track",
  "trail",
  "wood",
  "woodchips",
  "mud",
  "rock",
  "stones",
]);

export function planSurfaceIsUnpaved(surface?: string | null): boolean {
  const s = surface?.trim().toLowerCase() ?? "";
  return PLAN_UNPAVED_SURFACES.has(s);
}

export type PlanSurfaceKind = OsmSurfaceGroup;

export function planSurfaceKind(
  surface?: string | null
): PlanSurfaceKind | null {
  return osmSurfaceGroup(surface);
}

export type PlanSurfaceSlice = {
  kind: PlanSurfaceKind;
  coords: [number, number][];
};

/**
 * Merge short non-flag gaps so steep / surface bands do not flicker
 * every 20–40 m (Komoot paints continuous heat, not a dashed Morse code).
 */
export function fillShortFlagGaps(
  flags: boolean[],
  along: number[],
  mergeGapM: number
): void {
  if (!(mergeGapM > 0) || flags.length === 0 || along.length < flags.length + 1) {
    return;
  }
  let i = 0;
  while (i < flags.length) {
    if (!flags[i]) {
      i++;
      continue;
    }
    let j = i;
    while (j + 1 < flags.length) {
      if (flags[j + 1]) {
        j++;
        continue;
      }
      let g = j + 1;
      let gapM = 0;
      while (g < flags.length && !flags[g]) {
        gapM += along[g + 1]! - along[g]!;
        g++;
      }
      if (g < flags.length && flags[g] && gapM <= mergeGapM) {
        for (let k = j + 1; k < g; k++) flags[k] = true;
        j = g;
        continue;
      }
      break;
    }
    i = j + 1;
  }
}

/** Inclusive slice of a polyline between two along-track metres. */
export function planLineSlice(
  line: [number, number][],
  fromM: number,
  toM: number
): [number, number][] {
  if (line.length < 2) return [];
  const lo = Math.min(fromM, toM);
  const hi = Math.max(fromM, toM);
  if (!(hi > lo + 4)) return [];
  const out: [number, number][] = [];
  let walked = 0;
  for (let i = 1; i < line.length; i++) {
    const a = line[i - 1];
    const b = line[i];
    const seg = haversineM(a[1], a[0], b[1], b[0]);
    const aM = walked;
    const bM = walked + seg;
    if (bM < lo - 0.5) {
      walked = bM;
      continue;
    }
    if (aM > hi + 0.5) break;
    if (out.length === 0) {
      out.push(pointAlongRoute(line, Math.max(lo, aM)));
    }
    if (bM <= hi) {
      if (bM >= lo) out.push(b);
    } else {
      out.push(pointAlongRoute(line, hi));
      break;
    }
    walked = bM;
  }
  return out.length >= 2 ? out : [];
}

function elevAlongSamples(
  elevM: number[],
  alongM: number,
  lineLenM: number,
  distKm?: number[] | null
): number {
  if (elevM.length < 2 || !(lineLenM > 0)) return elevM[0] ?? 0;
  if (
    distKm &&
    distKm.length === elevM.length &&
    distKm[distKm.length - 1]! > 0
  ) {
    const km = Math.max(
      0,
      Math.min(distKm[distKm.length - 1]!, alongM / 1000)
    );
    for (let i = 1; i < distKm.length; i++) {
      if (km <= distKm[i]!) {
        const span = distKm[i]! - distKm[i - 1]!;
        const f = span < 1e-6 ? 1 : (km - distKm[i - 1]!) / span;
        return elevM[i - 1]! * (1 - f) + elevM[i]! * f;
      }
    }
    return elevM[elevM.length - 1]!;
  }
  const t = Math.max(0, Math.min(1, alongM / lineLenM));
  const x = t * (elevM.length - 1);
  const i = Math.max(0, Math.min(elevM.length - 2, Math.floor(x)));
  const f = x - i;
  return elevM[i]! * (1 - f) + elevM[i + 1]! * f;
}

/**
 * Steep climbs/descents as merged polylines on the live ribbon
 * (Komoot paints grade on the line, not only in the profile).
 */
export function planSteepLineSlices(opts: {
  line: [number, number][];
  elevM: number[];
  distKm?: number[] | null;
  steepPct?: number;
  minSegM?: number;
  mergeGapM?: number;
  maxSlices?: number;
}): [number, number][][] {
  const line = opts.line;
  const elevM = opts.elevM;
  if (line.length < 2 || elevM.length < 2) return [];
  const minSegM = opts.minSegM ?? 50;
  const mergeGapM = opts.mergeGapM ?? 80;
  const maxSlices = opts.maxSlices ?? 18;
  const along: number[] = new Array(line.length).fill(0);
  for (let i = 1; i < line.length; i++) {
    along[i] =
      along[i - 1]! +
      haversineM(line[i - 1]![1], line[i - 1]![0], line[i]![1], line[i]![0]);
  }
  const len = along[along.length - 1]!;
  if (len < minSegM * 2) return [];
  const steepPct = opts.steepPct ?? 8;
  const steep: boolean[] = [];
  for (let i = 1; i < line.length; i++) {
    const dist = along[i]! - along[i - 1]!;
    if (dist < minSegM) {
      steep.push(steep.length === 0 ? false : steep[steep.length - 1]!);
      continue;
    }
    steep.push(
      planElevSegmentSteep({
        fromM: elevAlongSamples(elevM, along[i - 1]!, len, opts.distKm),
        toM: elevAlongSamples(elevM, along[i]!, len, opts.distKm),
        distM: dist,
        steepPct,
      })
    );
  }
  fillShortFlagGaps(steep, along, mergeGapM);
  const slices: [number, number][][] = [];
  let cur: [number, number][] | null = null;
  for (let i = 0; i < steep.length; i++) {
    if (!steep[i]) {
      if (cur) {
        slices.push(cur);
        cur = null;
      }
      continue;
    }
    if (!cur) cur = [line[i]!, line[i + 1]!];
    else cur.push(line[i + 1]!);
  }
  if (cur) slices.push(cur);
  if (slices.length <= maxSlices) return slices;
  return [...slices]
    .sort((a, b) => lineLengthM(b) - lineLengthM(a))
    .slice(0, maxSlices);
}

/** Whole-ribbon surface tint (AllTrails) — asphalt / gravel / trail. */
export const PLAN_SURFACE_MERGE_GAP_M = 80;

export function planElevScrubT(alongM: number, lineLenM: number): number | null {
  if (!(lineLenM > 0) || !Number.isFinite(alongM)) return null;
  return Math.min(1, Math.max(0, alongM / lineLenM));
}

export function planSurfaceLineSlices(opts: {
  line: [number, number][];
  bands: { fromKm: number; toKm: number; surface: string | null }[];
  minSegM?: number;
  maxSlices?: number;
  mergeGapM?: number;
}): PlanSurfaceSlice[] {
  const minSegM = opts.minSegM ?? 50;
  const maxSlices = opts.maxSlices ?? 24;
  const mergeGapM = opts.mergeGapM ?? PLAN_SURFACE_MERGE_GAP_M;
  const merged: { kind: PlanSurfaceKind; fromM: number; toM: number }[] = [];
  const bands = [...opts.bands].sort((a, b) => a.fromKm - b.fromKm);
  for (const b of bands) {
    const kind = planSurfaceKind(b.surface);
    if (!kind) continue;
    const fromM = b.fromKm * 1000;
    const toM = b.toKm * 1000;
    if (!(toM - fromM >= minSegM)) continue;
    const last = merged[merged.length - 1];
    if (last && last.kind === kind && fromM <= last.toM + mergeGapM) {
      last.toM = Math.max(last.toM, toM);
    } else {
      merged.push({ kind, fromM, toM });
    }
  }
  const out: PlanSurfaceSlice[] = [];
  for (const m of merged) {
    const coords = planLineSlice(opts.line, m.fromM, m.toM);
    if (coords.length >= 2) out.push({ kind: m.kind, coords });
  }
  if (out.length <= maxSlices) return out;
  return [...out]
    .sort((a, b) => lineLengthM(b.coords) - lineLengthM(a.coords))
    .slice(0, maxSlices);
}

/** Unpaved / gravel stretches on the live ribbon (AllTrails surface tint). */
export function planUnpavedLineSlices(opts: {
  line: [number, number][];
  bands: { fromKm: number; toKm: number; surface: string | null }[];
  maxSlices?: number;
}): [number, number][][] {
  return planSurfaceLineSlices({
    line: opts.line,
    bands: opts.bands,
    maxSlices: opts.maxSlices ?? 18,
  })
    .filter((s) => s.kind === "gravel" || s.kind === "trail")
    .map((s) => s.coords);
}

const PLAN_LIVE_AB_ROUTE_IDS = new Set([
  "active",
  "active-merged",
  "approach",
]);

/** Painted live A–B — not catalog leftovers or quick alts. */
export function planShapeRouteId(id: string): boolean {
  if (PLAN_LIVE_AB_ROUTE_IDS.has(id)) return true;
  return (
    id.startsWith("steep-") ||
    id.startsWith("unpaved-") ||
    id.startsWith("paved-") ||
    id.startsWith("gravel-") ||
    id.startsWith("surf-")
  );
}

/** Line tap / near-line map tap inserts a via; far tap with a live line also inserts a via. */
export function planMapTapInsertsViaAlong(opts: {
  picking?: PlanSlot | null;
  hasStart: boolean;
  hasEnd: boolean;
  crossTrackM?: number | null;
  lineHit?: boolean;
  maxOffM?: number;
}): boolean {
  if (!opts.hasStart || !opts.hasEnd) return false;
  if (opts.picking === "start" || opts.picking === "end") return false;
  if (opts.picking === "via" || opts.lineHit) return true;
  const off = opts.crossTrackM;
  if (off == null || !Number.isFinite(off)) return false;
  return off <= (opts.maxOffM ?? PLAN_VIA_ALONG_MAX_OFF_M);
}

export function insertViaAlong(
  draft: PlanDraft,
  lngLat: [number, number],
  opts?: {
    line?: [number, number][] | null;
    label?: string;
    snapVia?: (p: [number, number]) => [number, number];
  }
): PlanDraft {
  const line = opts?.line;
  const trailSnap = opts?.snapVia ?? ((p: [number, number]) => p);
  let pin = lngLat;
  if (line && line.length >= 2) {
    const click = projectOntoRoute(line, lngLat[1], lngLat[0]);
    if (click.crossTrackM <= PLAN_VIA_ALONG_MAX_OFF_M) {
      pin = pointAlongRoute(line, click.distanceAlongM);
    } else {
      pin = trailSnap(lngLat);
    }
  } else {
    pin = trailSnap(lngLat);
  }
  const start = draft.waypoints.filter((w) => w.role === "start");
  const vias = draft.waypoints.filter((w) => w.role === "via");
  const end = draft.waypoints.filter((w) => w.role === "end");
  const via: PlanWaypoint = {
    id: `via-${Date.now()}`,
    role: "via",
    lngLat: pin,
    label: opts?.label ?? `Via ${vias.length + 1}`,
  };
  if (!line || line.length < 2) {
    return addVia(draft, pin, via.label);
  }
  const click = projectOntoRoute(line, pin[1], pin[0]);
  let insertAt = vias.length;
  let before = 0;
  for (const w of vias) {
    const along = projectOntoRoute(line, w.lngLat[1], w.lngLat[0]);
    if (along.distanceAlongM < click.distanceAlongM) before += 1;
  }
  insertAt = before;
  const nextVias = [...vias];
  nextVias.splice(insertAt, 0, via);
  return {
    ...draft,
    ...clearTourLeftover(draft),
    waypoints: [...start, ...nextVias, ...end],
  };
}

/**
 * Plan editor map tap: GPS→start + pin→end.
 * On/near the painted line → via (Komoot). Far tap after A+B with a live
 * line → via through that point (AllTrails continue / Komoot include).
 * Far tap without a line still replaces dest. Pick-end and Alt/hold always set dest.
 */
export function applyPlanMapTap(
  draft: PlanDraft,
  pin: [number, number],
  opts: {
    gps?: [number, number] | null;
    picking?: PlanSlot | null;
    startLabel: string;
    endLabel: string;
    myPosLabel: string;
    viaLabel?: string;
    snapVia?: (p: [number, number]) => [number, number];
    tourPreviewOnMap?: boolean;
    line?: [number, number][] | null;
    lineHit?: boolean;
    zoom?: number;
    /** Komoot Alt/Option — new finish, vias stay. */
    forceEnd?: boolean;
  }
): PlanDraft {
  const gps = opts.gps ?? null;
  const snap = opts.snapVia ?? ((p: [number, number]) => p);
  const leftover = planLeftoverTourWipesOnTap({
    leftover:
      Boolean(opts.tourPreviewOnMap) || draftHasDiscoverTourPreview(draft),
    hasStart: Boolean(startOf(draft)),
    hasEnd: Boolean(endOf(draft)),
    picking: opts.picking,
  });
  if (opts.picking === "start") return setStart(draft, pin, opts.startLabel);
  if (opts.forceEnd && startOf(draft)) {
    return setEnd(draft, pin, opts.endLabel);
  }
  const viaOpts = {
    line: opts.line,
    snapVia: snap,
    label: opts.viaLabel,
  };
  if (opts.picking === "via") {
    if (planViaIsDuplicate(viasOf(draft), pin)) return draft;
    return insertViaAlong(draft, pin, viaOpts);
  }
  const alongOff =
    opts.line && opts.line.length >= 2
      ? projectOntoRoute(opts.line, pin[1], pin[0]).crossTrackM
      : null;
  const shapeVia = planMapTapInsertsViaAlong({
    picking: opts.picking,
    hasStart: Boolean(startOf(draft)),
    hasEnd: Boolean(endOf(draft)),
    crossTrackM: alongOff,
    lineHit: opts.lineHit,
    maxOffM: plannedRouteTapRadiusM(opts.zoom ?? 14),
  });
  if (shapeVia) {
    if (planViaIsDuplicate(viasOf(draft), pin)) return draft;
    return insertViaAlong(draft, pin, viaOpts);
  }
  if (leftover) {
    const base = emptyDraft(draft.profile);
    const withStart = gps ? setStart(base, gps, opts.myPosLabel) : base;
    return setEnd(withStart, pin, opts.endLabel);
  }
  if (opts.picking === "end") {
    const next =
      !startOf(draft) && gps ? setStart(draft, gps, opts.myPosLabel) : draft;
    return setEnd(next, pin, opts.endLabel);
  }
  if (!startOf(draft) && !endOf(draft)) {
    if (gps) {
      return setEnd(setStart(draft, gps, opts.myPosLabel), pin, opts.endLabel);
    }
    return setEnd(draft, pin, opts.endLabel);
  }
  if (!startOf(draft)) {
    return setEnd(draft, pin, opts.endLabel);
  }
  if (!endOf(draft)) return setEnd(draft, pin, opts.endLabel);
  if (opts.line && opts.line.length >= 2) {
    if (planViaIsDuplicate(viasOf(draft), pin)) return draft;
    return insertViaAlong(draft, pin, viaOpts);
  }
  if (
    planBusyBlocksDestReplace({
      routingBusy: Boolean(opts.routingBusy),
      hasStart: Boolean(startOf(draft)),
      hasEnd: Boolean(endOf(draft)),
      picking: opts.picking,
      forceEnd: opts.forceEnd,
    })
  ) {
    return draft;
  }
  const withoutVias: PlanDraft = {
    ...draft,
    waypoints: draft.waypoints.filter((w) => w.role !== "via"),
  };
  return setEnd(withoutVias, pin, opts.endLabel);
}

/** After A+B with a live line, a tap beside the ribbon inserts a via. */
export function planFarTapInsertsVia(opts: {
  picking?: PlanSlot | null;
  hasStart: boolean;
  hasEnd: boolean;
  hasLiveLine: boolean;
}): boolean {
  if (opts.picking === "start" || opts.picking === "end") return false;
  return opts.hasStart && opts.hasEnd && opts.hasLiveLine;
}

/**
 * Long-press / Alt-hold “Set as destination” (Komoot).
 * Explicit via-pick or start-pick still places that pin. A+B required.
 * Hold on the painted line also sets dest — short tap on the line remains via.
 */
export function planLongPressSetsDest(opts: {
  picking?: PlanSlot | null;
  hasStart: boolean;
  hasEnd: boolean;
  tapHitsLine?: boolean;
}): boolean {
  if (!opts.hasStart || !opts.hasEnd) return false;
  if (opts.picking === "start" || opts.picking === "via") return false;
  return true;
}

/**
 * Hold / right-click in the plan editor: new dest (vias stay).
 * Building A+B (no dest yet) still places the next pin like a tap.
 */
export function applyPlanMapLongPress(
  draft: PlanDraft,
  pin: [number, number],
  opts: Parameters<typeof applyPlanMapTap>[2]
): PlanDraft {
  if (planLongPressSetsDest({
    picking: opts.picking,
    hasStart: Boolean(startOf(draft)),
    hasEnd: Boolean(endOf(draft)),
  })) {
    return applyPlanMapTap(draft, pin, { ...opts, forceEnd: true });
  }
  return applyPlanMapTap(draft, pin, opts);
}

/** Concatenate LineStrings (skip duplicate join point). */
export function concatLineStrings(
  parts: GeoJSON.LineString[]
): GeoJSON.LineString {
  const coordinates: [number, number][] = [];
  for (const part of parts) {
    const coords = (part.coordinates ?? []) as [number, number][];
    if (!coords.length) continue;
    if (
      coordinates.length &&
      coordinates[coordinates.length - 1][0] === coords[0][0] &&
      coordinates[coordinates.length - 1][1] === coords[0][1]
    ) {
      coordinates.push(...coords.slice(1));
    } else {
      coordinates.push(...coords);
    }
  }
  return { type: "LineString", coordinates };
}

export function mergeRouteResults(
  parts: ClientRouteResult[],
  profile: RoutingProfile,
  warnings: string[] = []
): ClientRouteResult {
  const geometry = concatLineStrings(parts.map((p) => p.geometry));
  const steps: NavStep[] = [];
  let along = 0;
  for (const part of parts) {
    for (const s of part.steps ?? []) {
      steps.push({
        ...s,
        id: `${part.engine}-${s.id}-${steps.length}`,
        distanceAlongM: along + (s.distanceAlongM ?? 0),
      });
    }
    along += part.distanceM;
  }
  return {
    distanceM: parts.reduce((a, p) => a + p.distanceM, 0),
    durationS: parts.reduce((a, p) => a + p.durationS, 0),
    geometry,
    engine: parts.map((p) => p.engine).join("+"),
    profile,
    warnings: [
      ...warnings,
      ...parts.flatMap((p) => p.warnings ?? []),
    ].filter(Boolean),
    steps: steps.length ? steps : undefined,
  };
}

/** Destination offsets for quick rides (loop-ish out-and-back via far point). */
export function quickDestinations(
  start: [number, number],
  minutes: number
): { id: string; label: string; to: [number, number]; reason: string }[] {
  // ~12–18 km/h average → distance budget one-way ~ half of round trip
  const kmBudget = Math.max(4, (minutes / 60) * 14 * 0.45);
  const deg = kmBudget / 111;
  const [lng, lat] = start;
  return [
    {
      id: "quick-n",
      label: `${minutes} min · Norden`,
      to: [lng, lat + deg],
      reason: "Out-and-back Richtung Norden",
    },
    {
      id: "quick-e",
      label: `${minutes} min · Osten`,
      to: [lng + deg / Math.cos((lat * Math.PI) / 180), lat],
      reason: "Out-and-back Richtung Osten",
    },
    {
      id: "quick-sw",
      label: `${minutes} min · Südwest`,
      to: [
        lng - deg * 0.7 / Math.cos((lat * Math.PI) / 180),
        lat - deg * 0.7,
      ],
      reason: "Out-and-back Richtung Südwest",
    },
  ];
}

/**
 * Quick-Optionen mit Cache, Sequenz + Pause (GraphHopper Free-Tier).
 * Default: nur 1 Engine-Call; weitere per `limit` / „Mehr laden“.
 */
export async function computeQuickOptions(
  start: [number, number],
  profile: RoutingProfile,
  minutes: number,
  opts?: {
    limit?: number;
    /** Mindestabstand zwischen Engine-Calls (ms) */
    gapMs?: number;
    signal?: AbortSignal;
    /** Cache ignorieren (manuelles Neu berechnen) */
    force?: boolean;
    /** Bei Limit geometrische Näherung statt leerer Liste */
    allowApprox?: boolean;
    /**
     * D-60-LOOP-FILTER-01: when false, never return out-and-back pads
     * („60 min · Norden“). Used when Route=Rundkurs / loopOnly.
     */
    allowOutAndBack?: boolean;
  }
): Promise<ComputeQuickOptionsResult> {
  // Rundkurs honesty: out-and-back Quick is never a valid primary suggestion.
  if (opts?.allowOutAndBack === false) {
    return { options: [], rateLimited: false, fromCache: false };
  }
  const limit = Math.max(1, Math.min(3, opts?.limit ?? 1));
  const gapMs = opts?.gapMs ?? 1200;
  const allowApprox = opts?.allowApprox ?? true;
  const key = quickCacheKey(start, profile, minutes);

  if (!opts?.force) {
    const cached = quickCache.get(key);
    if (cached && cached.length >= limit) {
      return {
        options: cached.slice(0, limit),
        rateLimited: false,
        fromCache: true,
      };
    }
  }

  const dests = quickDestinations(start, minutes);
  const existing = (!opts?.force ? quickCache.get(key) : undefined) ?? [];
  const out: QuickOption[] = [...existing];
  let rateLimited = false;

  for (let i = 0; i < dests.length && out.length < limit; i++) {
    if (opts?.signal?.aborted) break;
    if (out.some((o) => o.id === dests[i].id)) continue;

    if (out.length > existing.length || i > 0) {
      // pause before every new engine call after the first in this run
      const newCalls = out.filter((o) => !existing.some((e) => e.id === o.id))
        .length;
      if (newCalls > 0 || existing.length > 0) await sleep(gapMs);
    }
    if (opts?.signal?.aborted) break;

    const d = dests[i];
    const res = await requestRouteDetailed(profile, start, d.to);
    if (res.ok) {
      out.push({
        id: d.id,
        label: d.label,
        reason: d.reason,
        result: res.data,
      });
      continue;
    }
    if (res.rateLimited) {
      rateLimited = true;
      if (allowApprox) {
        out.push({
          id: d.id,
          label: d.label,
          reason: `${d.reason} (Näherung)`,
          result: approximateOutAndBack(start, d.to, profile, d.label),
        });
        while (out.length < limit) {
          const next = dests.find((x) => !out.some((o) => o.id === x.id));
          if (!next) break;
          out.push({
            id: next.id,
            label: next.label,
            reason: `${next.reason} (Näherung)`,
            result: approximateOutAndBack(
              start,
              next.to,
              profile,
              next.label
            ),
          });
        }
      }
      break;
    }
  }

  if (out.some((o) => o.result.engine !== "approx")) {
    quickCache.set(
      key,
      out.filter((o) => o.result.engine !== "approx")
    );
  }

  return {
    options: out.slice(0, limit),
    rateLimited,
    fromCache: existing.length > 0 && out.length === existing.length,
  };
}

export type ComputeLoopOptionsResult = {
  option: QuickOption | null;
  error?: "profile" | "ors" | "not_closed" | "fail";
  status?: number;
};

/**
 * OSM round-trip via POST /api/route/loop.
 * IDs never start with `quick-` (Rundkurs honesty treats those as pads).
 */
export async function computeLoopOptions(
  start: [number, number],
  profile: RoutingProfile,
  minutes: number,
  opts?: {
    seed?: number;
    lengthKm?: number;
    signal?: AbortSignal;
    lang?: string;
  }
): Promise<ComputeLoopOptionsResult> {
  if (!profileAllowsOsmRoundTrip(profile)) {
    return { option: null, error: "profile" };
  }
  const seed = opts?.seed && opts.seed >= 1 ? Math.floor(opts.seed) : 1;
  try {
    const res = await fetch("/api/route/loop", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({
        profile,
        from: start,
        minutes,
        seed,
        lang: opts?.lang,
        ...(typeof opts?.lengthKm === "number" && opts.lengthKm > 0
          ? { lengthKm: opts.lengthKm }
          : {}),
      }),
      signal: opts?.signal,
    });
    const text = await res.text();
    let data: ClientRouteResult & { error?: string } | null = null;
    try {
      data = text ? (JSON.parse(text) as ClientRouteResult & { error?: string }) : null;
    } catch {
      data = null;
    }
    if (!res.ok) {
      const code = data?.error;
      if (res.status === 422 || code === "not_closed") {
        return { option: null, error: "not_closed", status: res.status };
      }
      if (res.status === 503 || code === "ors_unconfigured") {
        return { option: null, error: "ors", status: res.status };
      }
      if (res.status === 400 || code === "profile_not_loopable") {
        return { option: null, error: "profile", status: res.status };
      }
      return { option: null, error: "fail", status: res.status };
    }
    if (!data?.geometry?.coordinates || data.geometry.coordinates.length < 4) {
      return { option: null, error: "fail", status: res.status };
    }
    return {
      option: {
        id: `around-you-${seed}`,
        label: "Rundkurs um dich · OSM-Wege",
        reason: (data.warnings ?? [])[0] ?? "",
        result: { ...data, loop: true, engine: data.engine || "openrouteservice" },
      },
    };
  } catch {
    return { option: null, error: "fail" };
  }
}

export async function computePointToPoint(
  draft: PlanDraft,
  opts?: { trails?: TrailSegment[] }
): Promise<ClientRouteResult | null> {
  const next = await resolvePointToPointDraft(draft, opts);
  return next?.computed ?? null;
}

/** Rider-facing one-liner: km · time, plus first honesty warning. No engine name. */
export function routeResultMessage(result: ClientRouteResult): string {
  const km = (result.distanceM / 1000).toFixed(1);
  const min = Math.round(result.durationS / 60);
  const head = `${km} km · ${min} min`;
  const rider = (result.warnings ?? []).find(
    (w) =>
      !w.startsWith("GraphHopper-Account") &&
      !w.includes("GRAPHHOPPER_ALLOW_EXTENDED") &&
      !w.startsWith("OpenRouteService Fallback") &&
      !w.startsWith("Live-Routing") &&
      !w.startsWith("Kein ROUTING_ENGINE") &&
      !w.startsWith("Öffentliches OSRM")
  );
  if (rider) return `${head} · ${rider}`;
  return head;
}

/** Adopt tour geometry as-is. Without geometry: empty result (pin-only UI). */
export function adoptTour(tour: BaseTour, profile: RoutingProfile): ClientRouteResult {
  if (!tour.geometry || tour.geometry.coordinates.length < 2) {
    const pin = tour.center ?? ([0, 0] as [number, number]);
    return {
      distanceM: (tour.distanceKm ?? 0) * 1000,
      durationS: (tour.durationMin ?? 0) * 60,
      geometry: { type: "LineString", coordinates: [pin] },
      engine: "tour-pin",
      profile,
      warnings: [
        "Kein Tour-Track — nur Ortspunkt. Ziel setzen oder Live-Routing/GPX.",
      ],
    };
  }
  const geometry = tour.geometry;
  const distanceM = (tour.distanceKm ?? 20) * 1000;
  const durationS = (tour.durationMin ?? 90) * 60;
  return {
    distanceM,
    durationS,
    geometry,
    engine: "tour-adopt",
    profile,
  };
}

export type SnapParts = {
  merged: ClientRouteResult;
  approach?: ClientRouteResult;
  tour: ClientRouteResult;
};

/**
 * Hybrid snap: route user → tour entry, then follow tour track.
 * Returns separate parts for map layers.
 */
export async function snapToTourParts(
  userStart: [number, number],
  tour: BaseTour,
  profile: RoutingProfile
): Promise<SnapParts | null> {
  if (!tour.geometry || tour.geometry.coordinates.length < 2) {
    const entry = (tour.center ?? null) as [number, number] | null;
    if (!entry) return null;
    const approach = await requestRoute(
      accessCostingForRideProfile(profile),
      userStart,
      entry,
      [],
      { accessLeg: true }
    );
    if (!approach) return null;
    return {
      merged: {
        ...approach,
        warnings: [
          ...(approach.warnings ?? []),
          "Anfahrt zum Ortspunkt — Tour-Track fehlt.",
        ],
      },
      approach,
      tour: {
        distanceM: 0,
        durationS: 0,
        geometry: { type: "LineString", coordinates: [entry] },
        engine: "tour-pin",
        profile,
        warnings: ["Kein Tour-Track"],
      },
    };
  }
  const tourGeom = tour.geometry;
  const entry = tourGeom.coordinates[0] as [number, number];
  if (!entry) return null;

  const approach = await requestRoute(
    accessCostingForRideProfile(profile),
    userStart,
    entry,
    [],
    { accessLeg: true }
  );
  const tourPart: ClientRouteResult = {
    distanceM: (tour.distanceKm ?? 20) * 1000,
    durationS: (tour.durationMin ?? 90) * 60,
    geometry: tourGeom,
    engine: "tour-track",
    profile,
    warnings: tour.geometry
      ? undefined
      : ["Tour-Track genähert — Partner-Geometrie folgt später."],
  };

  if (!approach) {
    return {
      merged: {
        ...tourPart,
        warnings: [
          ...(tourPart.warnings ?? []),
          "Anschluss zur Tour konnte nicht geroutet werden — nur Tour-Track.",
        ],
      },
      tour: tourPart,
    };
  }

  return {
    merged: mergeRouteResults(
      [approach, tourPart],
      profile,
      ["Hybrid: Position → Tour-Einstieg, dann Tour-Track"]
    ),
    approach,
    tour: tourPart,
  };
}

export async function snapToTour(
  userStart: [number, number],
  tour: BaseTour,
  profile: RoutingProfile
): Promise<ClientRouteResult | null> {
  const parts = await snapToTourParts(userStart, tour, profile);
  return parts?.merged ?? null;
}

export type AttachTrailMode = "append" | "via_chain";

export { lineLengthM } from "@/lib/routing/routeProgress";

function trailNavSteps(
  name: string,
  coords: [number, number][],
  distanceM: number
): NavStep[] {
  const start = coords[0];
  const end = coords[coords.length - 1];
  if (!start || !end) return [];
  return [
    {
      id: "trail-start",
      type: "start",
      instruction: `Trail ${name}`,
      instructionEn: `Trail ${name}`,
      distanceAlongM: 0,
      lengthM: distanceM,
      coordinate: { lng: start[0], lat: start[1] },
    },
    {
      id: "trail-end",
      type: "arrive",
      instruction: `Ende ${name}`,
      instructionEn: `End ${name}`,
      distanceAlongM: distanceM,
      lengthM: 0,
      coordinate: { lng: end[0], lat: end[1] },
    },
  ];
}

function trailEnginePart(
  name: string,
  geometry: GeoJSON.LineString,
  profile: RoutingProfile
): ClientRouteResult {
  const coords = (geometry.coordinates ?? []) as [number, number][];
  const distanceM = Math.max(1, Math.round(lineLengthM(coords)));
  const speedKmh = isRideProfileId(profile)
    ? getProfile(profile).defaultSpeedKmh
    : 16;
  const durationS = Math.max(1, Math.round((distanceM / 1000 / speedKmh) * 3600));
  return {
    distanceM,
    durationS,
    geometry,
    engine: "osm-trail",
    profile,
    steps: trailNavSteps(name, coords, distanceM),
    warnings: [`Trail „${name}“ liegt auf der Route.`],
  };
}

export type AttachTrailOpts = {
  accessProfile?: RoutingProfile;
  orientDownhill?: boolean;
  startElevM?: number | null;
  endElevM?: number | null;
};

/**
 * Connect a trail segment into the current draft.
 * Both modes keep OSM trail geometry in the nav line — GraphHopper `bike`
 * often routes around path/track between three vias.
 * - append: approach → trail → optional continue
 * - via_chain: same line, plus trail entry/mid/exit as draft waypoints
 */
export async function attachTrailToDraft(
  draft: PlanDraft,
  segment: {
    id: string;
    name: string;
    geometry: GeoJSON.LineString;
  },
  mode: AttachTrailMode,
  userStart?: [number, number] | null,
  opts?: AttachTrailOpts
): Promise<PlanDraft | null> {
  const raw = (segment.geometry.coordinates ?? []) as [number, number][];
  if (raw.length < 2) return null;
  const origin = userStart ?? startOf(draft) ?? raw[0];
  const oriented = orientTrail({
    geometry: raw,
    fromLng: origin[0],
    fromLat: origin[1],
    startElevM: opts?.startElevM,
    endElevM: opts?.endElevM,
    preferDownhill: opts?.orientDownhill === true,
  });
  const coords = oriented.geometry;
  const entry = oriented.entry;
  const exit = oriented.exit;
  const mid = coords[Math.floor(coords.length / 2)];
  const trailGeom: GeoJSON.LineString = {
    type: "LineString",
    coordinates: coords,
  };
  const profile = draft.profile;
  const access = opts?.accessProfile ?? accessCostingForRideProfile(profile);
  const gravityAccess = access === "auto" || access === "hiking";

  const approach = await requestRoute(access, origin, entry, [], {
    accessLeg: true,
  });
  const trailPart = trailEnginePart(segment.name, trailGeom, profile);

  const parts: ClientRouteResult[] = [];
  if (approach) parts.push(approach);
  parts.push(trailPart);

  const end = endOf(draft);
  if (
    !gravityAccess &&
    end &&
    (end[0] !== exit[0] || end[1] !== exit[1])
  ) {
    const continuePart = await requestRoute(profile, exit, end);
    if (continuePart) parts.push(continuePart);
  }

  const merged = mergeRouteResults(parts, profile, [
    `Trail in der Navi: ${segment.name}`,
    ...(oriented.usedElevation ? ["Einstieg oben (Höhe)"] : []),
  ]);

  let next = setStart(
    end && !gravityAccess ? draft : setEnd(draft, exit, "Trail-Ende"),
    origin,
    "Hier"
  );

  if (mode === "via_chain") {
    next = {
      ...next,
      waypoints: next.waypoints.filter((w) => w.role !== "via"),
    };
    next = addVia(next, entry, `${segment.name} Einstieg`);
    next = addVia(next, mid, `${segment.name} Mitte`);
    next = addVia(next, exit, `${segment.name} Ausstieg`);
    if (!endOf(next)) next = setEnd(next, exit, "Ziel");
  }

  return {
    ...next,
    mode: "hybrid",
    hybrid: { strategy: "snap" },
    computed: merged,
    label:
      mode === "via_chain"
        ? `${segment.name} (in Navi)`
        : `${segment.name} (angehängt)`,
    attachedTrailId: segment.id,
    layers: {
      approach: approach?.geometry,
      trail: trailGeom,
    },
  };
}

/** Gravity „Ich bin am Start“: OSM-Trail ohne Anfahrt. */
export function adoptTrailToDraft(
  draft: PlanDraft,
  segment: {
    id: string;
    name: string;
    geometry: GeoJSON.LineString;
  },
  userStart?: [number, number] | null,
  opts?: AttachTrailOpts
): PlanDraft | null {
  const raw = (segment.geometry.coordinates ?? []) as [number, number][];
  if (raw.length < 2) return null;
  const origin = userStart ?? startOf(draft) ?? raw[0];
  const oriented = orientTrail({
    geometry: raw,
    fromLng: origin[0],
    fromLat: origin[1],
    startElevM: opts?.startElevM,
    endElevM: opts?.endElevM,
    preferDownhill: opts?.orientDownhill === true,
  });
  const trailGeom: GeoJSON.LineString = {
    type: "LineString",
    coordinates: oriented.geometry,
  };
  const trailPart = trailEnginePart(segment.name, trailGeom, draft.profile);
  return {
    ...setEnd(setStart(draft, oriented.entry, "Trail-Start"), oriented.exit, "Trail-Ende"),
    mode: "hybrid",
    hybrid: { strategy: "adopt" },
    computed: trailPart,
    label: segment.name,
    attachedTrailId: segment.id,
    layers: { trail: trailGeom },
  };
}

/**
 * A–B routing that keeps an attached trail or auto-snaps a nearby
 * OSM trail/cycleway the engine skipped.
 */
export async function resolvePointToPointDraft(
  draft: PlanDraft,
  opts?: { trails?: TrailSegment[]; origin?: [number, number] | null }
): Promise<PlanDraft | null> {
  const from = startOf(draft);
  const to = endOf(draft);
  if (!from || !to) return null;
  const origin = opts?.origin ?? from;

  if (draft.attachedTrailId && draft.layers?.trail) {
    const stitched = await attachTrailToDraft(
      { ...draft, profile: draft.profile },
      {
        id: draft.attachedTrailId,
        name:
          draft.label?.replace(/\s*\([^)]*\)\s*$/, "").trim() || "Trail",
        geometry: draft.layers.trail,
      },
      draft.waypoints.some((w) => w.role === "via") ? "via_chain" : "append",
      origin
    );
    return stitched;
  }

  const costing = accessCostingForRideProfile(draft.profile);
  const engine = await requestRoute(
    costing,
    from,
    to,
    viasOf(draft),
    {
      accessLeg: costing === "auto",
      variant: draft.variant,
    }
  );
  if (!engine) return null;

  const coords = (engine.geometry?.coordinates ?? []) as [number, number][];
  const originPt = opts?.origin ?? from;
  const startIsGps =
    haversineM(from[1], from[0], originPt[1], originPt[0]) < 40;
  const snap = applyFarmTrimPinSnap({
    start: from,
    end: to,
    line: coords,
    warnings: engine.warnings,
    startIsGps,
  });
  let waypoints = draft.waypoints;
  if (snap.snappedStart || snap.snappedEnd) {
    waypoints = waypoints.map((w) => {
      if (w.role === "start" && snap.snappedStart) {
        return { ...w, lngLat: snap.start, label: undefined };
      }
      if (w.role === "end" && snap.snappedEnd) {
        return { ...w, lngLat: snap.end, label: undefined };
      }
      return w;
    });
  }

  // Pin A–B: keep the engine streets. Do not fish OSM last-mile
  // onto a nearby path (that cuts through fields).
  return {
    ...draft,
    waypoints,
    mode: "point_to_point",
    computed: engine,
    layers: undefined,
  };
}

export function geometryFromTourCenter(
  id: string,
  center: [number, number] | undefined,
  distanceKm: number
): GeoJSON.LineString | null {
  if (!allowDemoContent()) return null;
  if (!center) return buildDemoGeometry(id, distanceKm);
  return buildDemoGeometryAround(center, distanceKm, id);
}

function buildDemoGeometryAround(
  center: [number, number],
  distanceKm: number,
  seedId: string
): GeoJSON.LineString {
  let h = 0;
  for (let i = 0; i < seedId.length; i++) h = (h * 31 + seedId.charCodeAt(i)) | 0;
  h = Math.abs(h);
  const halfLng = 0.01 + (distanceKm / 180) * 0.035 + (h % 5) * 0.0008;
  const halfLat = halfLng * 0.7;
  const [lng, lat] = center;
  const corners: [number, number][] = [
    [lng - halfLng, lat - halfLat],
    [lng + halfLng, lat - halfLat],
    [lng + halfLng, lat + halfLat],
    [lng - halfLng, lat + halfLat],
  ];
  const coordinates: [number, number][] = [];
  for (let c = 0; c < 4; c++) {
    const a = corners[c];
    const b = corners[(c + 1) % 4];
    for (let i = 0; i < 16; i++) {
      const t = i / 16;
      coordinates.push([
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
      ]);
    }
  }
  coordinates.push(coordinates[0]);
  return { type: "LineString", coordinates };
}
