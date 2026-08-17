"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, type MouseEvent } from "react";
import {
  appDiscoverHref,
  isExternalAppDiscoverHref,
} from "@/lib/web/appLinks";
import { useHofTitle } from "@/hooks/useHofTitle";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { webChrome } from "@/lib/i18n/webChrome";
import { TrustSheet } from "./TrustSheet";

const HERO_DOORS = [
  { id: "hof" as const, href: "/home" },
  { id: "karte" as const, href: "/discover" },
  { id: "platz" as const, href: "/library" },
  { id: "werkstatt" as const, href: "/garage" },
];

export function LandingHero() {
  const [trustOpen, setTrustOpen] = useState(false);
  const title = useHofTitle();
  const lang = useChromeLang();
  const chrome = webChrome(lang);
  const hof = useHofCopy();
  const home = useHomepageCopy();

  function onAppDiscoverClick(e: MouseEvent<HTMLAnchorElement>) {
    const target = appDiscoverHref(navigator.userAgent);
    if (isExternalAppDiscoverHref(target)) {
      e.preventDefault();
      window.location.assign(target);
    }
  }

  return (
    <section className="relative isolate min-h-[100svh] overflow-hidden">
      <div className="absolute inset-0 bg-background">
        <Image
          src="/landing/hero-everyday.jpg"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover object-[78%_48%] sm:object-[82%_46%] animate-hero-ken"
        />
        <div
          className="absolute inset-0 bg-[linear-gradient(112deg,rgba(18,18,21,0.78)_0%,rgba(18,18,21,0.42)_34%,rgba(18,18,21,0.14)_58%,rgba(18,18,21,0.02)_78%,transparent_100%)]"
          aria-hidden
        />
        <div
          className="absolute inset-x-0 bottom-0 h-[22%] bg-gradient-to-t from-background via-background/35 to-transparent"
          aria-hidden
        />
      </div>

      <div className="relative z-10 mx-auto flex min-h-[100svh] max-w-6xl flex-col justify-end px-5 pb-[calc(5rem+var(--safe-bottom))] pt-[calc(8rem+var(--safe-top))] sm:justify-center sm:px-8 sm:pb-28 sm:pt-28 lg:px-10">
        <div className="max-w-[22rem] animate-hero-rise sm:max-w-md lg:max-w-[32rem]">
          <p className="text-[0.95rem] font-medium tracking-[0.06em] text-foreground/85 sm:text-base">
            Flow<span className="text-accent">Line</span>
          </p>
          <p className="mb-8 mt-2 text-[0.7rem] font-medium uppercase tracking-[0.16em] text-foreground/70 sm:mb-11">
            Outdoor · Cycling · Flow
          </p>

          <h1 className="text-[2.35rem] font-semibold leading-[1.08] tracking-[-0.03em] text-foreground [text-shadow:0_1px_24px_rgba(18,18,21,0.35)] sm:text-5xl md:text-[3.4rem] md:leading-[1.04]">
            {title}.
            <br />
            {home.ui.heroTagline}
          </h1>

          <p className="mt-7 max-w-sm text-[0.95rem] leading-[1.55] text-text-secondary sm:mt-8 sm:max-w-md sm:text-lg sm:leading-relaxed">
            {home.ui.heroLead(hof.rideOut)}
          </p>

          <div className="mt-10 flex flex-col items-stretch gap-3 sm:mt-12 sm:flex-row sm:items-center sm:gap-3.5">
            <Link
              href="/home"
              className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-7 text-[0.95rem] font-semibold text-on-accent transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              {chrome.toHof}
            </Link>
            <Link
              href="/download"
              onClick={onAppDiscoverClick}
              className="inline-flex h-12 items-center justify-center rounded-xl border border-foreground/25 bg-transparent px-7 text-[0.95rem] font-medium text-foreground/95 transition hover:border-foreground/45 hover:bg-foreground/[0.04] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-chrome sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              {chrome.loadApp}
            </Link>
          </div>

          <button
            type="button"
            onClick={() => setTrustOpen(true)}
            className="mt-4 text-left text-sm text-text-secondary underline-offset-4 hover:text-foreground hover:underline"
          >
            {home.ui.heroFair}
          </button>

          <ul
            className="mt-10 flex flex-wrap gap-2 sm:mt-12"
            aria-label={chrome.fourDoors}
          >
            {HERO_DOORS.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="inline-block rounded-md border border-foreground/14 bg-background/20 px-2.5 py-1 text-[0.72rem] font-medium tracking-[0.015em] text-foreground/80 transition hover:border-foreground/35 hover:text-foreground sm:text-xs"
                >
                  {item.id === "hof" ? title : chrome.hofNav[item.id]}
                </Link>
              </li>
            ))}
          </ul>

          <p className="mt-5 text-[0.7rem] leading-relaxed tracking-[0.01em] text-text-secondary/80 sm:mt-6 sm:text-[0.8rem]">
            {home.ui.heroFoot}
          </p>
        </div>
      </div>

      <TrustSheet open={trustOpen} onClose={() => setTrustOpen(false)} />
    </section>
  );
}
