/**
 * OpenRouteService (HeiGIT) — DACH cycling engine.
 *
 * Profiles: cycling-road / cycling-regular / cycling-mountain / cycling-electric / foot-hiking
 * Extra-info: surface, steepness, traildifficulty (never mapped onto S0–S3).
 * Geometry is routing truth; extras are honesty labels only.
 */

import type { RoutingProfile } from "@/lib/routing/profiles";
import {
  HONESTY_CYCLEWAY_DE,
  HONESTY_ROAD_DE,
} from "@/lib/routing/graphhopperHints";
import { pointInDach } from "@/lib/coverage/dach";
import {
  stepsFromDemoGeometry,
  type NavStep,
  type NavStepType,
} from "@/lib/routing/navSteps";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { roundTripWaypointCount } from "@/lib/routing/osmRoundTrip";

export const ORS_DEFAULT_URL = "https://api.openrouteservice.org";

export type OrsProfile =
  | "cycling-road"
  | "cycling-regular"
  | "cycling-mountain"
  | "cycling-electric"
  | "foot-hiking"
  | "driving-car";

export type OrsSurfaceShare = {
  id: number;
  label: string;
  distanceM: number;
};

export type OrsExtras = {
  surfaces: OrsSurfaceShare[];
  waytypes: OrsSurfaceShare[];
  dominantSurface?: string;
  dominantWaytype?: string;
  trailDifficultyMax?: number;
  steepnessHint?: string;
  /** Vertex ranges `[from, to, surfaceCode]` — honesty paint, not S-scale. */
  surfaceRanges?: [number, number, number][];
};

/** ORS surface codes — https://giscience.github.io/openrouteservice/documentation/extra-info/Surface */
const SURFACE_LABEL: Record<number, string> = {
  0: "unbekannt",
  1: "befestigt",
  2: "unbefestigt",
  3: "Asphalt",
  4: "Beton",
  5: "Pflaster",
  6: "Metall",
  7: "Holz",
  8: "verdichteter Schotter",
  9: "Schotter",
  10: "Erde",
  11: "Gras",
  12: "Sand",
  13: "Schnee/Eis",
};

/** ORS waytype — https://giscience.github.io/openrouteservice/documentation/extra-info/Waytype */
const WAYTYPE_LABEL: Record<number, string> = {
  0: "sonstige",
  1: "Staatsstraße",
  2: "Straße",
  3: "Straße",
  4: "Pfad",
  5: "Track",
  6: "Radweg",
  7: "Fußweg",
  8: "Stufen",
  9: "Fähre",
  10: "Baustelle",
};

const WAYTYPE_OFFROAD = new Set([4, 5, 6, 7]);
const WAYTYPE_BUSY = new Set([1, 2]);

export function orsApiKey(): string | null {
  const k =
    process.env.OPENROUTESERVICE_API_KEY?.trim() ||
    process.env.ORS_API_KEY?.trim() ||
    "";
  return k.length > 0 ? k : null;
}

export function orsBaseUrl(): string {
  return (
    process.env.OPENROUTESERVICE_URL?.replace(/\/$/, "") || ORS_DEFAULT_URL
  );
}

export function isOrsConfigured(): boolean {
  return Boolean(orsApiKey());
}

/** Map FlowLine sport profile → ORS costing. Gravel has no native ORS profile. */
export function orsProfileFor(profile: RoutingProfile): OrsProfile {
  switch (profile) {
    case "auto":
      return "driving-car";
    case "road":
      return "cycling-road";
    case "mtb_allmountain":
    case "mtb_enduro":
    case "downhill":
    case "emtb":
      return "cycling-mountain";
    case "ebike":
      return "cycling-electric";
    case "hiking":
      return "foot-hiking";
    case "gravel":
    case "urban":
    default:
      return "cycling-regular";
  }
}

/**
 * When GraphHopper Basic cannot distinguish mtb/gravel, ORS should take over
 * if a key is present. Explicit ROUTING_ENGINE still wins in engine.ts.
 */
export function orsPreferredForGraphhopperBasic(
  profile: RoutingProfile
): boolean {
  return (
    profile === "gravel" ||
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "downhill" ||
    profile === "emtb"
  );
}

