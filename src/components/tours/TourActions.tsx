"use client";

import { useCallback, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Bookmark,
  BookmarkCheck,
  Map,
  Navigation,
  Play,
  Route,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import type { PublicTour } from "@/lib/catalog/publicTours";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { activeRouteFromSuggestion } from "@/lib/routing/activeRoute";

function toSuggestion(tour: PublicTour): RouteSuggestion {
  return {
    id: tour.id,
    name: tour.name,
    category: tour.primaryCategory,
    distanceKm: tour.distanceKm,
    elevationM: tour.elevationM,
    durationMin: tour.durationMin,
    mtbScale: tour.difficulty,
    surface: tour.surface,
    loop: tour.loop,
    uncertainKmPct: 12,
    matchScore: 70,
    reasons: [
      tour.summary.slice(0, 80),
      `Belag ${tour.surface}`,
      tour.loop ? "Rundkurs" : "Etappe A→B",
    ],
    center: tour.center,
  };
}

export function TourActions({ tour }: { tour: PublicTour }) {
  const router = useRouter();
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const isRouteSaved = useAppStore((s) => s.isRouteSaved);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const [flash, setFlash] = useState<string | null>(null);

  const saved = isRouteSaved(tour.id);
  const suggestion = toSuggestion(tour);

  const toggleSave = useCallback(() => {
    if (isRouteSaved(tour.id)) {
      unsaveRoute(tour.id);
      setFlash("Aus Bibliothek entfernt");
    } else {
      saveRoute(suggestion);
      setFlash("In Bibliothek gespeichert");
    }
    setTimeout(() => setFlash(null), 2000);
  }, [tour.id, isRouteSaved, unsaveRoute, saveRoute, suggestion]);

  const startInApp = useCallback(async () => {
    // Live-Geometrie laden, falls Engine verfügbar
    try {
      const r = await fetch(
        `/api/tours/geometry?id=${encodeURIComponent(tour.id)}`
      );
      if (r.ok) {
        const j = await r.json();
        if (j?.geometry?.coordinates?.length >= 2) {
          setActiveRoute(
            activeRouteFromSuggestion(suggestion, j.geometry, j.steps)
          );
          router.push("/ride");
          return;
        }
      }
    } catch {
      /* pin-only fallback */
    }
    setActiveRoute(activeRouteFromSuggestion(suggestion));
    router.push("/ride");
  }, [setActiveRoute, suggestion, router, tour.id]);

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={startInApp}
          className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent px-4 py-3 text-sm font-semibold text-white hover:bg-accent-hover sm:flex-none"
        >
          <Play className="h-4 w-4 fill-current" />
          In App starten
        </button>
        <button
          type="button"
          onClick={toggleSave}
          className="inline-flex items-center justify-center gap-2 rounded-xl border border-border px-4 py-3 text-sm font-medium"
        >
          {saved ? (
            <BookmarkCheck className="h-4 w-4 text-accent" />
          ) : (
            <Bookmark className="h-4 w-4" />
          )}
          {saved ? "Gespeichert" : "Speichern"}
        </button>
      </div>
      <div className="flex flex-wrap gap-2">
        <a
          href={`/api/tours/${encodeURIComponent(tour.id)}/gpx`}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
          download
        >
          GPX
        </a>
        <Link
          href={`/planner?tour=${encodeURIComponent(tour.id)}`}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <Route className="h-3.5 w-3.5 text-accent" />
          Im Planner öffnen
        </Link>
        <Link
          href={`/discover?route=${encodeURIComponent(tour.id)}`}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <Map className="h-3.5 w-3.5 text-accent" />
          In Explore
        </Link>
        <Link
          href="/download"
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <Navigation className="h-3.5 w-3.5 text-accent" />
          App laden
        </Link>
      </div>
      {flash && (
        <p className="text-xs text-accent" role="status">
          {flash}
        </p>
      )}
    </div>
  );
}
