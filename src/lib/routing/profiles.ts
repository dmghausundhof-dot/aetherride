/**
 * RideProfile — Single Source of Truth for bike + hiking routing.
 *
 * Steuert Valhalla/Offline-Costing, Trail-Filter (S0–S3+), UI-Labels,
 * Farben und Default-Geschwindigkeiten.
 *
 * Keep in sync with profiles.rs and valhalla-costing.json
 * (`mobile/packages/routing_core/native/src/profiles.rs`,
 * `data/routing/valhalla-costing.json`).
 */

export type RideProfileId =
  | "mtb_allmountain"
  | "mtb_enduro"
  | "gravel"
  | "road"
  | "ebike"
  | "emtb"
  | "downhill"
  | "hiking";

export type TrailDifficulty = "s0" | "s1" | "s2" | "s3plus" | "open";

export interface ValhallaBicycleOptions {
  bicycle_type: "road" | "hybrid" | "mountain" | "cross";
  use_roads: number;
  use_hills: number;
  avoid_bad_surfaces: number;
}

export interface RideProfile {
  id: RideProfileId;
  label: string;
  shortLabel: string;
  description: string;
  category: "mtb" | "gravel" | "road" | "ebike" | "hike";
  icon: string;

  costing: "bicycle" | "pedestrian";
  bicycleOptions?: ValhallaBicycleOptions;
  pedestrianOptions?: { walking_speed: number; use_hills: number };
  defaultSpeedKmh: number;

  preferredSurfaces: string[];
  maxMtbScale: number | null;
  preferredDifficulties: TrailDifficulty[];
  routeColor: string;
  trailHighlightColor: string;

  acceptsHighway: (highway: string) => boolean;
  edgeFactor: (
    highway: string,
    mtbScale: number | null,
    surface: string
  ) => number | null;
}

export type ValhallaCosting = {
  costing: "bicycle" | "pedestrian";
  costing_options: {
    bicycle?: ValhallaBicycleOptions;
    pedestrian?: { walking_speed: number; use_hills: number };
  };
};

const RIDE_PROFILE_IDS: readonly RideProfileId[] = [
  "mtb_allmountain",
  "mtb_enduro",
  "gravel",
  "road",
  "ebike",
  "emtb",
  "downhill",
  "hiking",
];

/** Overlay-Kachelwerte (`mtb_scale`) plus OSM-Rohwerte. */
const TILE_VALUES: Record<TrailDifficulty, readonly string[]> = {
  s0: ["s0", "S0", "0"],
  s1: ["s1", "S1", "1"],
  s2: ["s2", "S2", "2"],
  s3plus: ["s3plus", "s3", "S3", "S3+", "3", "4", "5", "6"],
  open: ["", "open", "unrated", "unbewertet"],
};

const OVERLAY_SCALE_LABEL: Record<Exclude<TrailDifficulty, "open">, string> = {
  s0: "S0",
  s1: "S1",
  s2: "S2",
  s3plus: "S3",
};

type RideProfileFields = Omit<RideProfile, "acceptsHighway" | "edgeFactor">;

function withNav(fields: RideProfileFields): RideProfile {
  const id = fields.id;
  return {
    ...fields,
    acceptsHighway: (highway) => acceptsHighwayFor(id, highway),
    edgeFactor: (highway, mtbScale, surface) =>
      edgeFactorFor(id, highway, mtbScale, surface),
  };
}

function isPavedSurface(surface: string): boolean {
  return surface === "asphalt" || surface === "paved" || surface === "concrete";
}

function isRoughSurface(surface: string): boolean {
  return (
    surface === "ground" ||
    surface === "dirt" ||
    surface === "mud" ||
    surface === "gravel" ||
    surface === "fine_gravel" ||
    surface === "compacted" ||
    surface === ""
  );
}

function blocked(highway: string, ...names: string[]): boolean {
  return names.includes(highway);
}

function acceptsHighwayFor(id: RideProfileId, highway: string): boolean {
  return edgeFactorFor(id, highway, null, "") !== null;
}

