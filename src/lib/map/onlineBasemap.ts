/**
 * CDN PMTiles overview archives for the live (online) map.
 * Empty NEXT_PUBLIC_PMTILES_URL still uses this catalog — do not fall
 * through to OSM and ignore regional extracts.
 */

export const ONLINE_BASEMAP_CDN_ROOT =
  "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap";

export type OnlineBasemapId =
  | "dach-z11"
  | "france-west-z11"
  | "alps-south-z11"
  | "benelux-z11"
  | "italy-north-z11"
  | "catalonia-pyrenees-z11"
  | "uk-south-z11";

export type OnlineBasemapArchive = {
  id: OnlineBasemapId;
  /** west, south, east, north */
  bbox: [number, number, number, number];
  styleUrl: string;
};

/** Rider-facing names — never show archive ids like `uk-south-z11` on the site. */
export type OnlineBasemapRider = {
  id: OnlineBasemapId;
  name: string;
  area: string;
  teaser: string;
  hole: string;
  /** Preview camera [lng, lat] */
  center: [number, number];
  zoom: number;
};

export const MAP_ATTRIBUTION = "© OpenStreetMap · Protomaps";

export const MAP_ATTRIBUTION_HREF = {
  osm: "https://www.openstreetmap.org/copyright",
  protomaps: "https://protomaps.com/",
} as const;

function styleUrl(id: OnlineBasemapId): string {
  return `${ONLINE_BASEMAP_CDN_ROOT}/${id}-style.json`;
}

export const ONLINE_BASEMAP_ARCHIVES: readonly OnlineBasemapArchive[] = [
  {
    id: "uk-south-z11",
    bbox: [-1.5, 50.5, 1.8, 52.5],
    styleUrl: styleUrl("uk-south-z11"),
  },
  {
    id: "italy-north-z11",
    bbox: [11.5, 43.5, 14.1, 46.15],
    styleUrl: styleUrl("italy-north-z11"),
  },
  {
    id: "catalonia-pyrenees-z11",
    bbox: [-2.2, 41.15, 3.35, 43.55],
    styleUrl: styleUrl("catalonia-pyrenees-z11"),
  },
  {
    id: "alps-south-z11",
    bbox: [5.55, 43.4, 11.6, 45.9],
    styleUrl: styleUrl("alps-south-z11"),
  },
  {
    id: "benelux-z11",
    bbox: [2.4, 49.4, 7.25, 53.75],
    styleUrl: styleUrl("benelux-z11"),
  },
  {
    id: "france-west-z11",
    bbox: [-5.3, 42.3, 5.85, 51.1],
    styleUrl: styleUrl("france-west-z11"),
  },
  {
    id: "dach-z11",
    bbox: [5.8, 45.75, 17.25, 55.15],
    styleUrl: styleUrl("dach-z11"),
  },
];

