"use client";

import Link from "next/link";
import { AppDownloadButtons } from "./AppDownloadButtons";

export function LandingHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="text-lg font-bold text-foreground">
          Aether<span className="text-accent">Ride</span>
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          <Link href="/garage" className="text-sm text-text-secondary hover:text-foreground">
            Garage
          </Link>
          <Link href="/discover" className="text-sm text-text-secondary hover:text-foreground">
            Discover
          </Link>
          <Link href="/shop" className="text-sm text-text-secondary hover:text-foreground">
            Shop
          </Link>
        </nav>

        <div className="flex items-center gap-3">
          <Link
            href="/profile"
            className="hidden text-sm text-text-secondary hover:text-foreground sm:block"
          >
            Anmelden
          </Link>
          <AppDownloadButtons size="md" />
        </div>
      </div>
    </header>
  );
}
