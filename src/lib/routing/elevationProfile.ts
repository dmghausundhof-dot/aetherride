/**
 * F-NAV-007 — Höhenprofil + Oberflächen-/Schwierigkeitsbänder (P0)
 * Datenlücken als Lücke, nicht interpoliert kaschiert.
 */

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
  source: "track" | "api" | "demo";
}

function haversineKm(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const la1 = (a.lat * Math.PI) / 180;
  const la2 = (b.lat * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Profil aus Track-Punkten (elev optional → Lücke) */
export function buildElevationFromTrack(
  track: { lat: number; lng: number; elev?: number | null }[],
  source: ElevationProfile["source"] = "track"
): ElevationProfile {
  if (track.length < 2) {
    return {
      points: [],
      totalClimbM: 0,
      totalDistKm: 0,
      gapKm: 0,
      surfaceBands: [],
      scaleBands: [],
      source,
    };
  }

  const points: ProfilePoint[] = [];
  let dist = 0;
  let climb = 0;
  let gapKm = 0;
  let prevElev: number | null =
    track[0].elev != null && Number.isFinite(track[0].elev)
      ? Number(track[0].elev)
      : null;

  points.push({
    distKm: 0,
    elevM: prevElev,
    gradePct: 0,
    surface: null,
    mtbScale: null,
  });

  for (let i = 1; i < track.length; i++) {
    const d = haversineKm(track[i - 1], track[i]);
    dist += d;
    const elev =
      track[i].elev != null && Number.isFinite(track[i].elev!)
        ? Number(track[i].elev)
        : null;
    let grade: number | null = null;
    if (elev != null && prevElev != null && d > 0.0001) {
      grade = Math.round(((elev - prevElev) / (d * 1000)) * 1000) / 10;
      if (elev > prevElev) climb += elev - prevElev;
    } else if (elev == null) {
      gapKm += d;
    }
    points.push({
      distKm: Math.round(dist * 1000) / 1000,
      elevM: elev,
      gradePct: grade,
      surface: null,
      mtbScale: null,
    });
    if (elev != null) prevElev = elev;
  }

  return {
    points,
    totalClimbM: Math.round(climb),
    totalDistKm: Math.round(dist * 100) / 100,
    gapKm: Math.round(gapKm * 100) / 100,
    surfaceBands: bandify(points, (p) => p.surface ?? null, "surface"),
    scaleBands: bandify(points, (p) => p.mtbScale ?? null, "scale"),
    source,
  };
}

/** Demo-Profil mit absichtlicher Lücke (kein Fake-Interpolate) */
export function buildDemoElevationProfile(): ElevationProfile {
  const points: ProfilePoint[] = [];
  let elev = 780;
  let dist = 0;
  for (let i = 0; i < 40; i++) {
    dist = i * 0.5;
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

  const known = points.filter((p) => p.elevM != null);
  let climb = 0;
  for (let i = 1; i < known.length; i++) {
    const d = (known[i].elevM ?? 0) - (known[i - 1].elevM ?? 0);
    if (d > 0) climb += d;
  }

  const gapKm = points.filter((p) => p.elevM == null).length * 0.5;

  return {
    points,
    totalClimbM: Math.round(climb),
    totalDistKm: dist,
    gapKm,
    surfaceBands: bandify(points, (p) => p.surface ?? null, "surface"),
    scaleBands: bandify(points, (p) => p.mtbScale ?? null, "scale"),
    source: "demo",
  };
}

function bandify(
  points: ProfilePoint[],
  key: (p: ProfilePoint) => string | null,
  kind: "surface" | "scale"
): { fromKm: number; toKm: number; surface: string | null; scale: string | null }[] {
  if (points.length === 0) return [];
  const bands: {
    fromKm: number;
    toKm: number;
    surface: string | null;
    scale: string | null;
  }[] = [];
  let start = 0;
  let cur = key(points[0]);

  for (let i = 1; i <= points.length; i++) {
    const k = i < points.length ? key(points[i]) : Symbol("end");
    if (i === points.length || k !== cur) {
      bands.push({
        fromKm: points[start].distKm,
        toKm: points[i - 1].distKm,
        surface: kind === "surface" ? cur : null,
        scale: kind === "scale" ? cur : null,
      });
      start = i;
      cur = k as string | null;
    }
  }
  return bands;
}
