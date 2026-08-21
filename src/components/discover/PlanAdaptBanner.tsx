"use client";

import type { BaseTour } from "@/lib/routing/planDraft";
import type { discoverUi } from "@/lib/i18n/discoverUi";

type Copy = ReturnType<typeof discoverUi>;

export function PlanAdaptBanner({
  tour,
  copy,
  compact = false,
}: {
  tour: BaseTour;
  copy: Copy;
  compact?: boolean;
}) {
  const km = tour.distanceKm;
  const kmLabel =
    km != null ? `${km.toFixed(km < 10 ? 1 : 0)} km` : null;
  const minLabel = tour.durationMin != null ? `${tour.durationMin} min` : null;
  const climb =
    tour.elevationM != null && tour.elevationM > 0
      ? `↑ ${tour.elevationM} m`
      : "—";
  const surface = tour.surface?.trim() || "—";
  const photo = tour.photoUrl?.trim() || "";
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center gap-2.5 rounded-2xl border border-border bg-surface px-2.5 py-2">
        <div className="grid h-14 w-14 shrink-0 overflow-hidden rounded-lg bg-[#2A2E32] text-white/80">
          {photo ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={photo} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="grid place-items-center text-lg" aria-hidden>
              ▲
            </span>
          )}
        </div>
        <div className="min-w-0 flex-1">
          {tour.loop ? (
            <p className="text-[11px] font-bold text-chrome">{copy.loopClosed}</p>
          ) : null}
          <p className="truncate text-sm font-extrabold">{tour.name}</p>
          {compact && kmLabel && minLabel ? (
            <p className="truncate text-[12px] text-text-secondary">
              {kmLabel} · {minLabel}
            </p>
          ) : null}
        </div>
      </div>
      {!compact && kmLabel && minLabel ? (
        <div className="overflow-hidden rounded-2xl border border-border bg-surface">
          <div className="grid grid-cols-2">
            <Stat label={copy.statDuration} value={minLabel} />
            <Stat label={copy.statLength} value={kmLabel} borderLeft />
          </div>
          <div className="grid grid-cols-2 border-t border-border">
            <Stat label={copy.statAscent} value={climb} />
            <Stat label={copy.statSurface} value={surface} borderLeft />
          </div>
        </div>
      ) : null}
    </div>
  );
}

function Stat({
  label,
  value,
  borderLeft,
}: {
  label: string;
  value: string;
  borderLeft?: boolean;
}) {
  return (
    <div
      className={`px-3 py-2.5 ${borderLeft ? "border-l border-border" : ""}`}
    >
      <p className="text-[11px] font-semibold text-text-secondary">{label}</p>
      <p className="truncate text-[17px] font-extrabold leading-tight">{value}</p>
    </div>
  );
}
