"use client";

import { useEffect, useId, useRef } from "react";
import { Bike, Locate, Search, SlidersHorizontal } from "lucide-react";
import { FilterChips } from "@/components/discover/FilterChips";
import {
  DISCOVER_LENS_FILTERS,
  DEFAULT_FILTER_MINUTES,
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

/**
 * Komoot-Chrome wie Native: Suche + Navigieren, darunter optional ein
 * Navi-Profilchip (≥2), Umkreis, Filter mit Badge. Disziplin liegt im Sheet.
 */
export function DiscoverExploreChrome({
  searchQuery,
  onSearchQuery,
  onPlanRoute,
  aroundKm,
  filterCount,
  filterOpen,
  onOpenFilters,
  onCloseFilters,
  profileMenu,
  activeProfile,
  onProfile,
  minutes,
  onMinutes,
  filters,
  onFilters,
  routingProfile,
  resultCount,
}: {
  searchQuery: string;
  onSearchQuery: (q: string) => void;
  onPlanRoute: () => void;
  aroundKm: number;
  filterCount: number;
  filterOpen: boolean;
  onOpenFilters: () => void;
  onCloseFilters: () => void;
  profileMenu: RoutingProfile[];
  activeProfile: RoutingProfile;
  onProfile: (p: RoutingProfile) => void;
  minutes: number;
  onMinutes: (m: number) => void;
  filters: RouteFilterState;
  onFilters: (next: RouteFilterState) => void;
  routingProfile: RoutingProfile;
  resultCount: number;
}) {
  const lang = useChromeLang();
  const d = discoverCopy(lang);
  const closeLabel = discoverUi(lang).close;
  const titleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);
  const profileVisible = discoverNavProfileChipVisible(profileMenu);
  const filterActive = filterCount > 0;
  const profileOptions = profileMenu.includes(activeProfile)
    ? profileMenu
    : [activeProfile, ...profileMenu];

  useEffect(() => {
    if (!filterOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCloseFilters();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [filterOpen, onCloseFilters]);

  return (
    <div data-testid="discover-explore-chrome" className="space-y-2">
      <div className="rounded-xl border border-border bg-surface-elevated/80 p-2">
        <div className="flex items-center gap-2">
          <label className="relative min-w-0 flex-1">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
            <input
              data-testid="discover-explore-search"
              type="search"
              value={searchQuery}
              onChange={(e) => onSearchQuery(e.target.value)}
              placeholder={d.searchHint}
              className="w-full rounded-full border-0 bg-background py-2 pl-8 pr-3 text-[13px] outline-none ring-1 ring-border focus:ring-chrome"
            />
          </label>
          <button
            type="button"
            data-testid="discover-plan-route"
            onClick={onPlanRoute}
            className="shrink-0 rounded-full bg-accent px-3 py-2 text-[12.5px] font-extrabold text-on-accent hover:bg-accent-hover"
          >
            {d.planRouteCta}
          </button>
        </div>
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          {profileVisible ? (
            <label
              data-testid="discover-nav-profile-chip"
              className="inline-flex max-w-full items-center gap-1 rounded-full border border-border bg-background px-2 py-1 text-[12.5px] font-semibold"
            >
              <Bike className="h-3.5 w-3.5 shrink-0 text-text-secondary" />
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
            onClick={onOpenFilters}
            className="inline-flex items-center gap-1 rounded-full border border-border bg-background px-2.5 py-1 text-[12.5px] font-semibold text-text-secondary"
          >
            <Locate className="h-3.5 w-3.5" />
            {d.aroundKm(aroundKm)}
          </button>
          <button
            type="button"
            data-testid="discover-filter-chip"
            onClick={onOpenFilters}
            aria-expanded={filterOpen}
            className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[12.5px] font-bold ${
              filterActive
                ? "border-accent bg-accent text-on-accent"
                : "border-border bg-background text-text-secondary"
            }`}
          >
            <SlidersHorizontal className="h-3.5 w-3.5" />
            {filterActive ? `${d.filter} ${filterCount}` : d.filter}
          </button>
        </div>
      </div>

      {filterOpen ? (
        <div
          className="fixed inset-0 z-[80] flex items-end justify-center sm:items-center"
          role="presentation"
        >
          <button
            type="button"
            aria-label={closeLabel}
            className="absolute inset-0 bg-background/55"
            onClick={onCloseFilters}
          />
          <div
            data-testid="discover-filter-sheet"
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            className="relative z-10 flex max-h-[78vh] w-full max-w-lg flex-col rounded-t-xl border border-border bg-surface sm:m-4 sm:rounded-xl"
          >
            <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-3">
              <h2 id={titleId} className="text-lg font-extrabold">
                {d.filter}
              </h2>
              <button
                ref={closeRef}
                type="button"
                onClick={onCloseFilters}
                className="rounded-xl px-2 py-1 text-sm text-text-secondary"
              >
                {closeLabel}
              </button>
            </div>
            <div className="min-h-0 flex-1 overflow-y-auto px-4 py-3">
              <FilterChips
                minutes={minutes}
                onMinutes={onMinutes}
                filters={filters}
                onChange={onFilters}
                profile={routingProfile}
                showReset={false}
              />
            </div>
            <div className="flex gap-2 border-t border-border px-4 py-3">
              <button
                type="button"
                disabled={filterCount === 0 && minutes === DEFAULT_FILTER_MINUTES}
                onClick={() => {
                  onMinutes(DEFAULT_FILTER_MINUTES);
                  onFilters(DISCOVER_LENS_FILTERS);
                }}
                className="min-h-12 flex-1 rounded-full border border-border text-sm font-semibold disabled:opacity-40"
              >
                {d.reset}
              </button>
              <button
                type="button"
                onClick={onCloseFilters}
                className="min-h-12 flex-[2] rounded-full bg-accent text-sm font-extrabold text-on-accent hover:bg-accent-hover"
              >
                {d.showTours(resultCount)}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
