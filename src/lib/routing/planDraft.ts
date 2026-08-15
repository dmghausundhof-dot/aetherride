/**
 * Discover PlanDraft — einheitliches Modell für Schnell / A–B / Tour / Hybrid.
 */

import type { ClientRouteResult, RoutingProfile } from "@/lib/routing/profiles";
import { requestRoute, requestRouteDetailed } from "@/lib/routing/profiles";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { buildDemoGeometry } from "@/lib/routing/demoGeometry";
import type { NavStep } from "@/lib/routing/navSteps";

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

export function setStart(
  draft: PlanDraft,
  lngLat: [number, number],
  label = "Start"
): PlanDraft {
  const rest = draft.waypoints.filter((w) => w.role !== "start");
  return {
    ...draft,
    waypoints: [{ id: "start", role: "start", lngLat, label }, ...rest],
    computed: null,
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
    waypoints: [...rest, { id: "end", role: "end", lngLat, label }],
    computed: null,
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
    waypoints: [...start, ...vias, via, ...end],
    computed: null,
  };
}

export function removeWaypoint(draft: PlanDraft, id: string): PlanDraft {
  return {
    ...draft,
    waypoints: draft.waypoints.filter((w) => w.id !== id),
    computed: null,
  };
}

export function orderedWaypoints(draft: PlanDraft): PlanWaypoint[] {
  const start = draft.waypoints.filter((w) => w.role === "start");
  const vias = draft.waypoints.filter((w) => w.role === "via");
  const end = draft.waypoints.filter((w) => w.role === "end");
  return [...start, ...vias, ...end];
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

export async function computePointToPoint(
  draft: PlanDraft
): Promise<ClientRouteResult | null> {
  const from = startOf(draft);
  const to = endOf(draft);
  if (!from || !to) return null;
  return requestRoute(draft.profile, from, to, viasOf(draft));
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
    const approach = await requestRoute(profile, userStart, entry);
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

  const approach = await requestRoute(profile, userStart, entry);
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

/**
 * Connect a trail segment into the current draft.
 * - append: approach → trail geometry (+ optional continue to end)
 * - via_chain: trail entry/mid/exit as vias, engine re-routes
 */
export async function attachTrailToDraft(
  draft: PlanDraft,
  segment: {
    id: string;
    name: string;
    geometry: GeoJSON.LineString;
  },
  mode: AttachTrailMode,
  userStart?: [number, number] | null
): Promise<PlanDraft | null> {
  const coords = (segment.geometry.coordinates ?? []) as [number, number][];
  if (coords.length < 2) return null;
  const entry = coords[0];
  const exit = coords[coords.length - 1];
  const mid = coords[Math.floor(coords.length / 2)];
  const origin = userStart ?? startOf(draft) ?? entry;
  const profile = draft.profile;

  if (mode === "via_chain") {
    let next = setStart(draft, origin, "Start");
    next = {
      ...next,
      waypoints: next.waypoints.filter((w) => w.role !== "via"),
    };
    next = addVia(next, entry, `${segment.name} Einstieg`);
    next = addVia(next, mid, `${segment.name} Mitte`);
    next = addVia(next, exit, `${segment.name} Ausstieg`);
    if (!endOf(next)) next = setEnd(next, exit, "Ziel");
    const computed = await computePointToPoint(next);
    return {
      ...next,
      mode: "hybrid",
      hybrid: { strategy: "replan" },
      computed,
      label: `${segment.name} (Via)`,
      attachedTrailId: segment.id,
      layers: { trail: segment.geometry },
    };
  }

  // append
  const approach = await requestRoute(profile, origin, entry);
  const trailDist =
    Math.hypot(exit[0] - entry[0], exit[1] - entry[1]) * 111_000 * 1.4;
  const trailPart: ClientRouteResult = {
    distanceM: Math.round(trailDist),
    durationS: Math.round(trailDist / 4),
    geometry: segment.geometry,
    engine: "trail-seed",
    profile,
    warnings: [`Trail „${segment.name}“ eingefügt (Seed-Geometrie).`],
  };

  const parts: ClientRouteResult[] = [];
  if (approach) parts.push(approach);
  parts.push(trailPart);

  const end = endOf(draft);
  if (end && (end[0] !== exit[0] || end[1] !== exit[1])) {
    const continuePart = await requestRoute(profile, exit, end);
    if (continuePart) parts.push(continuePart);
  }

  const merged = mergeRouteResults(parts, profile, [
    `Trail angehängt: ${segment.name}`,
  ]);

  return {
    ...setStart(
      end ? draft : setEnd(draft, exit, "Trail-Ende"),
      origin,
      "Hier"
    ),
    mode: "hybrid",
    hybrid: { strategy: "snap" },
    computed: merged,
    label: `${segment.name} (angehängt)`,
    attachedTrailId: segment.id,
    layers: {
      approach: approach?.geometry,
      trail: segment.geometry,
    },
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
