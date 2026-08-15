"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, type MouseEvent } from "react";
import {
  appDiscoverHref,
  isExternalAppDiscoverHref,
} from "@/lib/web/appLinks";
import { useHofTitle } from "@/hooks/useHofTitle";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { TrustSheet } from "./TrustSheet";

const PILLS = ["Der Hof", "Karte", "Platz", "Werkstatt", "Laden"] as const;

export function LandingHero() {
  const [trustOpen, setTrustOpen] = useState(false);
  const title = useHofTitle();

  function onAppDiscoverClick(e: MouseEvent<HTMLAnchorElement>) {
    const target = appDiscoverHref(navigator.userAgent);
    if (isExternalAppDiscoverHref(target)) {
      e.preventDefault();
      window.location.assign(target);
    }
  }

  return (
    <section className="relative isolate min-h-[100svh] overflow-hidden">
      <div className="absolute inset-0">
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
          <p className="mb-8 text-[0.95rem] font-medium tracking-[0.06em] text-foreground/85 sm:mb-11 sm:text-base">
            Flow<span className="text-accent">Line</span>
          </p>

          <h1 className="text-[2.35rem] font-semibold leading-[1.08] tracking-[-0.03em] text-foreground [text-shadow:0_1px_24px_rgba(18,18,21,0.35)] sm:text-5xl md:text-[3.4rem] md:leading-[1.04]">
            {title}.
            <br />
            Das Rad wohnt hier.
          </h1>

          <p className="mt-7 max-w-sm text-[0.95rem] leading-[1.55] text-text-secondary sm:mt-8 sm:max-w-md sm:text-lg sm:leading-relaxed">
            Drei Sekunden: der Bewohner, der Himmel, eine Stunde vor dem Tor.
            Ein Knopf — {HOF_COPY.rideOut}.
          </p>

          <div className="mt-10 flex flex-col items-stretch gap-3 sm:mt-12 sm:flex-row sm:items-center sm:gap-3.5">
            <Link
              href="/home"
              className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-7 text-[0.95rem] font-semibold text-white transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              Zum Hof
            </Link>
            <Link
              href="/download"
              onClick={onAppDiscoverClick}
              className="inline-flex h-12 items-center justify-center rounded-lg border border-foreground/25 bg-transparent px-7 text-[0.95rem] font-medium text-foreground/95 transition hover:border-foreground/45 hover:bg-foreground/[0.04] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-chrome sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              App laden
            </Link>
          </div>

          <button
            type="button"
            onClick={() => setTrustOpen(true)}
            className="mt-4 text-left text-sm text-text-secondary underline-offset-4 hover:text-foreground hover:underline"
          >
            So bleibt’s fair
          </button>

          <ul
            className="mt-10 flex flex-wrap gap-2 sm:mt-12"
            aria-label="Fünf Türen"
          >
            {PILLS.map((label) => (
              <li
                key={label}
                className="rounded-md border border-foreground/14 bg-background/20 px-2.5 py-1 text-[0.72rem] font-medium tracking-[0.015em] text-foreground/80 sm:text-xs"
              >
                {label}
              </li>
            ))}
          </ul>

          <p className="mt-5 text-[0.7rem] leading-relaxed tracking-[0.01em] text-text-secondary/80 sm:mt-6 sm:text-[0.8rem]">
            Kein Feed, keine KPI-Leiste, kein zweiter Shop im Browser.
          </p>
        </div>
      </div>

      <TrustSheet open={trustOpen} onClose={() => setTrustOpen(false)} />
    </section>
  );
}