function edgeFactorFor(
  id: RideProfileId,
  highway: string,
  mtbScale: number | null,
  surface: string
): number | null {
  const rough = isRoughSurface(surface);
  const paved = isPavedSurface(surface);

  switch (id) {
    case "road": {
      if (blocked(highway, "path", "track", "footway", "steps")) return null;
      if (!paved && rough) return 4.0;
      return 1.0;
    }
    case "gravel": {
      if (blocked(highway, "motorway", "trunk", "steps")) return null;
      if ((mtbScale ?? 0) >= 4) return null;
      if (
        surface === "gravel" ||
        surface === "compacted" ||
        surface === "fine_gravel" ||
        highway === "track"
      ) {
        return 0.8;
      }
      if (paved) return 1.2;
      return 1.0;
    }
    case "hiking": {
      if (blocked(highway, "motorway", "trunk", "primary")) return null;
      if (highway === "path" || highway === "footway" || highway === "track") {
        return 0.85;
      }
      return 1.3;
    }
    case "mtb_enduro": {
      if (blocked(highway, "motorway", "trunk", "primary", "steps")) return null;
      const s = mtbScale ?? 1;
      if (s >= 2) return 0.7;
      if (highway === "path" || highway === "track") return 0.9;
      return 1.4;
    }
    case "downhill": {
      if (
        blocked(highway, "motorway", "trunk", "primary", "secondary", "steps")
      ) {
        return null;
      }
      const s = mtbScale ?? 0;
      if (s >= 3) return 0.55;
      if (s >= 1) return 0.7;
      if (highway === "path" || highway === "track") return 1.15;
      return 2.2;
    }
    case "mtb_allmountain":
    case "emtb": {
      if (blocked(highway, "motorway", "trunk", "steps")) return null;
      const max = id === "emtb" ? 4 : 3;
      if ((mtbScale ?? 0) > max) return 2.5;
      if (highway === "path" || highway === "track" || highway === "cycleway") {
        return 0.85;
      }
      return 1.2;
    }
    case "ebike": {
      if (blocked(highway, "motorway", "steps")) return null;
      if ((mtbScale ?? 0) >= 4) return null;
      if (
        highway === "cycleway" ||
        highway === "track" ||
        highway === "path" ||
        highway === "tertiary"
      ) {
        return 0.9;
      }
      return 1.15;
    }
  }
}

function scaleToDifficulty(scale: number): TrailDifficulty {
  if (scale <= 0) return "s0";
  if (scale === 1) return "s1";
  if (scale === 2) return "s2";
  return "s3plus";
}

function parseTrailScale(
  raw: string | number | undefined
): { difficulty: TrailDifficulty; scale: number } | null {
  if (raw === undefined || raw === "") return null;
  if (typeof raw === "number") {
    if (!Number.isFinite(raw)) return null;
    const scale = Math.floor(raw);
    return { difficulty: scaleToDifficulty(scale), scale };
  }
  const t = raw.trim().toLowerCase();
  if (!t) return null;
  if (t === "open" || t === "unrated" || t === "unbewertet") {
    return { difficulty: "open", scale: 0 };
  }
  const head = t.replace(/^s/, "").replace(/[^0-9].*$/, "");
  const scale = Number.parseInt(head, 10);
  if (!Number.isFinite(scale)) return null;
  return { difficulty: scaleToDifficulty(scale), scale };
}

