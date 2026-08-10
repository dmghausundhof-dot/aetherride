"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/garage", label: "Garage" },
  { href: "/discover", label: "Discover" },
  { href: "/shop", label: "Shop" },
  { href: "/profile", label: "Profil" },
];

export function AppHeader() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4">
        <Link href="/garage" className="text-lg font-bold text-foreground">
          Aether<span className="text-accent">Ride</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "rounded-lg px-4 py-2 text-sm font-medium transition",
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

        <div className="flex items-center gap-3">
          <div className="hidden sm:block">
            <AppDownloadButtons size="md" />
          </div>
        </div>
      </div>
    </header>
  );
}
