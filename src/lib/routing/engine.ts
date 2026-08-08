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
  engine: "valhalla" | "osrm" | "graphhopper" | "demo";
  profile: RoutingProfile;
  warnings?: string[];
  /** F-NAV-003 Turn-by-Turn */
  steps?: NavStep[];
};

function engine(): "valhalla" | "osrm" | "graphhopper" | "demo" {
  const e = (process.env.ROUTING_ENGINE || "").toLowerCase();
  if (e === "valhalla" || e === "osrm" || e === "graphhopper") return e;
  if (process.env.GRAPHHOPPER_API_KEY) return "graphhopper";
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
    case "urban":
      return {
        costing: "bicycle",
        costing_options: {
          bicycle: {
            bicycle_type: "hybrid",
            use_roads: 0.75,
            use_hills: 0.15,
            avoid_bad_surfaces: 0.7,
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
      case "emtb":
        return "mtb";
      case "gravel":
      case "ebike":
      case "urban":
      default:
        return "bike";
    }
  }
  return profile === "hiking" ? "foot" : "bike";
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
      "Kein ROUTING_ENGINE konfiguriert — Demo-Geometrie. Setze GRAPHHOPPER_API_KEY, VALHALLA_URL oder OSRM_URL.",
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
  };
}

function stepsFromGraphhopper(
  instructions: Array<{
    text?: string;
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
    });
    along += lengthM;
  }
  return steps;
}

async function routeGraphhopper(
  profile: RoutingProfile,
  points: [number, number][]
): Promise<RouteResult> {
  const key = process.env.GRAPHHOPPER_API_KEY?.trim();
  if (!key) throw new Error("GRAPHHOPPER_API_KEY missing");
  if (points.length < 2) throw new Error("GraphHopper: need ≥2 points");
  const base = (
    process.env.GRAPHHOPPER_URL || "https://graphhopper.com/api/1"
  ).replace(/\/$/, "");
  const ghProfile = graphhopperProfile(profile);
  const params = new URLSearchParams();
  // GraphHopper expects lat,lng
  for (const [lng, lat] of points) {
    params.append("point", `${lat},${lng}`);
  }
  params.set("profile", ghProfile);
  params.set("locale", "de");
  params.set("points_encoded", "false");
  params.set("elevation", "true");
  params.set("instructions", "true");
  params.set("key", key);

  const res = await fetch(`${base}/route?${params}`);
  if (!res.ok) {
    throw new Error(`GraphHopper ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const path = data.paths?.[0];
  if (!path?.points?.coordinates) throw new Error("GraphHopper: no path");

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
    process.env.GRAPHHOPPER_ALLOW_EXTENDED_PROFILES !== "1" &&
    (profile.startsWith("mtb") || profile === "emtb" || profile === "hiking")
  ) {
    warnings.push(
      `GraphHopper-Account: Profil „${ghProfile}“ (Basic). Für mtb/hike GRAPHHOPPER_ALLOW_EXTENDED_PROFILES=1 nach Plan-Upgrade.`
    );
  }

  return {
    distanceM: Math.round(path.distance || 0),
    durationS: Math.round((path.time || 0) / 1000),
    geometry,
    engine: "graphhopper",
    profile,
    steps: steps.length
      ? steps
      : stepsFromDemoGeometry(coordinates),
    warnings: warnings.length ? warnings : undefined,
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
  to: [number, number],
  vias: [number, number][] = []
): Promise<RouteResult> {
  const points = [from, ...vias, to];
  const kind = engine();
  if (kind === "demo") return demoRoute(profile, from, to);

  try {
    if (kind === "graphhopper") return await routeGraphhopper(profile, points);
    if (kind === "valhalla") {
      if (vias.length === 0) return await routeValhalla(profile, from, to);
      const parts: RouteResult[] = [];
      let prev = from;
      for (const p of [...vias, to]) {
        parts.push(await routeValhalla(profile, prev, p));
        prev = p;
      }
      return {
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
      };
    }
    if (vias.length === 0) return await routeOsrm(profile, from, to);
    const parts: RouteResult[] = [];
    let prev = from;
    for (const p of [...vias, to]) {
      parts.push(await routeOsrm(profile, prev, p));
      prev = p;
    }
    return {
      distanceM: parts.reduce((a, p) => a + p.distanceM, 0),
      durationS: parts.reduce((a, p) => a + p.durationS, 0),
      geometry: {
        type: "LineString",
        coordinates: parts.flatMap((p, i) =>
          i === 0 ? p.geometry.coordinates : p.geometry.coordinates.slice(1)
        ),
      },
      engine: "osrm",
      profile,
      steps: parts.flatMap((p) => p.steps ?? []),
    };
  } catch (e) {
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
}

/** Welche Engine ist konfiguriert (ohne Netzwerk-Probe). */
export function configuredRoutingEngine(): RouteResult["engine"] {
  return engine();
}

export function isLiveRoutingConfigured(): boolean {
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
