"use client";

import { useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import { Protocol } from "pmtiles";
import "maplibre-gl/dist/maplibre-gl.css";
import type {
  BikeOverlayClass,
  BikeOverlayFamily,
} from "@/lib/routing/bikeOverlayClass";
import {
  addBikeOverlayLayers,
  applyBikeOverlayVisibility,
  BIKE_OVERLAY_SOURCE_ID,
  removeBikeOverlayLayers,
  type BikeOverlayMapLike,
} from "@/lib/routing/bikeOverlayMap";
import {
  BIKE_OVERLAY_QUERY_LAYER_IDS,
  overlayFeatureToHit,
  type OverlayWayHit,
} from "@/lib/routing/overlayHit";
import type { RideProfileId } from "@/lib/routing/profiles";

export type { OverlayWayHit };
import { applyHillshade, HILLSHADE_SOURCE_ID, type HillshadeMapLike } from "@/lib/map/hillshade";
import {
  envLocksOnlineBasemapStyle,
  MAP_ATTRIBUTION,
  onlineBasemapStyleUrl,
} from "@/lib/map/onlineBasemap";
import {
  mapPinAnchor,
  mapPinDisplaySize,
  mapPoiDisplaySize,
  mapPinSvg,
  poiPinSrc,
  routePinSrc,
  resolveMapPinKind,
  type MapPinGlyph,
  type MapPinKind,
  type MapPoiKind,
} from "@/lib/map/mapPinSvg";
import {
  MAP_TAP_AFTER_CAMERA_MS,
  mapClickAfterCameraGesture,
} from "@/lib/map/mapTapGesture";
import {
  planRibbonDimOpacity,
  planRubberBandLngLat,
  planShapeKmChip,
  planShapeRouteId,
} from "@/lib/routing/planDraft";
import { pointAlongRoute, projectOntoRoute } from "@/lib/routing/routeProgress";

export type { MapPinGlyph, MapPinKind, MapPoiKind };

function queryRenderedRouteId(
  map: maplibregl.Map,
  point: { x: number; y: number },
  layerIds: Set<string>,
  pad = 28
): string | null {
  const layers = [...layerIds]
    .flatMap((id) => [`${id}-line`, `${id}-casing`])
    .filter((id) => Boolean(map.getLayer(id)));
  if (!layers.length) return null;
  const feats = map.queryRenderedFeatures(
    [
      [point.x - pad, point.y - pad],
      [point.x + pad, point.y + pad],
    ],
    { layers }
  );
  const hit = feats.find((f) => f.properties?.routeId);
  return hit?.properties?.routeId ? String(hit.properties.routeId) : null;
}

function routeHitPadPx(interactive: boolean): number {
  if (!interactive) return 22;
  if (
    typeof window !== "undefined" &&
    window.matchMedia?.("(pointer: coarse)").matches
  ) {
    return 44;
  }
  return 32;
}

function markerStackZ(kind: MapPinKind, selected?: boolean): number {
  if (selected && kind === "poi") return 5;
  if (kind === "tour" || kind === "start" || kind === "finish") return 4;
  if (kind === "poi") return 3;
  if (kind === "drop") return 2;
  return 3;
}

/** Same pin chrome → reuse DOM (zoom labels must not reload 3D PNGs). */
function markerReuseKey(m: MapMarker): string {
  const kind = resolveMapPinKind(m.id, m.kind);
  return [
    kind,
    m.poiKind ?? "",
    m.lngLat[0].toFixed(6),
    m.lngLat[1].toFixed(6),
    m.color ?? "",
    m.glyph ?? "",
    m.draggable ? "1" : "0",
    m.pulse ? "p" : "",
    m.id.startsWith("shape-handle") ? "h" : "",
  ].join("|");
}

function syncMarkerLabel(el: HTMLElement, m: MapMarker, kind: MapPinKind) {
  let lab = el.querySelector<HTMLElement>(".flowline-pin-label");
  const text = m.label?.trim() ?? "";
  if (!text) {
    lab?.remove();
    return;
  }
  if (!lab) {
    lab = document.createElement("div");
    lab.className = "flowline-pin-label";
    el.appendChild(lab);
  }
  lab.textContent = text;
  lab.style.position = "absolute";
  lab.style.left = "50%";
  lab.style.pointerEvents = "none";
  lab.style.whiteSpace = "nowrap";
  lab.style.fontWeight = "700";
  const inset = kind === "via";
  if (inset) {
    lab.style.top = "50%";
    lab.style.transform = "translate(-50%, -50%)";
    lab.style.fontSize = "11px";
    lab.style.color = kind === "via" ? "#1F1F1F" : "#fff";
    lab.style.marginTop = "";
    lab.style.textShadow = "";
    lab.style.background = "";
    lab.style.border = "";
    lab.style.borderRadius = "";
    lab.style.padding = "";
  } else {
    lab.style.top = "100%";
    lab.style.transform = "translateX(-50%)";
    lab.style.marginTop = kind === "poi" ? "5px" : "3px";
    lab.style.fontSize = kind === "poi" ? "10px" : "10px";
    lab.style.letterSpacing = "0.01em";
    if (kind === "poi") {
      lab.style.color = "#1A120C";
      lab.style.background = "#F4F1EC";
      lab.style.border = "1px solid #FF6A00";
      lab.style.borderRadius = "999px";
      lab.style.padding = "1px 7px";
      lab.style.textShadow = "none";
    } else {
      lab.style.color = "#F4F1EC";
      lab.style.background = "rgba(26,18,12,0.78)";
      lab.style.border = "none";
      lab.style.borderRadius = "999px";
      lab.style.padding = "1px 6px";
      lab.style.textShadow = "none";
    }
  }
}

function syncMarkerCaption(el: HTMLElement, m: MapMarker) {
  let cap = el.querySelector<HTMLElement>(".flowline-pin-caption");
  const text = m.caption?.trim() ?? "";
  if (!text) {
    cap?.remove();
    return;
  }
  if (!cap) {
    cap = document.createElement("div");
    cap.className = "flowline-pin-caption";
    el.appendChild(cap);
  }
  cap.textContent = text;
  cap.style.position = "absolute";
  cap.style.left = "50%";
  cap.style.top = "100%";
  cap.style.transform = "translateX(-50%)";
  cap.style.marginTop = "2px";
  cap.style.pointerEvents = "none";
  cap.style.whiteSpace = "nowrap";
  cap.style.fontSize = "10px";
  cap.style.fontWeight = "700";
  cap.style.color = "#1A120C";
  cap.style.background = "#F4F1EC";
  cap.style.border = "1px solid #FF6A00";
  cap.style.borderRadius = "999px";
  cap.style.padding = "1px 6px";
  cap.style.maxWidth = "120px";
  cap.style.overflow = "hidden";
  cap.style.textOverflow = "ellipsis";
}

function syncPoiChrome(el: HTMLElement, m: MapMarker) {
  const kind = resolveMapPinKind(m.id, m.kind);
  if (kind !== "poi" && kind !== "start" && kind !== "finish") return;
  const { w, h } =
    kind === "poi" ? mapPoiDisplaySize(m.selected) : mapPinDisplaySize(kind);
  el.style.width = `${w}px`;
  el.style.height = `${h}px`;
  el.style.zIndex = String(markerStackZ(kind, m.selected));
  const pin = el.firstElementChild as HTMLElement | null;
  if (!pin) return;
  pin.style.width = "100%";
  pin.style.height = "100%";
  pin.style.opacity = m.selected ? "1" : "0.92";
  pin.style.transform = m.selected ? "scale(1.08)" : "";
  pin.style.transformOrigin = "bottom center";
  const img = pin.querySelector("img");
  if (img) {
    img.width = w;
    img.height = h;
    img.style.width = `${w}px`;
    img.style.height = `${h}px`;
  }
}

function mountRasterPin(
  pin: HTMLElement,
  src: string,
  w: number,
  h: number,
  fallbackSvg: string
) {
  pin.innerHTML = fallbackSvg;
  const img = document.createElement("img");
  img.alt = "";
  img.draggable = false;
  img.width = w;
  img.height = h;
  img.style.width = `${w}px`;
  img.style.height = `${h}px`;
  img.style.display = "block";
  img.style.objectFit = "contain";
  img.style.pointerEvents = "none";
  img.onload = () => {
    pin.replaceChildren(img);
  };
  img.src = src;
}

function createHtmlMapMarker(
  map: maplibregl.Map,
  m: MapMarker,
  onClick: (id: string) => void,
  onDragEnd?: (id: string, lngLat: [number, number]) => void,
  onDrag?: (id: string, lngLat: [number, number]) => void
): maplibregl.Marker {
  const kind = resolveMapPinKind(m.id, m.kind);
  const { w, h } =
    kind === "poi" ? mapPoiDisplaySize(m.selected) : mapPinDisplaySize(kind);
  const isShapeHandle =
    kind === "circle" &&
    (Boolean(m.draggable) || m.id.startsWith("shape-handle"));
  const hit = isShapeHandle ? 44 : w;
  const el = document.createElement("div");
  el.style.position = "relative";
  el.style.width = `${isShapeHandle ? hit : w}px`;
  el.style.height = `${isShapeHandle ? hit : h}px`;
  el.style.cursor = isShapeHandle ? "grab" : "pointer";
  el.style.zIndex = String(markerStackZ(kind, m.selected));
  if (isShapeHandle) el.className = "flowline-shape-handle";
  if (m.id.startsWith("shape-tick")) el.classList.add("flowline-shape-tick");
  const pin = document.createElement("div");
  pin.className = isShapeHandle
    ? "flowline-shape-handle-disc"
    : "flowline-map-pin";
  pin.style.width = isShapeHandle ? `${w}px` : "100%";
  pin.style.height = isShapeHandle ? `${h}px` : "100%";
  pin.style.lineHeight = "0";
  if (isShapeHandle) {
    pin.style.position = "absolute";
    pin.style.left = "50%";
    pin.style.top = "50%";
    pin.style.transform = "translate(-50%, -50%)";
  }
  const rasterSrc =
    kind === "poi"
      ? poiPinSrc(m.poiKind ?? "place")
      : routePinSrc(kind, m.color);
  if (rasterSrc) {
    mountRasterPin(
      pin,
      rasterSrc,
      w,
      h,
      mapPinSvg(kind, m.color, m.glyph, m.poiKind ?? "place")
    );
    if (kind === "poi") {
      pin.style.opacity = m.selected ? "1" : "0.92";
      if (m.selected) {
        pin.style.transform = "scale(1.08)";
        pin.style.transformOrigin = "bottom center";
      }
    }
  } else {
    pin.innerHTML = mapPinSvg(kind, m.color, m.glyph);
  }
  if (kind === "halo" && !m.draggable) {
    el.style.pointerEvents = "none";
  }
  if (kind === "meet" || m.pulse) {
    pin.style.animation =
      kind === "halo"
        ? "flowline-halo-pulse 1.4s ease-in-out infinite"
        : "flowline-pin-pulse 1.7s ease-in-out infinite";
    pin.style.transformOrigin = "center center";
  }
  el.appendChild(pin);
  syncMarkerLabel(el, m, kind);
  syncMarkerCaption(el, m);
  el.addEventListener("click", (ev) => {
    ev.stopPropagation();
    onClick(m.id);
  });
  const marker = new maplibregl.Marker({
    element: el,
    anchor: mapPinAnchor(kind),
    draggable: Boolean(m.draggable),
  })
    .setLngLat(m.lngLat)
    .addTo(map);
  if (m.draggable && (onDragEnd || onDrag)) {
    if (onDrag) {
      marker.on("drag", () => {
        const ll = marker.getLngLat();
        onDrag(m.id, [ll.lng, ll.lat]);
      });
    }
    marker.on("dragend", () => {
      const ll = marker.getLngLat();
      onDragEnd?.(m.id, [ll.lng, ll.lat]);
    });
  }
  return marker;
}

export type MapMarker = {
  id: string;
  lngLat: [number, number];
  color?: string;
  label?: string;
  kind?: MapPinKind;
  glyph?: MapPinGlyph;
  poiKind?: MapPoiKind;
  selected?: boolean;
  draggable?: boolean;
  /** Finish/meet: CSS pulse while the live line is still coming. */
  pulse?: boolean;
  /** Named via under the number — not a generic “on map” placeholder. */
  caption?: string;
};

export type MapRouteRole =
  | "active"
  | "alt"
  | "tour"
  | "approach"
  | "trail"
  | "approx"
  | "steep"
  | "unpaved"
  | "paved"
  | "gravel";

export type MapRouteLayer = {
  id: string;
  geometry: GeoJSON.LineString;
  role: MapRouteRole;
  color?: string;
  width?: number;
  opacity?: number;
  dasharray?: number[];
};

/** Start / vias / dest + live line for Komoot-style rubber-band preview. */
export type PlanShapeAnchors = {
  start: [number, number];
  end: [number, number];
  vias: { id: string; lngLat: [number, number] }[];
  line: [number, number][];
};

const SHAPE_GHOST_SOURCE = "plan-shape-ghost";
const SHAPE_GHOST_LAYER = "plan-shape-rubber";
const SHAPE_HOVER_SOURCE = "plan-shape-hover";

const ROLE_STYLE: Record<
  MapRouteRole,
  {
    color: string;
    width: number;
    opacity: number;
    dasharray?: number[];
    casingColor?: string;
    casingWidth?: number;
  }
> = {
  active: {
    color: "#FF6A00",
    width: 4.5,
    opacity: 0.96,
    casingColor: "#1A120C",
    casingWidth: 8.8,
  },
  alt: {
    color: "#90A4AE",
    width: 3,
    opacity: 0.45,
    casingColor: "#263238",
    casingWidth: 5.6,
  },
  tour: {
    color: "#E65100",
    width: 3.8,
    opacity: 0.84,
    casingColor: "#1A120C",
    casingWidth: 7.6,
  },
  approach: {
    color: "#29B6F6",
    width: 4,
    opacity: 0.88,
    dasharray: [2, 2],
    casingColor: "#0A1A2A",
    casingWidth: 7.4,
  },
  trail: { color: "#B0BEC5", width: 2.5, opacity: 0.55, dasharray: [1.5, 1.5] },
  approx: {
    color: "#78909C",
    width: 3.5,
    opacity: 0.65,
    dasharray: [2, 2],
    casingColor: "#37474F",
    casingWidth: 6.6,
  },
  steep: {
    color: "#FF3B00",
    width: 5.4,
    opacity: 0.94,
  },
  unpaved: {
    color: "#C47B3A",
    width: 4.5,
    opacity: 0.94,
  },
  gravel: {
    color: "#E0B04A",
    width: 4.5,
    opacity: 0.94,
  },
  paved: {
    color: "#5C8FBF",
    width: 4.5,
    opacity: 0.94,
  },
};

interface MapViewProps {
  className?: string;
  center?: [number, number];
  zoom?: number;
  track?: { lat: number; lng: number }[];
  route?: GeoJSON.LineString | null;
  secondaryRoute?: GeoJSON.LineString | null;
  routes?: MapRouteLayer[];
  markers?: MapMarker[];
  showUserLocation?: boolean;
  interactiveSelect?: boolean;
  onMapClick?: (
    lngLat: [number, number],
    mods?: { alt?: boolean }
  ) => void;
  onMapLongPress?: (lngLat: [number, number]) => void;
  onRouteClick?: (routeId: string, lngLat?: [number, number]) => void;
  onOverlayClick?: (hit: OverlayWayHit) => void;
  onMarkerClick?: (id: string) => void;
  onMarkerDragEnd?: (id: string, lngLat: [number, number]) => void;
  /** Grab/drag the painted plan line to drop a via (Komoot). */
  shapeInteractive?: boolean;
  /** Live rubber-band anchors while shaping the plan line / pins. */
  shapeAnchors?: PlanShapeAnchors | null;
  /** km along the live line while hovering it — drives Höhenprofil + disc. */
  onShapeHover?: (km: number | null) => void;
  /** True while the rider is dragging the line or a plan pin (rubber-band). */
  onShapeDragging?: (active: boolean) => void;
  /** Chart scrub / sticky hover — same disc as line hover. */
  hoverKm?: number | null;
  /** Trail magnet while reshaping (Komoot gravity onto paths). */
  snapShapeFinger?: (lngLat: [number, number]) => [number, number];
  onMapReady?: (map: maplibregl.Map) => void;
  onViewChange?: (view: { center: [number, number]; zoom: number }) => void;
  onZoomChange?: (zoom: number) => void;
  fitRoute?: boolean;
  /** Frame these points when no route line is ready (GPS → new pin). */
  fitPoints?: [number, number][];
  bikeOverlayUrl?: string | null;
  bikeOverlayKind?: "pmtiles" | "geojson";
  bikeOverlayFamily?: BikeOverlayFamily;
  bikeOverlayVisible?: boolean;
  bikeOverlayExtraOn?: BikeOverlayClass[];
  bikeOverlayRideProfileId?: RideProfileId | null;
  bikeOverlayMinZoom?: number;
  hideFarmTracks?: boolean;
}

let pmtilesRegistered = false;

function ensurePmtilesProtocol() {
  if (pmtilesRegistered || typeof window === "undefined") return;
  const protocol = new Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);
  pmtilesRegistered = true;
}

