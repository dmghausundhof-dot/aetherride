/**
 * Trailhead orientation — gravity uses elevation (top = start), else nearest end.
 * Mirrors `mobile/lib/domain/routing/trail_access.dart`.
 */

export const kTrailElevDecideMinM = 8;

export type OrientedTrail = {
  geometry: [number, number][];
  entry: [number, number];
  exit: [number, number];
  reversed: boolean;
  usedElevation: boolean;
};

export function trailAccessHaversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const r = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.min(1, Math.sqrt(a)));
}

export function orientTrail(opts: {
  geometry: [number, number][];
  fromLng: number;
  fromLat: number;
  startElevM?: number | null;
  endElevM?: number | null;
  preferDownhill: boolean;
}): OrientedTrail {
  const { geometry, fromLng, fromLat, startElevM, endElevM, preferDownhill } =
    opts;
  if (geometry.length < 2) {
    const p = geometry[0] ?? [fromLng, fromLat];
    return {
      geometry,
      entry: p,
      exit: p,
      reversed: false,
      usedElevation: false,
    };
  }

  const first = geometry[0];
  const last = geometry[geometry.length - 1];
  let reverse = false;
  let usedElevation = false;

  if (
    preferDownhill &&
    startElevM != null &&
    endElevM != null &&
    Number.isFinite(startElevM) &&
    Number.isFinite(endElevM) &&
    Math.abs(startElevM - endElevM) >= kTrailElevDecideMinM
  ) {
    usedElevation = true;
    reverse = startElevM < endElevM;
  } else {
    const dFirst = trailAccessHaversineKm(fromLat, fromLng, first[1], first[0]);
    const dLast = trailAccessHaversineKm(fromLat, fromLng, last[1], last[0]);
    reverse = dLast < dFirst;
  }

  const geo = reverse ? [...geometry].reverse() : geometry;
  return {
    geometry: geo,
    entry: geo[0],
    exit: geo[geo.length - 1],
    reversed: reverse,
    usedElevation,
  };
}

export async function fetchEndpointElevations(
  a: [number, number],
  b: [number, number]
): Promise<{ startM: number | null; endM: number | null }> {
  try {
    const res = await fetch("/api/elevation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        locations: [
          { lat: a[1], lng: a[0] },
          { lat: b[1], lng: b[0] },
        ],
      }),
    });
    if (!res.ok) return { startM: null, endM: null };
    const data = (await res.json()) as {
      points?: { elevM?: number | null }[];
    };
    const pts = data.points ?? [];
    const start = pts[0]?.elevM;
    const end = pts[pts.length - 1]?.elevM;
    return {
      startM: start != null && Number.isFinite(start) ? start : null,
      endM: end != null && Number.isFinite(end) ? end : null,
    };
  } catch {
    return { startM: null, endM: null };
  }
}
