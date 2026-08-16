/**
 * CDN PMTiles overview archives for the live (online) map.
 * Empty NEXT_PUBLIC_PMTILES_URL still uses this catalog — do not fall
 * through to OSM and ignore France-west / Alps-south.
 */

export const ONLINE_BASEMAP_CDN_ROOT =
  "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap";

export type OnlineBasemapId =
  | "dach-z11"
  | "france-west-z11"
  | "alps-south-z11";

export type OnlineBasemapArchive = {
  id: OnlineBasemapId;
  /** west, south, east, north */
  bbox: [number, number, number, number];
  styleUrl: string;
};

function styleUrl(id: OnlineBasemapId): string {
  return `${ONLINE_BASEMAP_CDN_ROOT}/${id}-style.json`;
}

export const ONLINE_BASEMAP_ARCHIVES: readonly OnlineBasemapArchive[] = [
  {
    id: "alps-south-z11",
    bbox: [5.55, 43.4, 11.6, 45.9],
    styleUrl: styleUrl("alps-south-z11"),
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