function osmRasterStyle(): maplibregl.StyleSpecification {
  return {
    version: 8,
    sources: {
      osm: {
        type: "raster",
        tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
        tileSize: 256,
        attribution: "© OpenStreetMap",
      },
    },
    layers: [
      {
        id: "osm",
        type: "raster",
        source: "osm",
        minzoom: 0,
        maxzoom: 19,
      },
    ],
  };
}

function stadiaStyleUrl(): string | null {
  const key = process.env.NEXT_PUBLIC_STADIA_API_KEY?.trim();
  if (!key) return null;
  return `https://tiles.stadiamaps.com/styles/outdoors.json?api_key=${encodeURIComponent(key)}`;
}

function pmtilesStyleFromUrl(
  pmtilesUrl: string
): maplibregl.StyleSpecification | string {
  const u = pmtilesUrl.toLowerCase();
  const isStyleJson =
    (u.endsWith(".json") || u.includes("/styles/") || u.includes("style.json")) &&
    !u.endsWith(".pmtiles") &&
    !u.includes(".pmtiles?");
  if (isStyleJson) return pmtilesUrl;
  const sourceUrl = pmtilesUrl.startsWith("pmtiles://")
    ? pmtilesUrl
    : `pmtiles://${pmtilesUrl}`;
  return {
    version: 8,
    sources: {
      protomaps: {
        type: "vector",
        url: sourceUrl,
        attribution: MAP_ATTRIBUTION,
      },
    },
    layers: [
      {
        id: "background",
        type: "background",
        paint: { "background-color": "#e8eee9" },
      },
      {
        id: "earth",
        type: "fill",
        source: "protomaps",
        "source-layer": "earth",
        paint: { "fill-color": "#dfe8e2" },
      },
      {
        id: "landuse",
        type: "fill",
        source: "protomaps",
        "source-layer": "landuse",
        paint: { "fill-color": "#c5d9c8", "fill-opacity": 0.7 },
      },
      {
        id: "water",
        type: "fill",
        source: "protomaps",
        "source-layer": "water",
        filter: [
          "all",
          ["match", ["geometry-type"], ["Polygon", "MultiPolygon"], true, false],
          ["!=", ["get", "pmap:kind"], "river"],
          ["!=", ["get", "kind"], "river"],
        ],
        paint: { "fill-color": "#a8c8d8" },
      },
      {
        id: "waterway",
        type: "line",
        source: "protomaps",
        "source-layer": "water",
        filter: ["==", ["geometry-type"], "LineString"],
        layout: {
          "line-cap": "round",
          "line-join": "round",
        },
        paint: {
          "line-color": "#a8c8d8",
          "line-width": [
            "interpolate",
            ["linear"],
            ["zoom"],
            8,
            0.8,
            11,
            1.5,
            14,
            3,
          ],
        },
      },
      {
        id: "roads",
        type: "line",
        source: "protomaps",
        "source-layer": "roads",
        paint: {
          "line-color": [
            "match",
            ["get", "kind"],
            "highway",
            "#3a4a42",
            "major_road",
            "#5c6e66",
            "#8a9a92",
          ],
          "line-width": [
            "interpolate",
            ["linear"],
            ["zoom"],
            6,
            0.3,
            10,
            0.8,
            16,
            2.2,
          ],
        },
      },
    ],
  };
}

