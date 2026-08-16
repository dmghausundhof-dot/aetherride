import type { BikeOverlayClass, BikeOverlayFamily } from "./bikeOverlayClass";
import {
  BIKE_OVERLAY_COLORS,
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
  BIKE_OVERLAY_COLORS.unrated,
];

type LinePaint = {
  id: string;
  cls: Exclude<BikeOverlayClass, "hidden">;
  filter: unknown[];
  color: unknown;
  width: number;
  dasharray?: number[];
};

const LAYER_PAINT: LinePaint[] = [
  {
    id: BIKE_OVERLAY_LAYER_IDS.mtb,
    cls: "mtb",
    filter: ["==", ["get", "bike_class"], "mtb"],
    color: MTB_COLOR,
    width: 2.4,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.mtb_unrated,
    cls: "mtb_unrated",
    filter: ["==", ["get", "bike_class"], "mtb_unrated"],
    color: BIKE_OVERLAY_COLORS.unrated,
    width: 1.6,
    dasharray: [2, 1.4],
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.gravel,
    cls: "gravel",
    filter: ["==", ["get", "bike_class"], "gravel"],
    color: BIKE_OVERLAY_COLORS.gravel,
    width: 2,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.road,
    cls: "road",
    filter: ["==", ["get", "bike_class"], "road"],
    color: BIKE_OVERLAY_COLORS.road,
    width: 2.2,
  },
  {
    id: BIKE_OVERLAY_LAYER_IDS.urban,
    cls: "urban",
    filter: ["==", ["get", "bike_class"], "urban"],
    color: BIKE_OVERLAY_COLORS.urban,
    width: 1.8,
  },
];

export type BikeOverlayMapLike = {
  getSource: (id: string) => unknown;
  addSource: (id: string, spec: unknown) => void;
  removeSource?: (id: string) => void;
  getLayer: (id: string) => unknown;
  addLayer: (spec: object) => void;
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
};

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
    if (!(opts.extraOn ?? []).includes("mtb")) on.delete("mtb");
    if (!(opts.extraOn ?? []).includes("mtb_unrated")) on.delete("mtb_unrated");
  }
  if (p.category === "gravel") {
    on.add("gravel");
    on.add("road");
  }
  if (p.category === "urban") on.add("road");
  if (p.category === "hike") {
    on.add("mtb");
    on.add("mtb_unrated");
  }
  return on;
}

let lastOverlaySourceKey = "";

export function addBikeOverlayLayers(
  map: BikeOverlayMapLike,
  opts: {
    url: string;
    kind: "pmtiles" | "geojson";
    family: BikeOverlayFamily;
    visible: boolean;
    extraOn?: BikeOverlayClass[];
    rideProfileId?: RideProfileId | null;
  }
) {
  const sourceKey = `${opts.kind}:${opts.url}`;
  if (
    map.getSource(BIKE_OVERLAY_SOURCE_ID) &&
    lastOverlaySourceKey &&
    lastOverlaySourceKey !== sourceKey
  ) {
    for (const layer of LAYER_PAINT) {
      if (map.getLayer(layer.id)) map.removeLayer?.(layer.id);
    }
    map.removeSource?.(BIKE_OVERLAY_SOURCE_ID);
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

  for (const layer of LAYER_PAINT) {
    if (map.getLayer(layer.id)) continue;
    map.addLayer({
      id: layer.id,
      type: "line",
      source: BIKE_OVERLAY_SOURCE_ID,
      ...(sourceLayer ? { "source-layer": sourceLayer } : {}),
      filter: layer.filter,
      minzoom: layer.cls === "road" || layer.cls === "mtb" ? 5 : 9,
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
        "line-opacity": 0.85,
        ...(layer.dasharray ? { "line-dasharray": layer.dasharray } : {}),
      },
    });
  }

  applyBikeOverlayVisibility(map, {
    family: opts.family,
    visible: opts.visible,
    extraOn: opts.extraOn,
    rideProfileId: opts.rideProfileId,
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
    const hide =
      !opts.visible || resolvedFilter === false || !on.has(layer.cls);

    if (hide) {
      map.setLayoutProperty(layer.id, "visibility", "none");
      continue;
    }

    map.setFilter(layer.id, resolvedFilter);
    map.setLayoutProperty(layer.id, "visibility", "visible");
    const active = on.has(layer.cls);
    const highlighted = active && (layer.cls !== "mtb" || highlightMtb);
    map.setPaintProperty(layer.id, "line-opacity", highlighted ? 0.92 : 0.14);
    const width = highlighted && layer.cls === "mtb" ? layer.width * 1.25 : layer.width;
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
