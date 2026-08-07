/** Distanz / Höhenmeter aus Trackpunkten */

export type TrackPoint = { lat: number; lng: number; elev?: number; time: number };

function haversineM(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

export function trackDistanceM(track: TrackPoint[]): number {
  let d = 0;
  for (let i = 1; i < track.length; i++) {
    d += haversineM(track[i - 1], track[i]);
  }
  return d;
}

export function trackElevationGainM(track: TrackPoint[]): number {
  let gain = 0;
  for (let i = 1; i < track.length; i++) {
    const a = track[i - 1].elev;
    const b = track[i].elev;
    if (a == null || b == null) continue;
    const delta = b - a;
    if (delta > 0.5) gain += delta;
  }
  return gain;
}

/** Punkt entlang LineString bei Fortschritt 0–1 */
export function pointAlongLine(
  geometry: GeoJSON.LineString,
  progress: number
): { lat: number; lng: number } {
  const coords = geometry.coordinates;
  if (coords.length === 0) return { lat: 47.45, lng: 12.15 };
  if (coords.length === 1) {
    return { lat: coords[0][1], lng: coords[0][0] };
  }

  const lengths: number[] = [0];
  let total = 0;
  for (let i = 1; i < coords.length; i++) {
    total += haversineM(
      { lng: coords[i - 1][0], lat: coords[i - 1][1] },
      { lng: coords[i][0], lat: coords[i][1] }
    );
    lengths.push(total);
  }
  if (total <= 0) {
    return { lat: coords[0][1], lng: coords[0][0] };
  }

  const target = Math.min(1, Math.max(0, progress)) * total;
  let i = 1;
  while (i < lengths.length && lengths[i] < target) i++;
  const a = coords[i - 1];
  const b = coords[Math.min(i, coords.length - 1)];
  const segStart = lengths[i - 1];
  const segLen = lengths[Math.min(i, lengths.length - 1)] - segStart || 1;
  const t = (target - segStart) / segLen;
  return {
    lng: a[0] + (b[0] - a[0]) * t,
    lat: a[1] + (b[1] - a[1]) * t,
  };
}
