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
  const list =
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
    const title = String(
      o.title ?? o.name ?? (o.texts as { title?: string } | undefined)?.title ?? "Tour"
    );
    if (query && !title.toLowerCase().includes(query.toLowerCase())) {
      // soft filter — keep if no match field
    }
    const geo = o.geo as { lon?: number; lat?: number } | undefined;
    tours.push({
      id,
      title,
      type: String(o.type ?? o.category ?? "tour"),
      difficulty: o.difficulty != null ? String(o.difficulty) : undefined,
      lengthKm:
        typeof o.length === "number"
          ? o.length / (o.length > 200 ? 1000 : 1)
          : typeof o.distance === "number"
            ? o.distance
            : undefined,
      elevationM:
        typeof o.ascent === "number"
          ? o.ascent
          : typeof o.elevationGain === "number"
            ? o.elevationGain
            : undefined,
      durationMin:
        typeof o.time === "number"
          ? Math.round(o.time / 60)
          : typeof o.duration === "number"
            ? o.duration
            : undefined,
      summary: o.shortText != null ? String(o.shortText) : undefined,
      url: o.url != null ? String(o.url) : undefined,
      center:
        geo?.lon != null && geo?.lat != null
          ? [geo.lon, geo.lat]
          : undefined,
      source: "outdooractive",
    });
  }
  return tours;
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