export const RIDE_PROFILES: Record<RideProfileId, RideProfile> = {
  mtb_allmountain: withNav({
    id: "mtb_allmountain",
    label: "MTB",
    shortLabel: "AM",
    description: "Allmountain: S0–S2, Pfade und leichte Trails.",
    category: "mtb",
    icon: "mountain",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "mountain",
      use_roads: 0.25,
      use_hills: 0.75,
      avoid_bad_surfaces: 0.15,
    },
    defaultSpeedKmh: 12.6,
    preferredSurfaces: ["path", "track", "cycleway", "dirt", "ground", "compacted"],
    maxMtbScale: 3,
    preferredDifficulties: ["s0", "s1", "s2", "open"],
    routeColor: "#2E7D32",
    trailHighlightColor: "#4CAF50",
  }),
  mtb_enduro: withNav({
    id: "mtb_enduro",
    label: "Enduro",
    shortLabel: "EN",
    description: "Enduro: technische Trails S1–S3, wenig Straße.",
    category: "mtb",
    icon: "mountain-snow",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "mountain",
      use_roads: 0.1,
      use_hills: 0.9,
      avoid_bad_surfaces: 0.05,
    },
    defaultSpeedKmh: 10.8,
    preferredSurfaces: ["path", "track", "dirt", "ground", "roots"],
    maxMtbScale: 5,
    preferredDifficulties: ["s1", "s2", "s3plus"],
    routeColor: "#E65100",
    trailHighlightColor: "#FF6F00",
  }),
  downhill: withNav({
    id: "downhill",
    label: "Downhill",
    shortLabel: "DH",
    description:
      "Downhill: technische Abfahrten S1–S3+, minimale Straßennutzung.",
    category: "mtb",
    icon: "chevrons-down",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "mountain",
      use_roads: 0.05,
      use_hills: 1.0,
      avoid_bad_surfaces: 0.0,
    },
    defaultSpeedKmh: 11.5,
    preferredSurfaces: ["path", "track", "dirt", "ground"],
    maxMtbScale: 6,
    preferredDifficulties: ["s1", "s2", "s3plus"],
    routeColor: "#B71C1C",
    trailHighlightColor: "#E53935",
  }),
  gravel: withNav({
    id: "gravel",
    label: "Gravel",
    shortLabel: "GR",
    description: "Gravel: Schotter und leichte Trails S0–S1.",
    category: "gravel",
    icon: "route",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "hybrid",
      use_roads: 0.4,
      use_hills: 0.4,
      avoid_bad_surfaces: 0.3,
    },
    defaultSpeedKmh: 18,
    preferredSurfaces: ["gravel", "compacted", "fine_gravel", "track", "unclassified"],
    maxMtbScale: 1,
    preferredDifficulties: ["s0", "s1", "open"],
    routeColor: "#C49A3C",
    trailHighlightColor: "#D4A84B",
  }),
  road: withNav({
    id: "road",
    label: "Rennrad",
    shortLabel: "RR",
    description: "Rennrad: nur Asphalt/Paved, keine MTB-Trails.",
    category: "road",
    icon: "bike",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "road",
      use_roads: 0.9,
      use_hills: 0.2,
      avoid_bad_surfaces: 0.8,
    },
    defaultSpeedKmh: 25.2,
    preferredSurfaces: ["asphalt", "paved", "concrete"],
    maxMtbScale: null,
    preferredDifficulties: [],
    routeColor: "#1E88E5",
    trailHighlightColor: "#42A5F5",
  }),
  ebike: withNav({
    id: "ebike",
    label: "E-Trekking",
    shortLabel: "E",
    description: "E-Trekking: Radwege, Tracks, leichte Pfade.",
    category: "ebike",
    icon: "zap",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "hybrid",
      use_roads: 0.5,
      use_hills: 0.85,
      avoid_bad_surfaces: 0.4,
    },
    defaultSpeedKmh: 21.6,
    preferredSurfaces: ["cycleway", "track", "path", "tertiary", "compacted"],
    maxMtbScale: 3,
    preferredDifficulties: ["s0", "s1", "open"],
    routeColor: "#00897B",
    trailHighlightColor: "#26A69A",
  }),
  emtb: withNav({
    id: "emtb",
    label: "E-MTB",
    shortLabel: "eMTB",
    description: "E-MTB: Trails bis S2/S3, Unterstützung an Steigungen.",
    category: "ebike",
    icon: "zap",
    costing: "bicycle",
    bicycleOptions: {
      bicycle_type: "mountain",
      use_roads: 0.2,
      use_hills: 0.95,
      avoid_bad_surfaces: 0.1,
    },
    defaultSpeedKmh: 16.2,
    preferredSurfaces: ["path", "track", "cycleway", "dirt", "ground"],
    maxMtbScale: 4,
    preferredDifficulties: ["s0", "s1", "s2", "open"],
    routeColor: "#558B2F",
    trailHighlightColor: "#7CB342",
  }),
  hiking: withNav({
    id: "hiking",
    label: "Zu Fuß",
    shortLabel: "Hike",
    description: "Wandern: Pfade, Fußwege, Tracks — kein Autobahn-Routing.",
    category: "hike",
    icon: "footprints",
    costing: "pedestrian",
    pedestrianOptions: { walking_speed: 4.5, use_hills: 0.6 },
    defaultSpeedKmh: 4.32,
    preferredSurfaces: ["path", "footway", "track", "ground", "dirt"],
    maxMtbScale: 6,
    preferredDifficulties: ["s0", "s1", "s2", "s3plus", "open"],
    routeColor: "#6D4C41",
    trailHighlightColor: "#8D6E63",
  }),
};

