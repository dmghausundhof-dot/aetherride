"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMemo, useState } from "react";
import { Menu, X } from "lucide-react";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { getFleetMaintenanceDueCount } from "@/lib/maintenance/summary";
import { cn } from "@/lib/utils";
import { useAppStore } from "@/store/useAppStore";

/** Multi-Sport IA — Home + gleiche Sprache wie Flutter (Touren / Teile). */
const navItems = [
  { href: "/home", label: "Home", id: "home" as const },
  { href: "/discover", label: "Touren", id: "discover" as const },
  { href: "/planner", label: "Planen", id: "planner" as const },
  { href: "/library", label: "Bibliothek", id: "library" as const },
  { href: "/activities", label: "Fahrten", id: "activities" as const },
  { href: "/garage", label: "Garage", id: "garage" as const },
  { href: "/shop", label: "Teile", id: "shop" as const },
  { href: "/profile", label: "Profil", id: "profile" as const },
];

export function AppHeader() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const bikes = useAppStore((s) => s.bikes);
  const intervals = useAppStore((s) => s.maintenanceIntervals);

  const dueTotal = useMemo(
    () => getFleetMaintenanceDueCount(bikes, intervals).dueTotal,
    [bikes, intervals]
  );

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-14 items-center justify-between gap-3 px-4 lg:h-16 lg:max-w-none lg:px-6">
        <Link
          href="/home"
          className="text-lg font-bold text-foreground"
          onClick={() => setOpen(false)}
        >
          Aether<span className="text-accent">Ride</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + "/");
            const showMaintBadge = item.id === "garage" && dueTotal > 0;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "relative rounded-lg px-3 py-2 text-sm font-medium transition lg:px-4",
                  isActive
                    ? "bg-surface-elevated text-foreground"
                    : "text-text-secondary hover:bg-surface hover:text-foreground"
                )}
              >
                {item.label}
                {showMaintBadge && (
                  <span
                    className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-0.5 text-[9px] font-bold text-white"
                    aria-label={`${dueTotal} Wartungen fällig`}
                    data-testid="garage-nav-badge"
                  >
                    {dueTotal > 9 ? "9+" : dueTotal}
                  </span>
                )}
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
              const showMaintBadge = item.id === "garage" && dueTotal > 0;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className={cn(
                    "flex items-center justify-between rounded-lg px-3 py-3 text-sm font-medium",
                    isActive
                      ? "bg-surface-elevated text-foreground"
                      : "text-text-secondary"
                  )}
                >
                  <span>{item.label}</span>
                  {showMaintBadge && (
                    <span
                      className="flex h-5 min-w-5 items-center justify-center rounded-full bg-error px-1 text-[10px] font-bold text-white"
                      data-testid="garage-nav-badge-mobile"
                    >
                      {dueTotal > 9 ? "9+" : dueTotal}
                    </span>
                  )}
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
