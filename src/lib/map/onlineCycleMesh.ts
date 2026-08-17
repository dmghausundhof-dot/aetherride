/**
 * Online OSM cycle-network overlay (signed icn/ncn/rcn + MTB relations).
 * Not a contraction-hierarchy “mesh” and not a named OSM-Mesh product —
 * a visual route mesh on the live basemap catalog.
 *
 * At atlas zoom the signed mesh stays on (per Blatt). Past z11, DACH-wide
 * ways (cycleway/path/track) cover the whole DACH Blatt; pack PMTiles still
 * win when they are denser.
 */

import {
  ONLINE_BASEMAP_CDN_ROOT,
  archiveIdFromStyleUrl,
  basemapArchiveIdForLngLat,
  pointInBasemapBbox,
  type OnlineBasemapId,
} from "./onlineBasemap";

export const ONLINE_PACK_CDN_ROOT = ONLINE_BASEMAP_CDN_ROOT.replace(
  /\/basemap$/,
  ""
);

export const ONLINE_CYCLE_MESH_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/cycle-routes.pmtiles`;
export const ONLINE_CYCLE_MESH_GEOJSON_URL = `${ONLINE_BASEMAP_CDN_ROOT}/cycle-routes.geojson`;

/** DACH-wide OSM ways (cycleway/path/track) — not limited to Hausberg packs. */
export const DACH_WAYS_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/dach-ways.pmtiles`;

/** Same bbox as the dach-z11 online basemap. */
export const ONLINE_CYCLE_MESH_BBOX: [number, number, number, number] = [
  5.8, 45.75, 17.25, 55.15,
];

/** Past the z11 atlas: pack ways (path/track/cycleway) replace the signed mesh. */
export const BIKE_WAYS_MIN_ZOOM = 12;

/**
 * Signed icn/ncn/rcn PMTiles per online Blatt.
 * DACH keeps the historic `cycle-routes.pmtiles` filename.
 */
/** Only sheets that actually have a mesh file on the CDN (no 404). */
export const ONLINE_CYCLE_MESH_FILES: Partial<Record<OnlineBasemapId, string>> =
  {
    "dach-z11": "cycle-routes.pmtiles",
    "france-west-z11": "cycle-routes-france-west.pmtiles",
    "alps-south-z11": "cycle-routes-alps-south.pmtiles",
    "benelux-z11": "cycle-routes-benelux.pmtiles",
    "italy-north-z11": "cycle-routes-italy-north.pmtiles",
    "italy-center-z11": "cycle-routes-italy-center.pmtiles",
    "italy-south-z11": "cycle-routes-italy-south.pmtiles",
    "catalonia-pyrenees-z11": "cycle-routes-catalonia-pyrenees.pmtiles",
    "uk-south-z11": "cycle-routes-uk-south.pmtiles",
  };

/** Region packs that already publish a way-level bike-overlay on the CDN. */
export const DETAIL_BIKE_OVERLAY_PACKS = new Set([
  "rhein-neckar",
  "schwarzwald-nord",
  "vosges",
  "innsbruck",
  "kitzbuehel",
  "zermatt",
  "davos",
  "st-moritz",
  "interlaken",
  "morzine",
  "annecy",
  "lyon",
  "paris",
]);

export type OnlineBikeOverlayKind = "ways" | "mesh" | "none";

export type OnlineBikeOverlayChoice = {
  kind: OnlineBikeOverlayKind;
  url: string | null;
  regionId: string | null;
};

export function packHasDetailBikeOverlay(regionId: string | null | undefined): boolean {
  return Boolean(regionId && DETAIL_BIKE_OVERLAY_PACKS.has(regionId));
}

/** Direct CDN PMTiles — MapLibre range-requests, no Vercel hop. */
export function detailBikeOverlayPmtilesUrl(
  regionId: string | null | undefined
): string | null {
  if (!packHasDetailBikeOverlay(regionId) || !regionId) return null;
  return `${ONLINE_PACK_CDN_ROOT}/${regionId}/bike-overlay.pmtiles`;
}

