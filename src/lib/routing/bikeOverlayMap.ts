import type { BikeOverlayClass, BikeOverlayFamily } from "./bikeOverlayClass";
import {
  BIKE_OVERLAY_COLORS,
  overlayClassesForFamily,
} from "./bikeOverlayClass";

export const BIKE_OVERLAY_SOURCE_ID = "bike-overlay";
export const BIKE_OVERLAY_SOURCE_LAYER = "bike";

export const BIKE_OVERLAY_LAYER_IDS: Record<
  Exclude<BikeOverlayClass, "hidden">,
  string
> = {
  mtb: "bike-overlay-mtb",
  mtb_unrated: "bike-overlay-mtb-unrated",
  gravel: "bike-overlay-gravel",
  road: "bike-overlay-road",
  urban: "bike-overlay-urban",
};

const MTB_COLOR: unknown = [
  "match",
  ["get", "mtb_scale"],
  "S0",
  BIKE_OVERLAY_COLORS.S0,
  "S1",
  BIKE_OVERLAY_COLORS.S1,
  "S2",
  BIKE_OVERLAY_COLORS.S2,
  "S3",
  BIKE_OVERLAY_COLORS.S3,
  BIKE_OVERLAY_COLORS.unrated,
];

type LinePaint = {
  id: string;
  filter: unknown[];
  color: unknown;
  width: number;
  dasharray?: number[];
};

const LAYER_PAINT: LinePaint[] = [
  {
    id: BIKE_OVERLAY_LAYER_IDS.mtb,
    filter: ["==", ["get", "bike_class"], "mtb"],
    color: MTB_COLOR,
    width: 2.4,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.mtb_unrated,
    filter: ["==", ["get", "bike_class"], "mtb_unrated"],
    color: BIKE_OVERLAY_COLORS.unrated,
    width: 1.6,
    dasharray: [2, 1.4],
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.gravel,
    filter: ["==", ["get", "bike_class"], "gravel"],
    color: BIKE_OVERLAY_COLORS.gravel,
    width: 2,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.road,
    filter: ["==", ["get", "bike_class"], "road"],
    color: BIKE_OVERLAY_COLORS.road,
    width: 2.2,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.urban,
    filter: ["==", ["get", "bike_class"], "urban"],
    color: BIKE_OVERLAY_COLORS.urban,
    width: 1.8,
  },
];

export type BikeOverlayMapLike = {
  getSource: (id: string) => unknown;
  addSource: (id: string, spec: object) => void;
  getLayer: (id: string) => unknown;
  addLayer: (spec: object) => void;
  setLayoutProperty: (id: string, key: string, value: unknown) => void;
  setPaintProperty: (id: string, key: string, value: unknown) => void;
};

export function addBikeOverlayLayers(
  map: BikeOverlayMapLike,
  opts: {
    url: string;
    kind: "pmtiles" | "geojson";
    family: BikeOverlayFamily;
    visible: boolean;
    /** Extra classes the user toggled on. */
    extraOn?: BikeOverlayClass[];
  }
) {
  if (!map.getSource(BIKE_OVERLAY_SOURCE_ID)) {
    if (opts.kind === "pmtiles") {
      const url = opts.url.startsWith("pmtiles://")
        ? opts.url
        : `pmtiles://${opts.url}`;
      map.addSource(BIKE_OVERLAY_SOURCE_ID, {
        type: "vector",
        url,
        attribution: "© OpenStreetMap",
      });
    } else {
      map.addSource(BIKE_OVERLAY_SOURCE_ID, {
        type: "geojson",
        data: opts.url,
        attribution: "© OpenStreetMap",
      });
    }
  }

  const sourceLayer =
    opts.kind === "pmtiles" ? BIKE_OVERLAY_SOURCE_LAYER : undefined;

  for (const layer of LAYER_PAINT) {
    if (map.getLayer(layer.id)) continue;
    map.addLayer({
      id: layer.id,
      type: "line",
      source: BIKE_OVERLAY_SOURCE_ID,
      ...(sourceLayer ? { "source-layer": sourceLayer } : {}),
      filter: layer.filter,
      layout: {
        "line-cap": "round",
        "line-join": "round",
        visibility: "visible",
      },
      paint: {
        "line-color": layer.color,
        "line-width": [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          layer.width * 0.5,
          14,
          layer.width,
        ],
        "line-opacity": 0.85,
        ...(layer.dasharray ? { "line-dasharray": layer.dasharray } : {}),
      },
    });
  }

  applyBikeOverlayVisibility(map, {
    family: opts.family,
    visible: opts.visible,
    extraOn: opts.extraOn,
  });
}

export function applyBikeOverlayVisibility(
  map: BikeOverlayMapLike,
  opts: {
    family: BikeOverlayFamily;
    visible: boolean;
    extraOn?: BikeOverlayClass[];
  }
) {
  const on = new Set<string>(overlayClassesForFamily(opts.family));
  for (const extra of opts.extraOn ?? []) {
    if (extra !== "hidden") on.add(extra);
  }
  for (const [cls, layerId] of Object.entries(BIKE_OVERLAY_LAYER_IDS)) {
    if (!map.getLayer(layerId)) continue;
    if (!opts.visible) {
      map.setLayoutProperty(layerId, "visibility", "none");
      continue;
    }
    const active = on.has(cls);
    map.setLayoutProperty(layerId, "visibility", "visible");
    map.setPaintProperty(layerId, "line-opacity", active ? 0.88 : 0.16);
  }
}

/** RN bbox from data/routing/regions/rhein-neckar.json */
export const RHEIN_NECKAR_BBOX = [8.2, 49.2, 9.0, 49.6] as const;

export function pointInRheinNeckar(lng: number, lat: number): boolean {
  const [w, s, e, n] = RHEIN_NECKAR_BBOX;
  return lng >= w && lng <= e && lat >= s && lat <= n;
}