function lockedEnvStyle(): maplibregl.StyleSpecification | string | null {
  const pmtilesUrl = process.env.NEXT_PUBLIC_PMTILES_URL?.trim();
  if (!pmtilesUrl || !envLocksOnlineBasemapStyle(pmtilesUrl)) return null;
  return pmtilesStyleFromUrl(pmtilesUrl);
}

/** Web: CDN catalog (named regions) unless env locks a custom style. */
function pickInitialStyle(
  lng: number,
  lat: number
): {
  style: maplibregl.StyleSpecification | string;
  source: "stadia" | "pmtiles" | "osm";
  switchable: boolean;
} {
  const locked = lockedEnvStyle();
  if (locked) return { style: locked, source: "pmtiles", switchable: false };
  return {
    style: onlineBasemapStyleUrl(lng, lat),
    source: "pmtiles",
    switchable: true,
  };
}

function normalizeRoutes(
  routes: MapRouteLayer[] | undefined,
  route: GeoJSON.LineString | null | undefined,
  secondaryRoute: GeoJSON.LineString | null | undefined
): MapRouteLayer[] {
  if (routes?.length) return routes;
  const out: MapRouteLayer[] = [];
  if (secondaryRoute?.coordinates?.length) {
    out.push({ id: "secondary", geometry: secondaryRoute, role: "alt" });
  }
  if (route?.coordinates?.length) {
    out.push({ id: "primary", geometry: route, role: "active" });
  }
  return out;
}

function ensureShapeGhostLayer(map: maplibregl.Map) {
  if (!map.getSource(SHAPE_GHOST_SOURCE)) {
    map.addSource(SHAPE_GHOST_SOURCE, {
      type: "geojson",
      data: { type: "FeatureCollection", features: [] },
    });
  }
  if (map.getLayer(SHAPE_GHOST_SOURCE)) {
    try {
      map.removeLayer(SHAPE_GHOST_SOURCE);
    } catch {
      /* old dashed ghost */
    }
  }
  if (!map.getLayer(SHAPE_GHOST_LAYER)) {
    map.addLayer({
      id: SHAPE_GHOST_LAYER,
      type: "line",
      source: SHAPE_GHOST_SOURCE,
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-color": "#FF6A00",
        "line-width": 4.4,
        "line-opacity": 0.78,
      },
    });
  }
}

