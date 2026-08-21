"use client";

import { MapView, type MapMarker } from "@/components/MapView";

export function TourMapPin({
  center,
  name,
}: {
  center: [number, number];
  name: string;
}) {
  const markers: MapMarker[] = [
    {
      id: "tour-pin",
      lngLat: center,
      color: "#FF6A00",
      kind: "tour",
    },
  ];

  return (
    <MapView
      className="absolute inset-0 h-full w-full rounded-none"
      center={center}
      zoom={11}
      markers={markers}
      interactiveSelect={false}
    />
  );
}
