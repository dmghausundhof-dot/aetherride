/**
 * Outdooractive Enrichment — normalisierte Touren (nicht Routing-Truth).
 */

export interface OutdooractiveTour {
  id: string;
  title: string;
  type: string;
  difficulty?: string;
  lengthKm?: number;
  elevationM?: number;
  durationMin?: number;
  summary?: string;
  url?: string;
  /** [lng, lat] wenn bekannt */
  center?: [number, number];
  /** LineString-Koordinaten [lng,lat][] wenn API Geometry liefert */
  geometry?: [number, number][];
  source: "outdooractive" | "demo";
}

export interface OutdooractiveResponse {
  provider: "outdooractive";
  role: "enrichment_dach";
  configured: boolean;
  query?: string | null;
  tours: OutdooractiveTour[];
  attribution: string;
  warning?: string;
}

const DEMO_TOURS: OutdooractiveTour[] = [
  {
    id: "oa-demo-kaltenbronn",
    title: "Kaltenbronn Panorama (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 32,
    elevationM: 890,
    durationMin: 180,
    summary: "Beispiel-Enrichment — echte Touren wenn Outdooractive erreichbar.",
    url: "https://www.outdooractive.com/",
    center: [8.425, 48.642],
    source: "demo",
  },
  {
    id: "oa-demo-alpbach",
    title: "Alpbachtal Trail Mix (Beispiel)",
    type: "tour",
    difficulty: "schwer",
    lengthKm: 26,
    elevationM: 1100,
    durationMin: 160,
    summary: "DACH-Enrichment-Platzhalter — Routing bleibt unabhängig.",
    url: "https://www.outdooractive.com/",
    center: [11.944, 47.399],
    source: "demo",
  },
];

export function normalizeOutdooractivePayload(
  data: unknown,
  query?: string | null
): OutdooractiveTour[] {
  if (!data || typeof data !== "object") return [];
  const root = data as Record<string, unknown>;
  const answer =
    root.answer && typeof root.answer === "object"
      ? (root.answer as Record<string, unknown>)
      : null;
  const list =
    (Array.isArray(answer?.contents) && answer!.contents) ||
    (Array.isArray(root.contents) && root.contents) ||
    (Array.isArray(root.data) && root.data) ||
    (Array.isArray(root.results) && root.results) ||
    (Array.isArray(data) ? data : []);

  const tours: OutdooractiveTour[] = [];
  for (const item of list) {
    if (!item || typeof item !== "object") continue;
    const o = item as Record<string, unknown>;
    const id = String(o.id ?? o.uuid ?? o.oaId ?? "");
    if (!id) continue;
    // ID-only list rows (no title) — skip until hydrated
    const titleRaw =
      o.title ?? o.name ?? (o.texts as { title?: string } | undefined)?.title;
    if (titleRaw == null && Object.keys(o).length <= 2) continue;
    const title = String(titleRaw ?? "Tour");
    if (query && !title.toLowerCase().includes(query.toLowerCase())) {
      // soft filter — keep
    }
    const point = o.point;
    let center: [number, number] | undefined;
    if (Array.isArray(point) && point.length >= 2) {
      center = [Number(point[0]), Number(point[1])];
    }
    const geo = o.geo as { lon?: number; lat?: number } | undefined;
    if (!center && geo?.lon != null && geo?.lat != null) {
      center = [geo.lon, geo.lat];
    }
    const metrics =
      o.metrics && typeof o.metrics === "object"
        ? (o.metrics as Record<string, unknown>)
        : null;
    const elevation =
      metrics?.elevation && typeof metrics.elevation === "object"
        ? (metrics.elevation as Record<string, unknown>)
        : null;
    const duration =
      metrics?.duration && typeof metrics.duration === "object"
        ? (metrics.duration as Record<string, unknown>)
        : null;
    const lengthM =
      typeof metrics?.length === "number" ? metrics.length : undefined;
    const geometry = extractLineString(o);
    const category =
      o.category && typeof o.category === "object"
        ? (o.category as { title?: string; keys?: string[] })
        : null;
    tours.push({
      id,
      title,
      type: String(
        category?.keys?.[0] ?? category?.title ?? o.type ?? o.category ?? "tour"
      ),
      difficulty: o.difficulty != null ? String(o.difficulty) : undefined,
      lengthKm:
        lengthM != null
          ? lengthM / 1000
          : typeof o.length === "number"
            ? o.length / (o.length > 200 ? 1000 : 1)
            : typeof o.distance === "number"
              ? o.distance
              : undefined,
      elevationM:
        typeof elevation?.ascent === "number"
          ? elevation.ascent
          : typeof o.ascent === "number"
            ? o.ascent
            : typeof o.elevationGain === "number"
              ? o.elevationGain
              : undefined,
      durationMin:
        typeof duration?.minimal === "number"
          ? Math.round(duration.minimal / 60)
          : typeof o.time === "number"
            ? Math.round(o.time / 60)
            : typeof o.duration === "number"
              ? o.duration
              : undefined,
      summary:
        o.teaserText != null
          ? String(o.teaserText)
          : o.shortText != null
            ? String(o.shortText)
            : undefined,
      url: o.url != null ? String(o.url) : undefined,
      center: center ?? geometry?.[0],
      geometry,
      source: "outdooractive",
    });
  }
  return tours;
}

function extractLineString(o: Record<string, unknown>): [number, number][] | undefined {
  const candidates = [
    o.geometry,
    o.geoJson,
    o.geojson,
    (o.track as { geometry?: unknown } | undefined)?.geometry,
  ];
  for (const g of candidates) {
    if (!g || typeof g !== "object") continue;
    const geom = g as { type?: string; coordinates?: unknown };
    if (geom.type === "LineString" && Array.isArray(geom.coordinates)) {
      const out: [number, number][] = [];
      for (const c of geom.coordinates) {
        if (Array.isArray(c) && c.length >= 2) {
          out.push([Number(c[0]), Number(c[1])]);
        }
      }
      if (out.length >= 2) return out;
    }
    if (Array.isArray((g as { coordinates?: unknown }).coordinates)) {
      // bare coordinates array
    }
  }
  if (Array.isArray(o.coordinates)) {
    const out: [number, number][] = [];
    for (const c of o.coordinates) {
      if (Array.isArray(c) && c.length >= 2) {
        out.push([Number(c[0]), Number(c[1])]);
      }
    }
    if (out.length >= 2) return out;
  }
  return undefined;
}

export function outdooractiveDemoResponse(
  query?: string | null
): OutdooractiveResponse {
  const q = query?.trim().toLowerCase();
  const tours = q
    ? DEMO_TOURS.filter((t) => t.title.toLowerCase().includes(q))
    : DEMO_TOURS;
  return {
    provider: "outdooractive",
    role: "enrichment_dach",
    configured: false,
    query,
    tours: tours.length ? tours : DEMO_TOURS,
    attribution: "Demo · Outdooractive API nicht konfiguriert",
    warning:
      "Enrichment-only — keine Routing-Wahrheit. Setze OUTDOORACTIVE_API_KEY + OUTDOORACTIVE_PROJECT_KEY.",
  };
}