export function getProfile(id: RideProfileId): RideProfile {
  return RIDE_PROFILES[id];
}

export function listProfiles(): RideProfile[] {
  return RIDE_PROFILE_IDS.map((id) => RIDE_PROFILES[id]);
}

/** Alle Fahrrad-Profile, ohne hiking. */
export function listBikeProfiles(): RideProfile[] {
  return listProfiles().filter((p) => p.category !== "hike");
}

export function isRideProfileId(id: string): id is RideProfileId {
  return Object.prototype.hasOwnProperty.call(RIDE_PROFILES, id);
}

export function buildValhallaCosting(id: RideProfileId): ValhallaCosting {
  const profile = getProfile(id);
  if (profile.costing === "pedestrian") {
    return {
      costing: "pedestrian",
      costing_options: {
        pedestrian: profile.pedestrianOptions ?? {
          walking_speed: 4.5,
          use_hills: 0.6,
        },
      },
    };
  }
  return {
    costing: "bicycle",
    costing_options: {
      bicycle: profile.bicycleOptions,
    },
  };
}

export function isTrailSuitable(
  profileId: RideProfileId,
  tags: { highway?: string; mtb_scale?: string | number; surface?: string }
): boolean {
  const profile = getProfile(profileId);
  const highway = tags.highway ?? "";
  const surface = (tags.surface ?? "").toLowerCase();

  if (highway && !profile.acceptsHighway(highway)) return false;

  const parsed = parseTrailScale(tags.mtb_scale);
  if (parsed) {
    if (parsed.difficulty === "open") {
      return profile.preferredDifficulties.includes("open");
    }
    if (profile.maxMtbScale !== null && parsed.scale > profile.maxMtbScale) {
      return false;
    }
    return profile.preferredDifficulties.includes(parsed.difficulty);
  }

  if (surface && profile.preferredSurfaces.length > 0) {
    const surfaceOk = profile.preferredSurfaces.some(
      (s) => surface === s || surface.includes(s)
    );
    if (profile.category === "road") return surfaceOk;
  }

  if (profile.preferredDifficulties.includes("open")) return true;
  if (profile.preferredDifficulties.length === 0) {
    return !surface || profile.preferredSurfaces.includes(surface);
  }
  return false;
}

/** Overlay-Kachel-Labels S0–S3 für preferredDifficulties (ohne open). */
export function overlayScaleLabels(profileId: RideProfileId): string[] {
  return getProfile(profileId)
    .preferredDifficulties.filter(
      (d): d is Exclude<TrailDifficulty, "open"> => d !== "open"
    )
    .map((d) => OVERLAY_SCALE_LABEL[d]);
}

/**
 * Alle mtb_scale-Werte, die Overlay/OSM/API für ein Profil matchen
 * (S1, s1, 1, S3+, 3–6 …) — SSOT für MapLibre-Filter.
 */
export function overlayScaleMatchValues(profileId: RideProfileId): string[] {
  const diffs = getProfile(profileId).preferredDifficulties.filter(
    (d): d is Exclude<TrailDifficulty, "open"> => d !== "open"
  );
  const values = new Set<string>();
  for (const d of diffs) {
    for (const v of TILE_VALUES[d]) {
      if (v) values.add(v);
    }
  }
  return [...values];
}

