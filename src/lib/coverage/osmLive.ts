/**
 * Timeout-safe OSM Overpass (viewport / GPS radius — never all of DACH).
 */

export type OsmTrail = {
  id: string;
  name: string;
  mtbScale: string;
  surface?: string;
  highway?: string;
  lengthKm: number;
  center: [number, number];
  geometry: [number, number][];
  url: string;
  source: "osm";
};

export type OsmRoute = {
  id: string;
  title: string;
  type: string;
  difficulty?: string;
  lengthKm?: number;
  durationMin?: number;
  summary?: string;
  url?: string;
  center?: [number, number];
  geometry?: [number, number][];
  source: "osm";
};

export type OsmBbox = {
  west: number;
  south: number;
  east: number;
  north: number;
};

const OVERPASS = "https://overpass-api.de/api/interpreter";

function haversineKm(a: [number, number], b: [number, number]): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(b[1] - a[1]);
  const dLon = toRad(b[0] - a[0]);
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function pathLengthKm(coords: [number, number][]): number {
  let sum = 0;
  for (let i = 1; i < coords.length; i++) {
    sum += haversineKm(coords[i - 1], coords[i]);
  }
  return sum;
}

/** mtb_scale only — never map sac_scale → S0–S3. */
export function normalizeMtbScale(raw?: string): string {
  if (!raw) return "offen";
  const t = raw.trim().toLowerCase();
  if (t === "0" || t.startsWith("s0")) return "S0";
  if (t === "1" || t.startsWith("s1")) return "S1";
  if (t === "2" || t.startsWith("s2")) return "S2";
  if (
    t === "3" ||
    t === "4" ||
    t === "5" ||
    t === "6" ||
    t.startsWith("s3") ||
    t.startsWith("s4") ||
    t.startsWith("s5")
  ) {
    return "S3+";
  }
  return raw.slice(0, 12);
}

export function clampBbox(bbox: OsmBbox, maxDeg = 0.4): OsmBbox {
  const west = bbox.west;
  const south = bbox.south;
  const east = bbox.east;
  const north = bbox.north;
  const cx = (west + east) / 2;
  const cy = (south + north) / 2;
  const halfLng = Math.min(maxDeg / 2, Math.abs(east - west) / 2);
  const halfLat = Math.min(maxDeg / 2, Math.abs(north - south) / 2);
  return {
    west: cx - halfLng,
    south: cy - halfLat,
    east: cx + halfLng,
    north: cy + halfLat,
  };
}

export function bboxFromRadius(
  lat: number,
  lon: number,
  radiusKm: number
): OsmBbox {
  const dLat = radiusKm / 111;
  const cos = Math.max(0.2, Math.abs(Math.cos((lat * Math.PI) / 180)));
  const dLng = radiusKm / (111 * cos);
  return {
    west: lon - dLng,
    south: lat - dLat,
    east: lon + dLng,
    north: lat + dLat,
  };
}

function simplify(geometry: [number, number][], cap: number): [number, number][] {
  if (geometry.length <= cap) return geometry;
  const step = Math.max(1, Math.floor(geometry.length / cap));
  const simplified = geometry.filter((_, i) => i % step === 0);
  const last = geometry[geometry.length - 1];
  if (
    simplified.length === 0 ||
    simplified[simplified.length - 1][0] !== last[0] ||
    simplified[simplified.length - 1][1] !== last[1]
  ) {
    simplified.push(last);
  }
  return simplified;
}

async function overpass(query: string, timeoutMs: number): Promise<{
  elements?: Array<Record<string, unknown>>;
} | null> {
  try {
    const res = await fetch(OVERPASS, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        Accept: "application/json",
      },
      body: `data=${encodeURIComponent(query)}`,
      signal: AbortSignal.timeout(timeoutMs),
      next: { revalidate: 900 },
    });
    if (!res.ok) return null;
    return (await res.json()) as { elements?: Array<Record<string, unknown>> };
  } catch {
    return null;
  }
}

function aroundOrBbox(
  lat: number,
  lon: number,
  radiusM: number,
  bbox?: OsmBbox
): string {
  if (bbox) {
    const b = clampBbox(bbox);
    return `(${b.south},${b.west},${b.north},${b.east})`;
  }
  return `(around:${radiusM},${lat},${lon})`;
}

