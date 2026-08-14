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
  type BikeOverlayMapLike,
} from "@/lib/routing/bikeOverlayMap";
import type { RideProfileId } from "@/lib/routing/profiles";

export type MapMarker = {
  id: string;
  lngLat: [number, number];
  color?: string;
  label?: string;
};

export type MapRouteRole =
  | "active"
  | "alt"
  | "tour"
  | "approach"
  | "trail"
  | "approx";

export type MapRouteLayer = {
  id: string;
  geometry: GeoJSON.LineString;
  role: MapRouteRole;
  color?: string;
  width?: number;
  opacity?: number;
  dasharray?: number[];
};

const ROLE_STYLE: Record<
  MapRouteRole,
  { color: string; width: number; opacity: number; dasharray?: number[] }
> = {
  active: { color: "#4FC3F7", width: 5, opacity: 0.95 },
  alt: { color: "#90A4AE", width: 3, opacity: 0.45 },
  tour: { color: "#26A69A", width: 4, opacity: 0.85 },
  approach: { color: "#66BB6A", width: 4, opacity: 0.9, dasharray: [2, 2] },
  trail: { color: "#B0BEC5", width: 2.5, opacity: 0.55, dasharray: [1.5, 1.5] },
  approx: { color: "#78909C", width: 3.5, opacity: 0.65, dasharray: [2, 2] },
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
  onMapClick?: (lngLat: [number, number]) => void;
  onRouteClick?: (routeId: string) => void;
  onMarkerClick?: (id: string) => void;
  onMapReady?: (map: maplibregl.Map) => void;
  fitRoute?: boolean;
  bikeOverlayUrl?: string | null;
  bikeOverlayKind?: "pmtiles" | "geojson";
  bikeOverlayFamily?: BikeOverlayFamily;
  bikeOverlayVisible?: boolean;
  bikeOverlayExtraOn?: BikeOverlayClass[];
  bikeOverlayRideProfileId?: RideProfileId | null;
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

function pmtilesStyle(): maplibregl.StyleSpecification | string | null {
  const pmtilesUrl = process.env.NEXT_PUBLIC_PMTILES_URL?.trim();
  if (!pmtilesUrl) return null;
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
        attribution: "© OpenStreetMap · PMTiles",
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
        paint: { "fill-color": "#a8c8d8" },
      },
      {
        id: "roads",
        type: "line",
        source: "protomaps",
        "source-layer": "roads",
        paint: {
          "line-color": "#6a7a72",
          "line-width": ["interpolate", ["linear"], ["zoom"], 10, 0.5, 16, 3],
        },
      },
      {
        id: "paths",
        type: "line",
        source: "protomaps",
        "source-layer": "roads",
        filter: ["==", ["get", "kind"], "path"],
        paint: {
          "line-color": "#4a7a52",
          "line-width": 1.5,
          "line-dasharray": [2, 1],
        },
      },
    ],
  };
}

