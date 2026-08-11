"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { AppDownloadButtons } from "./AppDownloadButtons";

const links = [
  { href: "/discover", label: "Touren" },
  { href: "/planner", label: "Planen" },
  { href: "/regions", label: "Regionen" },
  { href: "/community", label: "Community" },
  { href: "/guides", label: "Guides" },
  { href: "/pricing", label: "Preise" },
  { href: "/download", label: "App" },
];

export function LandingHeader() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="text-lg font-bold text-foreground">
          Aether<span className="text-accent">Ride</span>
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          {links.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="text-sm text-text-secondary hover:text-foreground"
            >
              {l.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <Link
            href="/profile"
            className="hidden text-sm text-text-secondary hover:text-foreground sm:block"
          >
            Anmelden
          </Link>
          <div className="hidden sm:block">
            <AppDownloadButtons size="md" />
          </div>
          <button
            type="button"
            className="inline-flex h-10 w-10 items-center justify-center rounded-lg border border-border md:hidden"
            aria-label={open ? "Menü schließen" : "Menü öffnen"}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {open && (
        <div className="border-t border-border px-4 py-3 md:hidden">
          <nav className="flex flex-col gap-1">
            {links.map((l) => (
              <Link
                key={l.href}
                href={l.href}
                onClick={() => setOpen(false)}
                className="rounded-lg px-3 py-3 text-sm text-text-secondary"
              >
                {l.label}
              </Link>
            ))}
            <Link
              href="/profile"
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm text-text-secondary"
            >
              Anmelden
            </Link>
          </nav>
          <div className="mt-3">
            <AppDownloadButtons size="md" />
          </div>
        </div>
      )}
    </header>
  );
}
