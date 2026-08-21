"use client";

import { useEffect, useMemo, useState } from "react";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { pinGlyphForCategory, coveragePlacePoiKind } from "@/lib/map/mapPinSvg";
import { browseCoveragePinText } from "@/lib/map/tourPoiStops";
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
  category,
}: {
  tourId: string;
  center: [number, number];
  name: string;
  profile?: RoutingProfile;
  category?: string;
}) {
  const lang = useChromeLang();
  const [data, setData] = useState<GeometryPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [placeMarkers, setPlaceMarkers] = useState<MapMarker[]>([]);
  const [mapZoom, setMapZoom] = useState(11);

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
        let plates = 0;
        let stimme = 0;
        for (const p of j.places) {
          const lat = Number(p.lat);
          const lng = Number(p.lng);
          const id = String(p.id || "").trim();
          if (!id || !Number.isFinite(lat) || !Number.isFinite(lng)) continue;
          if (p.source === "stimme") {
            if (stimme >= 3) continue;
            stimme += 1;
            extra.push({
              id: `place-${id}`,
              lngLat: [lng, lat],
              color: "#6D4C41",
              kind: "stimme",
              label: (p.name || "").slice(0, 14),
            });
            continue;
          }
          const poiKind = coveragePlacePoiKind(p.kind);
          if (!poiKind || plates >= 8) continue;
          plates += 1;
          extra.push({
            id: `place-${id}`,
            lngLat: [lng, lat],
            kind: "poi",
            poiKind,
            label: p.name || "",
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

  const pinAt = useMemo((): [number, number] => {
    const c0 = data?.geometry?.coordinates?.[0];
    if (Array.isArray(c0) && c0.length >= 2) {
      return [Number(c0[0]), Number(c0[1])];
    }
    return center;
  }, [data, center]);

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

  const markers: MapMarker[] = useMemo(() => {
    const pin: MapMarker = {
      id: "tour-pin",
      lngLat: pinAt,
      color: "#FF6A00",
      kind: "tour",
      glyph: pinGlyphForCategory(category),
    };
    const extras = placeMarkers.map((m) =>
      m.kind === "poi"
        ? { ...m, label: browseCoveragePinText(m.label ?? "", mapZoom) }
        : m
    );
    return [pin, ...extras];
  }, [pinAt, placeMarkers, mapZoom, category]);

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
        onZoomChange={setMapZoom}
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
            {tourLiveMapStatus(
              { ...data, profile: (data.profile as RoutingProfile) || "gravel" },
              lang
            )}
          </p>
        )}
      </div>
    </div>
  );
}
