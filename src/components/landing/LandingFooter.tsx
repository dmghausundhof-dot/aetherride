import Link from "next/link";
import { AppDownloadButtons } from "./AppDownloadButtons";

export function LandingFooter() {
  return (
    <footer className="border-t border-border bg-surface py-12">
      <div className="mx-auto max-w-6xl px-4">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          <div>
            <div className="text-lg font-bold">
              Aether<span className="text-accent">Ride</span>
            </div>
            <p className="mt-1 text-sm text-text-secondary">
              Touren planen. Bike verstehen. Für alle Fahrradfahrer.
            </p>
          </div>

          <AppDownloadButtons size="md" />
        </div>

        <div className="mt-10 grid gap-8 sm:grid-cols-3">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Produkt
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link href="/discover" className="text-text-secondary hover:text-foreground">
                Explore
              </Link>
              <Link href="/planner" className="text-text-secondary hover:text-foreground">
                Planner
              </Link>
              <Link href="/library" className="text-text-secondary hover:text-foreground">
                Bibliothek
              </Link>
              <Link href="/regions" className="text-text-secondary hover:text-foreground">
                Regionen
              </Link>
              <Link href="/garage" className="text-text-secondary hover:text-foreground">
                Garage
              </Link>
              <Link href="/activities" className="text-text-secondary hover:text-foreground">
                Aktivitäten
              </Link>
              <Link href="/community" className="text-text-secondary hover:text-foreground">
                Community
              </Link>
              <Link href="/guides" className="text-text-secondary hover:text-foreground">
                Guides
              </Link>
              <Link href="/pricing" className="text-text-secondary hover:text-foreground">
                Preise
              </Link>
              <Link href="/download" className="text-text-secondary hover:text-foreground">
                App laden
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Disziplinen
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm text-text-secondary">
              <Link href="/discover?sport=road" className="hover:text-foreground">
                Rennrad
              </Link>
              <Link href="/discover?sport=gravel" className="hover:text-foreground">
                Gravel
              </Link>
              <Link href="/discover?sport=mtb" className="hover:text-foreground">
                Mountainbike
              </Link>
              <Link href="/discover?sport=urban" className="hover:text-foreground">
                City
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Rechtliches
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link href="/legal/impressum" className="text-text-secondary hover:text-foreground">
                Impressum
              </Link>
              <Link href="/legal/datenschutz" className="text-text-secondary hover:text-foreground">
                Datenschutz
              </Link>
              <Link href="/legal/widerruf" className="text-text-secondary hover:text-foreground">
                Widerruf
              </Link>
              <Link href="/privacy" className="text-text-secondary hover:text-foreground">
                Privacy
              </Link>
            </div>
          </div>
        </div>

        <p className="mt-10 text-center text-xs text-text-secondary">
          © {new Date().getFullYear()} AetherRide. Offline-First · DSGVO · Web
          plant, App fährt.
        </p>
      </div>
    </footer>
  );
}