/** Quiet/green + avoid highways so cycling engines prefer bike infra. */
export function orsDirectionsOptions(
  profile: RoutingProfile
): Record<string, unknown> | undefined {
  if (profile === "auto") {
    return { avoid_features: ["ferries"] };
  }
  if (profile === "hiking") {
    return { avoid_features: ["highways", "ferries"] };
  }
  if (
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "downhill" ||
    profile === "emtb"
  ) {
    return {
      avoid_features: ["highways", "ferries"],
      profile_params: { weightings: { steepness_difficulty: 2 } },
    };
  }
  if (profile === "gravel") {
    return {
      avoid_features: ["highways"],
      profile_params: { weightings: { quiet: 0.45, green: 0.7 } },
    };
  }
  if (profile === "road") {
    return {
      profile_params: { weightings: { steepness_difficulty: 1 } },
    };
  }
  // urban / ebike / default
  return {
    avoid_features: ["highways"],
    profile_params: { weightings: { quiet: 0.9, green: 0.5 } },
  };
}

export function pointPairInDach(points: [number, number][]): boolean {
  return points.every((p) => pointInDach(p[1], p[0]));
}

type OrsRange = [number, number, number];

type OrsExtraBlock = {
  values?: OrsRange[];
  summary?: Array<{ value?: number; distance?: number }>;
};

type OrsStep = {
  distance?: number;
  duration?: number;
  type?: number;
  instruction?: string;
  name?: string;
  way_points?: [number, number];
};

type OrsGeojson = {
  features?: Array<{
    geometry?: { type?: string; coordinates?: number[][] };
    properties?: {
      summary?: { distance?: number; duration?: number };
      segments?: Array<{ steps?: OrsStep[]; distance?: number; duration?: number }>;
      extras?: Record<string, OrsExtraBlock>;
    };
  }>;
  error?: { code?: number; message?: string };
};

function surfaceLabel(id: number): string {
  return SURFACE_LABEL[id] ?? `surface:${id}`;
}

function waytypeLabel(id: number): string {
  return WAYTYPE_LABEL[id] ?? `waytype:${id}`;
}

export function parseOrsExtras(
  extras: Record<string, OrsExtraBlock> | undefined,
  totalDistanceM: number
): OrsExtras {
  const surfaces: OrsSurfaceShare[] = [];
  const surfaceSummary = extras?.surface?.summary ?? [];
  for (const row of surfaceSummary) {
    const id = Number(row.value);
    if (!Number.isFinite(id)) continue;
    surfaces.push({
      id,
      label: surfaceLabel(id),
      distanceM: Math.round(row.distance ?? 0),
    });
  }
  surfaces.sort((a, b) => b.distanceM - a.distanceM);
  const dominant = surfaces[0];

  const waytypes: OrsSurfaceShare[] = [];
  for (const row of extras?.waytype?.summary ?? extras?.waytypes?.summary ?? []) {
    const id = Number(row.value);
    if (!Number.isFinite(id)) continue;
    waytypes.push({
      id,
      label: waytypeLabel(id),
      distanceM: Math.round(row.distance ?? 0),
    });
  }
  waytypes.sort((a, b) => b.distanceM - a.distanceM);
  const dominantWay = waytypes[0];

  let trailDifficultyMax: number | undefined;
  for (const row of extras?.traildifficulty?.summary ?? []) {
    const v = Number(row.value);
    if (!Number.isFinite(v)) continue;
    trailDifficultyMax =
      trailDifficultyMax == null ? v : Math.max(trailDifficultyMax, v);
  }

  const steep = extras?.steepness?.summary ?? [];
  let steepnessHint: string | undefined;
  if (steep.length) {
    const maxAbs = steep.reduce((m, r) => {
      const v = Math.abs(Number(r.value) || 0);
      return Math.max(m, v);
    }, 0);
    if (maxAbs >= 5) steepnessHint = "steil";
    else if (maxAbs >= 3) steepnessHint = "hügelig";
    else steepnessHint = "flach";
  }

  const surfaceRanges: [number, number, number][] = [];
  for (const row of extras?.surface?.values ?? []) {
    const a = Number(row[0]);
    const b = Number(row[1]);
    const id = Number(row[2]);
    if (!Number.isFinite(a) || !Number.isFinite(b) || !Number.isFinite(id)) {
      continue;
    }
    if (b <= a) continue;
    surfaceRanges.push([a, b, id]);
  }

  return {
    surfaces,
    waytypes,
    dominantSurface:
      dominant && dominant.distanceM >= totalDistanceM * 0.18
        ? dominant.label
        : undefined,
    dominantWaytype:
      dominantWay && dominantWay.distanceM >= totalDistanceM * 0.18
        ? dominantWay.label
        : undefined,
    trailDifficultyMax,
    steepnessHint,
    surfaceRanges: surfaceRanges.length ? surfaceRanges : undefined,
  };
}

