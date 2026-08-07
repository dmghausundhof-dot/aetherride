/**
 * Server-side routing against Valhalla or OSRM (Env-configured).
 * Spec F-NAV-001 — sportartspezifische Profile.
 * Spec F-NAV-003 — Maneuver/Steps in RouteResult.
 */

import {
  ROUTING_PROFILES,
  type RoutingProfile,
} from "@/lib/routing/profiles";
import {
  stepsFromDemoGeometry,
  stepsFromOsrmLegs,
  stepsFromValhallaLeg,
  type NavStep,
} from "@/lib/routing/navSteps";

export type RouteResult = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  engine: "valhalla" | "osrm" | "demo";
  profile: RoutingProfile;
  warnings?: string[];
  /** F-NAV-003 Turn-by-Turn */
  steps?: NavStep[];
};

function engine(): "valhalla" | "osrm" | "demo" {
  const e = (process.env.ROUTING_ENGINE || "").toLowerCase();
  if (e === "valhalla" || e === "osrm") return e;
  if (process.env.VALHALLA_URL) return "valhalla";
  if (process.env.OSRM_URL) return "osrm";
  return "demo";
}

function baseUrl(kind: "valhalla" | "osrm"): string | null {
  if (kind === "valhalla") {
    return (process.env.VALHALLA_URL || "").replace(/\/$/, "") || null;
  }
  return (process.env.OSRM_URL || "").replace(/\/$/, "") || null;
}

/** Valhalla costing model per AetherRide profile.
 * Keep in sync with `mobile/packages/routing_core/native/src/profiles.rs`
 * and `data/routing/valhalla-costing.json`.
 */
export function valhallaCosting(profile: RoutingProfile): {
  costing: string;
  costing_options?: Record<string, Record<string, string | number | boolean>>;
} {
  switch (profile) {
    case "hiking":
      return {
        costing: "pedestrian",
        costing_options: {
          pedestrian: { walking_speed: 4.5, use_hills: 0.6 },
        },
      };
    case "road":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "road",
            use_roads: 0.9,
            use_hills: 0.2,
            avoid_bad_surfaces: 0.8,
          },
        },
      };
    case "gravel":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "hybrid",
            use_roads: 0.4,
            use_hills: 0.4,
            avoid_bad_surfaces: 0.3,
          },
        },
      };
    case "ebike":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "hybrid",
            use_roads: 0.5,
            use_hills: 0.85,
            avoid_bad_surfaces: 0.4,
          },
        },
      };
    case "emtb":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "mountain",
            use_roads: 0.2,
            use_hills: 0.95,
            avoid_bad_surfaces: 0.1,
          },
        },
      };
    case "mtb_enduro":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "mountain",
            use_roads: 0.1,
            use_hills: 0.9,
            avoid_bad_surfaces: 0.05,
          },
        },
      };
    case "mtb_allmountain":
    default:
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "mountain",
            use_roads: 0.25,
            use_hills: 0.75,
            avoid_bad_surfaces: 0.15,
          },
        },
      };
  }
}

/** OSRM profile name */
export function osrmProfile(profile: RoutingProfile): string {
  if (profile === "hiking") return "foot";
  return "bike";
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
  const cfg = ROUTING_PROFILES[profile];
  return {
    distanceM: Math.round(dist),
    durationS: Math.round(dist / (cfg.id === "hiking" ? 1.2 : 4.5)),
    geometry: { type: "LineString", coordinates: coords },
    engine: "demo",
    profile,
    steps: stepsFromDemoGeometry(coords),
    warnings: [
      "Kein ROUTING_ENGINE konfiguriert — Demo-Geometrie. Setze VALHALLA_URL oder OSRM_URL.",
    ],
  };
}

async function routeValhalla(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): Promise<RouteResult> {
  const base = baseUrl("valhalla");
  if (!base) throw new Error("VALHALLA_URL missing");
  const { costing, costing_options } = valhallaCosting(profile);
  const body = {
    locations: [
      { lon: from[0], lat: from[1] },
      { lon: to[0], lat: to[1] },
    ],
    costing,
    costing_options,
    directions_options: { units: "kilometers", language: "en-US" },
  };
  const res = await fetch(`${base}/route`, {
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
  };
}

async function routeOsrm(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): Promise<RouteResult> {
  const base = baseUrl("osrm");
  if (!base) throw new Error("OSRM_URL missing");
  const p = osrmProfile(profile);
  const url = `${base}/route/v1/${p}/${from[0]},${from[1]};${to[0]},${to[1]}?overview=full&geometries=geojson&steps=true&annotations=false`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`OSRM ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const route = data.routes?.[0];
  if (!route?.geometry) throw new Error("OSRM: no route");
  const geometry = route.geometry as GeoJSON.LineString;
  const steps = stepsFromOsrmLegs(route.legs ?? []);
  return {
    distanceM: Math.round(route.distance),
    durationS: Math.round(route.duration),
    geometry,
    engine: "osrm",
    profile,
    steps: steps.length
      ? steps
      : stepsFromDemoGeometry(geometry.coordinates as [number, number][]),
  };
}

export async function computeRoute(
  profile: RoutingProfile,
  from: [number, number],
  to: [number, number]
): Promise<RouteResult> {
  const kind = engine();
  if (kind === "demo") return demoRoute(profile, from, to);
  if (kind === "valhalla") return routeValhalla(profile, from, to);
  return routeOsrm(profile, from, to);
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
