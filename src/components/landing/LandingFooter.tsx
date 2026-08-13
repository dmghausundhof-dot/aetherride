import Link from "next/link";
import { AppDownloadButtons } from "./AppDownloadButtons";
import { HOF_NAV } from "@/lib/nav/hofNav";

export function LandingFooter() {
  return (
    <footer className="border-t border-border bg-surface py-12 pb-[calc(3rem+var(--safe-bottom))]">
      <div className="mx-auto max-w-6xl px-4">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          <div>
            <div className="text-lg font-bold">
              Aether<span className="text-chrome">Ride</span>
            </div>
            <p className="mt-1 text-sm text-text-secondary">
              Das Rad wohnt hier. Du kommst zurück.
            </p>
          </div>

          <AppDownloadButtons size="md" />
        </div>

        <div className="mt-10 grid gap-8 sm:grid-cols-3">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Der Hof
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              {HOF_NAV.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-text-secondary hover:text-foreground"
                >
                  {item.id === "hof" ? "Der Hof" : item.label}
                </Link>
              ))}
              <Link href="/download" className="text-text-secondary hover:text-foreground">
                App laden
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Mehr
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link href="/regions" className="text-text-secondary hover:text-foreground">
                Regionen
              </Link>
              <Link href="/guides" className="text-text-secondary hover:text-foreground">
                Guides
              </Link>
              <Link href="/pricing" className="text-text-secondary hover:text-foreground">
                Preise
              </Link>
              <Link href="/download" className="text-text-secondary hover:text-foreground">
                App
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
                Daten & Privatsphäre
              </Link>
            </div>
          </div>
        </div>

        <p className="mt-10 text-center text-xs text-text-secondary">
          © {new Date().getFullYear()} AetherRide. Offline-First · DSGVO · Web
          ist der Hof, die App fährt.
        </p>
      </div>
    </footer>
  );
}