/** ORS instruction type → NavStepType */
export function orsTypeToNav(type: number): NavStepType {
  if (type === 11) return "start";
  if (type === 10) return "arrive";
  if (type === 6) return "continue";
  if (type === 9) return "uturn";
  if (type === 7 || type === 8) return "roundabout";
  if (type === 12 || type === 13) return "fork";
  if (type >= 0 && type <= 5) return "turn";
  return "unknown";
}

export function stepsFromOrs(
  steps: OrsStep[],
  coordinates: [number, number][]
): NavStep[] {
  let along = 0;
  const out: NavStep[] = [];
  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    const lengthM = Math.round(s.distance ?? 0);
    const idx = s.way_points?.[0] ?? 0;
    const coord = coordinates[Math.min(idx, Math.max(0, coordinates.length - 1))];
    const type = orsTypeToNav(s.type ?? 6);
    const text = (s.instruction || "Weiter").trim();
    const street = (s.name || "").trim() || undefined;
    out.push({
      id: `ors-${i}`,
      type,
      instruction: text,
      instructionEn: text,
      distanceAlongM: along,
      lengthM,
      coordinate: coord ? { lng: coord[0], lat: coord[1] } : undefined,
      engineType: s.type,
      streetName: street,
    });
    along += lengthM;
  }
  return out;
}

function extrasWarnings(
  extras: OrsExtras,
  profile: RoutingProfile
): string[] {
  const w: string[] = [];
  if (extras.dominantSurface) {
    w.push(`ORS Oberfläche überwiegend ${extras.dominantSurface}`);
  }
  if (extras.steepnessHint && extras.steepnessHint !== "flach") {
    w.push(`ORS Steigung: ${extras.steepnessHint}`);
  }
  if (
    extras.trailDifficultyMax != null &&
    extras.trailDifficultyMax >= 3 &&
    (profile === "road" || profile === "urban")
  ) {
    w.push(
      "ORS Trail-Schwierigkeit hoch — Rennrad/City-Profil, Track nicht als S-Skala gelesen"
    );
  }
  const wayTotal = extras.waytypes.reduce((s, x) => s + x.distanceM, 0);
  if (wayTotal > 0) {
    let offroad = 0;
    let busy = 0;
    let cycleway = 0;
    for (const row of extras.waytypes) {
      if (WAYTYPE_OFFROAD.has(row.id)) offroad += row.distanceM;
      if (WAYTYPE_BUSY.has(row.id)) busy += row.distanceM;
      if (row.id === 6) cycleway += row.distanceM;
    }
    const off = offroad / wayTotal;
    const bus = busy / wayTotal;
    const cy = cycleway / wayTotal;
    const trailSport =
      profile === "mtb_allmountain" ||
      profile === "mtb_enduro" ||
      profile === "downhill" ||
      profile === "emtb";
    if (trailSport && off < 0.18 && bus > 0.45) {
      w.push(HONESTY_ROAD_DE);
    } else if (profile === "gravel" && off < 0.2 && bus > 0.5) {
      w.push(
        "Wenig Track/Schotter auf dieser Linie — OSM-Wege antippen und anhängen."
      );
    } else if (
      (profile === "urban" || profile === "ebike") &&
      cy < 0.08 &&
      bus > 0.55
    ) {
      w.push(HONESTY_CYCLEWAY_DE);
    }
  }
  return w;
}

export type OrsRouteOk = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  steps: NavStep[];
  extras: OrsExtras;
  warnings: string[];
  orsProfile: OrsProfile;
};

