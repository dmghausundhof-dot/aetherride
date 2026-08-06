/**
 * F-NAV-001 — Sieben Spec-Profile mit eigener Kostenfunktion
 *
 * Spec-IDs: MTB_TRAIL, MTB_ENDURO, GRAVEL, ROAD, EBIKE_TOUR, EMTB, HIKING
 * OSM-Tags only; fehlendes Tagging → Unsicherheitsmarkierung, kein Optimismus.
 *
 * Produktion: Valhalla costing (online = offline, Spec 5.4).
 */

export type RoutingProfile =
  | "MTB_TRAIL"
  | "MTB_ENDURO"
  | "GRAVEL"
  | "ROAD"
  | "EBIKE_TOUR"
  | "EMTB"
  | "HIKING";

/** Legacy-Alias für bestehenden Demo-Code */
export type LegacyRoutingProfile =
  | "mtb_allmountain"
  | "mtb_enduro"
  | "gravel"
  | "road"
  | "ebike"
  | "hiking";

export interface CostWeights {
  /** Bevorzuge mtb:scale in [min,max] */
  mtbScalePrefer?: [number, number];
  mtbScaleAvoidAbove?: number;
  /** sac_scale für Hiking */
  sacPrefer?: string[];
  surfacePrefer: string[];
  surfaceAvoid: string[];
  highwayPrefer: string[];
  highwayAvoid: string[];
  /** Steigung: höher = mehr Hm akzeptabel */
  elevationAppetite: number;
  useRoads: number; // 0–1 Valhalla-ähnlich
  avoidBadSurfaces: number;
  turnPenalty: number;
  /** E-Bike: steilere Anstiege akzeptabler */
  eBikeAssistFactor?: number;
}

export interface ProfileConfig {
  id: RoutingProfile;
  label: string;
  costing: CostWeights;
  /** OSM-Tag-Grundlage (Dokumentation) */
  osmTags: string[];
}

export const ROUTING_PROFILES: Record<RoutingProfile, ProfileConfig> = {
  MTB_TRAIL: {
    id: "MTB_TRAIL",
    label: "MTB Trail",
    osmTags: ["highway", "surface", "mtb:scale", "smoothness", "tracktype"],
    costing: {
      mtbScalePrefer: [0, 3],
      mtbScaleAvoidAbove: 5,
      surfacePrefer: ["dirt", "compacted", "gravel", "ground"],
      surfaceAvoid: ["paving_stones"],
      highwayPrefer: ["path", "track", "cycleway"],
      highwayAvoid: ["motorway", "trunk", "steps"],
      elevationAppetite: 0.7,
      useRoads: 0.15,
      avoidBadSurfaces: 0.35,
      turnPenalty: 8,
    },
  },
  MTB_ENDURO: {
    id: "MTB_ENDURO",
    label: "MTB Enduro",
    osmTags: ["mtb:scale", "mtb:scale:uphill", "surface", "trail_visibility"],
    costing: {
      mtbScalePrefer: [2, 5],
      surfacePrefer: ["dirt", "ground", "rock"],
      surfaceAvoid: ["asphalt"],
      highwayPrefer: ["path", "track"],
      highwayAvoid: ["motorway", "trunk", "primary", "steps"],
      elevationAppetite: 0.95,
      useRoads: 0.05,
      avoidBadSurfaces: 0.1,
      turnPenalty: 5,
    },
  },
  GRAVEL: {
    id: "GRAVEL",
    label: "Gravel",
    osmTags: ["surface", "smoothness", "tracktype", "network"],
    costing: {
      mtbScaleAvoidAbove: 3,
      surfacePrefer: ["gravel", "compacted", "fine_gravel", "asphalt"],
      surfaceAvoid: ["mud", "sand"],
      highwayPrefer: ["track", "unclassified", "tertiary", "cycleway"],
      highwayAvoid: ["motorway", "trunk", "steps"],
      elevationAppetite: 0.45,
      useRoads: 0.4,
      avoidBadSurfaces: 0.45,
      turnPenalty: 10,
    },
  },
  ROAD: {
    id: "ROAD",
    label: "Rennrad",
    osmTags: ["highway", "surface", "cycleway", "smoothness"],
    costing: {
      surfacePrefer: ["asphalt", "paved", "concrete"],
      surfaceAvoid: ["gravel", "dirt", "mud", "sand"],
      highwayPrefer: ["cycleway", "primary", "secondary", "tertiary"],
      highwayAvoid: ["path", "track", "footway", "steps"],
      elevationAppetite: 0.25,
      useRoads: 0.85,
      avoidBadSurfaces: 0.9,
      turnPenalty: 12,
    },
  },
  EBIKE_TOUR: {
    id: "EBIKE_TOUR",
    label: "E-Bike Tour",
    osmTags: ["highway", "surface", "bicycle", "access", "incline"],
    costing: {
      surfacePrefer: ["asphalt", "compacted", "gravel"],
      surfaceAvoid: ["mud"],
      highwayPrefer: ["cycleway", "track", "tertiary", "secondary"],
      highwayAvoid: ["motorway", "steps"],
      elevationAppetite: 0.75,
      useRoads: 0.5,
      avoidBadSurfaces: 0.4,
      turnPenalty: 9,
      eBikeAssistFactor: 1.5,
    },
  },
  EMTB: {
    id: "EMTB",
    label: "E-MTB",
    osmTags: ["mtb:scale", "surface", "tracktype", "incline"],
    costing: {
      mtbScalePrefer: [0, 4],
      surfacePrefer: ["dirt", "compacted", "gravel"],
      surfaceAvoid: [],
      highwayPrefer: ["path", "track", "cycleway"],
      highwayAvoid: ["motorway", "trunk", "steps"],
      elevationAppetite: 0.9,
      useRoads: 0.2,
      avoidBadSurfaces: 0.25,
      turnPenalty: 7,
      eBikeAssistFactor: 1.6,
    },
  },
  HIKING: {
    id: "HIKING",
    label: "Wandern",
    osmTags: ["sac_scale", "trail_visibility", "highway", "foot", "incline"],
    costing: {
      sacPrefer: ["hiking", "mountain_hiking", "demanding_mountain_hiking"],
      surfacePrefer: ["ground", "dirt", "grass", "rock"],
      surfaceAvoid: [],
      highwayPrefer: ["path", "footway", "track", "steps"],
      highwayAvoid: ["motorway", "trunk", "primary"],
      elevationAppetite: 0.85,
      useRoads: 0.1,
      avoidBadSurfaces: 0.2,
      turnPenalty: 4,
    },
  },
};

