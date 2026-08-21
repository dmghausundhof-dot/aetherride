import {
  BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP,
  browseNetworkBeforeLayerIdFromGet,
} from "@/lib/map/browseMapStack";
import type { BikeOverlayClass, BikeOverlayFamily } from "./bikeOverlayClass";
import {
  BIKE_OVERLAY_COLORS,
  BIKE_OVERLAY_SURFACE_DIRT,
  BIKE_OVERLAY_SURFACE_GRAVEL,
  BIKE_OVERLAY_SURFACE_PAVED,
  overlayClassesForFamily,
} from "./bikeOverlayClass";
import {
  getProfile,
  overlayScaleLabels,
  overlayScaleMatchValues,
  prefersUnratedTrails,
  type RideProfileId,
} from "./profiles";

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
  "S3+",
  BIKE_OVERLAY_COLORS.S3,
  BIKE_OVERLAY_COLORS.unrated,
];

/**
 * Color cycleway/path/track by OSM `surface` when set.
 * Missing field OR empty string (tippecanoe often encodes `surface: ""`)
 * keeps [fallback] so class colors still read — not muted grey.
 */
export function bikeOverlaySurfaceLineColor(fallback: string): unknown[] {
  const surfaceStr: unknown[] = [
    "downcase",
    ["to-string", ["coalesce", ["get", "surface"], ""]],
  ];
  return [
    "case",
    [
      "any",
      ["!", ["has", "surface"]],
      ["==", surfaceStr, ""],
    ],
    fallback,
    [
      "match",
      surfaceStr,
      [...BIKE_OVERLAY_SURFACE_PAVED],
      BIKE_OVERLAY_COLORS.road,
      [...BIKE_OVERLAY_SURFACE_GRAVEL],
      BIKE_OVERLAY_COLORS.gravel,
      [...BIKE_OVERLAY_SURFACE_DIRT],
      BIKE_OVERLAY_COLORS.dirt,
      BIKE_OVERLAY_COLORS.unrated,
    ],
  ];
}

type LinePaint = {
  id: string;
  cls: Exclude<BikeOverlayClass, "hidden">;
  filter: unknown[];
  color: unknown;
  width: number;
  dasharray?: number[];
};

const LAYER_PAINT_BY_ID: Record<string, LinePaint> = {
  [BIKE_OVERLAY_LAYER_IDS.mtb_unrated]: {
    id: BIKE_OVERLAY_LAYER_IDS.mtb_unrated,
    cls: "mtb_unrated",
    filter: ["==", ["get", "bike_class"], "mtb_unrated"],
    color: bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.unrated),
    width: 1.6,
    dasharray: [2, 1.4],
  },
  [BIKE_OVERLAY_LAYER_IDS.gravel]: {
    id: BIKE_OVERLAY_LAYER_IDS.gravel,
    cls: "gravel",
    filter: ["==", ["get", "bike_class"], "gravel"],
    color: bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.gravel),
    width: 1.7,
  },
  [BIKE_OVERLAY_LAYER_IDS.mtb]: {
    id: BIKE_OVERLAY_LAYER_IDS.mtb,
    cls: "mtb",
    filter: ["==", ["get", "bike_class"], "mtb"],
    color: MTB_COLOR,
    width: 2.4,
  },
  [BIKE_OVERLAY_LAYER_IDS.road]: {
    id: BIKE_OVERLAY_LAYER_IDS.road,
    cls: "road",
    filter: ["==", ["get", "bike_class"], "road"],
    color: bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.road),
    width: 1.85,
  },
  [BIKE_OVERLAY_LAYER_IDS.urban]: {
    id: BIKE_OVERLAY_LAYER_IDS.urban,
    cls: "urban",
    filter: ["==", ["get", "bike_class"], "urban"],
    color: bikeOverlaySurfaceLineColor(BIKE_OVERLAY_COLORS.urban),
    width: 1.45,
  },
};

/** Bottom → top, under labels. Same order as the Browse-Karte stack. */
const LAYER_PAINT: LinePaint[] = BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP.map(
  (id) => LAYER_PAINT_BY_ID[id]
);

