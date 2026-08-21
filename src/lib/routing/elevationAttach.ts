import type { ElevationProfile, ProfilePoint } from "@/lib/routing/elevationProfile";
import { haversineM } from "@/lib/routing/routeProgress";

export type TrackElevSample = {
  elev: number;
  lat?: number;
  lng?: number;
  distKm?: number;
};

export function elevationSourceIsDemo(source?: string | null): boolean {
  return (source?.trim().toLowerCase() ?? "") === "demo";
}

export function trackHasRealElev(
  trackLngLat: ReadonlyArray<ArrayLike<number>>,
): boolean {
  for (const p of trackLngLat) {
    const ele = Number(p[2]);
    if (p.length >= 3 && Number.isFinite(ele)) return true;
  }
  return false;
}

export function trackElevSamplesFromPoints(
  points: ReadonlyArray<
    Pick<ProfilePoint, "elevM" | "distKm"> & {
      elev?: number | null;
      elevation?: number | null;
      lat?: number;
      lng?: number;
      lon?: number;
      dist_km?: number;
    }
  >,
): TrackElevSample[] {
  const out: TrackElevSample[] = [];
  for (const m of points) {
    const raw = m.elevM ?? m.elev ?? m.elevation;
    if (typeof raw !== "number" || !Number.isFinite(raw)) continue;
    const lat = typeof m.lat === "number" && Number.isFinite(m.lat) ? m.lat : undefined;
    const lngRaw = m.lng ?? m.lon;
    const lng =
      typeof lngRaw === "number" && Number.isFinite(lngRaw) ? lngRaw : undefined;
    const distRaw = m.distKm ?? m.dist_km;
    const distKm =
      typeof distRaw === "number" && Number.isFinite(distRaw) ? distRaw : undefined;
    out.push({ elev: raw, lat, lng, distKm });
  }
  return out;
}

/** Echte Samples auf die nächste Vertex. Lücken bleiben [lng,lat]. */
export function attachRealElevToTrack(
  trackLngLat: ReadonlyArray<ArrayLike<number>>,
  samples: readonly TrackElevSample[],
  opts?: { maxMatchM?: number; source?: string | null },
): number[][] {
  const maxMatchM = opts?.maxMatchM ?? 80;
  const track = trackLngLat.map((p) => Array.from(p, (v) => Number(v)));
  if (
    elevationSourceIsDemo(opts?.source) ||
    track.length < 2 ||
    samples.length === 0
  ) {
    return track;
  }
  const withGeo = samples.filter(
    (s) => s.lat != null && s.lng != null,
  );
  if (withGeo.length > 0) {
    placeByLngLat(track, withGeo, maxMatchM);
    return track;
  }
  const withKm = samples.filter((s) => s.distKm != null);
  if (withKm.length === samples.length) {
    placeByDistKm(track, withKm, maxMatchM);
    return track;
  }
  if (samples.length === track.length) {
    for (let i = 0; i < track.length; i++) {
      const row = track[i]!;
      if (row.length >= 3 && Number.isFinite(row[2])) continue;
      track[i] = [row[0]!, row[1]!, samples[i]!.elev];
    }
  }
  return track;
}

export function attachElevFromProfile(
  trackLngLat: ReadonlyArray<ArrayLike<number>>,
  profile?: ElevationProfile | null,
): number[][] {
  if (!profile || elevationSourceIsDemo(profile.source)) {
    return trackLngLat.map((p) => Array.from(p, (v) => Number(v)));
  }
  return attachRealElevToTrack(
    trackLngLat,
    trackElevSamplesFromPoints(profile.points),
    { source: profile.source },
  );
}

export async function fetchElevationProfile(
  coordinates: ReadonlyArray<ArrayLike<number>>,
): Promise<ElevationProfile | null> {
  if (coordinates.length < 2) return null;
  const track = coordinates.map((p) => ({
    lng: Number(p[0]),
    lat: Number(p[1]),
  }));
  if (track.some((p) => !Number.isFinite(p.lat) || !Number.isFinite(p.lng))) {
    return null;
  }
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 12_000);
  try {
    const res = await fetch("/api/elevation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ track }),
      signal: ctrl.signal,
    });
    if (!res.ok) return null;
    const j = (await res.json()) as ElevationProfile & { error?: string };
    if (j?.error || !j?.points || j.points.length < 2) return null;
    if (elevationSourceIsDemo(j.source)) return null;
    return j;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/** Hängt API-/Track-Höhe an, wenn sie wirklich da ist. Sonst unveränderte 2D-Linie. */
export async function lineWithApiElevation(
  coordinates: ReadonlyArray<ArrayLike<number>>,
  profile?: ElevationProfile | null,
): Promise<number[][]> {
  const track = coordinates.map((p) => Array.from(p, (v) => Number(v)));
  if (track.length < 2) return track;
  if (trackHasRealElev(track)) return track;
  if (profile && !elevationSourceIsDemo(profile.source)) {
    return attachElevFromProfile(track, profile);
  }
  const fetched = await fetchElevationProfile(track);
  if (!fetched) return track;
  return attachElevFromProfile(track, fetched);
}

function placeByLngLat(
  out: number[][],
  samples: readonly TrackElevSample[],
  maxMatchM: number,
) {
  for (const s of samples) {
    let bestI = -1;
    let bestM = maxMatchM;
    for (let i = 0; i < out.length; i++) {
      const row = out[i]!;
      const d = haversineM(s.lat!, s.lng!, row[1]!, row[0]!);
      if (d <= bestM) {
        bestM = d;
        bestI = i;
      }
    }
    if (bestI < 0) continue;
    const row = out[bestI]!;
    if (row.length >= 3 && Number.isFinite(row[2])) continue;
    out[bestI] = [row[0]!, row[1]!, s.elev];
  }
}

function placeByDistKm(
  out: number[][],
  samples: readonly TrackElevSample[],
  maxMatchM: number,
) {
  const along = new Array<number>(out.length).fill(0);
  for (let i = 1; i < out.length; i++) {
    const a = out[i - 1]!;
    const b = out[i]!;
    along[i] = along[i - 1]! + haversineM(a[1]!, a[0]!, b[1]!, b[0]!);
  }
  for (const s of samples) {
    const targetM = s.distKm! * 1000;
    let bestI = -1;
    let bestM = maxMatchM;
    for (let i = 0; i < along.length; i++) {
      const d = Math.abs(along[i]! - targetM);
      if (d <= bestM) {
        bestM = d;
        bestI = i;
      }
    }
    if (bestI < 0) continue;
    const row = out[bestI]!;
    if (row.length >= 3 && Number.isFinite(row[2])) continue;
    out[bestI] = [row[0]!, row[1]!, s.elev];
  }
}
