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
      {/* Full-bleed hero plane */}
      <div className="absolute inset-0">
        <Image
          src="/landing/hero-trail.jpg"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover object-[center_35%] animate-hero-ken"
        />
        <div
          className="absolute inset-0 bg-gradient-to-b from-background/55 via-background/70 to-background"
          aria-hidden
        />
        <div
          className="absolute inset-0 bg-gradient-to-r from-background/80 via-background/40 to-transparent"
          aria-hidden
        />
      </div>

      <div className="relative z-10 mx-auto flex min-h-[100svh] max-w-6xl flex-col justify-end px-4 pb-16 pt-28 sm:justify-center sm:pb-20 sm:pt-24">
        <div className="max-w-xl animate-hero-rise">
          <p className="mb-5 text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
            Aether<span className="text-accent">Ride</span>
          </p>

          <h1 className="text-[2.15rem] font-bold leading-[1.12] tracking-tight sm:text-5xl md:text-6xl">
            Touren &amp; Wartung —
            <br />
            ohne Abo-Falle.
          </h1>

          <p className="mt-5 max-w-md text-base leading-relaxed text-text-secondary sm:text-lg">
            Alltag und Abenteuer. Fair von Anfang an — ohne Lock-in.
          </p>

          <div className="mt-8 flex flex-col items-stretch gap-3 sm:flex-row sm:items-center">
            <Link
              href="/download"
              onClick={onAppDiscoverClick}
              className="inline-flex h-14 min-w-[10.5rem] items-center justify-center rounded-xl bg-accent px-8 text-base font-semibold text-white transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
            >
              App entdecken
            </Link>
            <button
              type="button"
              onClick={() => setTrustOpen(true)}
              className="inline-flex h-14 min-w-[10.5rem] items-center justify-center rounded-xl border border-border bg-surface/70 px-8 text-base font-semibold text-foreground backdrop-blur-sm transition hover:bg-surface-elevated focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
            >
              So bleibt’s fair
            </button>
          </div>

          <ul className="mt-8 flex flex-wrap gap-2" aria-label="Kernvorteile">
            {PILLS.map((label, i) => (
              <li
                key={label}
                className="animate-hero-rise rounded-lg border border-border/80 bg-background/45 px-3 py-1.5 text-xs font-medium text-foreground backdrop-blur-sm"
                style={{ animationDelay: `${180 + i * 90}ms` }}
              >
                {label}
              </li>
            ))}
          </ul>

          <p className="mt-5 text-xs text-text-secondary/90 sm:text-sm">
            Sync, Navigation und Export bleiben frei.
          </p>
        </div>
      </div>

      <TrustSheet open={trustOpen} onClose={() => setTrustOpen(false)} />
    </section>
  );
}
