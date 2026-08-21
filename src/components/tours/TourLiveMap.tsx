"use client";

import { useEffect, useMemo, useState } from "react";
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { MapFrame, MapHud } from "@/components/map/MapFrame";
import { pinGlyphForCategory, coveragePlacePoiKind } from "@/lib/map/mapPinSvg";
import { browseCoveragePinText } from "@/lib/map/tourPoiStops";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { lineEndpoints, sportPinColor, TOUR_LINE_COLOR } from "@/lib/tours/mapPins";
import { tourLiveMapStatus } from "@/lib/tours/tourLiveMapStatus";
import type { BikeCategory } from "@/types";

const EMPTY_LINE: [number, number][] = [];

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
  loop,
}: {
  tourId: string;
  center: [number, number];
  name: string;
  profile?: RoutingProfile;
  category?: BikeCategory | string;
  loop?: boolean;
}) {
  const lang = useChromeLang();
  const copy = catalogCopy(lang);
  const pinColor = sportPinColor(category ?? "gravel");
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
        if (!cancelled) setErr(copy.tour.mapUnreachable);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [tourId, profile, copy.tour.mapUnreachable]);

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
          places?: {
            id?: string;
            lat?: number;
            lng?: number;
            kind?: string;
            source?: string;
            name?: string;
          }[];
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

  const coords =
    (data?.geometry?.coordinates as [number, number][] | undefined) ?? EMPTY_LINE;
  const hasLine = coords.length >= 2;
  const ends = lineEndpoints(coords, loop);

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
          color: TOUR_LINE_COLOR,
          width: 5,
          opacity: 0.92,
        },
      ]
    : [];

  const markers: MapMarker[] = useMemo(() => {
    const pins: MapMarker[] = [];
    if (hasLine && ends.start) {
      pins.push({
        id: "start",
        lngLat: ends.start,
        color: pinColor,
        label: "A",
        kind: "start",
      });
      if (ends.end) {
        pins.push({
          id: "end",
          lngLat: ends.end,
          color: pinColor,
          label: "B",
          kind: "finish",
        });
      }
    } else {
      pins.push({
        id: "tour-pin",
        lngLat: pinAt,
        color: pinColor,
        kind: "tour",
        glyph: pinGlyphForCategory(category),
      });
    }
    const extras = placeMarkers.map((m) =>
      m.kind === "poi"
        ? { ...m, label: browseCoveragePinText(m.label ?? "", mapZoom) }
        : m
    );
    return [...pins, ...extras];
  }, [
    hasLine,
    ends.start,
    ends.end,
    pinAt,
    pinColor,
    placeMarkers,
    mapZoom,
    category,
  ]);

  const statusText = loading
    ? copy.tour.mapLoading
    : err
      ? `${err} · ${name}`
      : hasLine && data
        ? tourLiveMapStatus(
            { ...data, profile: profile ?? (data.profile as RoutingProfile) },
            lang,
          )
        : copy.tour.noTrackHint;

  return (
    <MapFrame tall className="h-full min-h-[inherit]">
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
      <MapHud position="top-left">
        <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-white/55">
          {copy.tour.fn.map}
        </p>
        <p className={`mt-1 text-[13px] font-medium leading-snug ${err ? "text-warning" : "text-white"}`}>
          {statusText}
        </p>
        <div className="mt-2.5 flex flex-wrap gap-2 text-[10px] font-semibold uppercase tracking-[0.1em] text-white/60">
          <span className="inline-flex items-center gap-1.5">
            <span className="inline-flex h-3.5 w-3.5 items-center justify-center rounded-[3px] bg-[#1C1A17] text-[8px] text-[#F4F1EA]">
              A
            </span>
            {copy.tour.mapStart}
          </span>
          {hasLine && ends.end ? (
            <span className="inline-flex items-center gap-1.5">
              <span className="inline-flex h-3.5 w-3.5 items-center justify-center rounded-[3px] border border-white/25 bg-[#F4F1EA] text-[8px] text-[#1C1A17]">
                B
              </span>
              {copy.tour.mapEnd}
            </span>
          ) : null}
        </div>
      </MapHud>
      {placeMarkers.length > 0 ? (
        <MapHud position="bottom-right">
          <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-white/55">
            {copy.tour.mapPlaces}
          </p>
          <p className="mt-1 text-[12px] text-white/85">{placeMarkers.length}</p>
        </MapHud>
      ) : null}
    </MapFrame>
  );
}