export function prefersUnratedTrails(profileId: RideProfileId): boolean {
  return getProfile(profileId).preferredDifficulties.includes("open");
}

/** Parse "S1–S2" / "S3+" Seed-Labels in TrailDifficulty. */
export function difficultiesFromTrailLabel(
  raw?: string | null
): TrailDifficulty[] {
  if (!raw || raw === "—" || raw === "-") return ["open"];
  const t = raw.toLowerCase();
  const found: TrailDifficulty[] = [];
  if (/\bs0\b/.test(t) || t.includes("s0")) found.push("s0");
  if (t.includes("s1")) found.push("s1");
  if (t.includes("s2")) found.push("s2");
  if (t.includes("s3")) found.push("s3plus");
  return found.length ? found : ["open"];
}

export function isLabeledTrailSuitable(
  profileId: RideProfileId,
  difficultyLabel?: string | null
): boolean {
  const preferred = getProfile(profileId).preferredDifficulties;
  if (preferred.length === 0) return false;
  return difficultiesFromTrailLabel(difficultyLabel).some((d) =>
    preferred.includes(d)
  );
}

/** MapLibre `layer.filter` — Trails nach preferredDifficulties des Profils. */
export function trailFilterExpression(profileId: RideProfileId): any[] {
  const profile = getProfile(profileId);
  const diffs = profile.preferredDifficulties;
  const scaleValues = diffs.flatMap((d) => [...TILE_VALUES[d]]);

  const scaleProp: any[] = [
    "to-string",
    ["coalesce", ["get", "mtb_scale"], ["get", "mtb:scale"], ""],
  ];
  const scaleMatch: any[] = ["in", scaleProp, ["literal", scaleValues]];

  if (diffs.length === 0) {
    const surfaces = profile.preferredSurfaces;
    return [
      "all",
      [
        "in",
        ["to-string", ["coalesce", ["get", "surface"], ""]],
        ["literal", surfaces],
      ],
      ["!", ["has", "mtb_scale"]],
    ];
  }

  if (diffs.includes("open")) {
    return [
      "any",
      scaleMatch,
      ["all", ["!", ["has", "mtb_scale"]], ["!", ["has", "mtb:scale"]]],
    ];
  }

  return scaleMatch;
}

/**
 * Usage — routing:
 * ```ts
 * const profile = getProfile(activeProfile);
 * const costing = buildValhallaCosting(profile.id);
 * // POST /route { locations, ...costing }
 * ```
 *
 * Usage — MapLibre trail layer:
 * ```ts
 * const p = getProfile(activeProfile);
 * map.setFilter("trails", trailFilterExpression(p.id));
 * map.setPaintProperty("trails", "line-color", p.trailHighlightColor);
 * map.setPaintProperty("route", "line-color", p.routeColor);
 * ```
 *
 * Usage — trail suitability:
 * ```ts
 * isTrailSuitable("downhill", { mtb_scale: 2 }); // true
 * isTrailSuitable("road", { mtb_scale: 2 });     // false
 * ```
 */

/* Legacy client API — RoutingProfile includes `urban` (City) plus RideProfileId. */

export type RoutingProfile = RideProfileId | "urban";

export interface ProfileConfig {
  id: RoutingProfile;
  label: string;
  prefer: string[];
  avoid: string[];
  maxSurfaceRoughness: number;
  preferMtbScaleMax?: number;
  preferElevation: boolean;
  eBikeAssistFactor?: number;
}

const URBAN_PROFILE: ProfileConfig = {
  id: "urban",
  label: "City",
  prefer: [
    "cycleway",
    "residential",
    "tertiary",
    "living_street",
    "path",
    "surface=asphalt|paved|concrete",
  ],
  avoid: ["motorway", "trunk", "mtb:scale>=2", "steps"],
  maxSurfaceRoughness: 0.35,
  preferElevation: false,
};