/** Web: Stadia first (reliable online), then PMTiles, then OSM. */
function pickInitialStyle(): {
  style: maplibregl.StyleSpecification | string;
  source: "stadia" | "pmtiles" | "osm";
} {
  const stadia = stadiaStyleUrl();
  if (stadia) return { style: stadia, source: "stadia" };
  const pm = pmtilesStyle();
  if (pm) return { style: pm, source: "pmtiles" };
  return { style: osmRasterStyle(), source: "osm" };
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
  onRouteClick,
  onMarkerClick,
  onMapReady,
  fitRoute = false,
  bikeOverlayUrl = null,
  bikeOverlayKind = "pmtiles",
  bikeOverlayFamily = "road",
  bikeOverlayVisible = true,
  bikeOverlayExtraOn = [],
  bikeOverlayRideProfileId = null,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const layerIdsRef = useRef<Set<string>>(new Set());
  const onClickRef = useRef(onMapClick);
  const onRouteClickRef = useRef(onRouteClick);
  const onMarkerClickRef = useRef(onMarkerClick);
  const [ready, setReady] = useState(false);
  const [tileSource, setTileSource] = useState<"stadia" | "pmtiles" | "osm">(
    "osm"
  );
  const [mapError, setMapError] = useState<string | null>(null);
  const fallbackTried = useRef(false);

  onClickRef.current = onMapClick;
  onRouteClickRef.current = onRouteClick;
  onMarkerClickRef.current = onMarkerClick;

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const initial = pickInitialStyle();
    setTileSource(initial.source);

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
      if (showUserLocation && navigator.geolocation) {
        navigator.geolocation.getCurrentPosition((pos) => {
          new maplibregl.Marker({ color: "#FF6B35" })
            .setLngLat([pos.coords.longitude, pos.coords.latitude])
            .addTo(map);
        });
      }
    });

    map.on("click", (e) => {
      const feats = map.queryRenderedFeatures(e.point, {
        layers: [...layerIdsRef.current].map((id) => `${id}-line`),
      });
      const hit = feats.find((f) => f.properties?.routeId);
      if (hit?.properties?.routeId) {
        onRouteClickRef.current?.(String(hit.properties.routeId));
        return;
      }
      onClickRef.current?.([e.lngLat.lng, e.lngLat.lat]);
    });

    map.on("error", (e) => {
      const err = e as { error?: { message?: string }; sourceId?: string };
      const msg = err?.error?.message || String(err?.error || "Kartenfehler");
      const sourceId = err?.sourceId ?? "";
      console.warn("[MapView]", msg);
      if (sourceId === BIKE_OVERLAY_SOURCE_ID || msg.includes("bike-overlay")) {
        return;
      }
      // Already on OSM, or overlay-only errors: don't wipe layers with setStyle.
      if (fallbackTried.current || initial.source === "osm") return;
      fallbackTried.current = true;
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
      if (resizeRaf) window.cancelAnimationFrame(resizeRaf);
      ro?.disconnect();
      markersRef.current.forEach((m) => m.remove());
      markersRef.current = [];
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
    if (!map || !ready || !bikeOverlayUrl) return;
    const overlayMap = map as unknown as BikeOverlayMapLike;
    const apply = () => {
      try {
        addBikeOverlayLayers(overlayMap, {
          url: bikeOverlayUrl,
          kind: bikeOverlayKind,
          family: bikeOverlayFamily,
          visible: bikeOverlayVisible,
          extraOn: bikeOverlayExtraOn,
          rideProfileId: bikeOverlayRideProfileId,
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
  ]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    map.getCanvas().style.cursor = interactiveSelect ? "crosshair" : "";
  }, [interactiveSelect, ready]);

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
      routeId?: string
    ) => {
      const layerId = `${id}-line`;
      if (coordinates.length < 2) {
        if (map.getLayer(layerId)) map.removeLayer(layerId);
        if (map.getSource(id)) map.removeSource(id);
        layerIdsRef.current.delete(id);
        return;
      }
      const geojson: GeoJSON.Feature = {
        type: "Feature",
        properties: { routeId: routeId ?? id },
        geometry: { type: "LineString", coordinates },
      };
      const source = map.getSource(id) as maplibregl.GeoJSONSource | undefined;
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
      } else {
        map.addSource(id, { type: "geojson", data: geojson });
        map.addLayer({
          id: layerId,
          type: "line",
          source: id,
          paint: {
            "line-color": color,
            "line-width": width,
            "line-opacity": opacity,
            ...(dasharray ? { "line-dasharray": dasharray } : {}),
          },
        });
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
        0.9
      );
    }

    const layers = normalizeRoutes(routes, route, secondaryRoute);
    const ordered = [
      ...layers.filter((l) => l.role !== "active"),
      ...layers.filter((l) => l.role === "active"),
    ];
    for (const layer of ordered) {
      const style = ROLE_STYLE[layer.role];
      const sourceId = `route-${layer.id}`;
      wanted.add(sourceId);
      upsertLine(
        sourceId,
        (layer.geometry.coordinates as [number, number][]) ?? [],
        layer.color ?? style.color,
        layer.width ?? style.width,
        layer.opacity ?? style.opacity,
        layer.dasharray ?? style.dasharray,
        layer.id
      );
    }

    for (const id of [...layerIdsRef.current]) {
      if (wanted.has(id)) continue;
      if (map.getLayer(`${id}-line`)) map.removeLayer(`${id}-line`);
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
    }
  }, [track, route, secondaryRoute, routes, ready, fitRoute, interactiveSelect]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = markers.map((m) => {
      const el = document.createElement("div");
      el.className = "flex flex-col items-center";
      const pin = document.createElement("div");
      pin.style.width = "14px";
      pin.style.height = "14px";
      pin.style.borderRadius = "999px";
      pin.style.background = m.color ?? "#4FC3F7";
      pin.style.border = "2px solid white";
      pin.style.boxShadow = "0 1px 4px rgba(0,0,0,.4)";
      el.appendChild(pin);
      if (m.label) {
        const lab = document.createElement("div");
        lab.textContent = m.label;
        lab.style.fontSize = "10px";
        lab.style.fontWeight = "700";
        lab.style.color = "#fff";
        lab.style.textShadow = "0 1px 2px rgba(0,0,0,.8)";
        lab.style.marginTop = "2px";
        el.appendChild(lab);
      }
      el.style.cursor = "pointer";
      el.addEventListener("click", (ev) => {
        ev.stopPropagation();
        onMarkerClickRef.current?.(m.id);
      });
      return new maplibregl.Marker({ element: el })
        .setLngLat(m.lngLat)
        .addTo(map);
    });
  }, [markers, ready]);

  const sourceLabel =
    tileSource === "stadia"
      ? "Stadia Outdoors · © OSM"
      : tileSource === "pmtiles"
        ? "PMTiles · Offline-fähig"
        : "OSM-Raster · Fallback";

  // Don't combine `relative` + caller's `absolute` on the same node — Tailwind
  // source order can keep `relative`, so the map never fills Discover's pane.
  const fillsParent = /\babsolute\b/.test(className);

  return (
    <div
      className={`${
        fillsParent
          ? "overflow-hidden bg-[#e8eee9]"
          : "relative overflow-hidden rounded-2xl bg-[#e8eee9]"
      } ${className}`}
      style={fillsParent ? { minHeight: 0 } : { minHeight: "min(55vh, 520px)" }}
    >
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