function isLivePlanSourceId(id: string): boolean {
  const raw = id.startsWith("route-") ? id.slice("route-".length) : id;
  return planShapeRouteId(raw) || raw === "primary";
}

function setPlanRibbonDimmed(
  map: maplibregl.Map,
  layerIds: Set<string>,
  dim: boolean
) {
  for (const id of layerIds) {
    if (!isLivePlanSourceId(id)) continue;
    try {
      const line = `${id}-line`;
      const casing = `${id}-casing`;
      const chevrons = `${id}-chevrons`;
      if (map.getLayer(line)) {
        map.setPaintProperty(
          line,
          "line-opacity",
          planRibbonDimOpacity(0.96, dim)
        );
      }
      if (map.getLayer(casing)) {
        map.setPaintProperty(
          casing,
          "line-opacity",
          planRibbonDimOpacity(0.88, dim)
        );
      }
      if (map.getLayer(chevrons)) {
        map.setPaintProperty(chevrons, "icon-opacity", dim ? 0 : 0.92);
      }
    } catch {
      /* style reload */
    }
  }
}

function setShapeGhostCoords(
  map: maplibregl.Map,
  coords: [number, number][] | null,
  layerIds?: Set<string>
) {
  try {
    ensureShapeGhostLayer(map);
    const src = map.getSource(SHAPE_GHOST_SOURCE) as
      | maplibregl.GeoJSONSource
      | undefined;
    src?.setData({
      type: "FeatureCollection",
      features:
        coords && coords.length >= 2
          ? [
              {
                type: "Feature",
                properties: {},
                geometry: { type: "LineString", coordinates: coords },
              },
            ]
          : [],
    });
    if (layerIds) {
      setPlanRibbonDimmed(map, layerIds, Boolean(coords && coords.length >= 2));
    }
  } catch {
    /* style reload */
  }
}

function ensureShapeHoverDisc(map: maplibregl.Map) {
  if (!map.getSource(SHAPE_HOVER_SOURCE)) {
    map.addSource(SHAPE_HOVER_SOURCE, {
      type: "geojson",
      data: { type: "FeatureCollection", features: [] },
    });
  }
  const haloId = `${SHAPE_HOVER_SOURCE}-halo`;
  if (!map.getLayer(haloId)) {
    map.addLayer({
      id: haloId,
      type: "circle",
      source: SHAPE_HOVER_SOURCE,
      paint: {
        "circle-radius": 7,
        "circle-color": "#FF6A00",
        "circle-stroke-width": 2.6,
        "circle-stroke-color": "#FFFFFF",
        "circle-opacity": 0.98,
      },
    });
  }
  const kmId = `${SHAPE_HOVER_SOURCE}-km`;
  if (!map.getLayer(kmId)) {
    map.addLayer({
      id: kmId,
      type: "symbol",
      source: SHAPE_HOVER_SOURCE,
      layout: {
        "text-field": ["get", "km"],
        "text-size": 12,
        "text-offset": [0, 1.25],
        "text-anchor": "top",
        "text-allow-overlap": true,
        "text-ignore-placement": true,
      },
      paint: {
        "text-color": "#E65100",
        "text-halo-color": "#FFFFFF",
        "text-halo-width": 1.5,
      },
    });
  }
}

function setShapeHoverDisc(
  map: maplibregl.Map,
  lngLat: [number, number] | null,
  kmLabel?: string | null
) {
  try {
    ensureShapeHoverDisc(map);
    const src = map.getSource(SHAPE_HOVER_SOURCE) as
      | maplibregl.GeoJSONSource
      | undefined;
    src?.setData({
      type: "FeatureCollection",
      features: lngLat
        ? [
            {
              type: "Feature",
              properties: { km: kmLabel?.trim() || "" },
              geometry: { type: "Point", coordinates: lngLat },
            },
          ]
        : [],
    });
  } catch {
    /* style reload */
  }
}

function setShapeHoverAlong(
  map: maplibregl.Map,
  line: [number, number][],
  lngLat: [number, number],
  atFinger: boolean
): number {
  const proj = projectOntoRoute(line, lngLat[1], lngLat[0]);
  const pt = atFinger
    ? lngLat
    : (pointAlongRoute(line, proj.distanceAlongM) as [number, number]);
  setShapeHoverDisc(map, pt, planShapeKmChip(proj.distanceAlongM));
  return proj.distanceAlongM / 1000;
}

function rubberBandFromAnchors(
  anchors: PlanShapeAnchors,
  finger: [number, number],
  dragging?: "start" | "end" | "via" | "line",
  draggingId?: string
): [number, number][] {
  const skip = draggingId
    ? anchors.vias.findIndex((v) => v.id === draggingId)
    : -1;
  return planRubberBandLngLat({
    start: anchors.start,
    end: anchors.end,
    vias: anchors.vias.map((v) => v.lngLat),
    finger,
    line: anchors.line,
    dragging,
    draggingViaIndex: skip >= 0 ? skip : null,
  });
}

function magnetShapeFinger(
  finger: [number, number],
  dragging: "start" | "end" | "via" | "line" | undefined,
  snap?: (lngLat: [number, number]) => [number, number]
): [number, number] {
  if (!snap || dragging === "start" || dragging === "end") return finger;
  return snap(finger);
}

function ensureRouteChevronImage(map: maplibregl.Map) {
  if (map.hasImage("flowline-chevron")) return;
  const canvas = document.createElement("canvas");
  canvas.width = 48;
  canvas.height = 48;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;
  ctx.translate(24, 24);
  ctx.beginPath();
  ctx.moveTo(0, -11);
  ctx.lineTo(10, 10);
  ctx.lineTo(0, 5);
  ctx.lineTo(-10, 10);
  ctx.closePath();
  ctx.fillStyle = "#FFFFFF";
  ctx.fill();
  ctx.lineJoin = "round";
  ctx.lineCap = "round";
  ctx.lineWidth = 2.2;
  ctx.strokeStyle = "#1A120C";
  ctx.stroke();
  map.addImage("flowline-chevron", ctx.getImageData(0, 0, 48, 48));
}

