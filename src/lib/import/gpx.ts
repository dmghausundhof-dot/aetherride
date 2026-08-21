/**
 * GPX Track/Route → SavedRoute-fähige Geometrie.
 */

export type ParsedGpx = {
  name: string;
  /** GeoJSON [lng, lat] oder [lng, lat, ele] — ele nur aus GPX. */
  coordinates: number[][];
  distanceKm: number;
  elevationM: number;
  durationMin: number;
};

function haversineM(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
}

export function parseGpx(
  xml: string,
  fallbackName = "GPX-Import"
): ParsedGpx | null {
  const pts: { lat: number; lng: number; elev?: number }[] = [];
  const re =
    /<(?:trkpt|rtept)\s+[^>]*lat="([^"]+)"[^>]*lon="([^"]+)"[^>]*>([\s\S]*?)<\/(?:trkpt|rtept)>/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(xml))) {
    const lat = Number(m[1]);
    const lng = Number(m[2]);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    const elevM = /<ele>\s*([-0-9.]+)\s*<\/ele>/i.exec(m[3] ?? "");
    pts.push({
      lat,
      lng,
      elev: elevM ? Number(elevM[1]) : undefined,
    });
  }
  if (pts.length < 2) {
    const re2 =
      /<(?:trkpt|rtept)\s+[^>]*lat="([^"]+)"[^>]*lon="([^"]+)"[^/]*\/>/gi;
    while ((m = re2.exec(xml))) {
      const lat = Number(m[1]);
      const lng = Number(m[2]);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
      pts.push({ lat, lng });
    }
  }
  if (pts.length < 2) return null;

  let dist = 0;
  let elevGain = 0;
  for (let i = 1; i < pts.length; i++) {
    dist += haversineM(pts[i - 1].lat, pts[i - 1].lng, pts[i].lat, pts[i].lng);
    const a = pts[i - 1].elev;
    const b = pts[i].elev;
    if (a != null && b != null && b - a > 0.5) elevGain += b - a;
  }

  const nameM = /<name>\s*([^<]+)\s*<\/name>/i.exec(xml);
  const name = nameM?.[1]?.trim() || fallbackName;

  return {
    name,
    coordinates: pts.map((p) =>
      p.elev != null && Number.isFinite(p.elev)
        ? [p.lng, p.lat, p.elev]
        : [p.lng, p.lat],
    ),
    distanceKm: dist / 1000,
    elevationM: elevGain,
    durationMin: Math.max(10, Math.round((dist / 1000 / 12) * 60)),
  };
}