function overlayLineOpacity(cls: Exclude<BikeOverlayClass, "hidden">): number {
  if (cls === "road" || cls === "urban" || cls === "gravel") return 0.34;
  return 0.7;
}

export type BikeOverlayMapLike = {
  getSource: (id: string) => unknown;
  addSource: (id: string, spec: unknown) => void;
  removeSource?: (id: string) => void;
  getLayer: (id: string) => unknown;
  addLayer: (spec: object, beforeId?: string) => void;
  removeLayer?: (id: string) => void;
  setLayoutProperty: (id: string, key: string, value: unknown) => void;
  setPaintProperty: (id: string, key: string, value: unknown) => void;
  setFilter: (id: string, filter: unknown) => void;
};

export type BikeOverlayApplyOpts = {
  family: BikeOverlayFamily;
  visible: boolean;
  extraOn?: BikeOverlayClass[];
  /** RideProfile SSOT — filtert MTB nach S-Skala und hebt Matches hervor. */
  rideProfileId?: RideProfileId | null;
  /** Hide OSM `highway=track` (Feldwege) — same as the app layer toggle. */
  hideFarmTracks?: boolean;
};

const FARM_TRACK_HIGHWAY_FILTER: unknown[] = [
  "!=",
  ["downcase", ["to-string", ["coalesce", ["get", "highway"], ""]]],
  "track",
];

/** Drop untagged farm tracks from an overlay class filter. */
export function bikeOverlayExcludeFarmTracks(
  filter: unknown[] | false
): unknown[] | false {
  if (filter === false) return false;
  return ["all", filter, FARM_TRACK_HIGHWAY_FILTER];
}

/**
 * MapLibre-Filter je Overlay-Klasse.
 * `false` = Layer ausblenden (z. B. Downhill ohne S0 / ohne Unrated).
 */
export function bikeOverlayLayerFilter(
  cls: Exclude<BikeOverlayClass, "hidden">,
  rideProfileId?: RideProfileId | null
): unknown[] | false {
  const classFilter: unknown[] = ["==", ["get", "bike_class"], cls];
  if (!rideProfileId) return classFilter;

  if (cls === "mtb") {
    const values = overlayScaleMatchValues(rideProfileId);
    if (values.length === 0) return false;
    return [
      "all",
      classFilter,
      [
        "in",
        ["to-string", ["coalesce", ["get", "mtb_scale"], ""]],
        ["literal", values],
      ],
    ];
  }

  if (cls === "mtb_unrated") {
    return prefersUnratedTrails(rideProfileId) ? classFilter : false;
  }

  return classFilter;
}

export function overlayClassesOn(opts: BikeOverlayApplyOpts): Set<string> {
  const on = new Set<string>(overlayClassesForFamily(opts.family));
  for (const extra of opts.extraOn ?? []) {
    if (extra !== "hidden") on.add(extra);
  }
  if (!opts.rideProfileId) return on;

  const p = getProfile(opts.rideProfileId);
  const labels = overlayScaleLabels(opts.rideProfileId);
  if (labels.length > 0) on.add("mtb");
  if (prefersUnratedTrails(opts.rideProfileId)) on.add("mtb_unrated");
  else on.delete("mtb_unrated");

  if (p.category === "road") {
    on.add("road");
    on.add("urban");
    if (!(opts.extraOn ?? []).includes("mtb")) on.delete("mtb");
    if (!(opts.extraOn ?? []).includes("mtb_unrated")) on.delete("mtb_unrated");
  }
  if (p.category === "gravel" || p.category === "ebike") {
    on.add("gravel");
    on.add("road");
  }
  if (p.category === "hike") {
    on.add("mtb");
    on.add("mtb_unrated");
  }
  return on;
}

let lastOverlaySourceKey = "";

export function removeBikeOverlayLayers(map: BikeOverlayMapLike) {
  for (const layer of LAYER_PAINT) {
    if (map.getLayer(layer.id)) map.removeLayer?.(layer.id);
  }
  if (map.getSource(BIKE_OVERLAY_SOURCE_ID)) {
    map.removeSource?.(BIKE_OVERLAY_SOURCE_ID);
  }
  lastOverlaySourceKey = "";
}

