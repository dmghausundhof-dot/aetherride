/**
 * Server-side routing: OpenRouteService, GraphHopper, Valhalla, OSRM.
 * Spec F-NAV-001 — sportartspezifische Profile.
 * Spec F-NAV-003 — Maneuver/Steps in RouteResult.
 */

import {
  buildValhallaCosting,
  getProfile,
  graphhopperCustomModel,
  isRideProfileId,
  type RoutingProfile,
  type ValhallaCosting,
} from "@/lib/routing/profiles";
import {
  cityCyclewaySnapWanted,
  detailShares,
  graphhopperSurfaceWarnings,
  type GhDetailRange,
} from "@/lib/routing/graphhopperHints";
import {
  stepsFromDemoGeometry,
  stepsFromOsrmLegs,
  stepsFromValhallaLeg,
  type NavStep,
} from "@/lib/routing/navSteps";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { showRoutingDebugUi } from "@/lib/routing/routingStatus";
import { chromeLangFrom, valhallaLanguage, type ChromeLang } from "@/lib/i18n/chromeLang";
import {
  fetchOrsRoute,
  isOrsConfigured,
  orsPreferredForGraphhopperBasic,
  orsProfileFor,
  type OrsExtras,
} from "@/lib/routing/openRouteService";
import {
  clampBbox,
  fetchOsmTrailsNear,
  type OsmTrail,
} from "@/lib/coverage/osmLive";
import { osmTrailToSegment } from "@/lib/routing/overlayHit";
import {
  applyCorridorCyclewaySnap,
  applyCorridorTrailSnap,
  profileWantsCorridorCycleways,
  profileWantsCorridorTrails,
} from "@/lib/routing/snapTrailCorridor";
import type { TrailSegment } from "@/lib/routing/trailSegments";
import {
  applyRouteVariant,
  parseRouteVariant,
  VARIANT_VALHALLA_ONLY,
  variantNeedsValhalla,
  type RouteVariant,
} from "@/lib/routing/routeVariant";

export type RoutingEngineKind =
  | "valhalla"
  | "osrm"
  | "graphhopper"
  | "openrouteservice"
  | "demo"
  | "editorial";

/** Live DACH engines the rider can pick. Offline Valhalla/OSRM stay fallbacks. */
export type SelectableRoutingEngine = "graphhopper" | "openrouteservice";

export const SELECTABLE_ROUTING_ENGINES: SelectableRoutingEngine[] = [
  "graphhopper",
  "openrouteservice",
];

export type ComputeRouteOptions = {
  /** Per-request picker. Does not rewrite costing (auto stays car / driving-car). */
  engine?: string | null;
  /**
   * Gravity/access legs (GPS→trailhead). Skip OSM trail/cycleway splice so
   * a walk/drive does not become the DH trail.
   */
  accessLeg?: boolean;
  /** planned | flatter | unpaved — Valhalla costing only. */
  variant?: string | null;
};

export type ResolvedRouteEngine = {
  kind: RoutingEngineKind;
  requested?: RoutingEngineKind;
  fallback: boolean;
};

export type RouteResult = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  engine: RoutingEngineKind;
  profile: RoutingProfile;
  warnings?: string[];
  /** F-NAV-003 Turn-by-Turn */
  steps?: NavStep[];
  /** OpenRouteService extra_info (surface/steepness) — honesty, not S-scale */
  orsExtras?: OrsExtras;
  /** GraphHopper road_class vertex shares — snap gate, not shown in UI. */
  roadClassShares?: Record<string, number>;
  /** Costing variant. Absent = planned. */
  variant?: RouteVariant;
  variantApplied?: boolean;
};

/** Öffentlicher OSRM (nur mit explizitem Opt-in oder Dev-Fallback) */
export const PUBLIC_OSRM_URL = "https://router.project-osrm.org";

