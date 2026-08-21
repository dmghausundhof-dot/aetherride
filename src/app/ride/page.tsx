"use client";

/**
 * Phase A: Live-Ride läuft nur in der nativen App.
 * Diese Route ist der Web-Bridge: geplante Tour zeigen → App laden.
 */
import Link from "next/link";
import { useMemo } from "react";
import { ArrowLeft, ExternalLink } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useAppStore } from "@/store/useAppStore";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { useHofCopy } from "@/hooks/useHofCopy";
import {
  appDeepLink,
  httpsAppLink,
  rideOpenPath,
} from "@/lib/web/appLinks";
import { formatDistanceElevation } from "@/lib/discover/elevationGuard";
import { webRideBridgeNeedsTrack } from "@/lib/routing/activeRoute";
import { mappeGoRideDiscoverHref } from "@/lib/tours/mappeList";
import type { SavedRoute } from "@/types/route";

export default function RideAppBridgePage() {
  const copy = useHofCopy();
  const activeRoute = useAppStore((s) => s.activeRoute);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const clearActiveRoute = useAppStore((s) => s.clearActiveRoute);

  const hasTrack = webRideBridgeNeedsTrack(
    activeRoute?.geometry?.coordinates?.length
  );
  const planHref = useMemo(() => {
    if (!activeRoute || hasTrack) return null;
    const saved = savedRoutes.find((r) => r.id === activeRoute.id);
    if (saved) return mappeGoRideDiscoverHref(saved);
    const stub: SavedRoute = {
      id: activeRoute.id,
      name: activeRoute.name,
      distanceKm: activeRoute.distanceKm,
      elevationM: activeRoute.elevationM,
      durationMin: activeRoute.durationMin,
      savedAt: activeRoute.setAt,
      source: "suggestion",
      geometry: null,
    };
    return mappeGoRideDiscoverHref(stub);
  }, [activeRoute, hasTrack, savedRoutes]);

  const deepLink = useMemo(() => {
    return appDeepLink(rideOpenPath(activeRoute?.id));
  }, [activeRoute]);

  const universalLink = useMemo(() => {
    return httpsAppLink(rideOpenPath(activeRoute?.id));
  }, [activeRoute]);

  return (
    <div className="hof-safe-page flex min-h-dvh flex-col bg-background">
      <header className="border-b border-border px-4 py-4">
        <div className="mx-auto flex max-w-lg items-center justify-between">
          <Link
            href="/discover"
            className="inline-flex items-center gap-1.5 text-sm text-text-secondary hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            {copy.rideBackToMap}
          </Link>
          <Link href="/" className="text-sm font-bold">
            Flow<span className="text-chrome">Line</span>
          </Link>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col px-4 py-10">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-chrome/15 text-chrome">
          <ChromeGlyph name="phone" size={28} current />
        </div>

        <h1 className="mt-6 text-2xl font-bold tracking-tight sm:text-3xl">
          {copy.rideBridgeTitle}
        </h1>
        <p className="mt-3 text-text-secondary">
          {copy.rideBridgeHint}
        </p>

        {activeRoute && hasTrack ? (
          <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/30 text-chrome">
                <ChromeGlyph name="nav" size={20} current />
              </div>
              <div className="min-w-0">
                <p className="text-xs font-medium tracking-wide text-text-secondary">
                  {copy.ridePlannedKicker}
                </p>
                <h2 className="truncate text-lg font-semibold">
                  {activeRoute.name}
                </h2>
                <p className="mt-1 text-sm tabular-nums text-text-secondary">
                  {[
                    formatDistanceElevation(
                      activeRoute.distanceKm,
                      activeRoute.elevationM,
                    ),
                    `${activeRoute.durationMin} min`,
                    activeRoute.mtbScale && activeRoute.mtbScale !== "—"
                      ? activeRoute.mtbScale
                      : null,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
                {activeRoute.surface && (
                  <p className="mt-1 text-xs text-text-secondary">
                    Belag: {activeRoute.surface}
                  </p>
                )}
              </div>
            </div>
      <p className="mt-4 text-xs text-text-secondary">
              Die Route ist in deinem Browser gemerkt. Nach dem Login in der App
              erscheint sie unter Karte bzw. als aktive Tour (Sync).
            </p>
            <button
              type="button"
              onClick={() => clearActiveRoute()}
              className="mt-3 text-xs text-text-secondary underline hover:text-foreground"
            >
              Tour-Auswahl verwerfen
            </button>
          </div>
        ) : activeRoute && planHref ? (
          <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
            <p className="text-sm font-semibold">{activeRoute.name}</p>
            <p className="mt-2 text-sm text-text-secondary">
              Noch kein Track — zuerst Ziel setzen im Planer.
            </p>
            <Link
              href={planHref}
              className="mt-4 inline-flex rounded-xl bg-accent px-4 py-2.5 text-sm font-semibold text-on-accent"
            >
              Im Planer öffnen
            </Link>
            <button
              type="button"
              onClick={() => clearActiveRoute()}
              className="mt-3 block text-xs text-text-secondary underline hover:text-foreground"
            >
              Tour-Auswahl verwerfen
            </button>
          </div>
        ) : (
          <div className="mt-8 rounded-2xl border border-dashed border-border bg-surface/50 p-5 text-sm text-text-secondary">
            Noch keine Tour ausgewählt. Plane eine Route unter{" "}
            <Link href="/discover" className="font-medium text-chrome">
              Karte
            </Link>
            , speichere sie und starte dann in der App.
          </div>
        )}

        <div className="mt-10">
          <p className="mb-4 text-sm font-medium">App herunterladen</p>
          <AppDownloadButtons size="lg" />
        </div>

        {hasTrack ? (
        <details className="mt-6 rounded-xl border border-border bg-surface px-4 py-3 text-sm">
          <summary className="cursor-pointer font-medium text-text-secondary">
            App direkt öffnen
          </summary>
          <div className="mt-3 flex flex-col gap-2">
            <a
              href={deepLink}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-chrome py-3 text-sm font-semibold text-on-accent transition hover:bg-chrome/90"
            >
              <ExternalLink className="h-4 w-4" />
              In der App öffnen
            </a>
            <a
              href={universalLink}
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-border py-3 text-sm font-medium text-foreground transition hover:bg-surface"
            >
              Web-Link zur App
            </a>
          </div>
        </details>
        ) : null}

        <div className="mt-12 grid gap-3">
          <Link
            href="/discover"
            className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-3 text-sm hover:border-chrome/40"
          >
            <ChromeGlyph name="karte" size={20} current className="text-chrome" />
            <span>
              <span className="font-semibold">Weiter auf der Karte</span>
              <span className="block text-xs text-text-secondary">
                OSM · Rundkurse · Planen
              </span>
            </span>
          </Link>
          <Link
            href="/download"
            className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-3 text-sm hover:border-chrome/40"
          >
            <ChromeGlyph name="phone" size={20} current className="text-chrome" />
            <span>
              <span className="font-semibold">Warum die App?</span>
              <span className="block text-xs text-text-secondary">
                Navigation, Offline, Sensoren
              </span>
            </span>
          </Link>
        </div>
      </main>
    </div>
  );
}
