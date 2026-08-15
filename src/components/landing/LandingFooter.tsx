import Link from "next/link";
import { AppDownloadButtons } from "./AppDownloadButtons";
import { HOF_NAV } from "@/lib/nav/hofNav";
import { MARKETING_NAV } from "@/lib/nav/marketingNav";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import { FLOWLINE_TAGLINE_DOTS } from "@/lib/content/brand";
import { legalContactEmail } from "@/lib/legal/siteLegal";

export function LandingFooter() {
  const email = legalContactEmail();

  return (
    <footer className="border-t border-border bg-surface py-12 pb-[calc(3rem+var(--safe-bottom))]">
      <div className="mx-auto max-w-6xl px-4">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          <div>
            <FlowLineWordmark />
            <p className="mt-1 text-[11px] font-medium uppercase tracking-[0.14em] text-text-secondary">
              {FLOWLINE_TAGLINE_DOTS}
            </p>
            <p className="mt-2 text-sm text-text-secondary">
              Das Rad wohnt hier. Du kommst zurück.
            </p>
          </div>

          <AppDownloadButtons size="md" />
        </div>

        <div className="mt-10 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Website
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              {MARKETING_NAV.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-text-secondary hover:text-foreground"
                >
                  {item.label}
                </Link>
              ))}
              <Link
                href="/anmelden"
                className="text-text-secondary hover:text-foreground"
              >
                Anmelden
              </Link>
            </div>
          </div>
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
              <Link
                href="/planner"
                className="text-text-secondary hover:text-foreground"
              >
                Planen
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Mehr
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link
                href="/ueber"
                className="text-text-secondary hover:text-foreground"
              >
                Über FlowLine
              </Link>
              <Link
                href="/faq"
                className="text-text-secondary hover:text-foreground"
              >
                FAQ
              </Link>
              <Link
                href="/share"
                className="text-text-secondary hover:text-foreground"
              >
                Teilen
              </Link>
              <Link
                href="/produkt"
                className="text-text-secondary hover:text-foreground"
              >
                Screens & Abläufe
              </Link>
              <Link
                href="/guides/web-vs-app"
                className="text-text-secondary hover:text-foreground"
              >
                Web vs. App
              </Link>
              <Link
                href="/activities"
                className="text-text-secondary hover:text-foreground"
              >
                Was reinkam
              </Link>
              <Link
                href="/privacy"
                className="text-text-secondary hover:text-foreground"
              >
                Daten & Privatsphäre
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              Rechtliches
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link
                href="/legal/impressum"
                className="text-text-secondary hover:text-foreground"
              >
                Impressum
              </Link>
              <Link
                href="/legal/datenschutz"
                className="text-text-secondary hover:text-foreground"
              >
                Datenschutz
              </Link>
              <Link
                href="/legal/agb"
                className="text-text-secondary hover:text-foreground"
              >
                AGB
              </Link>
              <Link
                href="/legal/widerruf"
                className="text-text-secondary hover:text-foreground"
              >
                Widerruf
              </Link>
              <Link
                href="/kontakt"
                className="text-text-secondary hover:text-foreground"
              >
                Kontakt
              </Link>
              <a
                href={`mailto:${email}`}
                className="text-text-secondary hover:text-foreground"
              >
                {email}
              </a>
            </div>
          </div>
        </div>

        <p className="mt-10 text-center text-xs text-text-secondary">
          © {new Date().getFullYear()} FlowLine. Offline-First · DSGVO · Web
          ist der Hof, die App fährt.
        </p>
      </div>
    </footer>
  );
}
