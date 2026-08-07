"use client";

import type { ReactNode } from "react";
import {
  DEFAULT_ROUTE_FILTERS,
  ELEVATION_OPTIONS,
  SCALE_OPTIONS,
  SURFACE_OPTIONS,
  type RouteFilterState,
} from "@/lib/routing/routeFilters";

export function FilterChips({
  minutes,
  onMinutes,
  filters,
  onChange,
}: {
  minutes: number;
  onMinutes: (m: number) => void;
  filters: RouteFilterState;
  onChange: (next: RouteFilterState) => void;
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
          onChange={(e) => onMinutes(Number(e.target.value))}
          className="mt-1 w-full"
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
        {SCALE_OPTIONS.filter((o) => o.id !== "any").map((o) => (
          <Chip
            key={o.id}
            active={filters.scale === o.id}
            onClick={() =>
              onChange({
                ...filters,
                scale: filters.scale === o.id ? "any" : o.id,
              })
            }
          >
            {o.label}
          </Chip>
        ))}
        {ELEVATION_OPTIONS.filter((o) => o.id !== "any").map((o) => (
          <Chip
            key={o.id}
            active={filters.elevation === o.id}
            onClick={() =>
              onChange({
                ...filters,
                elevation: filters.elevation === o.id ? "any" : o.id,
              })
            }
          >
            {o.label}
          </Chip>
        ))}
        {SURFACE_OPTIONS.filter((o) => o.id != null).map((o) => (
          <Chip
            key={o.id!}
            active={filters.surfaceQuery === o.id}
            onClick={() =>
              onChange({
                ...filters,
                surfaceQuery:
                  filters.surfaceQuery === o.id ? null : (o.id as string),
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
            className="rounded-full px-2.5 py-1 text-[11px] text-text-secondary underline"
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
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full px-2.5 py-1 text-[11px] font-medium ${
        active
          ? "bg-accent text-white"
          : "bg-surface-elevated text-text-secondary"
      }`}
    >
      {children}
    </button>
  );
}
