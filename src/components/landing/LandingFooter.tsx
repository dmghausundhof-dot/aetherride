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
              Die App, die dein Bike kennt.
            </p>
          </div>

          <AppDownloadButtons size="md" />
        </div>

        <div className="mt-10 flex flex-wrap justify-center gap-6 text-sm text-text-secondary">
          <Link href="/legal/impressum" className="hover:text-foreground">
            Impressum
          </Link>
          <Link href="/legal/datenschutz" className="hover:text-foreground">
            Datenschutz
          </Link>
          <Link href="/legal/widerruf" className="hover:text-foreground">
            Widerruf
          </Link>
          <Link href="/privacy" className="hover:text-foreground">
            Privacy
          </Link>
        </div>

        <p className="mt-8 text-center text-xs text-text-secondary">
          © {new Date().getFullYear()} AetherRide. Spec-konform · Offline-First · DSGVO.
        </p>
      </div>
    </footer>
  );
}