export function legacyToSpec(p: LegacyRoutingProfile | RoutingProfile): RoutingProfile {
  const map: Record<string, RoutingProfile> = {
    mtb_allmountain: "MTB_TRAIL",
    mtb_enduro: "MTB_ENDURO",
    gravel: "GRAVEL",
    road: "ROAD",
    ebike: "EBIKE_TOUR",
    hiking: "HIKING",
    MTB_TRAIL: "MTB_TRAIL",
    MTB_ENDURO: "MTB_ENDURO",
    GRAVEL: "GRAVEL",
    ROAD: "ROAD",
    EBIKE_TOUR: "EBIKE_TOUR",
    EMTB: "EMTB",
    HIKING: "HIKING",
  };
  return map[p] ?? "MTB_TRAIL";
}

export interface RouteEdgeDemo {
  id: string;
  distanceM: number;
  highway: string;
  surface?: string;
  mtbScale?: number;
  sacScale?: string;
  bicycleAccess?: "yes" | "no" | "dismount" | "unknown";
  /** Demo/OSM: offizielle MTB-Freigabe (z. B. Tirol-Modell) */
  mtbOfficial?: boolean;
  widthM?: number;
  /** Querfeldein — immer block */
  offTrail?: boolean;
  inclinePct?: number;
  latlng: [number, number][];
}

export interface RouteResult {
  profile: RoutingProfile;
  distanceM: number;
  durationS: number;
  elevationGainM: number;
  geometry: GeoJSON.LineString;
  uncertainKm: number;
  uncertainShare: number;
  accessWarnings: string[];
  blocked: boolean;
  /** Volle Findings für Mehr-Modus */
  accessFindings?: import("./accessRights").AccessFinding[];
  jurisdiction?: import("./accessRights").JurisdictionId;
  edges: RouteEdgeDemo[];
  costingNote: string;
}

/**
 * Demo-Router mit Spec-Kostenfunktion auf synthetischen Kanten.
 * Produktion: Valhalla FFI /api/route — identisch online/offline.
 */
export async function requestRoute(
  profile: RoutingProfile | LegacyRoutingProfile,
  from: [number, number],
  to: [number, number],
  jurisdiction: import("./accessRights").JurisdictionId = "AT-7"
): Promise<RouteResult | null> {
  const id = legacyToSpec(profile);
  const cfg = ROUTING_PROFILES[id];
  const { scoreDemoRoute } = await import("./engine");
  return scoreDemoRoute(cfg, from, to, jurisdiction);
}
