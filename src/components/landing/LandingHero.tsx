"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, type MouseEvent } from "react";
import {
  appDiscoverHref,
  isExternalAppDiscoverHref,
} from "@/lib/web/appLinks";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { TrustSheet } from "./TrustSheet";

export function LandingHero() {
  const [trustOpen, setTrustOpen] = useState(false);
  const lang = useChromeLang();
  const hof = useHofCopy();
  const home = useHomepageCopy();

  function onDiscoverClick(e: MouseEvent<HTMLAnchorElement>) {
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

          <h1 className="mt-8 text-[2.35rem] font-semibold leading-[1.08] tracking-[-0.03em] text-foreground [text-shadow:0_1px_24px_rgba(18,18,21,0.35)] sm:text-5xl md:text-[3.4rem] md:leading-[1.04]">
            {home.ui.heroTagline}
          </h1>

          <p className="mt-7 max-w-sm text-[0.95rem] leading-[1.55] text-text-secondary sm:mt-8 sm:max-w-md sm:text-lg sm:leading-relaxed">
            {home.ui.heroLead(hof.rideOut)}
          </p>

          <div className="mt-10 sm:mt-12">
            <Link
              href="/discover"
              onClick={onDiscoverClick}
              className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-7 text-[0.95rem] font-semibold text-on-accent transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:h-[3.25rem] sm:min-w-[11rem] sm:px-8"
            >
              {home.heroCta}
            </Link>
          </div>

          <button
            type="button"
            onClick={() => setTrustOpen(true)}
            className="mt-4 text-left text-sm text-text-secondary underline-offset-4 hover:text-foreground hover:underline"
          >
            {home.ui.heroFair}
          </button>

          <p className="mt-5 text-[0.7rem] leading-relaxed tracking-[0.01em] text-text-secondary/80 sm:mt-6 sm:text-[0.8rem]">
            {home.ui.heroFoot}
          </p>
        </div>
      </div>

      <TrustSheet open={trustOpen} onClose={() => setTrustOpen(false)} />
    </section>
  );
}
