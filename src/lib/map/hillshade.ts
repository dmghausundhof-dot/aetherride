/**
 * 2D hillshade on the live catalog — not a new PMTiles extract.
 * Terrarium DEM from AWS Open Data (Mapzen tiles).
 */

export const HILLSHADE_SOURCE_ID = "terrain-dem";
export const HILLSHADE_LAYER_ID = "hillshade";

export const HILLSHADE_TILES = [
  "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png",
] as const;

export const HILLSHADE_ATTRIBUTION = "© Mapzen / AWS Terrain";

export const HILLSHADE_SOURCE = {
  type: "raster-dem" as const,
  tiles: [...HILLSHADE_TILES],
  tileSize: 256,
  maxzoom: 15,
  encoding: "terrarium" as const,
  attribution: HILLSHADE_ATTRIBUTION,
};

export const HILLSHADE_LAYER = {
  id: HILLSHADE_LAYER_ID,
  type: "hillshade" as const,
  source: HILLSHADE_SOURCE_ID,
  paint: {
    "hillshade-exaggeration": 0.14,
    "hillshade-shadow-color": "#6a7a72",
    "hillshade-highlight-color": "#f6f8f6",
    "hillshade-accent-color": "#9aa8a0",
    "hillshade-illumination-direction": 315,
  },
};

export type HillshadeMapLike = {
  getSource: (id: string) => unknown;
  addSource: (id: string, spec: unknown) => void;
  getLayer: (id: string) => unknown;
  addLayer: (spec: object, beforeId?: string) => void;
};

/** Insert under roads so the Hof palette still reads. */
export function hillshadeBeforeLayerId(
  getLayer: (id: string) => unknown
): string | undefined {
  for (const id of ["roads", "road_minor", "highway_minor", "places"]) {
    if (getLayer(id)) return id;
  }
  return undefined;
}

export function applyHillshade(map: HillshadeMapLike): void {
  // Catalog PMTiles only. OSM raster / Stadia fallback have no `protomaps`
  // source — skip so DEM errors cannot fight the real basemap fallback.
  if (!map.getSource("protomaps")) return;
  if (!map.getSource(HILLSHADE_SOURCE_ID)) {
    map.addSource(HILLSHADE_SOURCE_ID, HILLSHADE_SOURCE);
  }
  if (map.getLayer(HILLSHADE_LAYER_ID)) return;
  const before = hillshadeBeforeLayerId((id) => map.getLayer(id));
  // MapLibre GL JS: addLayer(layer, beforeId?) — insert under roads.
  if (before) map.addLayer(HILLSHADE_LAYER, before);
  else map.addLayer(HILLSHADE_LAYER);
}
