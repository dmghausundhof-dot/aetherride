/**
 * Online OSM cycle-network overlay (signed icn/ncn/rcn + MTB relations).
 * Not a contraction-hierarchy “mesh” and not a named OSM-Mesh product —
 * a visual route mesh on the live basemap catalog.
 *
 * At atlas zoom the signed mesh stays on (per Blatt). From z10, country ways
 * (DACH / NL / BE / IT) plus city packs cover the network; pack PMTiles win
 * when they are denser. France/UK/Catalonia countryside uses live OSM.
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

/** Country-wide OSM ways — only files that exist on the CDN. */
export const DACH_WAYS_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/dach-ways.pmtiles`;
export const NL_WAYS_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/nl-ways.pmtiles`;
export const BE_WAYS_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/be-ways.pmtiles`;
export const ITALY_WAYS_PMTILES_URL = `${ONLINE_BASEMAP_CDN_ROOT}/italy-ways.pmtiles`;

/** Same bbox as the dach-z11 online basemap. */
export const ONLINE_CYCLE_MESH_BBOX: [number, number, number, number] = [
  5.8, 45.75, 17.25, 55.15,
];

export type CountryWaysSheet = {
  id: string;
  url: string;
  bbox: [number, number, number, number];
};

export const COUNTRY_WAYS_SHEETS: readonly CountryWaysSheet[] = [
  {
    id: "nl-ways",
    url: NL_WAYS_PMTILES_URL,
    bbox: [3.2, 50.75, 7.25, 53.7],
  },
  {
    id: "be-ways",
    url: BE_WAYS_PMTILES_URL,
    bbox: [2.4, 49.4, 6.45, 51.55],
  },
  {
    id: "italy-ways",
    url: ITALY_WAYS_PMTILES_URL,
    bbox: [6.6, 36.6, 18.55, 47.1],
  },
  {
    id: "dach-ways",
    url: DACH_WAYS_PMTILES_URL,
    bbox: ONLINE_CYCLE_MESH_BBOX,
  },
];

export function pointInNlWays(lng: number, lat: number): boolean {
  if (lng < 3.2 || lng > 7.25 || lat > 53.7) return false;
  if (lng >= 5.5) return lat >= 50.75;
  return lat >= 51.15;
}

export function countryWaysPmtilesUrl(
  lng: number,
  lat: number
): string | null {
  if (pointInNlWays(lng, lat)) return NL_WAYS_PMTILES_URL;
  for (const s of COUNTRY_WAYS_SHEETS) {
    if (s.id === "nl-ways") continue;
    if (pointInBasemapBbox(lng, lat, s.bbox)) return s.url;
  }
  return null;
}

/** Ways tiles start at z10 — switch from signed mesh as soon as they exist. */
export const BIKE_WAYS_MIN_ZOOM = 10;

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
  "strasbourg",
  "bordeaux",
  "nantes",
  "toulouse",
  "nice",
  "marseille",
  "lille",
  "montpellier",
  "grenoble",
  "dijon",
  "chambery",
  "clermont-ferrand",
  "reims",
  "rennes",
  "rouen",
  "alsace-vins",
  "nancy-moselle",
  "jura-fr",
  "amsterdam",
  "utrecht",
  "rotterdam",
  "den-haag",
  "eindhoven",
  "groningen",
  "milano",
  "torino",
  "firenze",
  "roma",
  "napoli",
  "bari",
]);

/** Non-DACH city packs — dachRegions only knows DACH envelopes. */
const EXTRA_DETAIL_PACK_BBOXES: Record<
  string,
  [number, number, number, number]
> = {
  paris: [2.2, 48.8, 2.48, 48.92],
  lyon: [4.7, 45.65, 5.05, 45.9],
  bordeaux: [-0.72, 44.72, -0.4, 44.95],
  nantes: [-1.7, 47.12, -1.4, 47.32],
  toulouse: [1.28, 43.48, 1.6, 43.72],
  nice: [7.1, 43.62, 7.4, 43.78],
  marseille: [5.22, 43.2, 5.52, 43.4],
  lille: [2.92, 50.52, 3.22, 50.75],
  montpellier: [3.75, 43.52, 4.02, 43.7],
  grenoble: [5.58, 45.08, 5.9, 45.32],
  dijon: [4.9, 47.22, 5.2, 47.42],
  chambery: [5.8, 45.48, 6.05, 45.68],
  clermont: [2.9, 45.68, 3.22, 45.9],
  "clermont-ferrand": [2.9, 45.68, 3.22, 45.9],
  reims: [3.9, 49.18, 4.18, 49.35],
  rennes: [-1.78, 48.05, -1.55, 48.18],
  rouen: [0.95, 49.35, 1.22, 49.52],
  amsterdam: [4.75, 52.3, 5.02, 52.43],
  utrecht: [5.05, 52.04, 5.2, 52.15],
  rotterdam: [4.4, 51.85, 4.58, 51.98],
  "den-haag": [4.22, 52.02, 4.4, 52.14],
  eindhoven: [5.4, 51.4, 5.55, 51.5],
  groningen: [6.5, 53.18, 6.65, 53.28],
  milano: [9.05, 45.38, 9.3, 45.55],
  torino: [7.55, 45, 7.8, 45.15],
  firenze: [11.15, 43.7, 11.35, 43.85],
  roma: [12.35, 41.8, 12.65, 42],
  napoli: [14.15, 40.8, 14.35, 40.92],
  bari: [16.8, 41.08, 17, 41.18],
};

export function extraDetailPackIdForPoint(
  lng: number,
  lat: number
): string | null {
  const hits = Object.entries(EXTRA_DETAIL_PACK_BBOXES).filter(
    ([id, bbox]) =>
      packHasDetailBikeOverlay(id) && pointInBasemapBbox(lng, lat, bbox)
  );
  if (!hits.length) return null;
  hits.sort((a, b) => {
    const aa = (a[1][2] - a[1][0]) * (a[1][3] - a[1][1]);
    const bb = (b[1][2] - b[1][0]) * (b[1][3] - b[1][1]);
    return aa - bb;
  });
  return hits[0][0];
}

export function browseUsesLiveNetworkFallback(kind: OnlineBikeOverlayKind) {
  return kind !== "ways";
}

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
 * Mesh at atlas zoom. At z ≥ 10: city pack, else country ways (NL/BE/IT/DACH),
 * else signed mesh. France/UK/Catalonia countryside uses live OSM in the app.
 */
export function chooseOnlineBikeOverlay(opts: {
  regionId?: string | null;
  lng: number;
  lat: number;
  zoom: number;
  currentStyle?: string | null;
  archiveId?: string | null;
}): OnlineBikeOverlayChoice {
  const packId =
    (opts.regionId && packHasDetailBikeOverlay(opts.regionId)
      ? opts.regionId
      : null) ?? extraDetailPackIdForPoint(opts.lng, opts.lat);
  const packWays = detailBikeOverlayPmtilesUrl(packId);
  if (packWays && opts.zoom >= BIKE_WAYS_MIN_ZOOM) {
    return {
      kind: "ways",
      url: packWays,
      regionId: packId,
    };
  }
  if (opts.zoom >= BIKE_WAYS_MIN_ZOOM) {
    const countryWays = countryWaysPmtilesUrl(opts.lng, opts.lat);
    if (countryWays) {
      return {
        kind: "ways",
        url: countryWays,
        regionId: packId ?? opts.regionId ?? null,
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