function bboxArea(bbox: [number, number, number, number]): number {
  return (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
}

export function pointInBasemapBbox(
  lng: number,
  lat: number,
  bbox: [number, number, number, number]
): boolean {
  return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
}

export function archiveIdFromStyleUrl(raw: string | null | undefined): OnlineBasemapId | null {
  if (!raw) return null;
  const u = raw.trim().toLowerCase();
  if (!u) return null;
  if (u.includes("catalonia-pyrenees-z")) return "catalonia-pyrenees-z11";
  if (u.includes("italy-north-z")) return "italy-north-z11";
  if (u.includes("uk-south-z")) return "uk-south-z11";
  if (u.includes("benelux-z")) return "benelux-z11";
  if (u.includes("alps-south-z")) return "alps-south-z11";
  if (u.includes("france-west-z")) return "france-west-z11";
  if (
    u.includes("dach-z11") ||
    u.includes("dach-z12") ||
    u.includes("dach-z13") ||
    u.includes("/basemap/dach-z")
  ) {
    return "dach-z11";
  }
  return null;
}

export function isCdnOverviewBasemap(raw: string): boolean {
  return archiveIdFromStyleUrl(raw) != null;
}

/** All seven z11 archives are overview tiles — never street-level HUD. */
export function isOverviewOnlyBasemap(raw: string): boolean {
  return isCdnOverviewBasemap(raw);
}

export function isStreetLevelBasemap(raw: string): boolean {
  const u = raw.trim();
  if (!u) return false;
  return !isOverviewOnlyBasemap(u);
}

export function envLocksOnlineBasemapStyle(envUrl: string | undefined): boolean {
  const u = envUrl?.trim() ?? "";
  if (!u) return false;
  return !isCdnOverviewBasemap(u);
}

export function basemapArchiveIdForLngLat(
  lng: number,
  lat: number,
  currentId?: string | null
): OnlineBasemapId | null {
  if (currentId) {
    const cur = ONLINE_BASEMAP_ARCHIVES.find((a) => a.id === currentId);
    if (cur && pointInBasemapBbox(lng, lat, cur.bbox)) return cur.id;
  }
  const hits = ONLINE_BASEMAP_ARCHIVES.filter((a) =>
    pointInBasemapBbox(lng, lat, a.bbox)
  );
  if (!hits.length) return null;
  hits.sort((a, b) => bboxArea(a.bbox) - bboxArea(b.bbox));
  return hits[0].id;
}

export function onlineBasemapStyleUrl(
  lng: number,
  lat: number,
  currentStyle?: string | null
): string {
  const currentId = archiveIdFromStyleUrl(currentStyle ?? null);
  const id =
    basemapArchiveIdForLngLat(lng, lat, currentId) ?? currentId ?? "dach-z11";
  const found = ONLINE_BASEMAP_ARCHIVES.find((a) => a.id === id);
  return found?.styleUrl ?? styleUrl("dach-z11");
}

/**
 * Display order for the website: how a rider groups the map, not smallest-bbox.
 * Matching still uses ONLINE_BASEMAP_ARCHIVES (tightest hit + hysteresis).
 */
export const ONLINE_BASEMAP_RIDER: readonly OnlineBasemapRider[] = [
  {
    id: "dach-z11",
    name: "DACH",
    area: "Deutschland · Österreich · Schweiz",
    teaser: "Der Alltag vor dem Tor: Feierabend, Alpenrand, Mittelland.",
    hole: "Polen und Skandinavien liegen außerhalb. Prag sitzt im Blatt — Tschechien ist kein Loch.",
    center: [9.2, 49.0],
    zoom: 5.4,
  },
  {
    id: "france-west-z11",
    name: "Frankreich",
    area: "Westlich der DACH-Kante",
    teaser: "Paris, Bretagne, Loire, Bordeaux — das große westliche Blatt.",
    hole: "Korsika und Übersee fehlen. Die Südostalpen sind ein eigenes Blatt.",
    center: [0.4, 46.7],
    zoom: 5.2,
  },
  {
    id: "alps-south-z11",
    name: "Alpen-Süd",
    area: "Nizza · Grenoble · Gardasee",
    teaser: "Südliche Alpen und obere italienische Seen, nicht ganz Italien.",
    hole: "Rom, der Süden und die Adria östlich von Venedig sind draußen.",
    center: [8.6, 44.65],
    zoom: 6.2,
  },
  {
    id: "benelux-z11",
    name: "Benelux",
    area: "Niederlande · Belgien · Luxemburg",
    teaser: "Flaches Land, NRW-West-Überlapp — ein Blatt, kein Benelux-Staatspack.",
    hole: "Norddeutschland bleibt DACH. Dänemark ist ein Loch.",
    center: [4.85, 51.55],
    zoom: 6.4,
  },
  {
    id: "italy-north-z11",
    name: "Norditalien",
    area: "Veneto · Friaul · Emilia",
    teaser: "Venedig, Triest, Rimini — östlich vom Alpen-Süd-Blatt.",
    hole: "Kein ganzes Italien. Südlich der Po-Ebene bleibt die Karte leer.",
    center: [12.8, 44.85],
    zoom: 6.6,
  },
  {
    id: "catalonia-pyrenees-z11",
    name: "Katalonien / Pyrenäen",
    area: "Barcelona · Pyrenäen · Baskenküste",
    teaser: "Ein Streifen am Mittelmeer, nicht die Iberische Halbinsel.",
    hole: "Madrid, Andalusien und Portugal sind Löcher.",
    center: [0.55, 42.35],
    zoom: 6.5,
  },
  {
    id: "uk-south-z11",
    name: "Südengland",
    area: "London · Südosten",
    teaser: "Ein Blatt um die Themse — nicht das Vereinigte Königreich.",
    hole: "Schottland, Wales, der Norden und Irland fehlen.",
    center: [0.15, 51.5],
    zoom: 7.2,
  },
];

export function riderBasemap(id: OnlineBasemapId): OnlineBasemapRider {
  return ONLINE_BASEMAP_RIDER.find((r) => r.id === id) ?? ONLINE_BASEMAP_RIDER[0];
}

export function archiveById(
  id: OnlineBasemapId
): OnlineBasemapArchive | undefined {
  return ONLINE_BASEMAP_ARCHIVES.find((a) => a.id === id);
}

export function riderBasemapForLngLat(
  lng: number,
  lat: number,
  currentId?: string | null
): OnlineBasemapRider | null {
  const id = basemapArchiveIdForLngLat(lng, lat, currentId);
  if (!id) return null;
  return riderBasemap(id);
}