export function pointInDachWays(lng: number, lat: number): boolean {
  return pointInBasemapBbox(lng, lat, ONLINE_CYCLE_MESH_BBOX);
}

export function dachWaysPmtilesUrl(lng: number, lat: number): string | null {
  if (!pointInDachWays(lng, lat)) return null;
  return DACH_WAYS_PMTILES_URL;
}

function archiveIdForMesh(
  lng: number,
  lat: number,
  current?: string | null
): OnlineBasemapId | null {
  const fromStyle = archiveIdFromStyleUrl(current ?? null);
  const fromId =
    current && current in ONLINE_CYCLE_MESH_FILES
      ? (current as OnlineBasemapId)
      : null;
  return basemapArchiveIdForLngLat(lng, lat, fromId ?? fromStyle);
}

export function cycleMeshPmtilesUrlForArchive(
  id: OnlineBasemapId | null | undefined
): string | null {
  if (!id) return null;
  const file = ONLINE_CYCLE_MESH_FILES[id];
  if (!file) return null;
  return `${ONLINE_BASEMAP_CDN_ROOT}/${file}`;
}

export function cycleMeshGeojsonUrlForArchive(
  id: OnlineBasemapId | null | undefined
): string | null {
  if (!id) return null;
  const file = ONLINE_CYCLE_MESH_FILES[id];
  if (!file) return null;
  return `${ONLINE_BASEMAP_CDN_ROOT}/${file.replace(/\.pmtiles$/, ".geojson")}`;
}

/**
 * Mesh at atlas zoom. At z ≥ 12: pack ways if denser, else DACH-wide ways
 * everywhere in the Blatt — not only ten Hausberg chips.
 */
export function chooseOnlineBikeOverlay(opts: {
  regionId?: string | null;
  lng: number;
  lat: number;
  zoom: number;
  currentStyle?: string | null;
  archiveId?: string | null;
}): OnlineBikeOverlayChoice {
  const packWays = detailBikeOverlayPmtilesUrl(opts.regionId);
  if (packWays && opts.zoom >= BIKE_WAYS_MIN_ZOOM) {
    return {
      kind: "ways",
      url: packWays,
      regionId: opts.regionId ?? null,
    };
  }
  if (opts.zoom >= BIKE_WAYS_MIN_ZOOM) {
    const dachWays = dachWaysPmtilesUrl(opts.lng, opts.lat);
    if (dachWays) {
      return {
        kind: "ways",
        url: dachWays,
        regionId: opts.regionId ?? null,
      };
    }
  }
  const mesh = onlineCycleMeshPmtilesUrl(
    opts.lng,
    opts.lat,
    opts.archiveId ?? opts.currentStyle
  );
  if (mesh) {
    return {
      kind: "mesh",
      url: mesh,
      regionId: opts.regionId ?? null,
    };
  }
  return { kind: "none", url: null, regionId: opts.regionId ?? null };
}

export function pointInOnlineCycleMesh(
  lng: number,
  lat: number,
  current?: string | null
): boolean {
  return onlineCycleMeshPmtilesUrl(lng, lat, current) != null;
}

/** CDN PMTiles of signed cycle routes on the Blatt under the camera. */
export function onlineCycleMeshPmtilesUrl(
  lng: number,
  lat: number,
  current?: string | null
): string | null {
  return cycleMeshPmtilesUrlForArchive(archiveIdForMesh(lng, lat, current));
}

export function onlineCycleMeshGeojsonUrl(
  lng: number,
  lat: number,
  current?: string | null
): string | null {
  return cycleMeshGeojsonUrlForArchive(archiveIdForMesh(lng, lat, current));
}

export function overlayHref(path: string, origin: string): string {
  if (/^https?:\/\//i.test(path)) return path;
  return `${origin}${path}`;
}
