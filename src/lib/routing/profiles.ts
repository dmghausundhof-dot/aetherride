/**
 * Sportartspezifische Routing-Profile (Spec F-NAV-001 — 7 Profile)
 *
 * Produktion:
 * - Self-hosted OSRM oder Valhalla (VALHALLA_URL / OSRM_URL / ROUTING_ENGINE)
 * - OSM Tags: highway, surface, mtb:scale, trail_visibility, sac_scale, …
 * - Offline: PMTiles (NEXT_PUBLIC_PMTILES_URL) + Graph-Service / Valhalla FFI
 */

export type RoutingProfile =
  | "mtb_allmountain"
  | "mtb_enduro"
  | "gravel"
  | "road"
  | "ebike"
  | "emtb"
  | "hiking";

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

export const ROUTING_PROFILES: Record<RoutingProfile, ProfileConfig> = {
  mtb_allmountain: {
    id: "mtb_allmountain",
    label: "MTB Trail / All-Mountain",
    prefer: ["path", "track", "cycleway", "mtb:scale=0-3"],
    avoid: ["motorway", "trunk", "steps"],
    maxSurfaceRoughness: 0.75,
    preferMtbScaleMax: 3,
    preferElevation: true,
  },
  mtb_enduro: {
    id: "mtb_enduro",
    label: "Enduro / DH-leaning",
    prefer: ["path", "track", "mtb:scale=2-5", "mtb:scale:imba"],
    avoid: ["motorway", "trunk", "primary", "steps"],
    maxSurfaceRoughness: 0.95,
    preferMtbScaleMax: 5,
    preferElevation: true,
  },
  gravel: {
    id: "gravel",
    label: "Gravel",
    prefer: [
      "track",
      "path",
      "unclassified",
      "tertiary",
      "surface=gravel|compacted|fine_gravel",
    ],
    avoid: ["motorway", "trunk", "steps", "mtb:scale>=4"],
    maxSurfaceRoughness: 0.55,
    preferElevation: false,
  },
  road: {
    id: "road",
    label: "Rennrad",
    prefer: [
      "cycleway",
      "primary",
      "secondary",
      "tertiary",
      "surface=asphalt|paved",
    ],
    avoid: ["path", "track", "footway", "steps", "surface=gravel|dirt|mud"],
    maxSurfaceRoughness: 0.2,
    preferElevation: false,
  },
  ebike: {
    id: "ebike",
    label: "E-Bike Tour",
    prefer: ["cycleway", "track", "path", "tertiary"],
    avoid: ["motorway", "steps", "mtb:scale>=4"],
    maxSurfaceRoughness: 0.65,
    preferElevation: true,
    eBikeAssistFactor: 1.4,
  },
  emtb: {
    id: "emtb",
    label: "E-MTB",
    prefer: ["path", "track", "mtb:scale=0-4", "cycleway"],
    avoid: ["motorway", "trunk", "steps"],
    maxSurfaceRoughness: 0.85,
    preferMtbScaleMax: 4,
    preferElevation: true,
    eBikeAssistFactor: 1.6,
  },
  hiking: {
    id: "hiking",
    label: "Wandern",
    prefer: ["path", "footway", "track", "sac_scale=hiking|mountain_hiking"],
    avoid: ["motorway", "trunk", "primary"],
    maxSurfaceRoughness: 0.9,
    preferElevation: true,
  },
};

export type ClientRouteResult = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  engine: string;
  profile: RoutingProfile;
  warnings?: string[];
};

/** Client-Call an /api/route */
export async function requestRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): Promise<ClientRouteResult | null> {
  const qs = new URLSearchParams({
    profile,
    from: `${from[0]},${from[1]}`,
    to: `${to[0]},${to[1]}`,
  });
  const res = await fetch(`/api/route?${qs}`);
  if (!res.ok) {
    console.error("[Routing]", res.status, await res.text());
    return null;
  }
  return res.json();
}

/** Map bike category → routing profile */
export function profileForBikeCategory(category: string): RoutingProfile {
  switch (category) {
    case "mtb_enduro":
    case "dh":
      return "mtb_enduro";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "emtb":
      return "emtb";
    case "etrekking":
    case "ebike":
    case "urban":
      return "ebike";
    case "hiking":
      return "hiking";
    default:
      return "mtb_allmountain";
  }
}