function publicOsrmAllowed(): boolean {
  if (process.env.ALLOW_PUBLIC_OSRM === "1" || process.env.ALLOW_PUBLIC_OSRM === "true") {
    return true;
  }
  // Dev: ohne Keys ehrliches Live-Routing statt nur Dreieck-Demo
  if (
    process.env.NODE_ENV !== "production" &&
    process.env.ALLOW_PUBLIC_OSRM !== "false"
  ) {
    return true;
  }
  return false;
}

function engine(): RoutingEngineKind {
  // editorial never selected as engine backend
  const e = (process.env.ROUTING_ENGINE || "").toLowerCase();
  if (e === "openrouteservice" || e === "ors") return "openrouteservice";
  if (e === "valhalla" || e === "osrm" || e === "graphhopper") return e;
  // Both keys + no explicit engine: GraphHopper stays primary; ORS hybrid
  // via engineForProfile (gravel/mtb/enduro). Set ROUTING_ENGINE=openrouteservice
  // to use ORS for every DACH profile.
  if (process.env.GRAPHHOPPER_API_KEY) return "graphhopper";
  if (isOrsConfigured()) return "openrouteservice";
  if (process.env.VALHALLA_URL) return "valhalla";
  if (process.env.OSRM_URL) return "osrm";
  if (publicOsrmAllowed()) return "osrm";
  return "demo";
}

/**
 * Hybrid default (no picker). Explicit ROUTING_ENGINE wins.
 * If GraphHopper is primary but Basic (no extended profiles) and ORS is
 * configured, mtb/gravel/enduro go to OpenRouteService — that is the DACH
 * cycling engine GraphHopper Basic cannot express.
 * Costing stays on `profile`; this never maps auto→bike.
 */
function engineForProfile(profile: RoutingProfile): RoutingEngineKind {
  if (profile === "auto") {
    const primary = engine();
    if (primary === "graphhopper") return "graphhopper";
    if (primary === "osrm") return "osrm";
    if (primary === "valhalla") return "valhalla";
    if (isOrsConfigured()) return "openrouteservice";
    return primary;
  }
  const primary = engine();
  const explicit = (process.env.ROUTING_ENGINE || "").toLowerCase();
  if (explicit === "openrouteservice" || explicit === "ors") {
    return "openrouteservice";
  }
  if (
    primary === "graphhopper" &&
    isOrsConfigured() &&
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES !== "1" &&
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES !== "true" &&
    orsPreferredForGraphhopperBasic(profile)
  ) {
    return "openrouteservice";
  }
  return primary;
}

export function parseRoutingEngineParam(
  raw: string | null | undefined
): RoutingEngineKind | undefined {
  if (!raw) return undefined;
  const e = raw.trim().toLowerCase();
  if (e === "graphhopper" || e === "gh") return "graphhopper";
  if (e === "openrouteservice" || e === "ors") return "openrouteservice";
  if (e === "valhalla") return "valhalla";
  if (e === "osrm") return "osrm";
  return undefined;
}

export function engineIsConfigured(kind: RoutingEngineKind): boolean {
  switch (kind) {
    case "graphhopper":
      return Boolean(process.env.GRAPHHOPPER_API_KEY?.trim());
    case "openrouteservice":
      return isOrsConfigured();
    case "valhalla":
      return Boolean(process.env.VALHALLA_URL?.trim());
    case "osrm":
      return Boolean(process.env.OSRM_URL?.trim()) || publicOsrmAllowed();
    default:
      return false;
  }
}

/**
 * Picker wins over hybrid. Unconfigured pick falls back instead of
 * silently rewriting auto→bike or gravity approach→downhill bicycle.
 */
export function resolveRouteEngine(
  profile: RoutingProfile,
  explicit?: RoutingEngineKind
): ResolvedRouteEngine {
  if (explicit && explicit !== "demo" && explicit !== "editorial") {
    if (engineIsConfigured(explicit)) {
      return { kind: explicit, requested: explicit, fallback: false };
    }
    return {
      kind: engineForProfile(profile),
      requested: explicit,
      fallback: true,
    };
  }
  return { kind: engineForProfile(profile), fallback: false };
}

