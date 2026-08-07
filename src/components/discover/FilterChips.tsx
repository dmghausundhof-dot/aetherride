"use client";

import {
  DEFAULT_ROUTE_FILTERS,
  ELEVATION_OPTIONS,
  SCALE_OPTIONS,
  SURFACE_OPTIONS,
  type RouteFilterState,
} from "@/lib/routing/routeFilters";

export function DiscoverFilterChips({
  filters,
  onChange,
  minutes,
  onMinutesChange,
}: {
  filters: RouteFilterState;
  onChange: (next: RouteFilterState) => void;
  minutes: number;
  onMinutesChange: (m: number) => void;
}) {
  return (
    <div className="flex flex-col gap-3">
      <label className="text-sm">
        <span className="text-text-secondary">Zeitfenster · </span>
        <span className="font-medium tabular-nums">{minutes} min</span>
        <input
          type="range"
          min={45}
          max={300}
          step={15}
          value={minutes}
          onChange={(e) => onMinutesChange(Number(e.target.value))}
          className="mt-1 w-full"
          aria-label="Verfügbare Zeit in Minuten"
        />
      </label>

      <div className="flex flex-wrap gap-1.5">
        <Chip
          active={filters.loopOnly}
          onClick={() =>
            onChange({ ...filters, loopOnly: !filters.loopOnly })
          }
        >
          Rundkurs
        </Chip>
        {SCALE_OPTIONS.map((o) => (
          <Chip
            key={o.id}
            active={filters.scale === o.id}
            onClick={() => onChange({ ...filters, scale: o.id })}
          >
            {o.label}
          </Chip>
        ))}
      </div>

      <div className="flex flex-wrap gap-1.5">
        {ELEVATION_OPTIONS.map((o) => (
          <Chip
            key={o.id}
            active={filters.elevation === o.id}
            onClick={() => onChange({ ...filters, elevation: o.id })}
          >
            {o.label}
          </Chip>
        ))}
        {SURFACE_OPTIONS.map((o) => (
          <Chip
            key={o.label}
            active={filters.surfaceQuery === o.id}
            onClick={() =>
              onChange({
                ...filters,
                surfaceQuery:
                  filters.surfaceQuery === o.id ? null : o.id,
              })
            }
          >
            {o.label}
          </Chip>
        ))}
        {(filters.loopOnly ||
          filters.scale !== "any" ||
          filters.elevation !== "any" ||
          filters.surfaceQuery) && (
          <button
            type="button"
            className="rounded-lg px-2 py-1 text-[11px] text-accent"
            onClick={() => onChange(DEFAULT_ROUTE_FILTERS)}
          >
            Zurücksetzen
          </button>
        )}
      </div>
    </div>
  );
}

function Chip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-lg px-2.5 py-1 text-[11px] font-medium transition ${
        active
          ? "bg-accent text-white"
          : "bg-surface-elevated text-text-secondary"
      }`}
    >
      {children}
    </button>
  );
}
