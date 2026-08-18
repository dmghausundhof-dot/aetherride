"use client";

import { useRouter } from "next/navigation";
import { MapView, type MapMarker } from "@/components/MapView";
import type { PublicTour } from "@/lib/catalog/publicTours";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { useChromeLang } from "@/hooks/useChromeLang";

const SPORT_COLOR: Record<string, string> = {
  road: "#1565C0",
  gravel: "#6D4C41",
  urban: "#00897B",
  etrekking: "#2E7D32",
  emtb: "#558B2F",
  mtb_trail: "#E65100",
  mtb_am: "#EF6C00",
  mtb_enduro: "#BF360C",
  hiking: "#5D4037",
};

function pinColor(tour: PublicTour): string {
  return SPORT_COLOR[tour.primaryCategory] ?? "#FF6A00";
}

export function RegionToursMap({
  tours,
  center,
}: {
  tours: PublicTour[];
  center: [number, number];
}) {
  const router = useRouter();
  const copy = catalogCopy(useChromeLang());
  if (tours.length === 0) return null;

  const markers: MapMarker[] = tours.map((tour) => ({
    id: tour.id,
    lngLat: tour.center,
    color: pinColor(tour),
    label: tour.loop ? "⟲" : "T",
  }));
  const mapCenter: [number, number] = [
    tours.reduce((sum, tour) => sum + tour.center[0], 0) / tours.length,
    tours.reduce((sum, tour) => sum + tour.center[1], 0) / tours.length,
  ];
  const spread = Math.max(
    ...tours.map((tour) =>
      Math.hypot(tour.center[0] - mapCenter[0], tour.center[1] - mapCenter[1]),
    ),
    0.08,
  );

  return (
    <div className="overflow-hidden rounded-2xl border border-border">
      <div className="relative h-[280px] w-full sm:h-[340px]">
        <MapView
          className="absolute inset-0 h-full w-full"
          center={Number.isFinite(mapCenter[0]) ? mapCenter : center}
          zoom={spread > 1.2 ? 7 : spread > 0.35 ? 9 : 11}
          markers={markers}
          fitRoute={false}
          interactiveSelect={false}
          onMarkerClick={(id) => {
            router.push(`/tours/${id}`);
          }}
        />
      </div>
      <p className="px-4 py-2 text-[11px] text-text-secondary">
        {copy.region.mapLead} · {tours.length}
      </p>
    </div>
  );
}
