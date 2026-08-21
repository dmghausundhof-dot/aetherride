"use client";

import { useEffect, useId, useRef, useState, type ReactNode, type RefObject } from "react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { RadNavMark } from "@/components/garage/RadNavMark";
import {
  DistanceMaxChips,
  FilterChips,
} from "@/components/discover/FilterChips";
import {
  DEFAULT_FILTER_MINUTES,
  aroundFilterActive,
  resetDiscoverAround,
  resetDiscoverSheetFilters,
} from "@/lib/discover/discoverExploreChrome";
import { discoverCopy } from "@/lib/i18n/discoverCopy";
import { discoverUi } from "@/lib/i18n/discoverUi";
import { useChromeLang } from "@/hooks/useChromeLang";
import {
  discoverNavProfileChipVisible,
  profileLabel,
  type RoutingProfile,
} from "@/lib/routing/profiles";
import type { RouteFilterState } from "@/lib/routing/routeFilters";

type ExploreSheet = "around" | "filter";

/**
 * Komoot-Chrome wie Native: Suche + Navigieren, darunter optional ein
 * Navi-Profilchip (≥2), Umkreis, Filter mit Badge. Distanz und Filter
 * sind zwei Flächen. Disziplin liegt im Filter-Sheet.
 */
type PlaceHit = { label: string; lat: number; lng: number };

