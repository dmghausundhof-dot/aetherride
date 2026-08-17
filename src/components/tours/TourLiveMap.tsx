"use client";

import { useEffect, useState } from "react";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { useChromeLang } from "@/hooks/useChromeLang";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { tourLiveMapStatus } from "@/lib/tours/tourLiveMapStatus";

type GeometryPayload = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  engine: string;
  profile: string;
  warnings?: string[];
  cached?: boolean;
  shape?: string;
  error?: string;
};

export function TourLiveMap({
  tourId,
  center,
  name,
  profile,
}: {
  tourId: string;
  center: [number, number];
  name: string;
  profile?: RoutingProfile;
}) {
  const lang = useChromeLang();
  const [data, setData] = useState<GeometryPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [placeMarkers, setPlaceMarkers] = useState<MapMarker[]>([]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setErr(null);
    const q = new URLSearchParams({ id: tourId });
    if (profile) q.set("profile", profile);
    void fetch(`/api/tours/geometry?${q}`)
      .then(async (r) => {
        const j = (await r.json()) as GeometryPayload;
        if (cancelled) return;
        if (!r.ok) {
          setErr(j.error ?? `Geometrie ${r.status}`);
          setData(null);
          return;
        }
        setData(j);
      })
      .catch(() => {
        if (!cancelled) setErr("Routing nicht erreichbar");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [tourId, profile]);

  useEffect(() => {
    let cancelled = false;
    const q = new URLSearchParams({
      lat: String(center[1]),
      lng: String(center[0]),
      tourId,
    });
    void fetch(`/api/community/places?${q}`)
      .then(async (r) => {
        if (!r.ok) return;
        const j = (await r.json()) as {
          places?: { id?: string; lat?: number; lng?: number; kind?: string; source?: string; name?: string }[];
        };
        if (cancelled || !Array.isArray(j.places)) return;
        const extra: MapMarker[] = [];
        for (const p of j.places.slice(0, 24)) {
          const lat = Number(p.lat);
          const lng = Number(p.lng);
          const id = String(p.id || "").trim();
          if (!id || !Number.isFinite(lat) || !Number.isFinite(lng)) continue;
          extra.push({
            id: `place-${id}`,
            lngLat: [lng, lat],
            color: p.source === "stimme" ? "#7C5CFF" : "#2BB0ED",
            label: (p.kind || p.name || "·").slice(0, 1).toUpperCase(),
          });
        }
        setPlaceMarkers(extra);
      })
      .catch(() => {
        if (!cancelled) setPlaceMarkers([]);
      });
    return () => {
      cancelled = true;
    };
  }, [tourId, center]);

  const hasLine =
    data?.geometry?.coordinates && data.geometry.coordinates.length >= 2;

  const routes: MapRouteLayer[] = hasLine
    ? [
        {
          id: "tour-live",
          role: "tour",
          geometry: data!.geometry,
          color: "#FF6A00",
          width: 5,
          opacity: 0.92,
        },
      ]
    : [];

  const markers: MapMarker[] = [
    {
      id: "tour-pin",
      lngLat: center,
      color: "#FF6A00",
      label: "T",
    },
    ...placeMarkers,
  ];

  return (
    <div className="relative h-full min-h-[280px] w-full">
      <MapView
        className="absolute inset-0 h-full w-full rounded-none"
        center={center}
        zoom={11}
        markers={markers}
        routes={routes}
        fitRoute={Boolean(hasLine)}
        interactiveSelect={false}
      />
      <div className="pointer-events-none absolute bottom-3 left-3 right-3 z-10">
        {loading && (
          <p className="rounded-lg bg-black/70 px-3 py-1.5 text-[11px] text-white">
            Live-Route wird berechnet…
          </p>
        )}
        {!loading && err && (
          <p className="rounded-lg bg-black/70 px-3 py-1.5 text-[11px] text-warning">
            {err} · Pin: {name}
          </p>
        )}
        {!loading && hasLine && data && (
          <p className="rounded-lg bg-black/70 px-3 py-1.5 text-[11px] text-white">
            {tourLiveMapStatus(data, lang)}
          </p>
        )}
      </div>
    </div>
  );
}
