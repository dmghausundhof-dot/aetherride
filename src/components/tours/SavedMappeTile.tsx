"use client";

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

/** Karten-Sheet: dieselbe Sprache wie der Touren-Tab, kürzerer Hero. */
export function SavedMappeTile({
  route,
  visLabel,
  loopLabel,
  noTrackLabel,
  caption,
  sourceChip,
  conditionLabel,
  akteLabel,
  removeLabel,
  rideLabel,
  onOpen,
  onAkte,
  onRemove,
  onGoRide,
}: {
  route: SavedRoute;
  visLabel: string;
  loopLabel: string;
  noTrackLabel: string;
  caption?: string;
  sourceChip?: string;
  conditionLabel?: string;
  akteLabel: string;
  removeLabel: string;
  rideLabel: string;
  onOpen: () => void;
  onAkte: () => void;
  onRemove: () => void;
  onGoRide?: () => void;
}) {
  const canRide = Boolean(onGoRide) && savedRouteHasTrack(route);
  const coords = savedRouteTrackCoords(route);
  const loop = savedRouteIsLoop(route);
  const spark = mappeElevSpark(coords);

  return (
    <li
      className="overflow-hidden rounded-2xl border border-border bg-surface"
      data-testid={`mappe-tile-${route.id}`}
    >
      <div className="relative">
        <TourLineThumb
          coordinates={coords}
          label={route.name}
          noTrackLabel={noTrackLabel}
          size={48}
          wide
        />
        {spark.length >= 2 ? (
          <svg
            viewBox="0 0 100 16"
            className={`pointer-events-none absolute bottom-2 h-3.5 text-accent ${canRide ? "inset-x-3 right-14" : "inset-x-3"}`}
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
            className="absolute bottom-1.5 right-2 rounded-full bg-background/80 p-1"
            data-testid={`mappe-tile-ride-${route.id}`}
            onClick={onGoRide}
            aria-label={rideLabel}
            title={rideLabel}
          >
            <MappeGlyph name="ride" size={28} alt="" />
          </button>
        ) : null}
      </div>
      <div className="flex items-start gap-0.5 py-1 pl-3 pr-1">
        <button
          type="button"
          className="min-w-0 flex-1 text-left"
          onClick={onOpen}
        >
          <MappeTourFace
            route={route}
            visLabel={visLabel}
            loopLabel={loopLabel}
            noTrackLabel={noTrackLabel}
            caption={caption}
            conditionLabel={conditionLabel}
            sourceChip={sourceChip}
            hideLoopChip={loop}
            showThumb={false}
            compact
          />
        </button>
        <button
          type="button"
          className="flex h-10 w-10 shrink-0 items-center justify-center text-text-secondary"
          data-testid={`mappe-tile-akte-${route.id}`}
          onClick={onAkte}
          aria-label={akteLabel}
          title={akteLabel}
        >
          <MappeGlyph name="mappe" size={18} />
        </button>
        <button
          type="button"
          className="flex h-10 w-10 shrink-0 items-center justify-center text-lg leading-none text-text-secondary"
          data-testid={`mappe-tile-remove-${route.id}`}
          onClick={onRemove}
          aria-label={removeLabel}
          title={removeLabel}
        >
          ×
        </button>
      </div>
    </li>
  );
}
