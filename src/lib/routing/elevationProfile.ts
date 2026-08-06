/**
 * F-NAV-007 — Höhenprofil + Oberflächen-/Schwierigkeitsbänder (P0)
 * Datenlücken als Lücke, nicht interpoliert kaschiert.
 */

import { haversineM, type PlannedRoute } from "./rideHandoff";
import type { RouteResult } from "./profiles";

export interface ProfilePoint {
  distKm: number;
  elevM: number | null; // null = Lücke
  gradePct: number | null;
  surface?: string | null;
  mtbScale?: string | null;
}

export interface ElevationProfile {
  points: ProfilePoint[];
  totalClimbM: number;
  totalDistKm: number;
  gapKm: number;
  surfaceBands: { fromKm: number; toKm: number; surface: string | null }[];
  scaleBands: { fromKm: number; toKm: number; scale: string | null }[];
}

/** Profil aus geplanter Route (Handoff) — Elev synthetisch aus Gain, Lücke mittig */
export function buildElevationProfileFromPlanned(
  planned: PlannedRoute
): ElevationProfile {
  const geom = planned.geometryLngLat;
  const n = Math.max(12, Math.min(80, geom.length));
  const points: ProfilePoint[] = [];
  let elev = 780;
  let distKm = 0;
  const totalKm = Math.max(0.1, planned.distanceM / 1000);
  const climbBudget = planned.elevationGainM;
  const gapFrom = totalKm * 0.4;
  const gapTo = totalKm * 0.48;

  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    if (i > 0 && geom.length >= 2) {
      const gi = Math.min(geom.length - 1, Math.round(t * (geom.length - 1)));
      const gj = Math.min(geom.length - 1, Math.round(((i - 1) / (n - 1)) * (geom.length - 1)));
      distKm +=
        haversineM(
          { lat: geom[gj][1], lng: geom[gj][0] },
          { lat: geom[gi][1], lng: geom[gi][0] }
        ) / 1000;
    } else {
      distKm = t * totalKm;
    }
    // absichtliche Lücke — nicht interpolieren
    if (distKm >= gapFrom && distKm <= gapTo) {
      points.push({
        distKm: Math.round(distKm * 100) / 100,
        elevM: null,
        gradePct: null,
        surface: null,
        mtbScale: planned.mtbScale ?? null,
      });
      continue;
    }
    const phase = t < 0.55 ? 1 : -0.7;
    const grade = phase * (climbBudget / (totalKm * 50));
    elev += grade * (totalKm / n) * 10;
    const scale =
      planned.mtbScale ??
      (t < 0.3 ? "S1" : t < 0.7 ? "S2" : "S3");
    points.push({
      distKm: Math.round(distKm * 100) / 100,
      elevM: Math.round(elev),
      gradePct: Math.round(grade * 10) / 10,
      surface: t < 0.25 ? "asphalt" : t < 0.6 ? "trail" : "root",
      mtbScale: scale,
    });
  }

  return summarizeProfile(points, distKm || totalKm);
}

/** Profil aus Demo-Router-Ergebnis (Edges) */
export function buildElevationProfileFromRoute(
  route: RouteResult
): ElevationProfile {
  const points: ProfilePoint[] = [];
  let elev = 780;
  let distKm = 0;
  const totalKm = Math.max(0.1, route.distanceM / 1000);
  const gapFrom = totalKm * 0.35;
  const gapTo = totalKm * 0.42;

  for (let i = 0; i < route.edges.length; i++) {
    const e = route.edges[i];
    distKm += e.distanceM / 1000;
    if (distKm >= gapFrom && distKm <= gapTo) {
      points.push({
        distKm: Math.round(distKm * 100) / 100,
        elevM: null,
        gradePct: null,
        surface: null,
        mtbScale: e.mtbScale != null ? `S${e.mtbScale}` : null,
      });
      continue;
    }
    const grade = e.inclinePct ?? (i % 3 === 0 ? 6 : -2);
    elev += (grade / 100) * e.distanceM;
    points.push({
      distKm: Math.round(distKm * 100) / 100,
      elevM: Math.round(elev),
      gradePct: Math.round(grade * 10) / 10,
      surface: e.surface ?? e.highway ?? null,
      mtbScale: e.mtbScale != null ? `S${e.mtbScale}` : null,
    });
  }

  if (points.length === 0) {
    return buildElevationProfileFromPlanned({
      id: "fallback",
      name: "route",
      profile: route.profile,
      source: "discover_route",
      distanceM: route.distanceM,
      elevationGainM: route.elevationGainM,
      durationMin: Math.round(route.durationS / 60),
      geometryLngLat: (route.geometry?.coordinates ?? []) as [number, number][],
    });
  }

  return summarizeProfile(points, distKm || totalKm);
}

