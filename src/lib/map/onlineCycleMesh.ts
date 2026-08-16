/**
 * Online OSM cycle-network overlay (signed icn/ncn/rcn + MTB relations).
 * Not a contraction-hierarchy “mesh” and not a named OSM-Mesh product —
 * a visual route mesh on the live basemap catalog.
 */

import {
  ONLINE_BASEMAP_CDN_ROOT,
  pointInBasemapBbox,
} from "./onlineBasemap";

export const ONLINE_CYCLE_MESH_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/cycle-routes.pmtiles`;
export const ONLINE_CYCLE_MESH_GEOJSON_URL = `${ONLINE_BASEMAP_CDN_ROOT}/cycle-routes.geojson`;

/** Same bbox as the dach-z11 online basemap — the mesh is DACH, not Europe. */
export const ONLINE_CYCLE_MESH_BBOX: [number, number, number, number] = [
  5.8, 45.75, 17.25, 55.15,
];

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
]);

export function packHasDetailBikeOverlay(regionId: string | null | undefined): boolean {
  return Boolean(regionId && DETAIL_BIKE_OVERLAY_PACKS.has(regionId));
}

export function pointInOnlineCycleMesh(lng: number, lat: number): boolean {
  return pointInBasemapBbox(lng, lat, ONLINE_CYCLE_MESH_BBOX);
}

/** CDN PMTiles of signed cycle routes on the DACH online Blatt. */
export function onlineCycleMeshPmtilesUrl(
  lng: number,
  lat: number
): string | null {
  if (!pointInOnlineCycleMesh(lng, lat)) return null;
  return ONLINE_CYCLE_MESH_PMTILES_URL;
}

export function onlineCycleMeshGeojsonUrl(
  lng: number,
  lat: number
): string | null {
  if (!pointInOnlineCycleMesh(lng, lat)) return null;
  return ONLINE_CYCLE_MESH_GEOJSON_URL;
}

export function overlayHref(path: string, origin: string): string {
  if (/^https?:\/\//i.test(path)) return path;
  return `${origin}${path}`;
}