function toLegacyConfig(p: RideProfile): ProfileConfig {
  const avoidBad = p.bicycleOptions?.avoid_bad_surfaces ?? 0.1;
  return {
    id: p.id,
    label: p.label,
    prefer: p.preferredSurfaces,
    avoid: [],
    maxSurfaceRoughness: Math.min(0.98, Math.max(0.15, 1 - avoidBad)),
    preferMtbScaleMax: p.maxMtbScale ?? undefined,
    preferElevation:
      (p.bicycleOptions?.use_hills ?? p.pedestrianOptions?.use_hills ?? 0) >= 0.5,
    eBikeAssistFactor:
      p.id === "ebike" ? 1.4 : p.id === "emtb" ? 1.6 : undefined,
  };
}

export const ROUTING_PROFILES: Record<RoutingProfile, ProfileConfig> = {
  mtb_allmountain: toLegacyConfig(RIDE_PROFILES.mtb_allmountain),
  mtb_enduro: toLegacyConfig(RIDE_PROFILES.mtb_enduro),
  downhill: toLegacyConfig(RIDE_PROFILES.downhill),
  gravel: toLegacyConfig(RIDE_PROFILES.gravel),
  road: toLegacyConfig(RIDE_PROFILES.road),
  ebike: toLegacyConfig(RIDE_PROFILES.ebike),
  emtb: toLegacyConfig(RIDE_PROFILES.emtb),
  hiking: toLegacyConfig(RIDE_PROFILES.hiking),
  urban: URBAN_PROFILE,
};

export function isRoutingProfile(id: string): id is RoutingProfile {
  return Object.prototype.hasOwnProperty.call(ROUTING_PROFILES, id);
}

/** UI-Label für Ride- und Legacy-City-Profil. */
export function profileLabel(id: RoutingProfile): string {
  return isRideProfileId(id) ? getProfile(id).label : URBAN_PROFILE.label;
}

export type ClientRouteResult = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  engine: string;
  profile: RoutingProfile;
  warnings?: string[];
  steps?: import("@/lib/routing/navSteps").NavStep[];
};

export type RequestRouteFailure = {
  ok: false;
  status: number;
  rateLimited: boolean;
  message: string;
};

export type RequestRouteSuccess = {
  ok: true;
  data: ClientRouteResult;
};

/** Client-Call an /api/route (mit Rate-Limit-Erkennung) */
export async function requestRouteDetailed(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number],
  vias: [number, number][] = []
): Promise<RequestRouteSuccess | RequestRouteFailure> {
  const qs = new URLSearchParams({
    profile,
    from: `${from[0]},${from[1]}`,
    to: `${to[0]},${to[1]}`,
  });
  for (const v of vias) {
    qs.append("via", `${v[0]},${v[1]}`);
  }
  const res = await fetch(`/api/route?${qs}`);
  if (!res.ok) {
    const text = await res.text();
    const rateLimited =
      res.status === 429 || /429|rate limit|minutely api limit/i.test(text);
    if (!rateLimited) {
      console.error("[Routing]", res.status, text.slice(0, 240));
    } else {
      console.warn("[Routing] Rate limit — weitere Engine-Calls pausiert");
    }
    return {
      ok: false,
      status: res.status,
      rateLimited,
      message: text.slice(0, 300),
    };
  }
  return { ok: true, data: await res.json() };
}

/** Client-Call an /api/route */
export async function requestRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number],
  vias: [number, number][] = []
): Promise<ClientRouteResult | null> {
  const result = await requestRouteDetailed(profile, from, to, vias);
  return result.ok ? result.data : null;
}

/** Map bike category → routing profile */
export function profileForBikeCategory(category: string): RoutingProfile {
  switch (category) {
    case "mtb_trail":
    case "mtb_am":
      return "mtb_allmountain";
    case "mtb_enduro":
      return "mtb_enduro";
    case "dh":
    case "downhill":
      return "downhill";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "urban":
      return "urban";
    case "emtb":
      return "emtb";
    case "etrekking":
    case "ebike":
      return "ebike";
    case "hiking":
      return "hiking";
    default:
      return "road";
  }
}

/**
 * Neutraler Discover-Default ohne aktives Bike.
 * Road/Radweg ist die inklusivste Basis für alle Fahrradfahrer (nicht MTB-first).
 */
export const DEFAULT_DISCOVER_PROFILE: RoutingProfile = "road";
