"use client";

import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { TourLineThumb } from "@/components/tours/TourLineThumb";
import { savedRouteTrackCoords } from "@/lib/tours/mappeList";
import { stimmeInboxShowsBody } from "@/lib/tours/tourAkte";
import type { SavedRoute } from "@/types/route";

export function MappeStimmeRow({
  title,
  body,
  noTrackLabel,
  conditionLabel,
  pendingLabel,
  route,
  onOpen,
}: {
  title: string;
  body: string;
  noTrackLabel: string;
  conditionLabel?: string;
  pendingLabel?: string;
  route?: SavedRoute;
  onOpen?: () => void;
}) {
  const coords = route ? savedRouteTrackCoords(route) : [];
  const showBody = stimmeInboxShowsBody(title, body);
  const line = [pendingLabel, showBody ? body : null]
    .filter(Boolean)
    .join(" · ");

  return (
    <li className="overflow-hidden rounded-2xl border border-border bg-surface-elevated">
      <button
        type="button"
        className="w-full text-left"
        onClick={onOpen}
        disabled={!onOpen}
      >
        {route ? (
          <TourLineThumb
            coordinates={coords}
            label={title}
            noTrackLabel={noTrackLabel}
            size={56}
            wide
          />
        ) : (
          <span className="flex px-3 pt-3">
            <MappeGlyph name="stimmen" size={18} />
          </span>
        )}
        <span className="flex items-center gap-2 px-3 py-2.5">
          <span className="min-w-0 flex-1">
            <span className="block truncate text-sm font-semibold">{title}</span>
            {line ? (
              <span className="mt-1 block truncate text-xs text-text-secondary">
                {line}
              </span>
            ) : null}
            {conditionLabel ? (
              <span className="mt-1.5 inline-flex items-center gap-1 rounded-full bg-surface px-2 py-0.5 text-[11px] text-text-secondary">
                <MappeGlyph name="stimmen" size={12} />
                {conditionLabel}
              </span>
            ) : null}
          </span>
          {onOpen ? (
            <span className="shrink-0 text-text-secondary">›</span>
          ) : null}
        </span>
      </button>
    </li>
  );
}