export async function fetchOsmTrailsNear(opts: {
  lat: number;
  lon: number;
  radiusKm?: number;
  bbox?: OsmBbox;
}): Promise<{ trails: OsmTrail[]; warning?: string }> {
  const radiusKm = Math.min(18, Math.max(3, opts.radiusKm ?? 8));
  const radiusM = Math.round(radiusKm * 1000);
  const loc = aroundOrBbox(opts.lat, opts.lon, radiusM, opts.bbox);
  const query = `
[out:json][timeout:22];
(
  way["highway"~"path|track"]["mtb_scale"]${loc};
  way["highway"="cycleway"]${loc};
  way["highway"="path"]["bicycle"~"yes|designated"]${loc};
  way["highway"~"path|track"]["sac_scale"]${loc};
  way["highway"="path"]["surface"~"ground|gravel|dirt|grass|compacted|fine_gravel|earth|unpaved"]["bicycle"!="no"]${loc};
  way["highway"="track"]["tracktype"~"grade2|grade3|grade4|grade5"]["bicycle"!="no"]${loc};
);
out body geom;
`.trim();

  const json = await overpass(query, 24000);
  if (!json) return { trails: [], warning: "Overpass timeout/offline" };

  const trails: OsmTrail[] = [];
  for (const el of json.elements ?? []) {
    if (el.type !== "way") continue;
    const tags = (el.tags as Record<string, string> | undefined) ?? {};
    const geomRaw = (el.geometry as Array<{ lat: number; lon: number }>) ?? [];
    if (geomRaw.length < 2) continue;
    const geometry: [number, number][] = [];
    for (const g of geomRaw) {
      if (!Number.isFinite(g.lat) || !Number.isFinite(g.lon)) continue;
      geometry.push([g.lon, g.lat]);
    }
    if (geometry.length < 2) continue;
    const simplified = simplify(geometry, 80);
    const lengthKm = pathLengthKm(simplified);
    if (lengthKm < 0.12 || lengthKm > 25) continue;
    const mtbScale = normalizeMtbScale(tags.mtb_scale);
    const name =
      tags.name ||
      tags["name:de"] ||
      tags.ref ||
      (mtbScale !== "offen"
        ? `Trail ${mtbScale}`
        : tags.highway === "cycleway"
          ? "Radweg"
          : "Pfad");
    const mid = simplified[Math.floor(simplified.length / 2)];
    trails.push({
      id: `osm-way-${el.id}`,
      name,
      mtbScale,
      surface: tags.surface || tags.tracktype || undefined,
      highway: tags.highway,
      lengthKm: Math.round(lengthKm * 100) / 100,
      center: mid,
      geometry: simplified,
      url: `https://www.openstreetmap.org/way/${el.id}`,
      source: "osm",
    });
  }
  trails.sort((a, b) => {
    const sa = a.mtbScale.startsWith("S") ? 0 : 1;
    const sb = b.mtbScale.startsWith("S") ? 0 : 1;
    if (sa !== sb) return sa - sb;
    return a.lengthKm - b.lengthKm;
  });
  return { trails: trails.slice(0, 80) };
}

export async function fetchOsmRoutesNear(opts: {
  lat: number;
  lon: number;
  radiusKm?: number;
  bbox?: OsmBbox;
}): Promise<{ routes: OsmRoute[]; warning?: string }> {
  const radiusKm = Math.min(40, Math.max(5, opts.radiusKm ?? 18));
  const radiusM = Math.round(radiusKm * 1000);
  const loc = aroundOrBbox(opts.lat, opts.lon, radiusM, opts.bbox);
  const query = `
[out:json][timeout:22];
(
  relation["route"="bicycle"]${loc};
  relation["route"="mtb"]${loc};
  relation["route"="hiking"]${loc};
  relation["route"="cycling"]${loc};
);
out body geom;
`.trim();

  const json = await overpass(query, 24000);
  if (!json) return { routes: [], warning: "Overpass timeout/offline" };

  const routes: OsmRoute[] = [];
  for (const el of json.elements ?? []) {
    if (el.type !== "relation") continue;
    const tags = (el.tags as Record<string, string> | undefined) ?? {};
    const name = tags.name || tags["name:de"] || tags.ref || tags.operator;
    if (!name) continue;
    const geometry: [number, number][] = [];
    const members = (el.members as Array<{
      geometry?: Array<{ lat: number; lon: number }>;
    }>) ?? [];
    for (const m of members) {
      if (!m.geometry?.length) continue;
      for (const g of m.geometry) {
        if (!Number.isFinite(g.lat) || !Number.isFinite(g.lon)) continue;
        geometry.push([g.lon, g.lat]);
      }
    }
    if (geometry.length < 2) continue;
    const simplified = simplify(geometry, 180);
    const lengthKm = pathLengthKm(simplified);
    if (lengthKm < 1.5 || lengthKm > 180) continue;
    const routeType = tags.route || "bicycle";
    const mid = simplified[Math.floor(simplified.length / 2)];
    routes.push({
      id: `osm-${el.id}`,
      title: name,
      type: routeType,
      difficulty: tags.mtb_scale || tags.sac_scale || tags.network || undefined,
      lengthKm: Math.round(lengthKm * 10) / 10,
      durationMin: Math.round((lengthKm / 14) * 60),
      summary: [
        tags.description?.slice(0, 120),
        routeType === "mtb" ? "OSM MTB-Route" : "OSM Rad-/Wanderroute",
        tags.network ? `Netz ${tags.network}` : null,
      ]
        .filter(Boolean)
        .join(" · "),
      url: `https://www.openstreetmap.org/relation/${el.id}`,
      center: mid,
      geometry: simplified,
      source: "osm",
    });
  }
  routes.sort((a, b) => (a.lengthKm ?? 99) - (b.lengthKm ?? 99));
  return { routes: routes.slice(0, 36) };
}
