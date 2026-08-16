/**
 * GPS → Route-Polyline: Distanz entlang der Route + Cross-Track.
 */

function toRad(d: number): number {
  return (d * Math.PI) / 180;
}

export function haversineM(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
}

/** Polyline length in metres. Coords are GeoJSON [lng, lat]. */
export function lineLengthM(coords: [number, number][]): number {
  let d = 0;
  for (let i = 1; i < coords.length; i++) {
    d += haversineM(
      coords[i - 1][1],
      coords[i - 1][0],
      coords[i][1],
      coords[i][0],
    );
  }
  return d;
}

/** Interpolated [lng, lat] at [alongM] (clamped to the line). */
export function pointAlongRoute(
  coordinates: [number, number][],
  alongM: number,
): [number, number] {
  if (!coordinates.length) return [0, 0];
  if (coordinates.length === 1 || alongM <= 0) return coordinates[0];
  let walked = 0;
  for (let i = 1; i < coordinates.length; i++) {
    const a = coordinates[i - 1];
    const b = coordinates[i];
    const seg = haversineM(a[1], a[0], b[1], b[0]);
    if (walked + seg >= alongM || i === coordinates.length - 1) {
      const t =
        seg < 0.01 ? 1 : Math.max(0, Math.min(1, (alongM - walked) / seg));
      return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
    }
    walked += seg;
  }
  return coordinates[coordinates.length - 1];
}

export type RouteProgress = {
  distanceAlongM: number;
  crossTrackM: number;
  segmentIndex: number;
};

/** coordinates: GeoJSON [lng, lat][] */
export function projectOntoRoute(
  coordinates: [number, number][] | number[][],
  lat: number,
  lng: number,
): RouteProgress {
  if (!coordinates.length) {
    return { distanceAlongM: 0, crossTrackM: Infinity, segmentIndex: 0 };
  }
  if (coordinates.length === 1) {
    const c = coordinates[0];
    return {
      distanceAlongM: 0,
      crossTrackM: haversineM(lat, lng, c[1], c[0]),
      segmentIndex: 0,
    };
  }

  let bestDist = Infinity;
  let bestAlong = 0;
  let bestSeg = 0;
  let alongBefore = 0;

  for (let i = 1; i < coordinates.length; i++) {
    const a = coordinates[i - 1];
    const b = coordinates[i];
    const ax = a[0];
    const ay = a[1];
    const bx = b[0];
    const by = b[1];
    const segLen = haversineM(ay, ax, by, bx);
    if (segLen < 0.01) {
      alongBefore += segLen;
      continue;
    }

    const latRad = toRad(ay);
    const dx = (lng - ax) * Math.cos(latRad) * 111320;
    const dy = (lat - ay) * 110540;
    const sx = (bx - ax) * Math.cos(latRad) * 111320;
    const sy = (by - ay) * 110540;
    const seg2 = sx * sx + sy * sy;
    const t = Math.max(0, Math.min(1, (dx * sx + dy * sy) / seg2));
    const px = ax + (bx - ax) * t;
    const py = ay + (by - ay) * t;
    const d = haversineM(lat, lng, py, px);
    if (d < bestDist) {
      bestDist = d;
      bestAlong = alongBefore + segLen * t;
      bestSeg = i - 1;
    }
    alongBefore += segLen;
  }

  return {
    distanceAlongM: bestAlong,
    crossTrackM: bestDist,
    segmentIndex: bestSeg,
  };
}

/** Off-Route Hysterese: enter ≥ 40 m, clear ≤ 25 m. */
export function updateOffRouteState(
  currentlyOff: boolean,
  crossTrackM: number,
  enterM = 40,
  clearM = 25,
): boolean {
  if (currentlyOff) return crossTrackM > clearM;
  return crossTrackM >= enterM;
}
