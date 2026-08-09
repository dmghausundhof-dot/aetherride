/**
 * Näherungs-Geometrie (Rechteck), wenn keine Engine-Polyline vorliegt.
 * Nicht als echter Trail/Track darstellen — UI soll „Näherung“ kennzeichnen.
 */

const BASE: Record<string, { lat: number; lng: number }> = {
  "idea-kaltenbronn": { lat: 48.642, lng: 8.425 },
  "idea-schauinsland": { lat: 47.912, lng: 7.898 },
  "idea-dreisam-city": { lat: 47.995, lng: 7.845 },
  "idea-kaiserstuhl-road": { lat: 48.09, lng: 7.67 },
  "r-kaltenbronn": { lat: 48.642, lng: 8.425 },
  default: { lat: 47.99, lng: 7.85 },
};

function hashSeed(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) | 0;
  return Math.abs(h);
}

/** Center [lng, lat] for pin-only tour ideas (no fake rectangle). */
export function demoCenterLngLat(
  routeId: string
): [number, number] {
  const c = BASE[routeId] ?? BASE.default;
  return [c.lng, c.lat];
}

/** @deprecated Prefer pin-only + live routing; keep for tests/legacy. */
export function buildDemoGeometry(
  routeId: string,
  distanceKm: number
): GeoJSON.LineString {
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
      // leichte Ausbauchung der Kanten
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
    // Eck-Fillet
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
