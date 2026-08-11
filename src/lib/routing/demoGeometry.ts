/**
 * Näherungs-Geometrie / Pin-Zentren für Tour-Ideen (Dev/Test only).
 * Production: buildDemoGeometry wirft; demoCenterLngLat nur noch neutrale Übersicht.
 */

import { allowDemoContent } from "@/lib/config/allowDemoContent";

const BASE: Record<string, { lat: number; lng: number }> = {
  "idea-koenigstuhl": { lat: 49.398, lng: 8.726 },
  "idea-odenwald-trail": { lat: 49.45, lng: 8.82 },
  "idea-neckartal-gravel": { lat: 49.38, lng: 8.68 },
  "r-heidelberg-city": { lat: 49.41, lng: 8.705 },
  "idea-kaltenbronn": { lat: 48.642, lng: 8.425 },
  "idea-schauinsland": { lat: 47.912, lng: 7.898 },
  "idea-dreisam-city": { lat: 47.995, lng: 7.845 },
  "idea-kaiserstuhl-road": { lat: 48.09, lng: 7.67 },
  "r-kaltenbronn": { lat: 48.642, lng: 8.425 },
  "r-kitz-gravel": { lat: 47.45, lng: 12.39 },
  "r-hochkoenig-emtb": { lat: 47.42, lng: 13.1 },
  "r-wilder-kaiser-hike": { lat: 47.56, lng: 12.3 },
  "r-inn-flat": { lat: 47.56, lng: 12.17 },
  "r-freiburg-city": { lat: 47.999, lng: 7.842 },
  "r-schwarzwald-gravel": { lat: 48.05, lng: 7.95 },
  "r-bodensee-road": { lat: 47.66, lng: 9.18 },
  "r-stuttgart-urban": { lat: 48.76, lng: 9.16 },
  "r-tegernsee-gravel": { lat: 47.71, lng: 11.76 },
  "r-vosges-gravel": { lat: 47.82, lng: 6.84 },
  "r-alsace-road": { lat: 48.08, lng: 7.45 },
  "r-annecy-road": { lat: 45.9, lng: 6.13 },
  "r-morzine-emtb": { lat: 46.18, lng: 6.71 },
  "r-provence-gravel": { lat: 43.84, lng: 5.23 },
  "r-bretagne-coast": { lat: 48.83, lng: -3.48 },
  "r-rhein-radweg": { lat: 49.45, lng: 8.48 },
  "r-neckar-touring": { lat: 49.35, lng: 8.95 },
  "r-pfalz-gravel": { lat: 49.2, lng: 7.95 },
  "r-karlsruhe-urban": { lat: 49.01, lng: 8.4 },
  "r-donau-touring": { lat: 48.55, lng: 10.35 },
  "r-muenchen-road": { lat: 48.05, lng: 11.4 },
  "r-elbe-touring": { lat: 51.1, lng: 13.6 },
  "r-eifel-gravel": { lat: 50.35, lng: 6.7 },
  "r-heidelberg-road": { lat: 49.41, lng: 8.71 },
  "r-mannheim-urban": { lat: 49.49, lng: 8.47 },
  "r-odenwald-gravel": { lat: 49.48, lng: 8.75 },
  "r-kaiserstuhl-gravel": { lat: 48.09, lng: 7.67 },
  "r-freiburg-road": { lat: 48.0, lng: 7.78 },
  "r-schauinsland-emtb": { lat: 47.91, lng: 7.9 },
  "r-titisee-road": { lat: 47.91, lng: 8.15 },
  "r-stuttgart-road": { lat: 48.78, lng: 9.1 },
  "r-muenchen-urban": { lat: 48.15, lng: 11.59 },
  "r-chiemsee-road": { lat: 47.86, lng: 12.4 },
  "r-nuernberg-urban": { lat: 49.45, lng: 11.08 },
  "r-koeln-urban": { lat: 50.94, lng: 6.96 },
  "r-mainz-road": { lat: 50.0, lng: 8.25 },
  "r-konstanz-urban": { lat: 47.66, lng: 9.18 },
  "r-ulm-urban": { lat: 48.4, lng: 9.99 },
  "r-starnberg-road": { lat: 47.99, lng: 11.34 },
  "r-ammersee-gravel": { lat: 48.0, lng: 11.1 },
  "r-garmisch-emtb": { lat: 47.49, lng: 11.1 },
  "r-lindau-road": { lat: 47.55, lng: 9.68 },
  "r-friedrichshafen-urban": { lat: 47.65, lng: 9.48 },
  "r-regensburg-urban": { lat: 49.02, lng: 12.1 },
  "r-augsburg-road": { lat: 48.37, lng: 10.9 },
  "r-passau-touring": { lat: 48.57, lng: 13.46 },
  "r-wuerzburg-road": { lat: 49.79, lng: 9.93 },
  "r-dresden-urban": { lat: 51.05, lng: 13.74 },
  "r-innsbruck-road": { lat: 47.27, lng: 11.39 },
  "r-zillertal-gravel": { lat: 47.23, lng: 11.87 },
  "r-chamonix-emtb": { lat: 45.92, lng: 6.87 },
  "r-geneve-urban": { lat: 46.2, lng: 6.15 },
  default: { lat: 47.99, lng: 7.85 },
};