export function addBikeOverlayLayers(
  map: BikeOverlayMapLike,
  opts: {
    url: string;
    kind: "pmtiles" | "geojson";
    family: BikeOverlayFamily;
    visible: boolean;
    extraOn?: BikeOverlayClass[];
    rideProfileId?: RideProfileId | null;
    hideFarmTracks?: boolean;
    /** Ways tiles start ~z10; signed mesh can show from atlas zoom. */
    minzoom?: number;
  }
) {
  const sourceKey = `${opts.kind}:${opts.url}`;
  if (
    map.getSource(BIKE_OVERLAY_SOURCE_ID) &&
    lastOverlaySourceKey &&
    lastOverlaySourceKey !== sourceKey
  ) {
    removeBikeOverlayLayers(map);
  }

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
    lastOverlaySourceKey = sourceKey;
  }

  const sourceLayer =
    opts.kind === "pmtiles" ? BIKE_OVERLAY_SOURCE_LAYER : undefined;
  const beforeId = browseNetworkBeforeLayerIdFromGet((id) => map.getLayer(id));

  for (const layer of LAYER_PAINT) {
    if (map.getLayer(layer.id)) continue;
    const spec = {
      id: layer.id,
      type: "line",
      source: BIKE_OVERLAY_SOURCE_ID,
      ...(sourceLayer ? { "source-layer": sourceLayer } : {}),
      filter: layer.filter,
      minzoom:
        opts.minzoom ??
        (layer.cls === "road" || layer.cls === "mtb" ? 5 : 9),
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
          5,
          layer.width * 0.55,
          10,
          layer.width * 0.85,
          14,
          layer.width,
        ],
        "line-opacity": overlayLineOpacity(layer.cls),
        ...(layer.dasharray ? { "line-dasharray": layer.dasharray } : {}),
      },
    };
    if (beforeId) map.addLayer(spec, beforeId);
    else map.addLayer(spec);
  }

  applyBikeOverlayVisibility(map, {
    family: opts.family,
    visible: opts.visible,
    extraOn: opts.extraOn,
    rideProfileId: opts.rideProfileId,
    hideFarmTracks: opts.hideFarmTracks,
  });
}

export function applyBikeOverlayVisibility(
  map: BikeOverlayMapLike,
  opts: BikeOverlayApplyOpts
) {
  const on = overlayClassesOn(opts);
  const highlightMtb = Boolean(
    opts.rideProfileId && overlayScaleLabels(opts.rideProfileId).length > 0
  );

  for (const layer of LAYER_PAINT) {
    if (!map.getLayer(layer.id)) continue;
    const filter = bikeOverlayLayerFilter(layer.cls, opts.rideProfileId);
    const extraForced = (opts.extraOn ?? []).includes(layer.cls);
    const resolvedFilter =
      filter === false && extraForced
        ? (["==", ["get", "bike_class"], layer.cls] as unknown[])
        : filter;
    const farmFilter = opts.hideFarmTracks
      ? bikeOverlayExcludeFarmTracks(resolvedFilter)
      : resolvedFilter;
    const hide =
      !opts.visible || farmFilter === false || !on.has(layer.cls);

    if (hide) {
      map.setLayoutProperty(layer.id, "visibility", "none");
      continue;
    }

    map.setFilter(layer.id, farmFilter);
    map.setLayoutProperty(layer.id, "visibility", "visible");
    map.setPaintProperty(layer.id, "line-color", layer.color);
    map.setPaintProperty(layer.id, "line-opacity", overlayLineOpacity(layer.cls));
    const width =
      highlightMtb && layer.cls === "mtb" ? layer.width * 1.25 : layer.width;
    map.setPaintProperty(layer.id, "line-width", [
      "interpolate",
      ["linear"],
      ["zoom"],
      5,
      width * 0.55,
      10,
      width * 0.85,
      14,
      width,
    ]);
  }
}

/** RN bbox from data/routing/regions/rhein-neckar.json */
export const RHEIN_NECKAR_BBOX = [8.2, 49.2, 9.0, 49.6] as const;

export function pointInRheinNeckar(lng: number, lat: number): boolean {
  const [w, s, e, n] = RHEIN_NECKAR_BBOX;
  return lng >= w && lng <= e && lat >= s && lat <= n;
}
