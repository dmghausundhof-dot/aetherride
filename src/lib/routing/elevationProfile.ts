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

  const known = points.filter((p) => p.elevM != null);
  let climb = 0;
  for (let i = 1; i < known.length; i++) {
    const d = (known[i].elevM ?? 0) - (known[i - 1].elevM ?? 0);
    if (d > 0) climb += d;
  }

  const gapKm = points.filter((p) => p.elevM == null).length * 0.5;

  const surfaceBands = bandify(points, (p) => p.surface ?? null, "surface");
  const scaleBands = bandify(points, (p) => p.mtbScale ?? null, "scale");

  return {
    points,
    totalClimbM: Math.round(climb),
    totalDistKm: dist,
    gapKm,
    surfaceBands,
    scaleBands,
  };
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