export function DiscoverExploreChrome({
  searchQuery,
  onSearchQuery,
  onSearchSubmit,
  placeHits,
  recents,
  onPlaceHit,
  browsePlace,
  aroundKm,
  filterCount,
  profileMenu,
  activeProfile,
  onProfile,
  minutes,
  onMinutes,
  filters,
  onFilters,
  routingProfile,
  resultCount,
  onOfflineMaps,
  onPlanRoute,
}: {
  searchQuery: string;
  onSearchQuery: (q: string) => void;
  onSearchSubmit?: () => void;
  placeHits?: PlaceHit[];
  recents?: PlaceHit[];
  onPlaceHit?: (hit: PlaceHit) => void;
  browsePlace?: { label: string } | null;
  onPlanRoute: () => void;
  aroundKm: number;
  filterCount: number;
  profileMenu: RoutingProfile[];
  activeProfile: RoutingProfile;
  onProfile: (p: RoutingProfile) => void;
  minutes: number;
  onMinutes: (m: number) => void;
  filters: RouteFilterState;
  onFilters: (next: RouteFilterState) => void;
  routingProfile: RoutingProfile;
  resultCount: number;
  onOfflineMaps?: () => void;
}) {
  const lang = useChromeLang();
  const d = discoverCopy(lang);
  const ui = discoverUi(lang);
  const closeLabel = ui.close;
  const aroundTitleId = useId();
  const filterTitleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);
  const [sheet, setSheet] = useState<ExploreSheet | null>(null);
  const profileVisible = discoverNavProfileChipVisible(profileMenu);
  const filterActive = filterCount > 0;
  const aroundActive = aroundFilterActive(filters.maxAwayKm ?? null);
  const profileOptions = profileMenu.includes(activeProfile)
    ? profileMenu
    : [activeProfile, ...profileMenu];

  useEffect(() => {
    if (!sheet) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setSheet(null);
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [sheet]);

  const showPlaceHits = Boolean(placeHits?.length && onPlaceHit);
  const showRecents =
    !showPlaceHits &&
    searchQuery.trim().length < 2 &&
    Boolean(recents?.length && onPlaceHit);
  const chipHits = showPlaceHits ? placeHits! : showRecents ? recents! : [];

  return (
    <div data-testid="discover-explore-chrome" className="space-y-2">
      <div className="rounded-xl border border-border bg-surface-elevated/80 p-2">
        <div className="flex items-center gap-2">
          <label className="relative min-w-0 flex-1">
            <ChromeGlyph
              name="search"
              size={16}
              current
              className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-text-secondary"
            />
            <input
              data-testid="discover-explore-search"
              type="search"
              value={searchQuery}
              onChange={(e) => onSearchQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key !== "Enter") return;
                e.preventDefault();
                onSearchSubmit?.();
              }}
              placeholder={d.searchHint}
              className="w-full rounded-full border-0 bg-background py-2 pl-8 pr-3 text-[13px] outline-none ring-1 ring-border focus:ring-chrome"
            />
          </label>
          <button
            type="button"
            data-testid="discover-plan-route"
            onClick={() => {
              setSheet(null);
              onPlanRoute();
            }}
            className="shrink-0 rounded-full bg-accent px-3 py-2 text-[12.5px] font-extrabold text-on-accent hover:bg-accent-hover"
          >
            {d.planRouteCta}
          </button>
        </div>
        {chipHits.length > 0 ? (
          <div
            data-testid="discover-place-hits"
            className="mt-2 space-y-1"
          >
            {showRecents ? (
              <p className="px-0.5 text-[11px] font-semibold text-text-secondary">
                {ui.recently}
              </p>
            ) : null}
            <div className="flex gap-1.5 overflow-x-auto pb-0.5">
            {chipHits.map((hit) => (
              <button
                key={`${hit.label}-${hit.lat}-${hit.lng}`}
                type="button"
                data-testid="discover-explore-place-chip"
                onClick={() => onPlaceHit?.(hit)}
                className="inline-flex max-w-[14rem] shrink-0 items-center gap-1 rounded-full border border-border bg-background px-2.5 py-1 text-[12px] font-semibold"
              >
                {showRecents ? (
                  <ChromeGlyph name="recent" size={12} current className="shrink-0 text-text-secondary" />
                ) : (
                  <ChromeGlyph name="search" size={12} current className="shrink-0 text-text-secondary" />
                )}
                <span className="truncate">{hit.label}</span>
              </button>
            ))}
            </div>
          </div>
        ) : null}
        {browsePlace ? (
          <div className="mt-2">
            <div
              data-testid="discover-back-to-gps"
              className="inline-flex max-w-full items-center gap-1.5 rounded-full border border-border bg-background px-2.5 py-1 text-[12px] font-semibold text-text-secondary"
            >
              <span className="truncate">{browsePlace.label}</span>
            </div>
          </div>
        ) : null}
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          {profileVisible ? (
            <label
              data-testid="discover-nav-profile-chip"
              className="inline-flex max-w-full items-center gap-1 rounded-full border border-border bg-background px-2 py-1 text-[12.5px] font-semibold"
            >
              <RadNavMark className="h-3.5 w-3.5 shrink-0 text-text-secondary" />
              <select
                value={activeProfile}
                onChange={(e) => onProfile(e.target.value as RoutingProfile)}
                className="max-w-[9rem] bg-transparent text-[12.5px] font-semibold outline-none"
                aria-label={d.sportPref}
              >
                {profileOptions.map((p) => (
                  <option key={p} value={p}>
                    {profileLabel(p)}
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          <button
            type="button"
            data-testid="discover-around-chip"
            aria-expanded={sheet === "around"}
            onClick={() => setSheet("around")}
            className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[12.5px] font-semibold ${
              aroundActive
                ? "border-accent bg-accent text-on-accent"
                : "border-border bg-background text-text-secondary"
            }`}
          >
            <ChromeGlyph name="locate" size={14} current />
            {d.aroundKm(aroundKm)}
          </button>
          <button
            type="button"
            data-testid="discover-filter-chip"
            aria-expanded={sheet === "filter"}
            onClick={() => setSheet("filter")}
            className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[12.5px] font-bold ${
              filterActive
                ? "border-accent bg-accent text-on-accent"
                : "border-border bg-background text-text-secondary"
            }`}
          >
            <ChromeGlyph name="filter" size={14} current />
            {filterActive ? `${d.filter} ${filterCount}` : d.filter}
          </button>
          {onOfflineMaps ? (
            <button
              type="button"
              data-testid="discover-offline-chip"
              onClick={onOfflineMaps}
              className="inline-flex items-center gap-1 rounded-full border border-border bg-background px-2.5 py-1 text-[12.5px] font-semibold text-text-secondary"
            >
              <ChromeGlyph name="download" size={14} current />
              {ui.offlineMapsChip}
            </button>
          ) : null}
        </div>
      </div>

      {sheet === "around" ? (
        <ExploreSheetFrame
          testId="discover-around-sheet"
          titleId={aroundTitleId}
          title={d.around}
          closeLabel={closeLabel}
          closeRef={closeRef}
          compact
          onClose={() => setSheet(null)}
          footer={
            <>
              <button
                type="button"
                disabled={!aroundActive}
                onClick={() => onFilters(resetDiscoverAround(filters))}
                className="min-h-12 flex-1 rounded-full border border-border text-sm font-semibold disabled:opacity-40"
              >
                {d.reset}
              </button>
              <button
                type="button"
                onClick={() => setSheet(null)}
                className="min-h-12 flex-[2] rounded-full bg-accent text-sm font-extrabold text-on-accent hover:bg-accent-hover"
              >
                {d.showTours(resultCount)}
              </button>
            </>
          }
        >
          <DistanceMaxChips
            maxDistanceKm={filters.maxAwayKm ?? null}
            onChange={(km) => onFilters({ ...filters, maxAwayKm: km })}
          />
        </ExploreSheetFrame>
      ) : null}

      {sheet === "filter" ? (
        <ExploreSheetFrame
          testId="discover-filter-sheet"
          titleId={filterTitleId}
          title={d.filter}
          closeLabel={closeLabel}
          closeRef={closeRef}
          onClose={() => setSheet(null)}
          footer={
            <>
              <button
                type="button"
                disabled={
                  filterCount === 0 && minutes === DEFAULT_FILTER_MINUTES
                }
                onClick={() => {
                  onMinutes(DEFAULT_FILTER_MINUTES);
                  onFilters(resetDiscoverSheetFilters(filters));
                }}
                className="min-h-12 flex-1 rounded-full border border-border text-sm font-semibold disabled:opacity-40"
              >
                {d.reset}
              </button>
              <button
                type="button"
                onClick={() => setSheet(null)}
                className="min-h-12 flex-[2] rounded-full bg-accent text-sm font-extrabold text-on-accent hover:bg-accent-hover"
              >
                {d.showTours(resultCount)}
              </button>
            </>
          }
        >
          <FilterChips
            minutes={minutes}
            onMinutes={onMinutes}
            filters={filters}
            onChange={onFilters}
            profile={routingProfile}
            showReset={false}
            showDistance
            showVisibility={false}
          />
        </ExploreSheetFrame>
      ) : null}
    </div>
  );
}

function ExploreSheetFrame({
  testId,
  titleId,
  title,
  closeLabel,
  closeRef,
  compact,
  onClose,
  footer,
  children,
}: {
  testId: string;
  titleId: string;
  title: string;
  closeLabel: string;
  closeRef: RefObject<HTMLButtonElement | null>;
  compact?: boolean;
  onClose: () => void;
  footer: ReactNode;
  children: ReactNode;
}) {
  return (
    <div
      className="fixed inset-0 z-[80] flex items-end justify-center sm:items-center"
      role="presentation"
    >
      <button
        type="button"
        aria-label={closeLabel}
        className="absolute inset-0 bg-background/55"
        onClick={onClose}
      />
      <div
        data-testid={testId}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className={`relative z-10 flex w-full max-w-lg flex-col rounded-t-xl border border-border bg-surface sm:m-4 sm:rounded-xl ${
          compact ? "" : "max-h-[78vh]"
        }`}
      >
        <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-3">
          <h2 id={titleId} className="text-lg font-extrabold">
            {title}
          </h2>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            className="rounded-xl px-2 py-1 text-sm text-text-secondary"
          >
            {closeLabel}
          </button>
        </div>
        <div
          className={`px-4 py-3 ${compact ? "" : "min-h-0 flex-1 overflow-y-auto"}`}
        >
          {children}
        </div>
        <div className="flex gap-2 border-t border-border px-4 py-3">
          {footer}
        </div>
      </div>
    </div>
  );
}
