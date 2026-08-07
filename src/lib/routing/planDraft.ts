/**
 * Discover PlanDraft — einheitliches Modell für Schnell / A–B / Tour / Hybrid.
 */

import type { ClientRouteResult, RoutingProfile } from "@/lib/routing/profiles";
import { requestRoute } from "@/lib/routing/profiles";
import { buildDemoGeometry } from "@/lib/routing/demoGeometry";
import type { NavStep } from "@/lib/routing/navSteps";

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

export type QuickOption = {
  id: string;
  label: string;
  reason: string;
  result: ClientRouteResult;
};

/** Compute up to 3 quick A→B options from start (engine). */
export async function computeQuickOptions(
  start: [number, number],
  profile: RoutingProfile,
  minutes: number
): Promise<QuickOption[]> {
  const dests = quickDestinations(start, minutes);
  const out: QuickOption[] = [];
  for (const d of dests) {
    const result = await requestRoute(profile, start, d.to);
    if (result) {
      out.push({
        id: d.id,
        label: d.label,
        reason: d.reason,
        result,
      });
    }
  }
  return out;
}

export async function computePointToPoint(
  draft: PlanDraft
): Promise<ClientRouteResult | null> {
  const from = startOf(draft);
  const to = endOf(draft);
  if (!from || !to) return null;
  return requestRoute(draft.profile, from, to);
}

/** Adopt tour geometry as-is (demo line if missing). */
export function adoptTour(tour: BaseTour, profile: RoutingProfile): ClientRouteResult {
  const geometry =
    tour.geometry ??
    buildDemoGeometry(tour.id, tour.distanceKm ?? 20);
  const distanceM = (tour.distanceKm ?? 20) * 1000;
  const durationS = (tour.durationMin ?? 90) * 60;
  return {
    distanceM,
    durationS,
    geometry,
    engine: "tour-adopt",
    profile,
    warnings: tour.geometry
      ? undefined
      : ["Tour-Geometrie genähert (Demo) — kein Partner-Track-Mirror."],
  };
}

/**
 * Hybrid snap: route user → tour entry, then follow tour track.
 */
export async function snapToTour(
  userStart: [number, number],
  tour: BaseTour,
  profile: RoutingProfile
): Promise<ClientRouteResult | null> {
  const tourGeom =
    tour.geometry ??
    buildDemoGeometry(tour.id, tour.distanceKm ?? 20);
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
      ...tourPart,
      warnings: [
        ...(tourPart.warnings ?? []),
        "Anschluss zur Tour konnte nicht geroutet werden — nur Tour-Track.",
      ],
    };
  }

  return mergeRouteResults(
    [approach, tourPart],
    profile,
    ["Hybrid: Position → Tour-Einstieg, dann Tour-Track"]
  );
}

export function geometryFromTourCenter(
  id: string,
  center: [number, number] | undefined,
  distanceKm: number
): GeoJSON.LineString {
  if (!center) return buildDemoGeometry(id, distanceKm);
  // Temporarily use buildDemoGeometry which looks up BASE by id;
  // for OA tours, synthesize around center via a unique id hash path:
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
