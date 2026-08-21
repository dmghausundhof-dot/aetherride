"use client";

import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { TourLineThumb } from "@/components/tours/TourLineThumb";
import {
  mappeCardStatParts,
  mappeFaceTag,
  savedRouteIsLoop,
  savedRouteTrackCoords,
} from "@/lib/tours/mappeList";
import type { SavedRoute } from "@/types/route";

export function MappeTourFace({
  route,
  visLabel,
  loopLabel,
  noTrackLabel,
  size = 80,
  caption,
  awayLabel,
  conditionLabel,
  sourceChip,
  showThumb = true,
  hideLoopChip = false,
  thumbWide = false,
  compact = false,
}: {
  route: SavedRoute;
  visLabel: string;
  loopLabel: string;
  noTrackLabel: string;
  size?: number;
  caption?: string;
  awayLabel?: string;
  conditionLabel?: string;
  sourceChip?: string;
  showThumb?: boolean;
  hideLoopChip?: boolean;
  thumbWide?: boolean;
  compact?: boolean;
}) {
  const stats = mappeCardStatParts(route);
  const coords = savedRouteTrackCoords(route);
  const shared = route.visibility === "shared";
  const loop = savedRouteIsLoop(route);
  const scale = compact ? null : mappeFaceTag(route.mtbScale);
  const surface = compact ? null : mappeFaceTag(route.surface);
  const gap = compact ? "mt-1" : "mt-1.5";
  const hasChips = Boolean(
    shared ||
      sourceChip ||
      (loop && !hideLoopChip) ||
      conditionLabel ||
      scale ||
      surface,
  );

  return (
    <div className="flex gap-3">
      {showThumb ? (
        <span
          className="shrink-0"
          style={thumbWide ? { width: size * 1.7 } : undefined}
        >
          <TourLineThumb
            coordinates={coords}
            label={route.name}
            noTrackLabel={noTrackLabel}
            size={size}
            wide={thumbWide}
          />
        </span>
      ) : null}
      <div className="min-w-0 flex-1 py-0.5">
        <span className={`block truncate font-semibold ${compact ? "text-[13px]" : "text-sm"}`}>{route.name}</span>
        {stats ? (
          compact ? (
            <span className={`${gap} block truncate text-[11px] tabular-nums text-text-secondary`}>
              {[stats.km, stats.hm, stats.min].filter(Boolean).join(" · ")}
            </span>
          ) : (
          <span className={`${gap} flex flex-wrap gap-x-3 gap-y-1 text-[11px] tabular-nums text-text-secondary`}>
            <span className="inline-flex items-center gap-1">
              <MappeGlyph name="distance" size={14} />
              {stats.km}
            </span>
            {stats.hm ? (
              <span className="inline-flex items-center gap-1">
                <MappeGlyph name="elevation" size={14} />
                {stats.hm}
              </span>
            ) : null}
            <span className="inline-flex items-center gap-1">
              <MappeGlyph name="duration" size={14} />
              {stats.min}
            </span>
          </span>
          )
        ) : (
          <span className={`${gap} block text-xs text-text-secondary`}>
            {noTrackLabel}
          </span>
        )}
        {hasChips ? (
        <span className={`${gap} flex flex-wrap items-center gap-1.5 text-[11px] text-text-secondary`}>
          {shared ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              <MappeGlyph name="shared" size={12} />
              {visLabel}
            </span>
          ) : null}
          {sourceChip ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              <MappeGlyph name="mappe" size={12} />
              {sourceChip}
            </span>
          ) : null}
          {loop && !hideLoopChip ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              <MappeGlyph name="loop" size={12} />
              {loopLabel}
            </span>
          ) : null}
          {conditionLabel ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              <MappeGlyph name="stimmen" size={12} />
              {conditionLabel}
            </span>
          ) : null}
          {scale ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              {scale}
            </span>
          ) : null}
          {surface ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-surface-elevated px-1.5 py-0.5">
              {surface}
            </span>
          ) : null}
        </span>
        ) : null}
        {awayLabel ? (
          <span className={`${gap} block truncate text-[11px] font-semibold text-text-secondary`}>
            {awayLabel}
          </span>
        ) : null}
        {caption ? (
          <span className={`${gap} block truncate text-[11px] text-text-secondary`}>
            {caption}
          </span>
        ) : null}
      </div>
    </div>
  );
}