function baseUrl(kind: "valhalla" | "osrm"): string | null {
  if (kind === "valhalla") {
    return (process.env.VALHALLA_URL || "").replace(/\/$/, "") || null;
  }
  const custom = (process.env.OSRM_URL || "").replace(/\/$/, "");
  if (custom) return custom;
  if (publicOsrmAllowed()) return PUBLIC_OSRM_URL;
  return null;
}

/** true wenn OSRM ohne eigenen Key (project-osrm) */
export function isUsingPublicOsrm(): boolean {
  return engine() === "osrm" && !process.env.OSRM_URL?.trim() && publicOsrmAllowed();
}

/** Valhalla costing — RideProfile SSOT in `profiles.ts` (urban bleibt Legacy). */
export function valhallaCosting(profile: RoutingProfile): ValhallaCosting {
  if (profile === "auto") {
    return {
      costing: "auto",
      costing_options: { auto: { use_highways: 1, use_tolls: 0.5 } },
    };
  }
  if (profile === "urban") {
    return {
      costing: "bicycle",
      costing_options: {
        bicycle: {
          bicycle_type: "hybrid",
          use_roads: 0.35,
          use_hills: 0.15,
          avoid_bad_surfaces: 0.7,
        },
      },
    };
  }
  return buildValhallaCosting(profile);
}

/** OSRM profile name */
export function osrmProfile(profile: RoutingProfile): string {
  if (profile === "hiking") return "foot";
  if (profile === "auto") return "driving";
  return "bike";
}

/**
 * GraphHopper Cloud profile.
 * Free/basic plans often only allow car|bike|foot — mtb/hike/racingbike need higher tier.
 * Override with GRAPHHOPPER_ALLOW_EXTENDED_PROFILES=1 when the account supports them.
 */
export function graphhopperProfile(profile: RoutingProfile): string {
  const extended =
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES === "1" ||
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES === "true";
  if (extended) {
    switch (profile) {
      case "hiking":
        return "hike";
      case "road":
        return "racingbike";
      case "mtb_allmountain":
      case "mtb_enduro":
      case "downhill":
      case "emtb":
        return "mtb";
      case "gravel":
      case "ebike":
      case "urban":
      case "auto":
        return profile === "auto" ? "car" : "bike";
      default:
        return "bike";
    }
  }
  if (profile === "auto") return "car";
  return profile === "hiking" ? "foot" : "bike";
}

/**
 * Native costing name for a sport/access profile on one engine.
 * Profile (what) is chosen first; engine (who) only translates it.
 */
export function nativeCostingFor(
  profile: RoutingProfile,
  engineKind: RoutingEngineKind
): string {
  switch (engineKind) {
    case "graphhopper":
      return graphhopperProfile(profile);
    case "openrouteservice":
      return orsProfileFor(profile);
    case "valhalla":
      return valhallaCosting(profile).costing;
    case "osrm":
      return osrmProfile(profile);
    default:
      return profile;
  }
}

function graphhopperCustomModelAllowed(): boolean {
  const v = process.env.GRAPHHOPPER_ALLOW_CUSTOM_MODEL;
  return v === "1" || v === "true";
}

function decodePolyline6(str: string): [number, number][] {
  let index = 0;
  let lat = 0;
  let lng = 0;
  const coordinates: [number, number][] = [];
  while (index < str.length) {
    let b: number;
    let shift = 0;
    let result = 0;
    do {
      b = str.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = str.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += dlng;
    coordinates.push([lng / 1e6, lat / 1e6]);
  }
  return coordinates;
}

function demoRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): RouteResult {
  const [flng, flat] = from;
  const [tlng, tlat] = to;
  const mid: [number, number] = [
    (flng + tlng) / 2 + 0.01,
    (flat + tlat) / 2 - 0.005,
  ];
  const coords: [number, number][] = [from, mid, to];
  const dist =
    Math.hypot(tlng - flng, tlat - flat) * 111_000 * 1.15;
  const speedMps = profile === "auto"
    ? 13.9
    : isRideProfileId(profile)
    ? getProfile(profile).defaultSpeedKmh / 3.6
    : 5.0;
  return {
    distanceM: Math.round(dist),
    durationS: Math.round(dist / speedMps),
    geometry: { type: "LineString", coordinates: coords },
    engine: "demo",
    profile,
    steps: stepsFromDemoGeometry(coords),
    warnings: [
      "Kein ROUTING_ENGINE konfiguriert — Demo-Geometrie. Setze OPENROUTESERVICE_API_KEY, GRAPHHOPPER_API_KEY, VALHALLA_URL oder OSRM_URL.",
    ],
  };
}

