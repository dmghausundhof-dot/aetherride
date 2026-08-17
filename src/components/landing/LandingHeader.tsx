"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import {
  MARKETING_NAV,
  isMarketingNavActive,
} from "@/lib/nav/marketingNav";
import { webChrome } from "@/lib/i18n/webChrome";
import { useChromeLang } from "@/hooks/useChromeLang";
import { usePathname } from "next/navigation";

export function LandingHeader() {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  const copy = webChrome(useChromeLang());

  return (
    <header className="hof-safe-header sticky top-0 z-50 border-b border-border/40 bg-background/55 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-5 sm:h-16 sm:px-8 lg:px-10">
        <Link
          href="/"
          className="text-[0.95rem] font-semibold tracking-tight text-foreground sm:text-base"
        >
          <FlowLineWordmark
            className="text-[0.95rem] font-semibold tracking-tight text-foreground sm:text-base"
            markClassName="h-5 w-auto"
          />
        </Link>

        <nav
          className="hidden items-center gap-6 lg:flex"
          aria-label={copy.websiteAria}
        >
          {MARKETING_NAV.map((item) => {
            const active = isMarketingNavActive(pathname, item.href);
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
                {copy.marketingNav[item.href]}
              </Link>
            );
          })}
        </nav>

        <div className="flex items-center gap-3">
          <Link
            href="/anmelden"
            className="hidden text-sm text-text-secondary hover:text-chrome sm:block"
          >
            {copy.arriveAtHof}
          </Link>
          <Link
            href="/home"
            className="hidden h-9 items-center rounded-xl bg-chrome px-3.5 text-sm font-semibold text-on-accent hover:bg-chrome/90 sm:inline-flex"
          >
            {copy.toHof}
          </Link>
          <button
            type="button"
            className="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-border lg:hidden"
            aria-label={open ? copy.menuClose : copy.menuOpen}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {open && (
        <div className="border-t border-border px-4 py-3 lg:hidden">
          <nav className="flex flex-col gap-1" aria-label={copy.websiteAria}>
            {MARKETING_NAV.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="rounded-lg px-3 py-3 text-sm text-text-secondary"
              >
                {copy.marketingNav[item.href]}
              </Link>
            ))}
            <Link
              href="/anmelden"
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm text-text-secondary"
            >
              {copy.arriveAtHof}
            </Link>
            <Link
              href="/home"
              onClick={() => setOpen(false)}
              className="mt-1 flex h-11 items-center justify-center rounded-xl bg-chrome px-3 text-sm font-semibold text-on-accent"
            >
              {copy.toHof}
            </Link>
          </nav>
        </div>
      )}
    </header>
  );
}
