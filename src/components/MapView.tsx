"use client";

import { useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import { Protocol } from "pmtiles";
import "maplibre-gl/dist/maplibre-gl.css";

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
  /** @deprecated use routes */
  route?: GeoJSON.LineString | null;
  /** @deprecated use routes */
  secondaryRoute?: GeoJSON.LineString | null;
  /** Multi-layer routes (preferred) */
  routes?: MapRouteLayer[];
  markers?: MapMarker[];
  showUserLocation?: boolean;
  interactiveSelect?: boolean;
  onMapClick?: (lngLat: [number, number]) => void;
  onRouteClick?: (routeId: string) => void;
  onMapReady?: (map: maplibregl.Map) => void;
  fitRoute?: boolean;
}

let pmtilesRegistered = false;

function ensurePmtilesProtocol() {
  if (pmtilesRegistered || typeof window === "undefined") return;
  const protocol = new Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);
  pmtilesRegistered = true;
}

function isMapLibreStyleUrl(url: string): boolean {
  const u = url.trim().toLowerCase();
  if (!u) return false;
  if (u.endsWith(".pmtiles") || u.includes(".pmtiles?")) return false;
  return (
    u.endsWith(".json") ||
    u.includes("/styles/") ||
    u.includes("style.json")
  );
}

function isRawPmtilesUrl(url: string): boolean {
  const u = url.trim().toLowerCase();
  return (
    u.endsWith(".pmtiles") ||
    u.includes(".pmtiles?") ||
    u.startsWith("pmtiles://")
  );
}

function buildStyle(): maplibregl.StyleSpecification | string {
  const pmtilesUrl = process.env.NEXT_PUBLIC_PMTILES_URL?.trim();
  if (pmtilesUrl) {
    // Style-JSON URL (same model as mobile) — pass through to MapLibre.
    if (isMapLibreStyleUrl(pmtilesUrl) && !isRawPmtilesUrl(pmtilesUrl)) {
      return pmtilesUrl;
    }
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
          paint: { "background-color": "#1a1f1c" },
        },
        {
          id: "earth",
          type: "fill",
          source: "protomaps",
          "source-layer": "earth",
          paint: { "fill-color": "#1e2622" },
        },
        {
          id: "landuse",
          type: "fill",
          source: "protomaps",
          "source-layer": "landuse",
          paint: { "fill-color": "#24302a", "fill-opacity": 0.6 },
        },
        {
          id: "water",
          type: "fill",
          source: "protomaps",
          "source-layer": "water",
          paint: { "fill-color": "#1a3a4a" },
        },
        {
          id: "roads",
          type: "line",
          source: "protomaps",
          "source-layer": "roads",
          paint: {
            "line-color": "#4a5c52",
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
            "line-color": "#7a9a7e",
            "line-width": 1.5,
            "line-dasharray": [2, 1],
          },
        },
      ],
    };
  }

  const stadiaKey = process.env.NEXT_PUBLIC_STADIA_API_KEY?.trim();
  if (stadiaKey) {
    return `https://tiles.stadiamaps.com/styles/outdoors.json?api_key=${encodeURIComponent(stadiaKey)}`;
  }

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

function normalizeRoutes(
  routes: MapRouteLayer[] | undefined,
  route: GeoJSON.LineString | null | undefined,
  secondaryRoute: GeoJSON.LineString | null | undefined
): MapRouteLayer[] {
  if (routes?.length) return routes;
  const out: MapRouteLayer[] = [];
  if (secondaryRoute?.coordinates?.length) {
    out.push({
      id: "secondary",
      geometry: secondaryRoute,
      role: "alt",
    });
  }
  if (route?.coordinates?.length) {
    out.push({ id: "primary", geometry: route, role: "active" });
  }
  return out;
}

/**
 * MapLibre-Karte.
 * Priorität: PMTiles → Stadia Outdoors → OSM-Raster-Fallback.
 */
export function MapView({
  className = "",
  center = [12.15, 47.45],
  zoom = 12,
  track = [],
  route = null,
  secondaryRoute = null,
  routes,
  markers = [],
  showUserLocation = false,
  interactiveSelect = false,
  onMapClick,
  onRouteClick,
  onMapReady,
  fitRoute = false,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const layerIdsRef = useRef<Set<string>>(new Set());
  const onClickRef = useRef(onMapClick);
  const onRouteClickRef = useRef(onRouteClick);
  const [ready, setReady] = useState(false);
  const usingPmtiles = Boolean(process.env.NEXT_PUBLIC_PMTILES_URL?.trim());
  const usingStadia = Boolean(
    !usingPmtiles && process.env.NEXT_PUBLIC_STADIA_API_KEY?.trim()
  );

  onClickRef.current = onMapClick;
  onRouteClickRef.current = onRouteClick;

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildStyle(),
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

    map.on("load", () => {
      setReady(true);
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
      console.warn("[MapView]", e.error);
    });

    mapRef.current = map;

    return () => {
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
      map.on("mouseenter", layerId, () => {
        if (!interactiveSelect) map.getCanvas().style.cursor = "pointer";
      });
      map.on("mouseleave", layerId, () => {
        map.getCanvas().style.cursor = interactiveSelect ? "crosshair" : "";
      });
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
    // Draw non-active first, active last (on top)
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

    // Cleanup stale layers
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
      return new maplibregl.Marker({ element: el })
        .setLngLat(m.lngLat)
        .addTo(map);
    });
  }, [markers, ready]);

  return (
    <div className={`relative overflow-hidden rounded-2xl ${className}`}>
      <div ref={containerRef} className="h-full w-full" />
      {!ready && (
        <div className="absolute inset-0 flex items-center justify-center bg-surface text-sm text-text-secondary">
          Karte wird geladen…
        </div>
      )}
      <div className="absolute bottom-2 left-2 rounded bg-black/60 px-2 py-0.5 text-[10px] text-white/80">
        {usingPmtiles
          ? "PMTiles · Offline-fähig"
          : usingStadia
            ? "Stadia Outdoors · © OSM"
            : "OSM-Raster · Fallback"}
      </div>
    </div>
  );
}