async function routeValhalla(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number],
  lang: ChromeLang = "de",
  variant: RouteVariant = "planned"
): Promise<RouteResult> {
  const base = baseUrl("valhalla");
  if (!base) throw new Error("VALHALLA_URL missing");
  const { costing, costing_options } = applyRouteVariant(
    valhallaCosting(profile),
    variant
  );
  const body = {
    locations: [
      { lon: from[0], lat: from[1] },
      { lon: to[0], lat: to[1] },
    ],
    costing,
    costing_options,
    directions_options: { units: "kilometers", language: valhallaLanguage(lang) },
  };
  const stadiaKey = process.env.STADIA_API_KEY?.trim();
  const routeUrl =
    stadiaKey && /stadiamaps\.com/i.test(base)
      ? `${base}/route/v1?api_key=${encodeURIComponent(stadiaKey)}`
      : `${base}/route`;
  const res = await fetch(routeUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`Valhalla ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const trip = data.trip;
  const leg = trip?.legs?.[0];
  const shape = leg?.shape || trip?.shape;
  if (!shape) throw new Error("Valhalla: no shape");
  const coordinates = decodePolyline6(shape);
  const maneuvers = Array.isArray(leg?.maneuvers) ? leg.maneuvers : [];
  const steps = stepsFromValhallaLeg(maneuvers, coordinates, true);
  return {
    distanceM: Math.round((trip.summary?.length || 0) * 1000),
    durationS: Math.round(trip.summary?.time || 0),
    geometry: { type: "LineString", coordinates },
    engine: "valhalla",
    profile,
    steps: steps.length ? steps : stepsFromDemoGeometry(coordinates),
    variant,
    variantApplied: variant !== "planned",
  };
}

function stepsFromGraphhopper(
  instructions: Array<{
    text?: string;
    street_name?: string;
    streetName?: string;
    distance?: number;
    time?: number;
    interval?: [number, number];
    sign?: number;
  }>,
  coordinates: [number, number][]
): NavStep[] {
  let along = 0;
  const steps: NavStep[] = [];
  for (let i = 0; i < instructions.length; i++) {
    const ins = instructions[i];
    const lengthM = Math.round(ins.distance ?? 0);
    const idx = ins.interval?.[0] ?? 0;
    const coord = coordinates[Math.min(idx, coordinates.length - 1)];
    const sign = ins.sign ?? 0;
    let type: NavStep["type"] = "turn";
    if (sign === 0) type = "continue";
    else if (sign === 4 || sign === 5) type = "arrive";
    else if (sign === 6) type = "roundabout";
    else if (Math.abs(sign) === 3) type = "uturn";
    else if (i === 0) type = "start";
    const text = ins.text || "Weiter";
    const streetRaw = (ins.street_name || ins.streetName || "").trim();
    const fromText = text.match(/\b(?:auf|onto)\s+(.+?)\.?$/i)?.[1]?.trim();
    const street = streetRaw || fromText || undefined;
    steps.push({
      id: `gh-${i}`,
      type,
      instruction: text,
      instructionEn: text,
      distanceAlongM: along,
      lengthM,
      coordinate: coord
        ? { lng: coord[0], lat: coord[1] }
        : undefined,
      engineType: sign,
      streetName: street,
    });
    along += lengthM;
  }
  return steps;
}

async function routeGraphhopper(
  profile: RoutingProfile,
  points: [number, number][],
  lang: ChromeLang = "de"
): Promise<RouteResult> {
  const key = process.env.GRAPHHOPPER_API_KEY?.trim();
  if (!key) throw new Error("GRAPHHOPPER_API_KEY missing");
  if (points.length < 2) throw new Error("GraphHopper: need ≥2 points");
  const base = (
    process.env.GRAPHHOPPER_URL || "https://graphhopper.com/api/1"
  ).replace(/\/$/, "");
  const ghProfile = graphhopperProfile(profile);
  const custom = graphhopperCustomModelAllowed()
    ? graphhopperCustomModel(profile)
    : null;

  let data: {
    paths?: Array<{
      distance?: number;
      time?: number;
      points?: { coordinates?: number[][] };
      instructions?: Array<{
        text?: string;
        street_name?: string;
        streetName?: string;
        distance?: number;
        time?: number;
        interval?: [number, number];
        sign?: number;
      }>;
      details?: {
        road_class?: GhDetailRange[];
        surface?: GhDetailRange[];
      };
    }>;
    message?: string;
  };

  if (custom) {
    const res = await fetch(`${base}/route?key=${encodeURIComponent(key)}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        profile: ghProfile,
        points,
        locale: lang,
        points_encoded: false,
        elevation: true,
        instructions: true,
        details: ["road_class", "surface"],
        pass_through: points.length > 2,
        "ch.disable": true,
        custom_model: custom,
      }),
    });
    data = await res.json();
    if (!res.ok || data.message) {
      // Paid-flag set on a free account → fall back to standard bike routing.
      data = await fetchGraphhopperGet(
        base,
        key,
        ghProfile,
        points,
        lang
      );
    }
  } else {
    data = await fetchGraphhopperGet(base, key, ghProfile, points, lang);
  }

  const path = data.paths?.[0];
  if (!path?.points?.coordinates) {
    throw new Error(
      data.message
        ? `GraphHopper: ${data.message}`
        : "GraphHopper: no path"
    );
  }

  const coordinates = (path.points.coordinates as number[][]).map(
    (c) => [c[0], c[1]] as [number, number]
  );
  const geometry: GeoJSON.LineString = {
    type: "LineString",
    coordinates,
  };
  const instructions = Array.isArray(path.instructions)
    ? path.instructions
    : [];
  const steps = stepsFromGraphhopper(instructions, coordinates);
  const warnings: string[] = [];
  if (
    showRoutingDebugUi() &&
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES !== "1" &&
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES !== "true" &&
    (profile.startsWith("mtb") ||
      profile === "downhill" ||
      profile === "emtb" ||
      profile === "hiking")
  ) {
    warnings.push(
      `GraphHopper-Account: Profil „${ghProfile}“ (Basic). Für mtb/hike GRAPHHOPPER_ALLOW_EXTENDED_PROFILES=1 nach Plan-Upgrade.`
    );
  }
  const roadClassShares = detailShares(path.details?.road_class);
  warnings.push(...graphhopperSurfaceWarnings(profile, roadClassShares));

  return {
    distanceM: Math.round(path.distance || 0),
    durationS: Math.round((path.time || 0) / 1000),
    geometry,
    engine: "graphhopper",
    profile,
    steps: steps.length ? steps : stepsFromDemoGeometry(coordinates),
    warnings: warnings.length ? warnings : undefined,
    roadClassShares:
      Object.keys(roadClassShares).length > 0 ? roadClassShares : undefined,
  };
}

