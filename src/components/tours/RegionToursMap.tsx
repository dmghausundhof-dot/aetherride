"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { MapView, type MapMarker } from "@/components/MapView";
import { MapFrame, MapHud } from "@/components/map/MapFrame";
import type { PublicTour } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { sportKeysOnTours, sportPinColor } from "@/lib/tours/mapPins";

export function RegionToursMap({
  tours,
  center,
}: {
  tours: PublicTour[];
  center: [number, number];
}) {
  const copy = catalogCopy(useChromeLang());
  const [selectedId, setSelectedId] = useState<string | null>(tours[0]?.id ?? null);
  const selected = tours.find((tour) => tour.id === selectedId) ?? tours[0] ?? null;
  const sports = useMemo(() => sportKeysOnTours(tours), [tours]);

  const markers: MapMarker[] = useMemo(
    () =>
      tours.map((tour) => ({
        id: tour.id,
        lngLat: tour.center,
        color: sportPinColor(tour.primaryCategory),
        label: tour.name,
        kind: "tour",
        selected: tour.id === selected?.id,
      })),
    [selected?.id, tours],
  );

  const mapCenter: [number, number] = useMemo(() => {
    if (tours.length === 0) return center;
    return [
      tours.reduce((sum, tour) => sum + tour.center[0], 0) / tours.length,
      tours.reduce((sum, tour) => sum + tour.center[1], 0) / tours.length,
    ];
  }, [center, tours]);

  if (tours.length === 0) return null;

  return (
    <MapFrame className="min-h-[340px] rounded-2xl border border-border sm:min-h-[440px]">
      <MapView
        className="absolute inset-0 h-full w-full rounded-none"
        center={Number.isFinite(mapCenter[0]) ? mapCenter : center}
        zoom={9}
        markers={markers}
        fitMarkers
        fitRoute={false}
        interactiveSelect={false}
        onMarkerClick={(id) => setSelectedId(id)}
      />
      <MapHud position="top-left">
        <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-white/55">
          {copy.region.mapTitle}
        </p>
        <p className="mt-1 text-[18px] font-semibold leading-tight tracking-tight text-white">
          {selected?.name}
        </p>
        {selected ? (
          <>
            <p className="mt-1 text-[12px] text-white/70">
              {selected.distanceKm} km · {selected.elevationM} hm ·{" "}
              {bikeCategoryLabel(selected.primaryCategory)}
            </p>
            <Link
              href={`/tours/${selected.id}`}
              className="mt-3 inline-flex min-h-9 items-center rounded-full bg-chrome px-3.5 text-[11px] font-semibold uppercase tracking-[0.12em] text-on-accent"
            >
              {copy.region.mapOpen}
            </Link>
          </>
        ) : null}
      </MapHud>
      <MapHud position="bottom-right">
        <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-white/55">
          {copy.region.mapTap}
        </p>
        <ul className="mt-2 flex flex-wrap gap-x-3 gap-y-1.5">
          {sports.map((sport) => (
            <li key={sport} className="inline-flex items-center gap-1.5 text-[11px] text-white/90">
              <span
                className="h-2.5 w-2.5 rounded-full"
                style={{ background: sportPinColor(sport) }}
                aria-hidden
              />
              {bikeCategoryLabel(sport as PublicTour["primaryCategory"])}
            </li>
          ))}
        </ul>
      </MapHud>
    </MapFrame>
  );
}
