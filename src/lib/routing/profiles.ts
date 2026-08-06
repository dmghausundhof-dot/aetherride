/**
 * Sportartspezifische Routing-Profile
 *
 * Produktion:
 * - Self-hosted OSRM oder Valhalla
 * - Custom Lua/Lua-ähnliche Profiles oder Valhalla costing models
 * - OSM Tags: highway, surface, mtb:scale, mtb:scale:imba, trail_visibility,
 *   sac_scale, smoothness, tracktype
 *
 * Offline: vorberechnete PMTiles + graph tiles oder on-device GraphHopper Lite
 */

export type RoutingProfile =
  | "mtb_allmountain"
  | "mtb_enduro"
  | "gravel"
  | "road"
  | "ebike"
  | "hiking";

export interface ProfileConfig {
  id: RoutingProfile;
  label: string;
  prefer: string[];
  avoid: string[];
  maxSurfaceRoughness: number; // 0–1
  preferMtbScaleMax?: number;
  preferElevation: boolean;
  eBikeAssistFactor?: number;
}

export const ROUTING_PROFILES: Record<RoutingProfile, ProfileConfig> = {
  mtb_allmountain: {
    id: "mtb_allmountain",
    label: "MTB All-Mountain",
    prefer: ["path", "track", "cycleway", "mtb:scale=0-3"],
    avoid: ["motorway", "trunk", "steps"],
    maxSurfaceRoughness: 0.75,
    preferMtbScaleMax: 3,
    preferElevation: true,
  },
  mtb_enduro: {
    id: "mtb_enduro",
    label: "Enduro",
    prefer: ["path", "track", "mtb:scale=2-5"],
    avoid: ["motorway", "trunk", "primary", "steps"],
    maxSurfaceRoughness: 0.95,
    preferMtbScaleMax: 5,
    preferElevation: true,
  },
  gravel: {
    id: "gravel",
    label: "Gravel",
    prefer: ["track", "path", "unclassified", "tertiary", "surface=gravel|compacted|fine_gravel"],
    avoid: ["motorway", "trunk", "steps", "mtb:scale>=4"],
    maxSurfaceRoughness: 0.55,
    preferElevation: false,
  },
  road: {
    id: "road",
    label: "Rennrad",
    prefer: ["cycleway", "primary", "secondary", "tertiary", "surface=asphalt|paved"],
    avoid: ["path", "track", "footway", "steps", "surface=gravel|dirt|mud"],
    maxSurfaceRoughness: 0.2,
    preferElevation: false,
  },
  ebike: {
    id: "ebike",
    label: "E-Bike",
    prefer: ["cycleway", "track", "path", "tertiary"],
    avoid: ["motorway", "steps"],
    maxSurfaceRoughness: 0.7,
    preferElevation: true,
    eBikeAssistFactor: 1.4, // steilere Anstiege akzeptabel
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

/**
 * Beispiel-Call an einen Routing-Service (Produktion).
 * Hier nur Interface – echte Calls gehen an /api/route oder self-hosted OSRM.
 */
export async function requestRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): Promise<{ distanceM: number; durationS: number; geometry: GeoJSON.LineString } | null> {
  // Placeholder – in Produktion:
  // const res = await fetch(`/api/route?profile=${profile}&from=...&to=...`);
  console.log(`[Routing] ${profile}: ${from} → ${to}`);
  return null;
}