async function fetchGraphhopperGet(
  base: string,
  key: string,
  ghProfile: string,
  points: [number, number][],
  lang: ChromeLang
) {
  const params = new URLSearchParams();
  for (const [lng, lat] of points) {
    params.append("point", `${lat},${lng}`);
  }
  params.set("profile", ghProfile);
  params.set("locale", lang);
  params.set("points_encoded", "false");
  params.set("elevation", "true");
  params.set("instructions", "true");
  params.append("details", "road_class");
  params.append("details", "surface");
  if (points.length > 2) params.set("pass_through", "true");
  params.set("key", key);

  const res = await fetch(`${base}/route?${params}`);
  const data = await res.json();
  if (!res.ok) {
    throw new Error(
      `GraphHopper ${res.status}: ${data.message || JSON.stringify(data).slice(0, 240)}`
    );
  }
  return data;
}

async function routeOsrm(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number],
  vias: [number, number][] = []
): Promise<RouteResult> {
  const base = baseUrl("osrm");
  if (!base) throw new Error("OSRM_URL missing");
  const p = osrmProfile(profile);
  const coords = [from, ...vias, to]
    .map(([lng, lat]) => `${lng},${lat}`)
    .join(";");
  const url = `${base}/route/v1/${p}/${coords}?overview=full&geometries=geojson&steps=true&annotations=false`;
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), 25_000);
  const res = await fetch(url, { signal: ac.signal }).finally(() =>
    clearTimeout(timer)
  );
  if (!res.ok) {
    throw new Error(`OSRM ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const route = data.routes?.[0];
  if (!route?.geometry) throw new Error("OSRM: no route");
  const geometry = route.geometry as GeoJSON.LineString;
  const steps = stepsFromOsrmLegs(route.legs ?? []);
  const warnings: string[] = [];
  if (isUsingPublicOsrm()) {
    warnings.push(
      "Öffentliches OSRM (project-osrm.org) — Demo/Dev. Produktion: eigener OSRM/Valhalla/GraphHopper."
    );
  }
  return {
    distanceM: Math.round(route.distance),
    durationS: Math.round(route.duration),
    geometry,
    engine: "osrm",
    profile,
    steps: steps.length
      ? steps
      : stepsFromDemoGeometry(geometry.coordinates as [number, number][]),
    warnings: warnings.length ? warnings : undefined,
  };
}

async function routeOpenRouteService(
  profile: RoutingProfile,
  points: [number, number][],
  lang: ChromeLang = "de"
): Promise<RouteResult> {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), 22_000);
  try {
    const r = await fetchOrsRoute({
      profile,
      points,
      signal: ac.signal,
      language: lang,
    });
    return {
      distanceM: r.distanceM,
      durationS: r.durationS,
      geometry: r.geometry,
      engine: "openrouteservice",
      profile,
      steps: r.steps,
      orsExtras: r.extras,
      warnings: r.warnings.length ? r.warnings : undefined,
    };
  } finally {
    clearTimeout(timer);
  }
}

function trailCorridorSnapEnabled(): boolean {
  const v = (process.env.TRAIL_CORRIDOR_SNAP || "1").toLowerCase();
  return v !== "0" && v !== "false" && v !== "off";
}

function profileUsesServerTrailSnap(profile: RoutingProfile): boolean {
  if (!profileWantsCorridorTrails(profile)) return false;
  return !profileWantsCorridorCycleways(profile);
}

function routeBbox(
  coords: [number, number][],
  padDeg: number,
  maxDeg: number
) {
  const lngs = coords.map((c) => Number(c[0]));
  const lats = coords.map((c) => Number(c[1]));
  return clampBbox(
    {
      west: Math.min(...lngs) - padDeg,
      south: Math.min(...lats) - padDeg,
      east: Math.max(...lngs) + padDeg,
      north: Math.max(...lats) + padDeg,
    },
    maxDeg
  );
}

function osmToSegments(trails: OsmTrail[]): TrailSegment[] {
  const segs: TrailSegment[] = [];
  for (const t of trails) {
    const s = osmTrailToSegment(t);
    if (s) segs.push(s);
  }
  return segs;
}

async function maybeEnrichCorridorCycleway(
  result: RouteResult,
  from: [number, number],
  to: [number, number]
): Promise<RouteResult> {
  // No GraphHopper road_class → fail-open (ORS/OSRM / missing details).
  if (!cityCyclewaySnapWanted(result.roadClassShares ?? {})) return result;
  if (result.distanceM < 800) return result;
  try {
    const coords = (result.geometry.coordinates ?? []) as [number, number][];
    if (coords.length < 2) return result;
    const { trails } = await fetchOsmTrailsNear({
      lat: (from[1] + to[1]) / 2,
      lon: (from[0] + to[0]) / 2,
      bbox: routeBbox(coords, 0.005, 0.1),
      timeoutMs: 8_000,
      kinds: "cycleways",
      limit: 80,
    });
    const segs = osmToSegments(trails);
    if (process.env.NODE_ENV !== "production") {
      console.info(
        `[cycleway-snap] ${result.profile} osm=${trails.length} segs=${segs.length}`
      );
    }
    if (!segs.length) return result;
    const next = applyCorridorCyclewaySnap({
      profile: result.profile,
      from,
      to,
      route: result,
      trails: segs,
    });
    if (process.env.NODE_ENV !== "production") {
      const snapped = (next.warnings ?? []).some((w) =>
        /Radweg/.test(w) && w.includes("in die Navi übernommen")
      );
      console.info(
        `[cycleway-snap] ${result.profile} osm=${trails.length} segs=${segs.length} snapped=${snapped}`
      );
    }
    return next;
  } catch {
    return result;
  }
}

async function maybeEnrichCorridorTrail(
  result: RouteResult,
  from: [number, number],
  to: [number, number],
  vias: [number, number][],
  accessLeg = false
): Promise<RouteResult> {
  if (accessLeg) return result;
  if (result.profile === "auto") return result;
  if (!trailCorridorSnapEnabled()) return result;
  if (vias.length > 0) return result;
  if (result.engine === "demo") return result;
  if (profileWantsCorridorCycleways(result.profile)) {
    return maybeEnrichCorridorCycleway(result, from, to);
  }
  if (!profileUsesServerTrailSnap(result.profile)) return result;
  try {
    const coords = (result.geometry.coordinates ?? []) as [number, number][];
    if (coords.length < 2) return result;
    const { trails } = await fetchOsmTrailsNear({
      lat: (from[1] + to[1]) / 2,
      lon: (from[0] + to[0]) / 2,
      bbox: routeBbox(coords, 0.014, 0.18),
      timeoutMs: 12_000,
      kinds: "trails",
      limit: 120,
    });
    if (!trails.length) return result;
    const segs = osmToSegments(trails);
    if (!segs.length) return result;
    const next = applyCorridorTrailSnap({
      profile: result.profile,
      from,
      to,
      route: result,
      trails: segs,
    });
    if (process.env.NODE_ENV !== "production") {
      const snapped = (next.warnings ?? []).some((w) =>
        w.includes("in die Navi übernommen")
      );
      console.info(
        `[corridor-snap] ${result.profile} osm=${trails.length} segs=${segs.length} snapped=${snapped}`
      );
    }
    return next;
  } catch {
    return result;
  }
}

export async function computeRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number],
  vias: [number, number][] = [],
  lang: ChromeLang | string = "de",
  opts?: ComputeRouteOptions
): Promise<RouteResult> {
  const language = chromeLangFrom(lang);
  const points = [from, ...vias, to];
  const variant = parseRouteVariant(opts?.variant);
  const forceValhalla =
    variantNeedsValhalla(variant) && engineIsConfigured("valhalla");
  let resolved = resolveRouteEngine(
    profile,
    parseRoutingEngineParam(opts?.engine)
  );
  if (forceValhalla) {
    resolved = { kind: "valhalla", requested: "valhalla", fallback: false };
  }
  const kind = resolved.kind;
  const effectiveVariant =
    variantNeedsValhalla(variant) && kind !== "valhalla" ? "planned" : variant;
  if (kind === "demo") {
    if (allowDemoContent()) return demoRoute(profile, from, to);
    throw new Error(
      "Kein Live-Routing konfiguriert — setze OPENROUTESERVICE_API_KEY, GRAPHHOPPER_API_KEY, VALHALLA_URL oder OSRM_URL.",
    );
  }

  try {
    let result: RouteResult;
    if (kind === "openrouteservice") {
      try {
        result = await routeOpenRouteService(profile, points, language);
      } catch (orsErr) {
        const envEngine = (process.env.ROUTING_ENGINE || "").toLowerCase();
        const orsForced =
          resolved.requested === "openrouteservice" ||
          envEngine === "openrouteservice" ||
          envEngine === "ors";
        if (!orsForced && process.env.GRAPHHOPPER_API_KEY?.trim()) {
          const gh = await routeGraphhopper(profile, points, language);
          const msg =
            orsErr instanceof Error ? orsErr.message : "ORS fehlgeschlagen";
          result = {
            ...gh,
            warnings: [
              `OpenRouteService Fallback → GraphHopper. ${msg}`,
              ...(gh.warnings ?? []),
            ],
          };
        } else {
          throw orsErr;
        }
      }
    } else if (kind === "graphhopper") {
      result = await routeGraphhopper(profile, points, language);
    } else if (kind === "valhalla") {
      if (vias.length === 0) {
        result = await routeValhalla(
          profile,
          from,
          to,
          language,
          effectiveVariant
        );
      } else {
        const parts: RouteResult[] = [];
        let prev = from;
        for (const p of [...vias, to]) {
          parts.push(
            await routeValhalla(profile, prev, p, language, effectiveVariant)
          );
          prev = p;
        }
        result = {
          distanceM: parts.reduce((a, p) => a + p.distanceM, 0),
          durationS: parts.reduce((a, p) => a + p.durationS, 0),
          geometry: {
            type: "LineString",
            coordinates: parts.flatMap((p, i) =>
              i === 0
                ? p.geometry.coordinates
                : p.geometry.coordinates.slice(1)
            ),
          },
          engine: "valhalla",
          profile,
          steps: parts.flatMap((p) => p.steps ?? []),
          warnings: parts.flatMap((p) => p.warnings ?? []),
          variant: effectiveVariant,
          variantApplied: effectiveVariant !== "planned",
        };
      }
    } else {
      // OSRM: multi-waypoint in one request
      result = await routeOsrm(profile, from, to, vias);
    }
    if (resolved.fallback && resolved.requested) {
      result = {
        ...result,
        warnings: [
          `Engine ${resolved.requested} nicht konfiguriert — ${result.engine}.`,
          ...(result.warnings ?? []),
        ],
      };
    }
    const variantApplied =
      effectiveVariant !== "planned" && result.engine === "valhalla";
    result = {
      ...result,
      variant,
      variantApplied,
      warnings: [
        ...(variantNeedsValhalla(variant) && !variantApplied
          ? [VARIANT_VALHALLA_ONLY]
          : []),
        ...(result.warnings ?? []),
      ],
    };
    return await maybeEnrichCorridorTrail(
      result,
      from,
      to,
      vias,
      opts?.accessLeg === true
    );
  } catch (e) {
    // Production: fail-closed — never invent geometry after a live failure.
    if (allowDemoContent()) {
      const demo = demoRoute(profile, from, to);
      const msg = e instanceof Error ? e.message : "Routing fehlgeschlagen";
      return {
        ...demo,
        warnings: [
          `Live-Routing (${kind}) fehlgeschlagen — Demo-Geometrie. ${msg}`,
          ...(demo.warnings ?? []),
        ],
      };
    }
    throw e instanceof Error
      ? e
      : new Error("Live-Routing fehlgeschlagen");
  }
}

/** Welche Engine ist konfiguriert (ohne Netzwerk-Probe). */
export function configuredRoutingEngine(): Exclude<
  RouteResult["engine"],
  "editorial"
> {
  const e = engine();
  return e === "editorial" ? "demo" : e;
}

export function configuredEngineForProfile(
  profile: RoutingProfile
): Exclude<RouteResult["engine"], "editorial"> {
  const e = engineForProfile(profile);
  return e === "editorial" ? "demo" : e;
}

export function isLiveRoutingConfigured(): boolean {
  // public OSRM zählt als live (ehrlich gelabelt), nicht als Dreieck-Demo
  return configuredRoutingEngine() !== "demo";
}

export function isValidLngLat(pair: [number, number]): boolean {
  const [lng, lat] = pair;
  return (
    Number.isFinite(lng) &&
    Number.isFinite(lat) &&
    lng >= -180 &&
    lng <= 180 &&
    lat >= -90 &&
    lat <= 90
  );
}