export function MapView({
  className = "",
  center = [8.4, 48.0],
  zoom = 11,
  track = [],
  route = null,
  secondaryRoute = null,
  routes,
  markers = [],
  showUserLocation = false,
  interactiveSelect = false,
  onMapClick,
  onMapLongPress,
  onRouteClick,
  onOverlayClick,
  onMarkerClick,
  onMarkerDragEnd,
  onMapReady,
  onViewChange,
  onZoomChange,
  fitRoute = false,
  fitPoints,
  shapeInteractive = false,
  shapeAnchors = null,
  onShapeHover,
  onShapeDragging,
  hoverKm = null,
  snapShapeFinger,
  bikeOverlayUrl = null,
  bikeOverlayKind = "pmtiles",
  bikeOverlayFamily = "road",
  bikeOverlayVisible = true,
  bikeOverlayExtraOn = [],
  bikeOverlayRideProfileId = null,
  bikeOverlayMinZoom,
  hideFarmTracks = false,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const markerRecsRef = useRef<
    Map<string, { marker: maplibregl.Marker; key: string }>
  >(new Map());
  const layerIdsRef = useRef<Set<string>>(new Set());
  const onClickRef = useRef(onMapClick);
  const onLongPressRef = useRef(onMapLongPress);
  const onRouteClickRef = useRef(onRouteClick);
  const onOverlayClickRef = useRef(onOverlayClick);
  const onMarkerClickRef = useRef(onMarkerClick);
  const onMarkerDragEndRef = useRef(onMarkerDragEnd);
  const onZoomChangeRef = useRef(onZoomChange);
  const interactiveSelectRef = useRef(interactiveSelect);
  const shapeInteractiveRef = useRef(shapeInteractive);
  const shapeAnchorsRef = useRef(shapeAnchors);
  const onShapeHoverRef = useRef(onShapeHover);
  const onShapeDraggingRef = useRef(onShapeDragging);
  const hoverKmRef = useRef(hoverKm);
  const snapShapeFingerRef = useRef(snapShapeFinger);
  const onViewChangeRef = useRef(onViewChange);
  const [ready, setReady] = useState(false);
  const [tileSource, setTileSource] = useState<"stadia" | "pmtiles" | "osm">(
    "osm"
  );
  const [mapError, setMapError] = useState<string | null>(null);
  const fallbackTried = useRef(false);
  const lastFitPointsKey = useRef("");

  onClickRef.current = onMapClick;
  onLongPressRef.current = onMapLongPress;
  onRouteClickRef.current = onRouteClick;
  onOverlayClickRef.current = onOverlayClick;
  onMarkerClickRef.current = onMarkerClick;
  onMarkerDragEndRef.current = onMarkerDragEnd;
  onZoomChangeRef.current = onZoomChange;
  interactiveSelectRef.current = interactiveSelect;
  shapeInteractiveRef.current = shapeInteractive;
  shapeAnchorsRef.current = shapeAnchors;
  onShapeHoverRef.current = onShapeHover;
  onShapeDraggingRef.current = onShapeDragging;
  hoverKmRef.current = hoverKm;
  snapShapeFingerRef.current = snapShapeFinger;
  onViewChangeRef.current = onViewChange;

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const initial = pickInitialStyle(center[0], center[1]);
    setTileSource(initial.source);
    let currentStyleUrl =
      typeof initial.style === "string" ? initial.style : "";

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: initial.style,
      center,
      zoom,
      attributionControl: false,
    });

    map.addControl(
      new maplibregl.NavigationControl({ showCompass: true }),
      "top-right"
    );
    map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right"
    );

    let lastW = 0;
    let lastH = 0;
    let resizeRaf = 0;
    const doResize = () => {
      const el = containerRef.current;
      if (!el) return;
      const w = el.clientWidth;
      const h = el.clientHeight;
      if (w < 2 || h < 2) return;
      if (w === lastW && h === lastH) return;
      lastW = w;
      lastH = h;
      try {
        map.resize();
      } catch {
        /* ignore */
      }
    };
    const scheduleResize = () => {
      if (resizeRaf) return;
      resizeRaf = window.requestAnimationFrame(() => {
        resizeRaf = 0;
        doResize();
      });
    };

    map.on("load", () => {
      setReady(true);
      setMapError(null);
      lastW = 0;
      lastH = 0;
      doResize();
      // second resize after layout settles (desktop flex/absolute)
      window.setTimeout(doResize, 100);
      window.setTimeout(doResize, 400);
      onMapReady?.(map);
      const c0 = map.getCenter();
      onViewChangeRef.current?.({
        center: [c0.lng, c0.lat],
        zoom: map.getZoom(),
      });
      onZoomChangeRef.current?.(map.getZoom());
      if (showUserLocation && navigator.geolocation) {
        const locSize = { w: 22, h: 22 };
        navigator.geolocation.getCurrentPosition((pos) => {
          const el = document.createElement("div");
          el.style.width = `${locSize.w}px`;
          el.style.height = `${locSize.h}px`;
          el.style.pointerEvents = "none";
          el.innerHTML = mapPinSvg("flow", "#FF6A00");
          new maplibregl.Marker({
            element: el,
            anchor: "center",
          })
            .setLngLat([pos.coords.longitude, pos.coords.latitude])
            .addTo(map);
        });
      }
    });

    let suppressClickUntil = 0;
    let holdTimer: number | null = null;
    let holdStart: { x: number; y: number; lng: number; lat: number } | null =
      null;
    let routeDrag: { id: string; x: number; y: number } | null = null;
    let routeDragging = false;
    const clearHold = () => {
      if (holdTimer != null) {
        window.clearTimeout(holdTimer);
        holdTimer = null;
      }
      holdStart = null;
    };
    const setShapeHandleDim = (on: boolean) => {
      wrapRef.current?.classList.toggle("flowline-map-shaping", on);
    };
    const endRouteDrag = () => {
      if (routeDragging) {
        setShapeHandleDim(false);
        onShapeDraggingRef.current?.(false);
        try {
          map.dragPan.enable();
        } catch {
          /* ignore */
        }
      }
      routeDrag = null;
      routeDragging = false;
    };
    const canvas = map.getCanvas();
    const onPointerDown = (ev: PointerEvent) => {
      if (ev.button !== 0) return;
      const lngLat = map.unproject([ev.offsetX, ev.offsetY]);
      holdStart = {
        x: ev.offsetX,
        y: ev.offsetY,
        lng: lngLat.lng,
        lat: lngLat.lat,
      };
      if (shapeInteractiveRef.current) {
        const hit = queryRenderedRouteId(
          map,
          { x: ev.offsetX, y: ev.offsetY },
          layerIdsRef.current,
          routeHitPadPx(true)
        );
        if (hit) routeDrag = { id: hit, x: ev.offsetX, y: ev.offsetY };
      }
      holdTimer = window.setTimeout(() => {
        const start = holdStart;
        holdTimer = null;
        holdStart = null;
        if (!start || !onLongPressRef.current) return;
        if (routeDragging) return;
        suppressClickUntil = Date.now() + MAP_TAP_AFTER_CAMERA_MS;
        onLongPressRef.current([start.lng, start.lat]);
      }, 450);
    };
    const onPointerMove = (ev: PointerEvent) => {
      if (routeDrag && shapeInteractiveRef.current) {
        const dx = ev.offsetX - routeDrag.x;
        const dy = ev.offsetY - routeDrag.y;
        if (dx * dx + dy * dy > 64) {
          if (!routeDragging) {
            routeDragging = true;
            setShapeHandleDim(true);
            onShapeDraggingRef.current?.(true);
            clearHold();
            try {
              map.dragPan.disable();
            } catch {
              /* ignore */
            }
            canvas.style.cursor = "grabbing";
          }
          const anchors = shapeAnchorsRef.current;
          if (routeDragging && anchors) {
            const here = map.unproject([ev.offsetX, ev.offsetY]);
            const finger = magnetShapeFinger(
              [here.lng, here.lat],
              "line",
              snapShapeFingerRef.current
            );
            setShapeGhostCoords(
              map,
              rubberBandFromAnchors(anchors, finger, "line"),
              layerIdsRef.current
            );
            if (anchors.line.length >= 2) {
              const km = setShapeHoverAlong(map, anchors.line, finger, true);
              onShapeHoverRef.current?.(km);
            }
          }
        }
      }
      if (!holdStart) return;
      const dx = ev.offsetX - holdStart.x;
      const dy = ev.offsetY - holdStart.y;
      if (dx * dx + dy * dy > 144) clearHold();
    };
    const onPointerUp = (ev: PointerEvent) => {
      if (routeDragging && routeDrag) {
        suppressClickUntil = Date.now() + MAP_TAP_AFTER_CAMERA_MS;
        const lngLat = map.unproject([ev.offsetX, ev.offsetY]);
        const finger = magnetShapeFinger(
          [lngLat.lng, lngLat.lat],
          "line",
          snapShapeFingerRef.current
        );
        setShapeGhostCoords(map, null, layerIdsRef.current);
        setShapeHoverDisc(map, null);
        onRouteClickRef.current?.(routeDrag.id, finger);
      }
      endRouteDrag();
      clearHold();
    };
    canvas.addEventListener("pointerdown", onPointerDown);
    canvas.addEventListener("pointermove", onPointerMove);
    canvas.addEventListener("pointerup", onPointerUp);
    canvas.addEventListener("pointercancel", () => {
      setShapeGhostCoords(map, null, layerIdsRef.current);
      setShapeHoverDisc(map, null);
      endRouteDrag();
      clearHold();
    });
    map.on("contextmenu", (e) => {
      e.preventDefault();
      if (mapClickAfterCameraGesture(Date.now(), suppressClickUntil)) return;
      onLongPressRef.current?.([e.lngLat.lng, e.lngLat.lat]);
    });
    map.on("movestart", (e) => {
      if (e.originalEvent) {
        suppressClickUntil = Date.now() + MAP_TAP_AFTER_CAMERA_MS;
        clearHold();
      }
    });
    map.on("mousemove", (e) => {
      if (routeDragging) {
        canvas.style.cursor = "grabbing";
        return;
      }
      if (!shapeInteractiveRef.current) {
        setShapeHoverDisc(map, null);
        onShapeHoverRef.current?.(null);
        return;
      }
      const hit = queryRenderedRouteId(
        map,
        e.point,
        layerIdsRef.current,
        routeHitPadPx(true)
      );
      canvas.style.cursor = hit
        ? "grab"
        : interactiveSelectRef.current
          ? "crosshair"
          : "";
      const anchors = shapeAnchorsRef.current;
      if (hit && anchors?.line && anchors.line.length >= 2) {
        const km = setShapeHoverAlong(
          map,
          anchors.line,
          [e.lngLat.lng, e.lngLat.lat],
          false
        );
        onShapeHoverRef.current?.(km);
      } else if (
        hoverKmRef.current != null &&
        anchors?.line &&
        anchors.line.length >= 2
      ) {
        setShapeHoverDisc(
          map,
          pointAlongRoute(anchors.line, hoverKmRef.current * 1000),
          planShapeKmChip(hoverKmRef.current * 1000)
        );
      } else {
        setShapeHoverDisc(map, null);
        onShapeHoverRef.current?.(null);
      }
    });
    canvas.addEventListener("mouseleave", () => {
      const anchors = shapeAnchorsRef.current;
      const km = hoverKmRef.current;
      if (km != null && anchors?.line && anchors.line.length >= 2) {
        setShapeHoverDisc(
          map,
          pointAlongRoute(anchors.line, km * 1000),
          planShapeKmChip(km * 1000)
        );
        return;
      }
      setShapeHoverDisc(map, null);
    });

    map.on("click", (e) => {
      if (mapClickAfterCameraGesture(Date.now(), suppressClickUntil)) return;
      const routeId = queryRenderedRouteId(
        map,
        e.point,
        layerIdsRef.current,
        routeHitPadPx(shapeInteractiveRef.current)
      );
      if (routeId) {
        onRouteClickRef.current?.(routeId, [e.lngLat.lng, e.lngLat.lat]);
        return;
      }
      const overlayLayers = BIKE_OVERLAY_QUERY_LAYER_IDS.filter((id) =>
        Boolean(map.getLayer(id))
      );
      if (
        overlayLayers.length &&
        onOverlayClickRef.current &&
        !interactiveSelectRef.current
      ) {
        const pad = 7;
        const overlayFeats = map.queryRenderedFeatures(
          [
            [e.point.x - pad, e.point.y - pad],
            [e.point.x + pad, e.point.y + pad],
          ],
          { layers: overlayLayers }
        );
        for (const f of overlayFeats) {
          const way = overlayFeatureToHit({
            properties: (f.properties ?? {}) as Record<string, unknown>,
            geometry: f.geometry as {
              type?: string;
              coordinates?: unknown;
            },
          });
          if (way) {
            onOverlayClickRef.current(way);
            return;
          }
        }
      }
      onClickRef.current?.([e.lngLat.lng, e.lngLat.lat], {
        alt: Boolean(
          e.originalEvent &&
            "altKey" in e.originalEvent &&
            (e.originalEvent as MouseEvent).altKey
        ),
      });
    });

    map.on("moveend", () => {
      const c = map.getCenter();
      onViewChangeRef.current?.({
        center: [c.lng, c.lat],
        zoom: map.getZoom(),
      });
      onZoomChangeRef.current?.(map.getZoom());
      if (!initial.switchable || fallbackTried.current) return;
      const next = onlineBasemapStyleUrl(c.lng, c.lat, currentStyleUrl);
      if (!next || next === currentStyleUrl) return;
      currentStyleUrl = next;
      try {
        map.setStyle(next);
        setTileSource("pmtiles");
      } catch (err) {
        console.warn("[MapView] online basemap switch failed", err);
      }
    });

    map.on("error", (e) => {
      const err = e as { error?: { message?: string }; sourceId?: string };
      const msg = err?.error?.message || String(err?.error || "Kartenfehler");
      const sourceId = err?.sourceId ?? "";
      console.warn("[MapView]", msg);
      if (
        sourceId === BIKE_OVERLAY_SOURCE_ID ||
        sourceId === HILLSHADE_SOURCE_ID ||
        msg.includes("bike-overlay") ||
        msg.includes("terrain-dem") ||
        msg.includes("hillshade")
      ) {
        return;
      }
      // Already on OSM, or overlay-only errors: don't wipe layers with setStyle.
      if (fallbackTried.current || initial.source === "osm") return;
      fallbackTried.current = true;
      const stadia = stadiaStyleUrl();
      if (stadia) {
        setMapError(
          "Kartenanbieter nicht erreichbar – wechsle auf Stadia-Fallback."
        );
        setTileSource("stadia");
        try {
          map.setStyle(stadia);
        } catch (setErr) {
          console.warn("[MapView] setStyle fallback failed", setErr);
        }
        return;
      }
      setMapError(
        "Kartenanbieter nicht erreichbar – wechsle auf OpenStreetMap-Fallback."
      );
      setTileSource("osm");
      try {
        map.setStyle(osmRasterStyle());
      } catch (setErr) {
        console.warn("[MapView] setStyle fallback failed", setErr);
      }
    });

    // Observe container size (Discover absolute layout). Guard against
    // map.resize() ↔ ResizeObserver loops that freeze the tab.
    const ro =
      typeof ResizeObserver !== "undefined"
        ? new ResizeObserver(() => scheduleResize())
        : null;
    if (containerRef.current && ro) {
      ro.observe(containerRef.current);
      if (containerRef.current.parentElement) {
        ro.observe(containerRef.current.parentElement);
      }
    }

    mapRef.current = map;

    return () => {
      clearHold();
      wrapRef.current?.classList.remove("flowline-map-shaping");
      canvas.removeEventListener("pointerdown", onPointerDown);
      canvas.removeEventListener("pointermove", onPointerMove);
      canvas.removeEventListener("pointerup", clearHold);
      canvas.removeEventListener("pointercancel", clearHold);
      if (resizeRaf) window.cancelAnimationFrame(resizeRaf);
      ro?.disconnect();
      markersRef.current.forEach((m) => m.remove());
      markersRef.current = [];
      markerRecsRef.current.clear();
      map.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- mount once
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    map.setCenter(center);
  }, [center, ready]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    const line = shapeAnchors?.line;
    if (hoverKm == null || !line || line.length < 2) {
      if (hoverKm == null) setShapeHoverDisc(map, null);
      return;
    }
    setShapeHoverDisc(map, pointAlongRoute(line, hoverKm * 1000));
  }, [hoverKm, shapeAnchors, ready]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    const apply = () => {
      try {
        applyHillshade(map as unknown as HillshadeMapLike);
      } catch (err) {
        console.warn("[MapView] hillshade", err);
      }
      try {
        const waterFilter: unknown = [
          "all",
          ["match", ["geometry-type"], ["Polygon", "MultiPolygon"], true, false],
          ["!=", ["get", "pmap:kind"], "river"],
          ["!=", ["get", "kind"], "river"],
          ["!=", ["get", "pmap:kind"], "stream"],
          ["!=", ["get", "kind"], "stream"],
          ["!=", ["get", "pmap:kind"], "canal"],
          ["!=", ["get", "kind"], "canal"],
        ];
        for (const id of ["water", "water-fill", "water_fill"]) {
          if (map.getLayer(id)) map.setFilter(id, waterFilter as never);
        }
      } catch (err) {
        console.warn("[MapView] water filter", err);
      }
    };
    apply();
    map.on("style.load", apply);
    return () => {
      map.off("style.load", apply);
    };
  }, [ready]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    const overlayMap = map as unknown as BikeOverlayMapLike;
    if (!bikeOverlayUrl) {
      try {
        removeBikeOverlayLayers(overlayMap);
      } catch {
        /* overlay not attached */
      }
      return;
    }
    const apply = () => {
      try {
        addBikeOverlayLayers(overlayMap, {
          url: bikeOverlayUrl,
          kind: bikeOverlayKind,
          family: bikeOverlayFamily,
          visible: bikeOverlayVisible,
          extraOn: bikeOverlayExtraOn,
          rideProfileId: bikeOverlayRideProfileId,
          minzoom: bikeOverlayMinZoom,
          hideFarmTracks,
        });
      } catch (err) {
        console.warn("[MapView] bike overlay", err);
      }
    };
    apply();
    map.on("style.load", apply);
    return () => {
      map.off("style.load", apply);
    };
  }, [
    ready,
    bikeOverlayUrl,
    bikeOverlayKind,
    bikeOverlayFamily,
    bikeOverlayVisible,
    bikeOverlayExtraOn,
    bikeOverlayRideProfileId,
    bikeOverlayMinZoom,
    hideFarmTracks,
  ]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready || !bikeOverlayUrl) return;
    try {
      applyBikeOverlayVisibility(map as unknown as BikeOverlayMapLike, {
        family: bikeOverlayFamily,
        visible: bikeOverlayVisible,
        extraOn: bikeOverlayExtraOn,
        rideProfileId: bikeOverlayRideProfileId,
        hideFarmTracks,
      });
    } catch {
      /* source not ready yet */
    }
  }, [
    ready,
    bikeOverlayUrl,
    bikeOverlayFamily,
    bikeOverlayVisible,
    bikeOverlayExtraOn,
    bikeOverlayRideProfileId,
    hideFarmTracks,
  ]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    map.getCanvas().style.cursor =
      interactiveSelect || shapeInteractive ? "crosshair" : "";
  }, [interactiveSelect, shapeInteractive, ready]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;

    const upsertLine = (
      id: string,
      coordinates: [number, number][],
      color: string,
      width: number,
      opacity: number,
      dasharray?: number[],
      routeId?: string,
      casingColor?: string,
      casingWidth?: number,
      chevrons = false
    ) => {
      const layerId = `${id}-line`;
      const casingId = `${id}-casing`;
      const chevronId = `${id}-chevrons`;
      if (coordinates.length < 2) {
        if (map.getLayer(layerId)) map.removeLayer(layerId);
        if (map.getLayer(casingId)) map.removeLayer(casingId);
        if (map.getLayer(chevronId)) map.removeLayer(chevronId);
        if (map.getSource(id)) map.removeSource(id);
        layerIdsRef.current.delete(id);
        return;
      }
      ensureRouteChevronImage(map);
      const geojson: GeoJSON.Feature = {
        type: "Feature",
        properties: { routeId: routeId ?? id },
        geometry: { type: "LineString", coordinates },
      };
      const source = map.getSource(id) as maplibregl.GeoJSONSource | undefined;
      const lineLayout: maplibregl.LineLayerSpecification["layout"] = {
        "line-cap": "round",
        "line-join": "round",
      };
      if (source) {
        source.setData(geojson);
        if (map.getLayer(layerId)) {
          map.setPaintProperty(layerId, "line-color", color);
          map.setPaintProperty(layerId, "line-width", width);
          map.setPaintProperty(layerId, "line-opacity", opacity);
          if (dasharray) {
            map.setPaintProperty(layerId, "line-dasharray", dasharray);
          }
        }
        if (casingWidth && casingColor && map.getLayer(casingId)) {
          map.setPaintProperty(casingId, "line-color", casingColor);
          map.setPaintProperty(casingId, "line-width", casingWidth);
        }
      } else {
        map.addSource(id, { type: "geojson", data: geojson });
        if (casingWidth && casingColor) {
          map.addLayer({
            id: casingId,
            type: "line",
            source: id,
            layout: lineLayout,
            paint: {
              "line-color": casingColor,
              "line-width": casingWidth,
              "line-opacity": 0.88,
            },
          });
        }
        map.addLayer({
          id: layerId,
          type: "line",
          source: id,
          layout: lineLayout,
          paint: {
            "line-color": color,
            "line-width": width,
            "line-opacity": opacity,
            ...(dasharray ? { "line-dasharray": dasharray } : {}),
          },
        });
      }
      if (
        casingWidth &&
        casingColor &&
        !map.getLayer(casingId) &&
        map.getLayer(layerId)
      ) {
        map.addLayer(
          {
            id: casingId,
            type: "line",
            source: id,
            layout: lineLayout,
            paint: {
              "line-color": casingColor,
              "line-width": casingWidth,
              "line-opacity": 0.88,
            },
          },
          layerId
        );
      }
      if (chevrons && map.hasImage("flowline-chevron") && !map.getLayer(chevronId)) {
        map.addLayer({
          id: chevronId,
          type: "symbol",
          source: id,
          minzoom: 12,
          layout: {
            "symbol-placement": "line",
            "symbol-spacing": [
              "interpolate",
              ["linear"],
              ["zoom"],
              11,
              88,
              14,
              56,
              16,
              36,
            ] as unknown as number,
            "icon-image": "flowline-chevron",
            "icon-size": [
              "interpolate",
              ["linear"],
              ["zoom"],
              11,
              0.2,
              14,
              0.24,
              16,
              0.3,
            ] as unknown as number,
            "icon-rotation-alignment": "map",
            "icon-pitch-alignment": "map",
            "icon-allow-overlap": true,
            "icon-ignore-placement": true,
            "icon-keep-upright": false,
          },
          paint: {
            "icon-opacity": 0.92,
          },
        });
      }
      if (!chevrons && map.getLayer(chevronId)) {
        map.removeLayer(chevronId);
      }
      layerIdsRef.current.add(id);
    };

    const wanted = new Set<string>();

    if (track.length >= 2) {
      wanted.add("track");
      upsertLine(
        "track",
        track.map((p) => [p.lng, p.lat]),
        "#FF6B35",
        4,
        0.9,
        undefined,
        undefined,
        "#1A120C",
        8,
        true
      );
    }

    const layers = normalizeRoutes(routes, route, secondaryRoute);
    const overlayRole = (r: MapRouteRole) =>
      r === "steep" ||
      r === "unpaved" ||
      r === "paved" ||
      r === "gravel";
    const ordered = [
      ...layers.filter((l) => l.role !== "active" && !overlayRole(l.role)),
      ...layers.filter((l) => l.role === "active"),
      ...layers.filter((l) => l.role === "paved"),
      ...layers.filter((l) => l.role === "gravel"),
      ...layers.filter((l) => l.role === "unpaved"),
      ...layers.filter((l) => l.role === "steep"),
    ];
    for (const layer of ordered) {
      const style = ROLE_STYLE[layer.role];
      const sourceId = `route-${layer.id}`;
      wanted.add(sourceId);
      const opacity = layer.opacity ?? style.opacity;
      const dash = layer.dasharray ?? style.dasharray;
      const chevrons =
        layer.role === "active" &&
        opacity >= 0.55 &&
        !dash;
      upsertLine(
        sourceId,
        (layer.geometry.coordinates as [number, number][]) ?? [],
        layer.color ?? style.color,
        layer.width ?? style.width,
        opacity,
        dash,
        layer.id,
        style.casingColor,
        style.casingWidth,
        chevrons
      );
    }

    for (const id of [...layerIdsRef.current]) {
      if (wanted.has(id)) continue;
      if (map.getLayer(`${id}-line`)) map.removeLayer(`${id}-line`);
      if (map.getLayer(`${id}-casing`)) map.removeLayer(`${id}-casing`);
      if (map.getLayer(`${id}-chevrons`)) map.removeLayer(`${id}-chevrons`);
      if (map.getSource(id)) map.removeSource(id);
      layerIdsRef.current.delete(id);
    }

    if (fitRoute && layers.length) {
      const bounds = new maplibregl.LngLatBounds();
      let any = false;
      for (const layer of layers) {
        for (const c of layer.geometry.coordinates as [number, number][]) {
          bounds.extend(c);
          any = true;
        }
      }
      if (any) {
        map.fitBounds(bounds, { padding: 48, maxZoom: 14, duration: 600 });
      }
      return;
    }
    if (fitPoints && fitPoints.length >= 2) {
      const key = fitPoints
        .map((p) => `${p[0].toFixed(5)},${p[1].toFixed(5)}`)
        .join(";");
      if (key === lastFitPointsKey.current) return;
      lastFitPointsKey.current = key;
      const bounds = new maplibregl.LngLatBounds();
      for (const p of fitPoints) bounds.extend(p);
      map.fitBounds(bounds, { padding: 48, maxZoom: 14, duration: 600 });
    }
  }, [
    track,
    route,
    secondaryRoute,
    routes,
    ready,
    fitRoute,
    fitPoints,
    interactiveSelect,
  ]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    const recs = markerRecsRef.current;
    const stacked = [...markers].sort((a, b) => {
      const za = markerStackZ(resolveMapPinKind(a.id, a.kind), a.selected);
      const zb = markerStackZ(resolveMapPinKind(b.id, b.kind), b.selected);
      return za - zb;
    });
    const nextIds = new Set(stacked.map((m) => m.id));
    for (const [id, rec] of recs) {
      if (nextIds.has(id)) continue;
      rec.marker.remove();
      recs.delete(id);
    }
    for (const m of stacked) {
      const key = markerReuseKey(m);
      const prev = recs.get(m.id);
      if (prev && prev.key === key) {
        const kind = resolveMapPinKind(m.id, m.kind);
        const el = prev.marker.getElement();
        syncMarkerLabel(el, m, kind);
        syncMarkerCaption(el, m);
        syncPoiChrome(el, m);
        el.style.zIndex = String(markerStackZ(kind, m.selected));
        prev.marker.setLngLat(m.lngLat);
        continue;
      }
      prev?.marker.remove();
      const marker = createHtmlMapMarker(
        map,
        m,
        (id) => {
          onMarkerClickRef.current?.(id);
        },
        (id, lngLat) => {
          setShapeGhostCoords(map, null, layerIdsRef.current);
          setShapeHoverDisc(map, null);
          wrapRef.current?.classList.toggle("flowline-map-shaping", false);
          onShapeDraggingRef.current?.(false);
          onMarkerDragEndRef.current?.(id, lngLat);
        },
        (id, lngLat) => {
          wrapRef.current?.classList.toggle("flowline-map-shaping", true);
          onShapeDraggingRef.current?.(true);
          const anchors = shapeAnchorsRef.current;
          if (!anchors) return;
          const dragging =
            id === "start"
              ? "start"
              : id === "end"
                ? "end"
                : id.startsWith("shape-handle")
                  ? "line"
                  : "via";
          const finger = magnetShapeFinger(
            lngLat,
            dragging,
            snapShapeFingerRef.current
          );
          setShapeGhostCoords(
            map,
            rubberBandFromAnchors(anchors, finger, dragging, id),
            layerIdsRef.current
          );
          setPlanRibbonDimmed(map, layerIdsRef.current, true);
          if (anchors.line.length >= 2) {
            const km = setShapeHoverAlong(map, anchors.line, finger, true);
            onShapeHoverRef.current?.(km);
          }
        }
      );
      recs.set(m.id, { marker, key });
    }
    markersRef.current = [...recs.values()].map((r) => r.marker);
  }, [markers, ready]);

  const sourceLabel =
    tileSource === "stadia"
      ? "© OpenStreetMap · Stadia"
      : tileSource === "pmtiles"
        ? MAP_ATTRIBUTION
        : "© OpenStreetMap";

  // Don't combine `relative` + caller's `absolute` on the same node — Tailwind
  // source order can keep `relative`, so the map never fills Discover's pane.
  const fillsParent = /\babsolute\b/.test(className);

  return (
    <div
      ref={wrapRef}
      className={`${
        fillsParent
          ? "overflow-hidden bg-[#e8eee9]"
          : "relative overflow-hidden rounded-2xl bg-[#e8eee9]"
      } ${className}`}
      style={fillsParent ? { minHeight: 0 } : { minHeight: "min(55vh, 520px)" }}
    >
      <style>{`
        @keyframes flowline-pin-pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.14); }
        }
        @keyframes flowline-halo-pulse {
          0%, 100% { transform: scale(0.92); opacity: 0.35; }
          50% { transform: scale(1.18); opacity: 0.7; }
        }
        .flowline-map-pin svg {
          display: block;
          overflow: visible;
        }
        .flowline-shape-handle {
          display: grid;
          place-items: center;
        }
        .flowline-shape-handle::after {
          content: "";
          position: absolute;
          inset: 2px;
          border-radius: 999px;
          border: 2px solid rgba(255, 255, 255, 0.92);
          box-shadow: 0 1px 4px rgba(26, 18, 12, 0.28);
          pointer-events: none;
        }
        .flowline-shape-handle:hover .flowline-shape-handle-disc,
        .flowline-shape-handle:active .flowline-shape-handle-disc {
          transform: translate(-50%, -50%) scale(1.22);
        }
        .flowline-shape-handle:hover::after,
        .flowline-shape-handle:active::after {
          border-color: rgba(255, 106, 0, 0.55);
        }
        .flowline-shape-handle:active {
          cursor: grabbing;
        }
        .flowline-map-shaping .flowline-shape-handle {
          opacity: 0.45;
        }
        .flowline-map-shaping .flowline-shape-handle:hover,
        .flowline-map-shaping .flowline-shape-handle:active {
          opacity: 0.85;
        }
        .flowline-map-shaping .flowline-shape-tick {
          opacity: 0;
          pointer-events: none;
        }
      `}</style>
      <div ref={containerRef} className="absolute inset-0 h-full w-full" />
      {!ready && (
        <div className="absolute inset-0 flex items-center justify-center bg-surface/90 text-sm text-text-secondary">
          Karte wird geladen…
        </div>
      )}
      {mapError && (
        <div className="absolute left-2 right-2 top-2 rounded-lg bg-warning/90 px-3 py-2 text-xs text-black">
          {mapError}
        </div>
      )}
      <div className="absolute bottom-2 left-2 rounded bg-black/60 px-2 py-0.5 text-[10px] text-white/80">
        {sourceLabel}
      </div>
    </div>
  );
}
