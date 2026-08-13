"use client";

/**
 * Phase A: Live-Ride läuft nur in der nativen App.
 * Diese Route ist der Web-Bridge: geplante Tour zeigen → App laden.
 */
import Link from "next/link";
import { useMemo } from "react";
import {
  Smartphone,
  Map as MapIcon,
  Navigation,
  ArrowLeft,
  ExternalLink,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import {
  appDeepLink,
  httpsAppLink,
  rideOpenPath,
} from "@/lib/web/appLinks";

export default function RideAppBridgePage() {
  const activeRoute = useAppStore((s) => s.activeRoute);
  const clearActiveRoute = useAppStore((s) => s.clearActiveRoute);

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
            Zurück zur Karte
          </Link>
          <Link href="/" className="text-sm font-bold">
            Aether<span className="text-chrome">Ride</span>
          </Link>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col px-4 py-10">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-chrome/15 text-chrome">
          <Smartphone className="h-7 w-7" />
        </div>

        <h1 className="mt-6 text-2xl font-bold tracking-tight sm:text-3xl">
          Die Straße ist die App
        </h1>
        <p className="mt-3 text-text-secondary">
          Live-GPS, Offline-Karten, Sensoren und Hintergrund-Aufzeichnung sind
          nur in der nativen Android- und iOS-App verfügbar — nicht im Browser.
        </p>

        {activeRoute ? (
          <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/30 text-chrome">
                <Navigation className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <p className="text-xs font-medium uppercase tracking-wide text-text-secondary">
                  Geplante Tour
                </p>
                <h2 className="truncate text-lg font-semibold">
                  {activeRoute.name}
                </h2>
                <p className="mt-1 text-sm tabular-nums text-text-secondary">
                  {activeRoute.distanceKm} km · {activeRoute.elevationM} hm ·{" "}
                  {activeRoute.durationMin} min
                  {activeRoute.mtbScale && activeRoute.mtbScale !== "—"
                    ? ` · ${activeRoute.mtbScale}`
                    : ""}
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

        <details className="mt-6 rounded-xl border border-border bg-surface px-4 py-3 text-sm">
          <summary className="cursor-pointer font-medium text-text-secondary">
            App direkt öffnen
          </summary>
          <div className="mt-3 flex flex-col gap-2">
            <a
              href={deepLink}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-chrome py-3 text-sm font-semibold text-background transition hover:bg-chrome/90"
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

        <div className="mt-12 grid gap-3">
          <Link
            href="/discover"
            className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-3 text-sm hover:border-chrome/40"
          >
            <MapIcon className="h-5 w-5 text-chrome" />
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
            <Smartphone className="h-5 w-5 text-chrome" />
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
