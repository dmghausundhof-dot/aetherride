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

interface MapViewProps {
  className?: string;
  center?: [number, number];
  zoom?: number;
  track?: { lat: number; lng: number }[];
  /** Primäre Route (aktiv) */
  route?: GeoJSON.LineString | null;
  /** Sekundäre / Preview-Route (gedimmt) */
  secondaryRoute?: GeoJSON.LineString | null;
  markers?: MapMarker[];
  showUserLocation?: boolean;
  interactiveSelect?: boolean;
  onMapClick?: (lngLat: [number, number]) => void;
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

function buildStyle(): maplibregl.StyleSpecification | string {
  const pmtilesUrl = process.env.NEXT_PUBLIC_PMTILES_URL?.trim();
  if (pmtilesUrl) {
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
  markers = [],
  showUserLocation = false,
  interactiveSelect = false,
  onMapClick,
  onMapReady,
  fitRoute = false,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const onClickRef = useRef(onMapClick);
  const [ready, setReady] = useState(false);
  const usingPmtiles = Boolean(process.env.NEXT_PUBLIC_PMTILES_URL?.trim());
  const usingStadia = Boolean(
    !usingPmtiles && process.env.NEXT_PUBLIC_STADIA_API_KEY?.trim()
  );

  onClickRef.current = onMapClick;

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
      opacity: number
    ) => {
      if (coordinates.length < 2) {
        if (map.getLayer(`${id}-line`)) map.removeLayer(`${id}-line`);
        if (map.getSource(id)) map.removeSource(id);
        return;
      }
      const geojson: GeoJSON.Feature = {
        type: "Feature",
        properties: {},
        geometry: { type: "LineString", coordinates },
      };
      const source = map.getSource(id) as maplibregl.GeoJSONSource | undefined;
      if (source) {
        source.setData(geojson);
      } else {
        map.addSource(id, { type: "geojson", data: geojson });
        map.addLayer({
          id: `${id}-line`,
          type: "line",
          source: id,
          paint: {
            "line-color": color,
            "line-width": width,
            "line-opacity": opacity,
          },
        });
      }
    };

    if (track.length >= 2) {
      upsertLine(
        "track",
        track.map((p) => [p.lng, p.lat]),
        "#FF6B35",
        4,
        0.9
      );
    }

    upsertLine(
      "secondary-route",
      (secondaryRoute?.coordinates as [number, number][]) ?? [],
      "#90A4AE",
      3,
      0.55
    );

    upsertLine(
      "route",
      (route?.coordinates as [number, number][]) ?? [],
      "#4FC3F7",
      4.5,
      0.95
    );

    if (fitRoute && route?.coordinates?.length) {
      const bounds = new maplibregl.LngLatBounds();
      for (const c of route.coordinates as [number, number][]) {
        bounds.extend(c);
      }
      if (secondaryRoute?.coordinates?.length) {
        for (const c of secondaryRoute.coordinates as [number, number][]) {
          bounds.extend(c);
        }
      }
      map.fitBounds(bounds, { padding: 48, maxZoom: 14, duration: 600 });
    }
  }, [track, route, secondaryRoute, ready, fitRoute]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = markers.map((m) => {
      const marker = new maplibregl.Marker({ color: m.color ?? "#4FC3F7" })
        .setLngLat(m.lngLat)
        .addTo(map);
      if (m.label) {
        marker.setPopup(
          new maplibregl.Popup({ offset: 12 }).setText(m.label)
        );
      }
      return marker;
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
