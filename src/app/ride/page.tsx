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
  hasStoreLinks,
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
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="border-b border-border px-4 py-4">
        <div className="mx-auto flex max-w-lg items-center justify-between">
          <Link
            href="/discover"
            className="inline-flex items-center gap-1.5 text-sm text-text-secondary hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            Zurück zu Explore
          </Link>
          <Link href="/" className="text-sm font-bold">
            Aether<span className="text-accent">Ride</span>
          </Link>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col px-4 py-10">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-accent/15 text-accent">
          <Smartphone className="h-7 w-7" />
        </div>

        <h1 className="mt-6 text-2xl font-bold tracking-tight sm:text-3xl">
          Navigation läuft in der App
        </h1>
        <p className="mt-3 text-text-secondary">
          Live-GPS, Offline-Karten, Sensoren und Hintergrund-Aufzeichnung sind
          nur in der nativen Android- und iOS-App verfügbar — nicht im Browser.
        </p>

        {activeRoute ? (
          <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/30 text-accent">
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
              Die Route ist in deinem Browser-Konto / Store gemerkt. Nach dem
              Login in der App erscheint sie unter Discover bzw. als aktive
              Tour (Sync).
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
            Noch keine Tour ausgewählt. Plane eine Route in{" "}
            <Link href="/discover" className="font-medium text-accent">
              Explore
            </Link>
            , speichere sie und starte dann in der App.
          </div>
        )}

        <div className="mt-10">
          <p className="mb-4 text-sm font-medium">App herunterladen</p>
          <AppDownloadButtons size="lg" />
        </div>

        <div className="mt-6 flex flex-col gap-2">
          <a
            href={deepLink}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white transition hover:bg-accent-hover"
          >
            <ExternalLink className="h-4 w-4" />
            App öffnen (Schema)
          </a>
          <a
            href={universalLink}
            className="inline-flex items-center justify-center gap-2 rounded-xl border border-border py-3 text-sm font-medium text-foreground transition hover:bg-surface"
          >
            Universal Link /open/ride
          </a>
        </div>
        <p className="mt-2 text-center text-[11px] text-text-secondary">
          Schema <code className="text-[10px]">aetherride://</code>
          {hasStoreLinks()
            ? " · Store-Links gesetzt"
            : " · Store-URLs in Vercel setzen (NEXT_PUBLIC_*_STORE_URL)"}
          . App Links: /.well-known/assetlinks.json
        </p>

        <div className="mt-12 grid gap-3">
          <Link
            href="/discover"
            className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-3 text-sm hover:border-accent/40"
          >
            <MapIcon className="h-5 w-5 text-accent" />
            <span>
              <span className="font-semibold">Weiter planen</span>
              <span className="block text-xs text-text-secondary">
                Explore · Desktop-Cockpit
              </span>
            </span>
          </Link>
          <Link
            href="/download"
            className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-3 text-sm hover:border-accent/40"
          >
            <Smartphone className="h-5 w-5 text-accent" />
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
