/**
 * Outdooractive Enrichment — normalisierte Touren (nicht Routing-Truth).
 */

import { allowDemoContent } from "@/lib/config/allowDemoContent";

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
  role: "enrichment_eu";
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
    summary: "OA-Beispiel Schwarzwald — Live-IDs wenn Projekt-Katalog regional filtert.",
    url: "https://www.outdooractive.com/",
    center: [8.425, 48.642],
    source: "demo",
  },
  {
    id: "oa-demo-schauinsland",
    title: "Schauinsland Trail-Idee (Beispiel)",
    type: "tour",
    difficulty: "S1–S2",
    lengthKm: 22,
    elevationM: 980,
    durationMin: 130,
    summary: "OA-Beispiel Freiburg — Enrichment, keine Routing-Wahrheit.",
    url: "https://www.outdooractive.com/",
    center: [7.898, 47.912],
    source: "demo",
  },
  {
    id: "oa-demo-dreisam",
    title: "Dreisam City-Schleife (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 12,
    elevationM: 80,
    durationMin: 45,
    summary: "OA-Beispiel Urban Freiburg.",
    url: "https://www.outdooractive.com/",
    center: [7.845, 47.995],
    source: "demo",
  },
  {
    id: "oa-demo-kaiserstuhl",
    title: "Kaiserstuhl Rennrad (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 48,
    elevationM: 620,
    durationMin: 140,
    summary: "OA-Beispiel Road/Gravel westlich Freiburg.",
    url: "https://www.outdooractive.com/",
    center: [7.67, 48.09],
    source: "demo",
  },
  {
    id: "oa-demo-bodensee",
    title: "Bodensee Südufer (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 72,
    elevationM: 280,
    durationMin: 200,
    summary: "OA-Beispiel Road/E-Trekking.",
    url: "https://www.outdooractive.com/",
    center: [9.18, 47.66],
    source: "demo",
  },
  {
    id: "oa-demo-stuttgart",
    title: "Stuttgart Höhenpark (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 22,
    elevationM: 340,
    durationMin: 70,
    summary: "OA-Beispiel Urban Stuttgart.",
    url: "https://www.outdooractive.com/",
    center: [9.16, 48.76],
    source: "demo",
  },
  {
    id: "oa-demo-inn",
    title: "Inn-Radweg (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 34,
    elevationM: 120,
    durationMin: 90,
    summary: "OA-Beispiel flache Road-Tour.",
    url: "https://www.outdooractive.com/",
    center: [12.17, 47.56],
    source: "demo",
  },
  {
    id: "oa-demo-kitz",
    title: "Gravel Loop Kitzbühel (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 62,
    elevationM: 890,
    durationMin: 180,
    summary: "OA-Beispiel Tirol Gravel.",
    url: "https://www.outdooractive.com/",
    center: [12.39, 47.45],
    source: "demo",
  },
  {
    id: "oa-demo-hochkoenig",
    title: "E-MTB Hochkönig (Beispiel)",
    type: "tour",
    difficulty: "S2–S3",
    lengthKm: 41,
    elevationM: 1580,
    durationMin: 165,
    summary: "OA-Beispiel alpine E-MTB.",
    url: "https://www.outdooractive.com/",
    center: [13.1, 47.42],
    source: "demo",
  },
  {
    id: "oa-demo-tegernsee",
    title: "Tegernsee Gravel Mix (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 45,
    elevationM: 780,
    durationMin: 150,
    summary: "OA-Beispiel Bayern Gravel.",
    url: "https://www.outdooractive.com/",
    center: [11.76, 47.71],
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
    summary: "OA-Beispiel Alpbachtal.",
    url: "https://www.outdooractive.com/",
    center: [11.944, 47.399],
    source: "demo",
  },
  {
    id: "oa-demo-wilder-kaiser",
    title: "Wilder Kaiser Höhenweg (Beispiel)",
    type: "tour",
    difficulty: "T2",
    lengthKm: 14,
    elevationM: 980,
    durationMin: 300,
    summary: "OA-Beispiel Wandern — nicht als Bike-Trail.",
    url: "https://www.outdooractive.com/",
    center: [12.3, 47.56],
    source: "demo",
  },
  {
    id: "oa-demo-vosges",
    title: "Vosges Ballon d'Alsace (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 42,
    elevationM: 1100,
    durationMin: 180,
    summary: "OA-Beispiel Frankreich — Vogesen Gravel/MTB.",
    url: "https://www.outdooractive.com/",
    center: [6.84, 47.82],
    source: "demo",
  },
  {
    id: "oa-demo-alsace-road",
    title: "Route des Vins d'Alsace (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 55,
    elevationM: 480,
    durationMin: 160,
    summary: "OA-Beispiel Frankreich — Elsass Rennrad/E-Trekking.",
    url: "https://www.outdooractive.com/",
    center: [7.45, 48.08],
    source: "demo",
  },
  {
    id: "oa-demo-annecy",
    title: "Lac d'Annecy Rundfahrt (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 40,
    elevationM: 220,
    durationMin: 120,
    summary: "OA-Beispiel Frankreich — Annecy Road/Urban.",
    url: "https://www.outdooractive.com/",
    center: [6.13, 45.9],
    source: "demo",
  },
  {
    id: "oa-demo-morzine",
    title: "Morzine / Portes du Soleil (Beispiel)",
    type: "tour",
    difficulty: "S2–S3",
    lengthKm: 28,
    elevationM: 1200,
    durationMin: 150,
    summary: "OA-Beispiel Frankreich — Alpine Trails.",
    url: "https://www.outdooractive.com/",
    center: [6.71, 46.18],
    source: "demo",
  },
  {
    id: "oa-demo-provence",
    title: "Luberon Gravel Mix (Beispiel)",
    type: "tour",
    difficulty: "mittel",
    lengthKm: 48,
    elevationM: 650,
    durationMin: 170,
    summary: "OA-Beispiel Frankreich — Provence Gravel/Road.",
    url: "https://www.outdooractive.com/",
    center: [5.23, 43.84],
    source: "demo",
  },
  {
    id: "oa-demo-bretagne",
    title: "Côte de Granit Rose (Beispiel)",
    type: "tour",
    difficulty: "leicht",
    lengthKm: 38,
    elevationM: 180,
    durationMin: 110,
    summary: "OA-Beispiel Frankreich — Bretagne Küstenradweg.",
    url: "https://www.outdooractive.com/",
    center: [-3.48, 48.83],
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
      o.title ??
      o.name ??
      (o.texts as { title?: string } | undefined)?.title ??
      (typeof o.titleLocalized === "object" && o.titleLocalized
        ? Object.values(o.titleLocalized as Record<string, string>)[0]
        : undefined);
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
      durationMin: toDurationMin(
        typeof duration?.minimal === "number"
          ? duration.minimal
          : typeof duration?.maximal === "number"
            ? duration.maximal
            : typeof o.time === "number"
              ? o.time
              : typeof o.duration === "number"
                ? o.duration
                : undefined
      ),
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

/**
 * OA `metrics.duration.minimal` ist üblicherweise Minuten (auch 30–90).
 * Werte ≥1000 werden als Sekunden interpretiert.
 */
export function toDurationMin(v: number | undefined): number | undefined {
  if (v == null || !Number.isFinite(v) || v <= 0) return undefined;
  if (v >= 1000) return Math.round(v / 60); // Sekunden → Minuten
  return Math.round(v); // bereits Minuten (inkl. kurze Touren < 1 h)
}

/**
 * Behalte Touren in/nahe BBox [minLon,minLat,maxLon,maxLat].
 * Kein weltweiter Fallback — lieber leer (Caller → Demo).
 */
export function filterToursByBbox(
  tours: OutdooractiveTour[],
  bbox: string | null | undefined,
  pad = 0.25
): OutdooractiveTour[] {
  if (!bbox) return tours;
  const parts = bbox.split(",").map(Number);
  if (parts.length < 4 || parts.some((n) => !Number.isFinite(n))) return tours;
  const [minLon, minLat, maxLon, maxLat] = parts;
  const inPad = (padDeg: number) =>
    tours.filter((t) => {
      const c = t.center ?? t.geometry?.[0];
      if (!c) return false;
      const [lng, lat] = c;
      return (
        lng >= minLon - padDeg &&
        lng <= maxLon + padDeg &&
        lat >= minLat - padDeg &&
        lat <= maxLat + padDeg
      );
    });
  for (const p of [pad, 0.6, 1.0]) {
    const hit = inPad(p);
    if (hit.length) return hit;
  }
  return [];
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
  query?: string | null,
  bbox?: string | null
): OutdooractiveResponse {
  if (!allowDemoContent()) {
    return {
      provider: "outdooractive",
      role: "enrichment_eu",
      configured: false,
      query,
      tours: [],
      attribution: "Outdooractive — keine Demo-Touren in Production",
      warning: "Outdooractive nicht konfiguriert oder keine Live-Treffer",
    };
  }
  const q = query?.trim().toLowerCase();
  let tours = q
    ? DEMO_TOURS.filter((t) => t.title.toLowerCase().includes(q))
    : [...DEMO_TOURS];
  // Alle Beispiele (DACH + Frankreich) behalten; Nähe nur für Sortierung
  if (bbox) {
    const parts = bbox.split(",").map(Number);
    if (parts.length >= 4 && parts.every(Number.isFinite)) {
      const cx = (parts[0] + parts[2]) / 2;
      const cy = (parts[1] + parts[3]) / 2;
      tours = [...tours].sort((a, b) => {
        const ca = a.center ?? [cx, cy];
        const cb = b.center ?? [cx, cy];
        return (
          Math.hypot(ca[0] - cx, ca[1] - cy) -
          Math.hypot(cb[0] - cx, cb[1] - cy)
        );
      });
    }
  }
  return {
    provider: "outdooractive",
    role: "enrichment_eu",
    configured: false,
    query,
    tours: tours.length ? tours : DEMO_TOURS,
    attribution: "Demo · Outdooractive API nicht konfiguriert / keine Regionaltreffer",
    warning:
      "Enrichment-only — keine Routing-Wahrheit. Beispiele für DACH + Frankreich.",
  };
}
