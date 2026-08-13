"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { HOF_NAV, isHofNavActive } from "@/lib/nav/hofNav";
import { useHofTitle } from "@/hooks/useHofTitle";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { usePathname } from "next/navigation";

export function LandingHeader() {
  const [open, setOpen] = useState(false);
  const hofTitle = useHofTitle();
  const pathname = usePathname();

  return (
    <header className="hof-safe-header sticky top-0 z-50 border-b border-border/40 bg-background/55 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-5 sm:h-16 sm:px-8 lg:px-10">
        <Link
          href="/"
          className="text-[0.95rem] font-semibold tracking-tight text-foreground sm:text-base"
        >
          Aether<span className="text-chrome">Ride</span>
        </Link>

        <nav className="hidden items-center gap-6 md:flex" aria-label="Der Hof">
          {HOF_NAV.map((item) => {
            const label = item.id === "hof" ? hofTitle : item.label;
            const active = isHofNavActive(pathname, item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={
                  active
                    ? "text-sm font-semibold text-chrome"
                    : "text-sm text-text-secondary hover:text-foreground"
                }
              >
                {label}
              </Link>
            );
          })}
        </nav>

        <div className="flex items-center gap-3">
          <Link
            href="/profile"
            className="hidden text-sm text-text-secondary hover:text-chrome sm:block"
          >
            {HOF_COPY.profile}
          </Link>
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
            {HOF_NAV.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="rounded-lg px-3 py-3 text-sm text-text-secondary"
              >
                {item.id === "hof" ? hofTitle : item.label}
              </Link>
            ))}
            <Link
              href="/profile"
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm text-text-secondary"
            >
              {HOF_COPY.profile}
            </Link>
            <Link
              href="/download"
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm text-chrome"
            >
              App laden
            </Link>
          </nav>
        </div>
      )}
    </header>
  );
}
