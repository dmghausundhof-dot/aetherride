"use client";

import Link from "next/link";
import { ChevronRight, ExternalLink } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { ElevationStrip } from "@/components/ElevationStrip";
import { TourCommunityChip } from "@/components/community/TourCommunityChip";
import { eventsForTour } from "@/lib/tours/tourFunctions";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";
import { useChromeLang } from "@/hooks/useChromeLang";
import { discoverUi } from "@/lib/i18n/discoverUi";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { bikeMatchLine, riderFacingReasons } from "@/lib/discover/riderHonesty";
import { useAppStore } from "@/store/useAppStore";

export function RouteCard({
  route,
  highlighted,
  saved,
  onOpen,
  onStart,
  onToggleSave,
}: {
  route: RouteSuggestion;
  highlighted?: boolean;
  saved?: boolean;
  onOpen: () => void;
  onStart: () => void;
  onToggleSave: () => void;
}) {
  const lang = useChromeLang();
  const d = discoverUi(lang);
  const reasons = riderFacingReasons(route.reasons);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const matchLine = bikeMatchLine(
    Boolean(activeBike),
    activeBike ? bikeCategoryLabel(activeBike.category, lang) : null,
    d.fitsYourBike,
  );
  const elev = sanitizeElevationM(route.elevationM, route.distanceKm);
  return (
    <article
      id={`route-${route.id}`}
      className={`rounded-2xl border bg-surface p-4 ${
        highlighted ? "border-accent ring-1 ring-accent/40" : "border-border"
      }`}
    >
      <button type="button" onClick={onOpen} className="w-full text-left">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <h3 className="font-semibold">{route.name}</h3>
            <p className="mt-0.5 text-[11px] text-text-secondary">
              {d.tourIdea}
            </p>
            <p className="mt-0.5 text-xs tabular-nums text-text-secondary">
              {route.distanceFromOriginKm != null
                ? d.away(route.distanceFromOriginKm)
                : ""}
              {formatDistanceElevation(route.distanceKm, elev)} ·{" "}
              {route.durationMin} min
              {route.mtbScale !== "—" ? ` · ${route.mtbScale}` : ""}
            </p>
          </div>
          {matchLine ? (
            <div className="rounded-full bg-accent/20 px-2 py-1 text-xs font-semibold text-accent">
              {matchLine}
            </div>
          ) : null}
        </div>
        {elev != null && (
          <div className="mt-2 text-accent">
            <ElevationStrip
              elevationM={elev}
              distanceKm={route.distanceKm}
              estimated
            />
          </div>
        )}
        <div className="mt-2 flex flex-wrap gap-2 text-[11px]">
          <TourCommunityChip tourId={route.id} />
          {eventsForTour(route.id).slice(0, 1).map((event) => (
            <span
              key={event.id}
              className="inline-flex items-center rounded-md bg-surface-elevated px-2 py-0.5 text-text-secondary"
            >
              {event.dateLabel}
            </span>
          ))}
          <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
            <MappeGlyph name={route.loop ? "loop" : "distance"} size={12} />
            {route.loop ? d.loopRound : d.pointAb}
          </span>
          <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
            <MappeGlyph name="elevation" size={12} />
            {route.surface}
          </span>
        </div>
        <p className="mt-2 line-clamp-2 text-xs text-text-secondary">
          {d.because}
          {reasons.slice(0, 2).join(" — ")}
        </p>
        {route.rangeNote && (
          <p className="mt-2 text-xs text-warning">{route.rangeNote}</p>
        )}
        <p className="mt-2 inline-flex items-center gap-1 text-xs font-medium text-accent">
          {d.details} <ChevronRight className="h-3.5 w-3.5" />
        </p>
      </button>
      <div className="mt-3 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={onToggleSave}
          className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-border px-3 py-2.5 text-sm"
          aria-label={saved ? d.unsaveAria : d.saveAria}
        >
          {saved ? (
            <ChromeGlyph name="merken" size={16} current className="text-accent" />
          ) : (
            <ChromeGlyph name="merken" size={16} current className="text-text-secondary" />
          )}
        </button>
        <Link
          href={`/tours/${route.id}`}
          className="inline-flex items-center justify-center gap-1 rounded-xl border border-border px-3 py-2.5 text-xs font-medium text-text-secondary hover:text-foreground"
        >
          <ExternalLink className="h-3.5 w-3.5" /> {d.pageLink}
        </Link>
        <button
          type="button"
          onClick={onStart}
          className="flex min-w-[7rem] flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent"
        >
          <MappeGlyph name="ride" size={16} /> {d.startInApp}
        </button>
      </div>
    </article>
  );
}
