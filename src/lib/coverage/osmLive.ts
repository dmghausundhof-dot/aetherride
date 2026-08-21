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
  /** True when OSM has name / name:de / ref — not a generated „Pfad“. */
  hasOsmName: boolean;
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

const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.openstreetmap.fr/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
] as const;

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

/** Honest S-Grade from OSM `mtb:scale` — never sac_scale, never „offen“. */
export function isHonestOsmSGrade(mtbScale: string): boolean {
  return (
    mtbScale === "S0" ||
    mtbScale === "S1" ||
    mtbScale === "S2" ||
    mtbScale === "S3" ||
    mtbScale === "S3+"
  );
}

/** Overpass parts: real OSM keys `mtb:scale` / `mtb:scale:imba` (not `mtb_scale`). */
export function osmSGradeOverpassParts(loc: string): string[] {
  return [
    `way["highway"~"path|track|bridleway"]["mtb:scale"]${loc};`,
    `way["highway"~"path|track|bridleway"]["mtb:scale:imba"]${loc};`,
  ];
}

/** mtb_scale only — never map sac_scale → S0–S3. Collapsed 3–6 → S3+ (not S3). */
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

/** Accepts `123`, `way/123`, `osm-way-123`. */
export function parseOsmWayId(raw: unknown): string | null {
  if (raw == null) return null;
  const s = String(raw).trim();
  if (!s) return null;
  const m = s.match(/(?:osm-way-|way[/:-])?(\d{1,18})\s*$/i);
  return m?.[1] ?? null;
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
  const body = `data=${encodeURIComponent(query)}`;
  for (let i = 0; i < OVERPASS_ENDPOINTS.length; i++) {
    const ms = i === 0 ? timeoutMs : Math.min(12_000, timeoutMs);
    try {
      const res = await fetch(OVERPASS_ENDPOINTS[i], {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          Accept: "application/json",
          "User-Agent": "AetherRide/dev (https://aetherride.app)",
        },
        body,
        signal: AbortSignal.timeout(ms),
        next: { revalidate: 900 },
      });
      if (!res.ok) continue;
      const json = (await res.json()) as {
        elements?: Array<Record<string, unknown>>;
      };
      if (json?.elements) return json;
    } catch {
      continue;
    }
  }
  return null;
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
  timeoutMs?: number;
  /** Default: mtb trails + cycleways. `trails` skips city cycleways. `sgrade` = tagged only. */
  kinds?: "all" | "trails" | "cycleways" | "sgrade";
  limit?: number;
}): Promise<{ trails: OsmTrail[]; warning?: string }> {
  const radiusKm = Math.min(18, Math.max(3, opts.radiusKm ?? 8));
  const radiusM = Math.round(radiusKm * 1000);
  const timeoutMs = Math.min(24_000, Math.max(3_000, opts.timeoutMs ?? 24_000));
  const queryTimeoutS = Math.max(3, Math.floor(timeoutMs / 1000) - 1);
  const loc = aroundOrBbox(opts.lat, opts.lon, radiusM, opts.bbox);
  const kinds = opts.kinds ?? "all";
  const parts: string[] = [];
  if (kinds === "sgrade") {
    parts.push(...osmSGradeOverpassParts(loc));
  } else if (kinds !== "cycleways") {
    parts.push(
      ...osmSGradeOverpassParts(loc),
      `way["highway"="path"]["bicycle"~"yes|designated"]${loc}(if:length()>200);`,
      `way["highway"~"path|track"]["sac_scale"]${loc};`,
      // No untagged highway=track / grass field paths.
      // Tagged MTB tracks stay via mtb:scale above.
    );
  }
  if (kinds !== "trails" && kinds !== "sgrade") {
    const cyclewayMinM = kinds === "cycleways" ? 80 : 200;
    parts.push(`way["highway"="cycleway"]${loc}(if:length()>${cyclewayMinM});`);
  }
  const query = `
[out:json][timeout:${queryTimeoutS}];
(
  ${parts.join("\n  ")}
);
out body geom;
`.trim();

  const json = await overpass(query, timeoutMs);
  if (!json) return { trails: [], warning: "Overpass timeout/offline" };

  const trails: OsmTrail[] = [];
  const minKm = kinds === "cycleways" ? 0.08 : kinds === "sgrade" ? 0.04 : 0.12;
  const maxKm = kinds === "cycleways" ? 12 : 25;
  for (const el of json.elements ?? []) {
    const trail = trailFromOverpassWay(el, { minKm, maxKm });
    if (!trail) continue;
    if (kinds === "sgrade" && !isHonestOsmSGrade(trail.mtbScale)) continue;
    trails.push(trail);
  }
  trails.sort((a, b) => {
    const sa = a.mtbScale.startsWith("S") ? 0 : 1;
    const sb = b.mtbScale.startsWith("S") ? 0 : 1;
    if (sa !== sb) return sa - sb;
    return b.lengthKm - a.lengthKm;
  });
  const limit = Math.min(200, Math.max(20, opts.limit ?? 80));
  return { trails: trails.slice(0, limit) };
}

function trailFromOverpassWay(
  el: Record<string, unknown>,
  opts?: { minKm?: number; maxKm?: number }
): OsmTrail | null {
  if (el.type !== "way") return null;
  const tags = (el.tags as Record<string, string> | undefined) ?? {};
  const geomRaw = (el.geometry as Array<{ lat: number; lon: number }>) ?? [];
  if (geomRaw.length < 2) return null;
  const geometry: [number, number][] = [];
  for (const g of geomRaw) {
    if (!Number.isFinite(g.lat) || !Number.isFinite(g.lon)) continue;
    geometry.push([g.lon, g.lat]);
  }
  if (geometry.length < 2) return null;
  const simplified = simplify(geometry, 80);
  const lengthKm = pathLengthKm(simplified);
  if (opts?.minKm != null && lengthKm < opts.minKm) return null;
  if (opts?.maxKm != null && lengthKm > opts.maxKm) return null;
  const mtbScale = normalizeMtbScale(
    tags["mtb:scale"] || tags["mtb:scale:imba"] || tags.mtb_scale
  );
  const hasOsmName = Boolean(tags.name || tags["name:de"] || tags.ref);
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
  return {
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
    hasOsmName,
  };
}

/** Single-way Overpass lookup — surface / full geom for overlay tap sheets. */
export async function fetchOsmWayById(
  osmIdRaw: string
): Promise<OsmTrail | null> {
  const osmId = parseOsmWayId(osmIdRaw);
  if (!osmId) return null;
  const query = `
[out:json][timeout:12];
way(${osmId});
out body geom;
`.trim();
  const json = await overpass(query, 14000);
  if (!json) return null;
  for (const el of json.elements ?? []) {
    const trail = trailFromOverpassWay(el);
    if (trail) return trail;
  }
  return null;
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
