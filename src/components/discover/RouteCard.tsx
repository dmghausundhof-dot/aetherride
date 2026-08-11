"use client";

import Link from "next/link";
import { Mountain, Route, Bookmark, BookmarkCheck, Play, ChevronRight, ExternalLink } from "lucide-react";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { ElevationStrip } from "@/components/ElevationStrip";
import { sanitizeElevationM } from "@/lib/discover/elevationGuard";

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
              Tour-Idee · Geometrie wird beim Planen geroutet
            </p>
            <p className="mt-0.5 text-xs tabular-nums text-text-secondary">
              {route.distanceFromOriginKm != null
                ? `~${route.distanceFromOriginKm} km entfernt · `
                : ""}
              {route.distanceKm} km
              {elev != null ? ` · ${elev} hm` : ""} · {route.durationMin}{" "}
              min
              {route.mtbScale !== "—" ? ` · ${route.mtbScale}` : ""}
            </p>
          </div>
          <div className="rounded-full bg-accent/20 px-2 py-1 text-xs font-bold text-accent">
            {route.matchScore}%
          </div>
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
          <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
            <Route className="h-3 w-3" />
            {route.loop ? "Rundkurs" : "A→B"}
          </span>
          <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
            <Mountain className="h-3 w-3" />
            {route.surface}
          </span>
        </div>
        <p className="mt-2 line-clamp-2 text-xs text-text-secondary">
          Weil: {route.reasons.slice(0, 2).join(" — ")}
        </p>
        {route.rangeNote && (
          <p className="mt-2 text-xs text-warning">{route.rangeNote}</p>
        )}
        <p className="mt-2 inline-flex items-center gap-1 text-xs font-medium text-accent">
          Details <ChevronRight className="h-3.5 w-3.5" />
        </p>
      </button>
      <div className="mt-3 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={onToggleSave}
          className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-border px-3 py-2.5 text-sm"
          aria-label={saved ? "Gespeichert entfernen" : "Speichern"}
        >
          {saved ? (
            <BookmarkCheck className="h-4 w-4 text-accent" />
          ) : (
            <Bookmark className="h-4 w-4" />
          )}
        </button>
        <Link
          href={`/tours/${route.id}`}
          className="inline-flex items-center justify-center gap-1 rounded-xl border border-border px-3 py-2.5 text-xs font-medium text-text-secondary hover:text-foreground"
        >
          <ExternalLink className="h-3.5 w-3.5" /> Seite
        </Link>
        <button
          type="button"
          onClick={onStart}
          className="flex min-w-[7rem] flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
        >
          <Play className="h-4 w-4 fill-current" /> In App starten
        </button>
      </div>
    </article>
  );
}
