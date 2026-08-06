/**
 * Discover → Ride Handoff + Track-Geometrie-Helfer
 * Web-Demo: synthetische Polylines / Demo-Router-Geometrie.
 */

import type { RoutingProfile, RouteResult } from "./profiles";
import type { RouteSuggestion } from "./suggestions";
import type { JurisdictionId } from "./accessRights";

export interface PlannedRoute {
  id: string;
  name: string;
  profile: RoutingProfile | string;
  source: "discover_route" | "discover_suggestion";
  distanceM: number;
  elevationGainM: number;
  durationMin: number;
  /** GeoJSON-Reihenfolge: [lng, lat] */
  geometryLngLat: [number, number][];
  jurisdiction?: JurisdictionId;
  mtbScale?: string;
}

export type TrackPoint = {
  lat: number;
  lng: number;
  elev?: number;
  time: number;
};

export function haversineM(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
  const R = 6371000;
  const toR = (d: number) => (d * Math.PI) / 180;
  const dLat = toR(b.lat - a.lat);
  const dLon = toR(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toR(a.lat)) * Math.cos(toR(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

export function trackDistanceM(pts: { lat: number; lng: number }[]): number {
  let d = 0;
  for (let i = 1; i < pts.length; i++) d += haversineM(pts[i - 1], pts[i]);
  return d;
}

export function lineStringToLngLat(
  geometry: GeoJSON.LineString | undefined | null
): [number, number][] {
  if (!geometry?.coordinates?.length) return [];
  return geometry.coordinates.map((c) => [c[0], c[1]] as [number, number]);
}

/** Demo-Polyline um Alpbach für Vorschläge ohne Router-Geometrie */
export function buildDemoGeometryForSuggestion(
  s: Pick<RouteSuggestion, "id" | "distanceKm" | "loop">
): [number, number][] {
  const n = Math.max(24, Math.min(120, Math.round(s.distanceKm * 2)));
  const baseLat = 47.45 + (hash(s.id) % 20) * 0.001;
  const baseLng = 12.15 + (hash(s.id) % 15) * 0.0015;
  const scale = Math.sqrt(s.distanceKm / 25);
  const pts: [number, number][] = [];
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    const angle = s.loop ? t * Math.PI * 2 : t * Math.PI * 0.85;
    const lat = baseLat + Math.sin(angle) * 0.012 * scale + t * 0.002 * scale;
    const lng = baseLng + Math.cos(angle) * 0.018 * scale + t * 0.01 * scale;
    pts.push([lng, lat]);
  }
  return pts;
}

function hash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return Math.abs(h);
}

export function plannedRouteFromRouteResult(
  r: RouteResult,
  name = "Demo-Route"
): PlannedRoute | null {
  const geometryLngLat = lineStringToLngLat(r.geometry);
  if (geometryLngLat.length < 2) return null;
  return {
    id: `route-${r.profile}-${Date.now()}`,
    name,
    profile: r.profile,
    source: "discover_route",
    distanceM: r.distanceM,
    elevationGainM: r.elevationGainM,
    durationMin: Math.max(1, Math.round(r.durationS / 60)),
    geometryLngLat,
    jurisdiction: r.jurisdiction,
  };
}

export function plannedRouteFromSuggestion(s: RouteSuggestion): PlannedRoute {
  return {
    id: s.id,
    name: s.name,
    profile: s.category,
    source: "discover_suggestion",
    distanceM: Math.round(s.distanceKm * 1000),
    elevationGainM: s.elevationM,
    durationMin: s.durationMin,
    geometryLngLat: buildDemoGeometryForSuggestion(s),
    mtbScale: s.mtbScale,
  };
}

/** Punkt entlang der geplanten Linie nach Fortschritt 0…1 */
export function pointAlongGeometry(
  geometryLngLat: [number, number][],
  progress01: number
): { lat: number; lng: number } {
  if (geometryLngLat.length === 0) return { lat: 47.45, lng: 12.15 };
  if (geometryLngLat.length === 1) {
    return { lat: geometryLngLat[0][1], lng: geometryLngLat[0][0] };
  }
  const p = Math.min(1, Math.max(0, progress01));
  const total = trackDistanceM(
    geometryLngLat.map(([lng, lat]) => ({ lat, lng }))
  );
  if (total <= 0) {
    const last = geometryLngLat[geometryLngLat.length - 1];
    return { lat: last[1], lng: last[0] };
  }
  const target = p * total;
  let acc = 0;
  for (let i = 1; i < geometryLngLat.length; i++) {
    const a = { lat: geometryLngLat[i - 1][1], lng: geometryLngLat[i - 1][0] };
    const b = { lat: geometryLngLat[i][1], lng: geometryLngLat[i][0] };
    const seg = haversineM(a, b);
    if (acc + seg >= target) {
      const t = seg > 0 ? (target - acc) / seg : 0;
      return {
        lat: a.lat + (b.lat - a.lat) * t,
        lng: a.lng + (b.lng - a.lng) * t,
      };
    }
    acc += seg;
  }
  const last = geometryLngLat[geometryLngLat.length - 1];
  return { lat: last[1], lng: last[0] };
}

export function geometryToPreviewTrack(
  geometryLngLat: [number, number][]
): { lat: number; lng: number }[] {
  return geometryLngLat.map(([lng, lat]) => ({ lat, lng }));
}

export function buildTrackStats(
  track: TrackPoint[],
  planned?: Pick<PlannedRoute, "elevationGainM" | "distanceM"> | null
): { distanceM: number; elevationGainM: number } {
  const distanceM = Math.round(trackDistanceM(track));
  if (track.length >= 2 && planned) {
    const frac = Math.min(
      1,
      distanceM / Math.max(1, planned.distanceM)
    );
    return {
      distanceM: distanceM > 20 ? distanceM : planned.distanceM,
      elevationGainM: Math.round(planned.elevationGainM * Math.max(frac, 0.15)),
    };
  }
  if (distanceM > 20) {
    return {
      distanceM,
      elevationGainM: planned?.elevationGainM
        ? Math.round(planned.elevationGainM * 0.4)
        : Math.round(distanceM * 0.04),
    };
  }
  return {
    distanceM: planned?.distanceM ?? 0,
    elevationGainM: planned?.elevationGainM ?? 0,
  };
}
