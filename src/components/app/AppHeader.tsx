"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { cn } from "@/lib/utils";

/** Multi-Sport IA — gleiche Sprache wie die Flutter-App (Touren / Teile). */
const navItems = [
  { href: "/discover", label: "Touren" },
  { href: "/planner", label: "Planen" },
  { href: "/library", label: "Bibliothek" },
  { href: "/activities", label: "Fahrten" },
  { href: "/garage", label: "Garage" },
  { href: "/shop", label: "Teile" },
  { href: "/profile", label: "Profil" },
];

export function AppHeader() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-14 items-center justify-between gap-3 px-4 lg:h-16 lg:max-w-none lg:px-6">
        <Link
          href="/"
          className="text-lg font-bold text-foreground"
          onClick={() => setOpen(false)}
        >
          Aether<span className="text-accent">Ride</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "rounded-lg px-3 py-2 text-sm font-medium transition lg:px-4",
                  isActive
                    ? "bg-surface-elevated text-foreground"
                    : "text-text-secondary hover:bg-surface hover:text-foreground"
                )}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="flex items-center gap-2 sm:gap-3">
          <div className="hidden sm:block">
            <AppDownloadButtons size="md" />
          </div>
          <button
            type="button"
            className="inline-flex h-10 w-10 items-center justify-center rounded-lg border border-border text-foreground md:hidden"
            aria-label={open ? "Menü schließen" : "Menü öffnen"}
            aria-expanded={open}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {open && (
        <div className="border-t border-border bg-background px-4 py-3 md:hidden">
          <nav className="flex flex-col gap-1">
            {navItems.map((item) => {
              const isActive =
                pathname === item.href || pathname.startsWith(item.href + "/");
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className={cn(
                    "rounded-lg px-3 py-3 text-sm font-medium",
                    isActive
                      ? "bg-surface-elevated text-foreground"
                      : "text-text-secondary"
                  )}
                >
                  {item.label}
                </Link>
              );
            })}
            <Link
              href="/download"
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm font-medium text-accent"
            >
              App laden
            </Link>
          </nav>
          <div className="mt-3 sm:hidden">
            <AppDownloadButtons size="md" />
          </div>
        </div>
      )}
    </header>
  );
}
