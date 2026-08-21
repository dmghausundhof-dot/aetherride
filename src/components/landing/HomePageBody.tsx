"use client";

import Image from "next/image";
import Link from "next/link";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { featuredPublicTours } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { formatDistanceElevation } from "@/lib/discover/elevationGuard";

export function HomePageBody() {
  const h = useHomepageCopy();
  const featured = featuredPublicTours();

  return (
    <>
      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold sm:text-3xl">{h.ui.leversTitle}</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            {h.bikesLine}
          </p>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {h.levers.map((lever) => (
              <Link
                key={lever.title}
                href={lever.href}
                className="rounded-2xl border border-border bg-background/60 p-6 transition hover:border-chrome/50"
              >
                <h3 className="text-xl font-semibold">{lever.title}</h3>
                <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                  {lever.body}
                </p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {h.split.kicker}
          </p>
          <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.split.title}</h2>
          <div className="mt-8 grid gap-6 md:grid-cols-2">
            <div className="rounded-2xl border border-border bg-surface p-8">
              <ChromeGlyph name="karte" size={32} current className="text-sage" />
              <h3 className="mt-4 text-xl font-bold">{h.ui.onWebsite}</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {h.split.webLead}
              </p>
            </div>
            <div className="rounded-2xl border border-border bg-surface p-8">
              <ChromeGlyph name="phone" size={32} current className="text-sage" />
              <h3 className="mt-4 text-xl font-bold">{h.ui.inApp}</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {h.split.appLead}
              </p>
            </div>
          </div>
          <p className="mt-6 max-w-2xl text-sm text-text-secondary">
            <span className="font-semibold text-foreground">
              {h.mapsShort.title}
            </span>{" "}
            {h.mapsShort.body}{" "}
            <Link href="/karten" className="font-semibold text-chrome hover:underline">
              Karten →
            </Link>
          </p>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-2xl font-bold sm:text-3xl">{h.ui.screenTitle}</h2>
          <figure className="mt-8 overflow-hidden rounded-2xl border border-border bg-background">
            <div className="relative aspect-[4/3] bg-background">
              <Image
                src={h.productScreen.src}
                alt={h.productScreen.alt}
                fill
                sizes="(min-width: 768px) 48rem, 100vw"
                className="object-cover object-top"
              />
            </div>
            <figcaption className="p-5">
              <p className="font-semibold">{h.productScreen.title}</p>
              <p className="mt-1 text-sm text-text-secondary">
                {h.productScreen.caption}
              </p>
            </figcaption>
          </figure>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {h.tours.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.tours.title}</h2>
              <p className="mt-3 text-sm text-text-secondary">{h.tours.lead}</p>
            </div>
            <Link
              href="/regions"
              className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
            >
              {h.ui.allRegions} →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {featured.map((t) => (
              <Link
                key={t.id}
                href={`/tours/${t.id}`}
                className="rounded-2xl border border-border bg-surface p-4 transition hover:border-chrome/40"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                  {bikeCategoryLabel(t.primaryCategory)}
                </p>
                <p className="mt-1 font-medium">{t.name}</p>
                <p className="mt-2 line-clamp-3 text-xs text-text-secondary">
                  {t.summary}
                </p>
                <p className="mt-3 text-xs tabular-nums text-text-secondary">
                  {formatDistanceElevation(t.distanceKm, t.elevationM)}
                </p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-2">
          <div>
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {h.honesty.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.ui.standTitle}</h2>
            <p className="mt-3 text-sm text-text-secondary">{h.honesty.lead}</p>
            <div className="mt-8 grid gap-4">
              <div className="rounded-2xl border border-border bg-background/60 p-6">
                <h3 className="font-semibold">{h.ui.alreadyHere}</h3>
                <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                  {h.honesty.live.map((line) => (
                    <li key={line}>· {line}</li>
                  ))}
                </ul>
              </div>
              <div className="rounded-2xl border border-border bg-background/60 p-6">
                <h3 className="font-semibold">{h.ui.notYetTitle}</h3>
                <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                  {h.honesty.notYet.map((line) => (
                    <li key={line}>· {line}</li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
          <div>
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {h.ui.faqKicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.ui.faqTitle}</h2>
            <p className="mt-3 text-sm text-text-secondary">{h.ui.faqLead}</p>
            <dl className="mt-8 space-y-4">
              {h.homeFaq.map((item) => (
                <div
                  key={item.q}
                  className="rounded-2xl border border-border bg-background/60 p-5"
                >
                  <dt className="font-semibold">{item.q}</dt>
                  <dd className="mt-2 text-sm text-text-secondary">{item.a}</dd>
                </div>
              ))}
            </dl>
            <p className="mt-6 text-sm font-semibold">
              <Link href="/faq" className="text-text-secondary hover:text-chrome hover:underline">
                {h.ui.allQuestions} →
              </Link>
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