function hashSeed(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) | 0;
  return Math.abs(h);
}

/** Center [lng, lat] for pin-only tour ideas (no fake rectangle). */
export function demoCenterLngLat(routeId: string): [number, number] {
  const c = BASE[routeId] ?? BASE.default;
  return [c.lng, c.lat];
}

/** Luftlinie in km (approx). */
export function haversineKm(
  a: [number, number],
  b: [number, number]
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const [lng1, lat1] = a;
  const [lng2, lat2] = b;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(s)));
}

/** @deprecated Prefer pin-only + live routing; keep for tests/legacy. */
export function buildDemoGeometry(
  routeId: string,
  distanceKm: number
): GeoJSON.LineString {
  if (!allowDemoContent()) {
    throw new Error(
      "Demo-Geometrie in Production deaktiviert — Live-Routing oder GPX nutzen.",
    );
  }
  const center = BASE[routeId] ?? BASE.default;
  const seed = hashSeed(routeId);
  const halfLng = 0.01 + (distanceKm / 180) * 0.035 + (seed % 5) * 0.0008;
  const halfLat = halfLng * 0.7;
  const cornerPts = 8;
  const coordinates: [number, number][] = [];

  const corners: [number, number][] = [
    [center.lng - halfLng, center.lat - halfLat],
    [center.lng + halfLng, center.lat - halfLat],
    [center.lng + halfLng, center.lat + halfLat],
    [center.lng - halfLng, center.lat + halfLat],
  ];

  for (let c = 0; c < 4; c++) {
    const a = corners[c];
    const b = corners[(c + 1) % 4];
    const steps = Math.max(12, Math.round(20 + (seed % 7)));
    for (let i = 0; i < steps; i++) {
      const t = i / steps;
      const bulge = 0.15 * Math.sin(t * Math.PI) * ((seed % 3) + 1) * 0.001;
      const lng = a[0] + (b[0] - a[0]) * t;
      const lat = a[1] + (b[1] - a[1]) * t;
      const nx = -(b[1] - a[1]);
      const ny = b[0] - a[0];
      const nlen = Math.hypot(nx, ny) || 1;
      coordinates.push([
        Math.round((lng + (nx / nlen) * bulge) * 1e6) / 1e6,
        Math.round((lat + (ny / nlen) * bulge) * 1e6) / 1e6,
      ]);
    }
    for (let k = 1; k <= cornerPts; k++) {
      const t = k / (cornerPts + 1);
      const next = corners[(c + 1) % 4];
      const after = corners[(c + 2) % 4];
      const lng = next[0] + (after[0] - next[0]) * t * 0.15;
      const lat = next[1] + (after[1] - next[1]) * t * 0.15;
      coordinates.push([
        Math.round(lng * 1e6) / 1e6,
        Math.round(lat * 1e6) / 1e6,
      ]);
    }
  }
  coordinates.push(coordinates[0]);
  return { type: "LineString", coordinates };
}

export function centerOfGeometry(
  geometry: GeoJSON.LineString | null | undefined
): [number, number] {
  if (!geometry?.coordinates?.length) return [12.15, 47.45];
  const mid = geometry.coordinates[Math.floor(geometry.coordinates.length / 2)];
  return [mid[0], mid[1]];
}
