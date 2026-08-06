"use client";

import { useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

interface MapViewProps {
  className?: string;
  center?: [number, number]; // [lng, lat]
  zoom?: number;
  track?: { lat: number; lng: number }[];
  showUserLocation?: boolean;
  onMapReady?: (map: maplibregl.Map) => void;
}

/**
 * MapLibre-basierte Karte.
 * Produktion: Offline-PMTiles (z. B. über pmtiles Protocol) + custom Style
 * mit mtb:scale, surface, trail Tags aus OSM.
 *
 * Routing-Profile (OSRM/Valhalla) werden serverseitig oder on-device berechnet.
 */
export function MapView({
  className = "",
  center = [12.15, 47.45], // Alpenraum
  zoom = 12,
  track = [],
  showUserLocation = false,
  onMapReady,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: {
        version: 8,
        sources: {
          osm: {
            type: "raster",
            tiles: [
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ],
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
      },
      center,
      zoom,
      attributionControl: false,
    });

    map.addControl(new maplibregl.NavigationControl({ showCompass: true }), "top-right");
    map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right"
    );

    map.on("load", () => {
      setReady(true);
      onMapReady?.(map);

      // Track-Linie
      if (track.length > 1) {
        map.addSource("track", {
          type: "geojson",
          data: {
            type: "Feature",
            properties: {},
            geometry: {
              type: "LineString",
              coordinates: track.map((p) => [p.lng, p.lat]),
            },
          },
        });
        map.addLayer({
          id: "track-line",
          type: "line",
          source: "track",
          paint: {
            "line-color": "#FF6B35",
            "line-width": 4,
            "line-opacity": 0.9,
          },
        });
      }
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Update track when it changes
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready || track.length < 2) return;

    const source = map.getSource("track") as maplibregl.GeoJSONSource | undefined;
    const geojson = {
      type: "Feature" as const,
      properties: {},
      geometry: {
        type: "LineString" as const,
        coordinates: track.map((p) => [p.lng, p.lat]),
      },
    };

    if (source) {
      source.setData(geojson);
    } else {
      map.addSource("track", { type: "geojson", data: geojson });
      map.addLayer({
        id: "track-line",
        type: "line",
        source: "track",
        paint: {
          "line-color": "#FF6B35",
          "line-width": 4,
          "line-opacity": 0.9,
        },
      });
    }
  }, [track, ready]);

  return (
    <div className={`relative overflow-hidden rounded-2xl ${className}`}>
      <div ref={containerRef} className="h-full w-full" />
      {!ready && (
        <div className="absolute inset-0 flex items-center justify-center bg-surface text-text-secondary text-sm">
          Karte wird geladen…
        </div>
      )}
      <div className="absolute bottom-2 left-2 rounded bg-black/60 px-2 py-0.5 text-[10px] text-white/80">
        OSM · Offline-PMTiles in Produktion
      </div>
    </div>
  );
}
