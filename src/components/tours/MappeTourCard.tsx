"use client";

import type { ReactNode } from "react";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { MappeTourFace } from "@/components/tours/MappeTourFace";
import { TourLineThumb } from "@/components/tours/TourLineThumb";
import {
  mappeElevSpark,
  savedRouteHasTrack,
  savedRouteIsLoop,
  savedRouteTrackCoords,
} from "@/lib/tours/mappeList";
import type { SavedRoute } from "@/types/route";

export function MappeTourCard({
  route,
  visLabel,
  loopLabel,
  noTrackLabel,
  rideLabel,
  open,
  onOpen,
  onGoRide,
  caption,
  awayLabel,
  conditionLabel,
  sourceChip,
  children,
}: {
  route: SavedRoute;
  visLabel: string;
  loopLabel: string;
  noTrackLabel: string;
  rideLabel: string;
  open: boolean;
  onOpen: () => void;
  onGoRide?: () => void;
  caption?: string;
  awayLabel?: string;
  conditionLabel?: string;
  sourceChip?: string;
  children?: ReactNode;
}) {
  const canRide = Boolean(onGoRide) && savedRouteHasTrack(route);
  const coords = savedRouteTrackCoords(route);
  const loop = savedRouteIsLoop(route);
  const spark = mappeElevSpark(coords);

  return (
    <li
      className="overflow-hidden rounded-2xl border border-border bg-surface"
      data-testid={`platz-tour-${route.id}`}
    >
      <div className="relative">
        <TourLineThumb
          coordinates={coords}
          label={route.name}
          noTrackLabel={noTrackLabel}
          size={92}
          wide
        />
        {spark.length >= 2 ? (
          <svg
            viewBox="0 0 100 16"
            className={`pointer-events-none absolute bottom-2.5 h-4 text-accent ${canRide ? "inset-x-3 right-14" : "inset-x-3"}`}
            aria-hidden
            preserveAspectRatio="none"
          >
            <path
              d={spark
                .map((y, i) => {
                  const x = (i / (spark.length - 1)) * 100;
                  const py = (1 - y) * 16;
                  return `${i === 0 ? "M" : "L"}${x} ${py}`;
                })
                .join(" ")}
              fill="none"
              stroke="currentColor"
              strokeWidth="1.6"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        ) : null}
        {canRide ? (
          <button
            type="button"
            className="absolute bottom-2 right-2 rounded-full bg-background/80 p-1"
            data-testid={`platz-tour-ride-${route.id}`}
            onClick={onGoRide}
            aria-label={rideLabel}
          >
            <MappeGlyph name="ride" size={36} alt={rideLabel} />
          </button>
        ) : null}
      </div>
      <button
        type="button"
        className="w-full px-3 py-2.5 text-left"
        onClick={onOpen}
        aria-expanded={open}
      >
        <MappeTourFace
          route={route}
          visLabel={visLabel}
          loopLabel={loopLabel}
          noTrackLabel={noTrackLabel}
          caption={caption}
          awayLabel={awayLabel}
          conditionLabel={conditionLabel}
          sourceChip={sourceChip}
          showThumb={false}
          hideLoopChip={loop}
        />
      </button>
      {open && children ? (
        <div className="border-t border-border px-3 py-3">{children}</div>
      ) : null}
    </li>
  );
}
