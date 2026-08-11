"use client";

import { useEffect, useState } from "react";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import type { RoutingProfile } from "@/lib/routing/profiles";

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
  const [data, setData] = useState<GeometryPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);

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

  const hasLine =
    data?.geometry?.coordinates && data.geometry.coordinates.length >= 2;

  const routes: MapRouteLayer[] = hasLine
    ? [
        {
          id: "tour-live",
          role: "tour",
          geometry: data!.geometry,
          color: "#FF6B35",
          width: 5,
          opacity: 0.92,
        },
      ]
    : [];

  const markers: MapMarker[] = [
    {
      id: "tour-pin",
      lngLat: center,
      color: "#FF6B35",
      label: "T",
    },
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
            {(data.distanceM / 1000).toFixed(1)} km ·{" "}
            {Math.round(data.durationS / 60)} min · {data.engine}
            {data.cached ? " · Cache" : ""}
            {data.shape ? ` · ${data.shape}` : ""}
            {data.warnings?.[0] ? ` · ${data.warnings[0].slice(0, 80)}…` : ""}
          </p>
        )}
      </div>
    </div>
  );
}
