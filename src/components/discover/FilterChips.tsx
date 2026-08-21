"use client";

import type { ReactNode } from "react";
import {
  DEFAULT_ROUTE_FILTERS,
  DISTANCE_MAX_OPTIONS,
  ELEVATION_OPTIONS,
  SPORT_FILTER_OPTIONS,
  SURFACE_OPTIONS,
  VISIBILITY_FILTER_OPTIONS,
  type RouteFilterState,
  type SurfaceKey,
} from "@/lib/routing/routeFilters";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { useChromeLang } from "@/hooks/useChromeLang";
import {
  discoverCopy,
  discoverDifficulty,
  discoverElevationLabel,
} from "@/lib/i18n/discoverCopy";

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
          ? "bg-accent text-on-accent"
          : "bg-surface-elevated text-text-secondary"
      }`}
    >
      {children}
    </button>
  );
}

export function DistanceMaxChips({
  maxDistanceKm,
  onChange,
}: {
  maxDistanceKm: number | null;
  onChange: (km: number | null) => void;
}) {
  const lang = useChromeLang();
  const d = discoverCopy(lang);
  return (
    <div
      className="flex flex-wrap gap-1.5"
      data-testid="discover-around-chips"
    >
      {DISTANCE_MAX_OPTIONS.filter((o) => o.id != null).map((o) => (
        <Chip
          key={o.id!}
          active={maxDistanceKm === o.id}
          onClick={() =>
            onChange(maxDistanceKm === o.id ? null : (o.id as number))
          }
        >
          {d.dist(o.id as number)}
        </Chip>
      ))}
    </div>
  );
}

export function FilterChips({
  minutes,
  onMinutes,
  filters,
  onChange,
  profile = "road",
  showTime = true,
  showReset = true,
  showDistance = true,
  showVisibility = true,
}: {
  minutes: number;
  onMinutes: (m: number) => void;
  filters: RouteFilterState;
  onChange: (next: RouteFilterState) => void;
  /** Aktives Routing-Profil steuert Schwierigkeits-Labels */
  profile?: RoutingProfile;
  showTime?: boolean;
  /** Native-Sheet hat eigenen Reset-Fuß — dann hier aus. */
  showReset?: boolean;
  /** Tourlänge (≤ km). Umkreis sitzt am eigenen Chip. */
  showDistance?: boolean;
  /** Mappe-Sichtbarkeit — nicht auf der öffentlichen Karte. */
  showVisibility?: boolean;
}) {
  const lang = useChromeLang();
  const d = discoverCopy(lang);
  const difficulty = discoverDifficulty(profile, lang);

  return (
    <div className="flex flex-col gap-3">
      {showTime && (
        <label className="text-sm">
          <span className="text-text-secondary">{d.timeWindow}</span>
          <span className="font-medium tabular-nums">{d.minutes(minutes)}</span>
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
      )}

      <div className="flex flex-wrap gap-1.5">
        <span className="w-full text-[10px] font-medium tracking-wide text-text-secondary">
          {d.sportPref}
        </span>
        {SPORT_FILTER_OPTIONS.map((o) => (
          <Chip
            key={o.id}
            active={filters.sport === o.id}
            onClick={() => onChange({ ...filters, sport: o.id })}
          >
            {d.sport[o.id]}
          </Chip>
        ))}
      </div>

      <div className="flex flex-wrap gap-1.5">
        <Chip
          active={filters.loopOnly}
          onClick={() => onChange({ ...filters, loopOnly: !filters.loopOnly })}
        >
          {d.loop}
        </Chip>
        {difficulty
          .filter((o) => o.id !== "any")
          .map((o) => (
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
            {discoverElevationLabel(o.id, lang)}
          </Chip>
        ))}
        {showDistance ? (
          <DistanceMaxChips
            maxDistanceKm={filters.maxDistanceKm}
            onChange={(km) => onChange({ ...filters, maxDistanceKm: km })}
          />
        ) : null}
        {SURFACE_OPTIONS.filter((o) => o.id != null).map((o) => (
          <Chip
            key={o.id!}
            active={filters.surfaceQuery === o.id}
            onClick={() =>
              onChange({
                ...filters,
                surfaceQuery:
                  filters.surfaceQuery === o.id ? null : (o.id as SurfaceKey),
              })
            }
          >
            {d.surface[o.id as SurfaceKey]}
          </Chip>
        ))}
      </div>

      {showVisibility ? (
      <div className="flex flex-wrap gap-1.5">
        <span className="w-full text-[10px] font-medium tracking-wide text-text-secondary">
          {d.mappe}
        </span>
        {VISIBILITY_FILTER_OPTIONS.map((o) => (
          <Chip
            key={o.id}
            active={(filters.visibility ?? "all_mine") === o.id}
            onClick={() => onChange({ ...filters, visibility: o.id })}
          >
            {o.id === "all_mine"
              ? d.visAll
              : o.id === "private"
                ? d.visPrivate
                : d.visPublic}
          </Chip>
        ))}
      </div>
      ) : null}

      {showReset && (
        <div className="flex flex-wrap gap-1.5">
          {(filters.loopOnly ||
            filters.scale !== "any" ||
            filters.elevation !== "any" ||
            filters.surfaceQuery ||
            (showDistance && filters.maxDistanceKm != null) ||
            filters.sport !== "all" ||
            (filters.visibility ?? "all_mine") !== "all_mine") && (
            <button
              type="button"
              className="rounded-full px-2.5 py-1 text-[11px] text-text-secondary underline"
              onClick={() => onChange(DEFAULT_ROUTE_FILTERS)}
            >
              {d.reset}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