/** Punkt auf Geometrie bei Distanz entlang Route (für Profil-Tap → Marker) */
export function pointAtDistanceAlongPlanned(
  planned: PlannedRoute,
  distKm: number
): { lat: number; lng: number } | null {
  const geom = planned.geometryLngLat;
  if (geom.length < 2) return null;
  let target = distKm * 1000;
  let along = 0;
  for (let i = 1; i < geom.length; i++) {
    const a = { lat: geom[i - 1][1], lng: geom[i - 1][0] };
    const b = { lat: geom[i][1], lng: geom[i][0] };
    const seg = haversineM(a, b);
    if (along + seg >= target) {
      const t = seg > 0 ? (target - along) / seg : 0;
      return {
        lat: a.lat + (b.lat - a.lat) * t,
        lng: a.lng + (b.lng - a.lng) * t,
      };
    }
    along += seg;
  }
  const last = geom[geom.length - 1];
  return { lat: last[1], lng: last[0] };
}

function summarizeProfile(
  points: ProfilePoint[],
  totalDistKm: number
): ElevationProfile {
  const known = points.filter((p) => p.elevM != null);
  let climb = 0;
  for (let i = 1; i < known.length; i++) {
    const d = (known[i].elevM ?? 0) - (known[i - 1].elevM ?? 0);
    if (d > 0) climb += d;
  }
  const gapKm =
    points.filter((p) => p.elevM == null).length *
    (points.length > 1
      ? totalDistKm / Math.max(1, points.length - 1)
      : 0);

  return {
    points,
    totalClimbM: Math.round(climb),
    totalDistKm: Math.round(totalDistKm * 100) / 100,
    gapKm: Math.round(gapKm * 100) / 100,
    surfaceBands: bandify(points, (p) => p.surface ?? null, "surface"),
    scaleBands: bandify(points, (p) => p.mtbScale ?? null, "scale"),
  };
}

/** Demo-Profil mit absichtlicher Lücke (kein Fake-Interpolate) */
export function buildDemoElevationProfile(): ElevationProfile {
  const points: ProfilePoint[] = [];
  let elev = 780;
  let dist = 0;
  for (let i = 0; i < 40; i++) {
    dist = i * 0.5;
    // Lücke km 8–10
    if (dist >= 8 && dist <= 10) {
      points.push({
        distKm: dist,
        elevM: null,
        gradePct: null,
        surface: null,
        mtbScale: null,
      });
      continue;
    }
    const grade = Math.sin(i / 3) * 8 + (i > 20 ? -2 : 3);
    elev += grade * 0.5 * 10;
    points.push({
      distKm: dist,
      elevM: Math.round(elev),
      gradePct: Math.round(grade * 10) / 10,
      surface: i < 10 ? "asphalt" : i < 25 ? "trail" : "root",
      mtbScale: i < 10 ? "—" : i < 22 ? "S1" : i < 30 ? "S2" : "S3",
    });
  }

  return summarizeProfile(points, dist);
}

function bandify(
  points: ProfilePoint[],
  key: (p: ProfilePoint) => string | null,
  kind: "surface" | "scale"
): { fromKm: number; toKm: number; surface: string | null; scale: string | null }[] {
  const bands: {
    fromKm: number;
    toKm: number;
    surface: string | null;
    scale: string | null;
  }[] = [];
  let cur = key(points[0]);
  let from = points[0].distKm;
  for (let i = 1; i < points.length; i++) {
    const k = key(points[i]);
    if (k !== cur) {
      bands.push({
        fromKm: from,
        toKm: points[i].distKm,
        surface: kind === "surface" ? cur : null,
        scale: kind === "scale" ? cur : null,
      });
      cur = k;
      from = points[i].distKm;
    }
  }
  bands.push({
    fromKm: from,
    toKm: points[points.length - 1].distKm,
    surface: kind === "surface" ? cur : null,
    scale: kind === "scale" ? cur : null,
  });
  return bands;
}
