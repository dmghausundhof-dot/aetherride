/**
 * F-NAV-001 Demo-Kostenfunktion + Unsicherheitsanteil
 * Produktion: Valhalla dynamic costing (mtb:scale, surface, turn_penalty).
 */

import type { ProfileConfig, RouteEdgeDemo, RouteResult, RoutingProfile } from "./profiles";
import { evaluateAccessForEdges } from "./accessRights";

function haversineM(a: [number, number], b: [number, number]): number {
  const R = 6371000;
  const toR = (d: number) => (d * Math.PI) / 180;
  const dLat = toR(b[0] - a[0]);
  const dLon = toR(b[1] - a[1]);
  const lat1 = toR(a[0]);
  const lat2 = toR(b[0]);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Synthetische Kette von OSM-ähnlichen Kanten zwischen from/to */
function buildDemoEdges(
  from: [number, number],
  to: [number, number],
  profile: RoutingProfile
): RouteEdgeDemo[] {
  const steps = 6;
  const edges: RouteEdgeDemo[] = [];
  for (let i = 0; i < steps; i++) {
    const t0 = i / steps;
    const t1 = (i + 1) / steps;
    const a: [number, number] = [
      from[0] + (to[0] - from[0]) * t0,
      from[1] + (to[1] - from[1]) * t0,
    ];
    const b: [number, number] = [
      from[0] + (to[0] - from[0]) * t1,
      from[1] + (to[1] - from[1]) * t1,
    ];
    const dist = haversineM(a, b);
    const kind = i % 3;
    if (profile === "HIKING") {
      edges.push({
        id: `e${i}`,
        distanceM: dist,
        highway: kind === 0 ? "path" : "footway",
        surface: kind === 2 ? undefined : "ground",
        sacScale: kind === 1 ? "mountain_hiking" : "hiking",
        bicycleAccess: "no",
        inclinePct: 8 + kind * 4,
        latlng: [a, b],
      });
    } else if (profile === "ROAD") {
      edges.push({
        id: `e${i}`,
        distanceM: dist,
        highway: kind === 0 ? "cycleway" : "tertiary",
        surface: "asphalt",
        bicycleAccess: "yes",
        inclinePct: 2 + kind,
        latlng: [a, b],
      });
    } else {
      edges.push({
        id: `e${i}`,
        distanceM: dist,
        highway: kind === 0 ? "path" : kind === 1 ? "track" : "cycleway",
        surface: kind === 2 ? undefined : kind === 0 ? "dirt" : "gravel",
        mtbScale: kind === 0 ? 2 : kind === 1 ? 1 : undefined,
        bicycleAccess: kind === 1 ? "unknown" : "yes",
        inclinePct: 6 + kind * 5,
        latlng: [a, b],
      });
    }
  }
  // Demo: eine potenziell problematische Kante für Wegerecht
  if (profile !== "HIKING" && profile !== "ROAD") {
    edges.push({
      id: "e_access",
      distanceM: 180,
      highway: "path",
      surface: "ground",
      mtbScale: 1,
      bicycleAccess: "no",
      inclinePct: 4,
      latlng: [to, [to[0] + 0.001, to[1] + 0.001]],
    });
  }
  return edges;
}

function edgeCost(edge: RouteEdgeDemo, cfg: ProfileConfig): number {
  const w = cfg.costing;
  let cost = edge.distanceM;

  if (w.highwayAvoid.includes(edge.highway)) cost *= 50;
  if (w.highwayPrefer.includes(edge.highway)) cost *= 0.75;

  if (!edge.surface) {
    // Unsicher — nicht optimistisch, leichte Penalty + Markierung extern
    cost *= 1.15;
  } else if (w.surfaceAvoid.includes(edge.surface)) {
    cost *= 1 + w.avoidBadSurfaces * 3;
  } else if (w.surfacePrefer.includes(edge.surface)) {
    cost *= 0.85;
  }

  if (edge.mtbScale != null && w.mtbScalePrefer) {
    const [lo, hi] = w.mtbScalePrefer;
    if (edge.mtbScale < lo || edge.mtbScale > hi) cost *= 1.4;
    if (w.mtbScaleAvoidAbove != null && edge.mtbScale > w.mtbScaleAvoidAbove)
      cost *= 8;
  }

  if (edge.inclinePct != null) {
    const steep = Math.max(0, edge.inclinePct - 5);
    cost *= 1 + steep * (1 - w.elevationAppetite) * 0.04;
    if (w.eBikeAssistFactor) {
      cost /= 1 + (w.eBikeAssistFactor - 1) * Math.min(1, steep / 15);
    }
  }

  cost += w.turnPenalty * 2;
  return cost;
}

export function scoreDemoRoute(
  cfg: ProfileConfig,
  from: [number, number],
  to: [number, number]
): RouteResult {
  const edges = buildDemoEdges(from, to, cfg.id);
  // sortiere/wähle: hier linear; Kosten nur zur Transparenz
  let totalCost = 0;
  let distanceM = 0;
  let uncertainM = 0;
  let elev = 0;

  for (const e of edges) {
    totalCost += edgeCost(e, cfg);
    distanceM += e.distanceM;
    if (
      !e.surface ||
      (e.mtbScale == null && cfg.id.startsWith("MTB"))
    ) {
      uncertainM += e.distanceM;
    }
    if (cfg.id === "HIKING" && !e.sacScale) uncertainM += e.distanceM;
    elev += Math.max(0, (e.inclinePct ?? 0) * (e.distanceM / 100));
  }

  const access = evaluateAccessForEdges(edges, "AT-7");
  const usable = access.blocked
    ? edges.filter((e) => !access.blockedEdgeIds.has(e.id))
    : edges;

  const coords = usable.flatMap((e) => e.latlng);
  const durationS = Math.round(
    (distanceM / 1000 / (cfg.id === "HIKING" ? 4 : 14)) * 3600
  );

  return {
    profile: cfg.id,
    distanceM: Math.round(distanceM),
    durationS,
    elevationGainM: Math.round(elev),
    geometry: {
      type: "LineString",
      coordinates: coords.map(([lat, lng]) => [lng, lat]),
    },
    uncertainKm: Math.round((uncertainM / 1000) * 100) / 100,
    uncertainShare: distanceM ? uncertainM / distanceM : 0,
    accessWarnings: access.warnings,
    blocked: access.blocked && usable.length === 0,
    edges: usable,
    costingNote: `Demo-Kosten ${Math.round(totalCost)} · Valhalla in Produktion (G-0). Unsichere km ausgewiesen, nicht optimistisch bewertet.`,
  };
}
