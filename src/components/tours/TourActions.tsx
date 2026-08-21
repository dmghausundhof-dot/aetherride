"use client";

import { useCallback, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useAppStore } from "@/store/useAppStore";
import type { PublicTour } from "@/lib/catalog/publicTours";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import {
  activeRouteForWebRideBridge,
  savedRouteForWebRideHandoff,
  webRideBridgeNeedsTrack,
} from "@/lib/routing/activeRoute";
import { lineWithApiElevation } from "@/lib/routing/elevationAttach";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { webChrome } from "@/lib/i18n/webChrome";

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
  const lang = useChromeLang();
  const copy = catalogCopy(lang).tour;
  const chrome = webChrome(lang);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const isRouteSaved = useAppStore((s) => s.isRouteSaved);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const [flash, setFlash] = useState<string | null>(null);

  const saved = isRouteSaved(tour.id);
  const suggestion = toSuggestion(tour);

  const toggleSave = useCallback(async () => {
    if (isRouteSaved(tour.id)) {
      unsaveRoute(tour.id);
      setFlash(copy.flashRemoved);
      setTimeout(() => setFlash(null), 2000);
      return;
    }
    let coords: number[][] | null = null;
    try {
      const r = await fetch(
        `/api/tours/geometry?id=${encodeURIComponent(tour.id)}`,
      );
      if (r.ok) {
        const j = (await r.json()) as { geometry?: GeoJSON.LineString | null };
        const raw = j?.geometry?.coordinates;
        if (raw && raw.length >= 2) coords = raw;
      }
    } catch {
      /* pin-only */
    }
    if (coords && coords.length >= 2) {
      const withEle = await lineWithApiElevation(coords);
      saveRoute({
        id: suggestion.id,
        name: suggestion.name,
        distanceKm: suggestion.distanceKm,
        elevationM: suggestion.elevationM,
        durationMin: suggestion.durationMin,
        mtbScale: suggestion.mtbScale,
        surface: suggestion.surface,
        reasons: suggestion.reasons,
        savedAt: new Date().toISOString(),
        source: "suggestion",
        geometry: { type: "LineString", coordinates: withEle },
      });
    } else {
      saveRoute(suggestion);
    }
    setFlash(copy.flashSaved);
    setTimeout(() => setFlash(null), 2000);
  }, [tour.id, isRouteSaved, unsaveRoute, saveRoute, suggestion, copy]);

  const startInApp = useCallback(async () => {
    let geometry: GeoJSON.LineString | null = null;
    try {
      const r = await fetch(
        `/api/tours/geometry?id=${encodeURIComponent(tour.id)}`
      );
      if (r.ok) {
        const j = await r.json();
        if (webRideBridgeNeedsTrack(j?.geometry?.coordinates?.length)) {
          geometry = j.geometry;
        }
      }
    } catch {
      /* pin-only */
    }
    if (geometry) {
      const withEle = await lineWithApiElevation(geometry.coordinates);
      const entry = savedRouteForWebRideHandoff({
        id: suggestion.id,
        name: suggestion.name,
        distanceKm: suggestion.distanceKm,
        elevationM: suggestion.elevationM,
        durationMin: suggestion.durationMin,
        geometry: { type: "LineString", coordinates: withEle },
        source: "suggestion",
        mtbScale: suggestion.mtbScale,
        surface: suggestion.surface,
        loop: suggestion.loop,
        reasons: suggestion.reasons,
      });
      if (entry) {
        if (!isRouteSaved(entry.id)) saveRoute(entry);
        const active = activeRouteForWebRideBridge(entry);
        if (active) {
          setActiveRoute(active);
          router.push("/ride");
          return;
        }
      }
    }
    setFlash(copy.noTrackHint);
    setTimeout(() => setFlash(null), 3500);
  }, [
    copy.noTrackHint,
    isRouteSaved,
    router,
    saveRoute,
    setActiveRoute,
    suggestion,
    tour.id,
  ]);

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={startInApp}
          className="inline-flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent px-4 py-3 text-sm font-semibold text-on-accent hover:bg-accent-hover sm:flex-none"
        >
          <ChromeGlyph name="play" size={16} current />
          {copy.startInApp}
        </button>
        <button
          type="button"
          onClick={toggleSave}
          className="inline-flex items-center justify-center gap-2 rounded-xl border border-border px-4 py-3 text-sm font-medium"
        >
          {saved ? (
            <ChromeGlyph name="merken" size={16} current className="text-accent" />
          ) : (
            <ChromeGlyph name="merken" size={16} current className="text-text-secondary" />
          )}
          {saved ? copy.saved : copy.save}
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
          href={`/discover?panel=plan&tour=${encodeURIComponent(tour.id)}`}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <ChromeGlyph name="split" size={14} current className="text-accent" />
          {copy.openPlanner}
        </Link>
        <Link
          href={`/discover?route=${encodeURIComponent(tour.id)}`}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <ChromeGlyph name="karte" size={14} current className="text-accent" />
          {copy.inTours}
        </Link>
        <Link
          href="/download"
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-xs font-medium hover:border-accent/40"
        >
          <ChromeGlyph name="phone" size={14} current className="text-accent" />
          {chrome.loadApp}
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
