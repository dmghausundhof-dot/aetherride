/**
 * Route-Follow + Off-Route (Community: AllTrails/Komoot „off route“ erwartet)
 * Demo: Abstand zur geplanten Polyline.
 */

import { haversineM, type PlannedRoute } from "./rideHandoff";

export interface RouteFollowStatus {
  progress01: number;
  remainingM: number;
  distanceToRouteM: number;
  offRoute: boolean;
  /** Schwelle Demo — Produktion: Profil/Geschwindigkeit */
  offRouteThresholdM: number;
  hintDe: string | null;
}

const OFF_ROUTE_M = 45;

export function distanceToPolylineM(
  point: { lat: number; lng: number },
  geometryLngLat: [number, number][]
): number {
  if (geometryLngLat.length === 0) return Infinity;
  if (geometryLngLat.length === 1) {
    return haversineM(point, {
      lat: geometryLngLat[0][1],
      lng: geometryLngLat[0][0],
    });
  }
  let min = Infinity;
  for (let i = 1; i < geometryLngLat.length; i++) {
    const a = { lat: geometryLngLat[i - 1][1], lng: geometryLngLat[i - 1][0] };
    const b = { lat: geometryLngLat[i][1], lng: geometryLngLat[i][0] };
    min = Math.min(min, distancePointToSegmentM(point, a, b));
  }
  return min;
}

function distancePointToSegmentM(
  p: { lat: number; lng: number },
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
  // Approximiert in lokaler Metrik
  const toXY = (q: { lat: number; lng: number }) => {
    const x = ((q.lng - a.lng) * Math.PI) / 180 * 6371000 * Math.cos((a.lat * Math.PI) / 180);
    const y = ((q.lat - a.lat) * Math.PI) / 180 * 6371000;
    return { x, y };
  };
  const P = toXY(p);
  const A = { x: 0, y: 0 };
  const B = toXY(b);
  const abx = B.x - A.x;
  const aby = B.y - A.y;
  const apx = P.x - A.x;
  const apy = P.y - A.y;
  const ab2 = abx * abx + aby * aby;
  const t = ab2 > 0 ? Math.max(0, Math.min(1, (apx * abx + apy * aby) / ab2)) : 0;
  const cx = A.x + abx * t;
  const cy = A.y + aby * t;
  return Math.hypot(P.x - cx, P.y - cy);
}

export function evaluateRouteFollow(
  planned: PlannedRoute | null | undefined,
  current: { lat: number; lng: number } | null,
  progress01: number
): RouteFollowStatus | null {
  if (!planned || planned.geometryLngLat.length < 2 || !current) return null;
  const distanceToRouteM = distanceToPolylineM(current, planned.geometryLngLat);
  const offRoute = distanceToRouteM > OFF_ROUTE_M;
  const remainingM = Math.max(
    0,
    Math.round(planned.distanceM * (1 - Math.min(1, Math.max(0, progress01))))
  );
  let hintDe: string | null = null;
  if (offRoute) hintDe = "Abseits der Route";
  else if (progress01 > 0.95) hintDe = "Ziel fast erreicht";
  return {
    progress01: Math.min(1, Math.max(0, progress01)),
    remainingM,
    distanceToRouteM: Math.round(distanceToRouteM),
    offRoute,
    offRouteThresholdM: OFF_ROUTE_M,
    hintDe,
  };
}
