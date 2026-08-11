"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, type MouseEvent } from "react";
import {
  appDiscoverHref,
  isExternalAppDiscoverHref,
} from "@/lib/web/appLinks";
import { TrustSheet } from "./TrustSheet";

const PILLS = ["Offline & Sync", "Akku im Griff", "Garage"] as const;

/**
 * L-HERO-01 / L-HERO-02 / L-HERO-03 / L-TRUST-01
 * Locked marketing copy — do not rewrite.
 * Visual bar: calmer / more confident than Komoot ads (EU-everyday).
 */
export function LandingHero() {
  const [trustOpen, setTrustOpen] = useState(false);

  function onAppDiscoverClick(e: MouseEvent<HTMLAnchorElement>) {
    const target = appDiscoverHref(navigator.userAgent);
    if (isExternalAppDiscoverHref(target)) {
      e.preventDefault();
      window.location.assign(target);
    }
  }

  return (
    <section className="relative isolate min-h-[100svh] overflow-hidden">
      {/* One strong full-bleed visual — real ride still */}
      <div className="absolute inset-0">
        <Image
          src="/landing/hero-trail.jpg"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover object-[68%_42%] sm:object-[72%_40%] animate-hero-ken"
        />
        {/* Soft readability only — photo stays the subject */}
        <div
          className="absolute inset-0 bg-[linear-gradient(105deg,rgba(10,18,16,0.88)_0%,rgba(10,18,16,0.62)_38%,rgba(10,18,16,0.22)_62%,rgba(10,18,16,0.08)_100%)]"
          aria-hidden
        />
        <div
          className="absolute inset-x-0 bottom-0 h-[28%] bg-gradient-to-t from-background via-background/50 to-transparent"
          aria-hidden
        />
      </div>

      <div className="relative z-10 mx-auto flex min-h-[100svh] max-w-6xl flex-col justify-end px-5 pb-20 pt-32 sm:justify-center sm:px-8 sm:pb-24 sm:pt-28 lg:px-10">
        <div className="max-w-[22rem] animate-hero-rise sm:max-w-md lg:max-w-lg">
          <p className="mb-8 text-[0.95rem] font-medium tracking-[0.04em] text-foreground/90 sm:mb-10 sm:text-base">
            Aether<span className="text-accent">Ride</span>
          </p>

          <h1 className="text-[2.35rem] font-semibold leading-[1.08] tracking-[-0.03em] text-foreground sm:text-5xl md:text-[3.35rem] md:leading-[1.05]">
            Touren &amp; Wartung —
            <br />
            ohne Abo-Falle.
          </h1>

          <p className="mt-7 max-w-sm text-[0.95rem] leading-[1.55] text-text-secondary sm:mt-8 sm:text-lg sm:leading-relaxed">
            Alltag und Abenteuer. Fair von Anfang an — ohne Lock-in.
          </p>

          <div className="mt-10 flex flex-col items-stretch gap-3 sm:mt-12 sm:flex-row sm:items-center sm:gap-3.5">
            <Link
              href="/download"
              onClick={onAppDiscoverClick}
              className="inline-flex h-12 items-center justify-center rounded-lg bg-accent px-7 text-[0.95rem] font-semibold text-white transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              App entdecken
            </Link>
            <button
              type="button"
              onClick={() => setTrustOpen(true)}
              className="inline-flex h-12 items-center justify-center rounded-lg border border-foreground/25 bg-transparent px-7 text-[0.95rem] font-medium text-foreground/95 transition hover:border-foreground/45 hover:bg-foreground/[0.04] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              So bleibt’s fair
            </button>
          </div>

          <ul
            className="mt-10 flex flex-wrap gap-2 sm:mt-12"
            aria-label="Kernvorteile"
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
            Sync, Navigation und Export bleiben frei.
          </p>
        </div>
      </div>

      <TrustSheet open={trustOpen} onClose={() => setTrustOpen(false)} />
    </section>
  );
}
