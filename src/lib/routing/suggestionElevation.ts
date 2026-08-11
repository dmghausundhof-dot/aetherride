/**
 * Synthetisches Höhen-/Oberflächenprofil für Routenvorschläge,
 * wenn noch kein Track vorliegt — Lücken werden nicht kaschiert.
 */

import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { ElevationProfile, ProfilePoint } from "@/lib/routing/elevationProfile";

function hashSeed(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) | 0;
  return Math.abs(h);
}

function parsePrimaryScale(mtbScale: string): string {
  if (!mtbScale || mtbScale === "—") return "—";
  const m = mtbScale.match(/S\d|T\d/i);
  return m ? m[0].toUpperCase() : mtbScale.slice(0, 4);
}

function surfaceForSegment(surface: string, t: number): string {
  const parts = surface.split("/").map((s) => s.trim());
  if (parts.length <= 1) return surface;
  return t < 0.45 ? parts[0] : (parts[1] ?? parts[0]);
}

/** Profil aus Vorschlags-Metadaten (km/hm/Scale/Surface). */
export function buildElevationForSuggestion(
  route: Pick<
    RouteSuggestion,
    "id" | "distanceKm" | "elevationM" | "mtbScale" | "surface" | "source"
  >
): ElevationProfile {
  const n = Math.max(24, Math.min(48, Math.round(route.distanceKm * 1.2)));
  const seed = hashSeed(route.id);
  const baseElev = 700 + (seed % 180);
  const peakClimb = Math.max(route.elevationM, 60);
  const primaryScale = parsePrimaryScale(route.mtbScale);
  const points: ProfilePoint[] = [];
  let climb = 0;
  let gapKm = 0;
  let prevElev: number | null = baseElev;

  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    const distKm = Math.round(t * route.distanceKm * 1000) / 1000;
    const inGap = t > 0.42 && t < 0.48;

    if (inGap) {
      const step =
        i === 0 ? 0 : distKm - (points[points.length - 1]?.distKm ?? 0);
      gapKm += Math.max(0, step);
      points.push({
        distKm,
        elevM: null,
        gradePct: null,
        surface: null,
        mtbScale: null,
      });
      continue;
    }

    let rel: number;
    if (t < 0.55) rel = Math.pow(t / 0.55, 1.1);
    else if (t < 0.72) rel = 1 - (t - 0.55) * 0.2;
    else rel = 0.88 * (1 - (t - 0.72) / 0.28);

    const wobble = Math.sin(t * Math.PI * (3 + (seed % 4))) * 0.06;
    const elev = Math.round(baseElev + peakClimb * (rel + wobble));
    let grade: number | null = null;
    if (prevElev != null && i > 0) {
      const dKm = distKm - (points[points.length - 1]?.distKm ?? 0);
      if (dKm > 0.0001) {
        grade = Math.round(((elev - prevElev) / (dKm * 1000)) * 1000) / 10;
        if (elev > prevElev) climb += elev - prevElev;
      }
    }

    const scale =
      t < 0.2
        ? primaryScale === "—"
          ? "—"
          : "S0"
        : t < 0.65
          ? primaryScale
          : primaryScale === "S3"
            ? "S2"
            : primaryScale;

    points.push({
      distKm,
      elevM: elev,
      gradePct: grade,
      surface: surfaceForSegment(route.surface, t),
      mtbScale: scale,
    });
    prevElev = elev;
  }

  return {
    points,
    totalClimbM: Math.round(climb || route.elevationM),
    totalDistKm: route.distanceKm,
    gapKm: Math.round(gapKm * 100) / 100,
    surfaceBands: bandify(points, (p) => p.surface ?? null, "surface"),
    scaleBands: bandify(points, (p) => p.mtbScale ?? null, "scale"),
    // Curated seeds ≠ fake demo routing — label as seed for Discover chrome.
    source:
      route.source === "seed" || route.id.startsWith("seed-")
        ? "seed"
        : route.source === "catalog"
          ? "seed"
          : "demo",
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