async function postOrsDirections(opts: {
  profile: RoutingProfile;
  coordinates: [number, number][];
  options?: Record<string, unknown>;
  signal?: AbortSignal;
  language?: ChromeLang;
}): Promise<OrsRouteOk> {
  const key = orsApiKey();
  if (!key) throw new Error("OPENROUTESERVICE_API_KEY missing");
  if (opts.coordinates.length < 1) {
    throw new Error("OpenRouteService: need coordinates");
  }

  const orsProfile = orsProfileFor(opts.profile);
  const url = `${orsBaseUrl()}/v2/directions/${orsProfile}/geojson`;
  const body: Record<string, unknown> = {
    coordinates: opts.coordinates,
    language: opts.language ?? "de",
    instructions: true,
    elevation: true,
    extra_info:
      orsProfile === "driving-car"
        ? ["waytype"]
        : ["surface", "steepness", "traildifficulty", "waytype"],
    units: "m",
  };
  if (opts.options) body.options = opts.options;

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: key,
      "Content-Type": "application/json",
      Accept: "application/geo+json, application/json",
    },
    body: JSON.stringify(body),
    signal: opts.signal,
  });

  const rawText = await res.text();
  if (res.status === 429) {
    throw new Error(`OpenRouteService 429 rate limit: ${rawText.slice(0, 180)}`);
  }
  if (!res.ok) {
    throw new Error(`OpenRouteService ${res.status}: ${rawText.slice(0, 240)}`);
  }

  let json: OrsGeojson;
  try {
    json = JSON.parse(rawText) as OrsGeojson;
  } catch {
    throw new Error("OpenRouteService: invalid JSON");
  }
  if (json.error?.message) {
    throw new Error(`OpenRouteService: ${json.error.message}`);
  }

  const feat = json.features?.[0];
  const coordsRaw = feat?.geometry?.coordinates;
  if (!coordsRaw || coordsRaw.length < 2) {
    throw new Error("OpenRouteService: no geometry");
  }
  const coordinates: [number, number][] = coordsRaw.map((c) => [
    Number(c[0]),
    Number(c[1]),
  ]);

  const summary = feat?.properties?.summary;
  const distanceM = Math.round(summary?.distance ?? 0);
  const durationS = Math.round(summary?.duration ?? 0);
  const extras = parseOrsExtras(feat?.properties?.extras, distanceM);
  const rawSteps = (feat?.properties?.segments ?? []).flatMap(
    (seg) => seg.steps ?? []
  );
  const steps = stepsFromOrs(rawSteps, coordinates);
  const warnings = extrasWarnings(extras, opts.profile);
  if (!pointPairInDach(opts.coordinates)) {
    warnings.push(
      "Start/Ziel außerhalb DACH — OpenRouteService bleibt global, weniger kuratierte Seeds"
    );
  }

  return {
    distanceM,
    durationS,
    geometry: { type: "LineString", coordinates },
    steps: steps.length ? steps : stepsFromDemoGeometry(coordinates),
    extras,
    warnings,
    orsProfile,
  };
}

export async function fetchOrsRoute(opts: {
  profile: RoutingProfile;
  points: [number, number][];
  signal?: AbortSignal;
  language?: ChromeLang;
}): Promise<OrsRouteOk> {
  if (opts.points.length < 2) throw new Error("OpenRouteService: need ≥2 points");
  return postOrsDirections({
    profile: opts.profile,
    coordinates: opts.points,
    options: orsDirectionsOptions(opts.profile),
    signal: opts.signal,
    language: opts.language,
  });
}

/** POST body for ORS `options.round_trip` (one start coordinate). */
export function orsRoundTripRequestBody(opts: {
  profile: RoutingProfile;
  start: [number, number];
  lengthM: number;
  seed?: number;
  points?: number;
  language?: ChromeLang;
}): Record<string, unknown> {
  const lengthM = Math.min(120_000, Math.max(5_000, Math.round(opts.lengthM)));
  const points = opts.points ?? roundTripWaypointCount(lengthM);
  const seed =
    typeof opts.seed === "number" && Number.isFinite(opts.seed) && opts.seed >= 1
      ? Math.floor(opts.seed)
      : 1;
  const base = orsDirectionsOptions(opts.profile);
  const options: Record<string, unknown> = {
    ...(base ?? {}),
    round_trip: { length: lengthM, points, seed },
  };
  const orsProfile = orsProfileFor(opts.profile);
  return {
    coordinates: [opts.start],
    language: opts.language ?? "de",
    instructions: true,
    elevation: true,
    extra_info:
      orsProfile === "driving-car"
        ? ["waytype"]
        : ["surface", "steepness", "traildifficulty", "waytype"],
    units: "m",
    options,
  };
}

/** One-point ORS round-trip. Caller must check closure (`trackIsClosedLoop`). */
export async function fetchOrsRoundTrip(opts: {
  profile: RoutingProfile;
  start: [number, number];
  lengthM: number;
  seed?: number;
  points?: number;
  signal?: AbortSignal;
  language?: ChromeLang;
}): Promise<OrsRouteOk> {
  const body = orsRoundTripRequestBody(opts);
  return postOrsDirections({
    profile: opts.profile,
    coordinates: [opts.start],
    options: body.options as Record<string, unknown>,
    signal: opts.signal,
    language: opts.language,
  });
}
