"use client";

import Link from "next/link";
import { Suspense } from "react";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import {
  KartenCoverageFallback,
  KartenCoverageSection,
} from "@/components/landing/KartenCoverageSection";
import { Home, Map, BookOpen, Smartphone, Store, Wrench } from "lucide-react";
import { HOME_FAQ_IDS } from "@/lib/content/homepage";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { getPublicTour, featuredPublicTours } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { faqItems } from "@/lib/i18n/faqCopy";
import { guideFor } from "@/lib/i18n/guidesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

const DOOR_ICONS = [Home, Map, BookOpen, Wrench, Store] as const;

const REGION_CHIPS = [
  { slug: "norddeutschland", name: "Norddeutschland" },
  { slug: "berlin-brandenburg", name: "Berlin" },
  { slug: "rhein-neckar", name: "Rhein-Neckar" },
  { slug: "schwarzwald", name: "Schwarzwald" },
  { slug: "nrw", name: "NRW" },
  { slug: "oesterreich", name: "Österreich" },
  { slug: "schweiz", name: "Schweiz" },
] as const;

export function HomePageBody() {
  const lang = useChromeLang();
  const h = useHomepageCopy();
  const chrome = webChrome(lang);
  const featured = featuredPublicTours();
  const guides = h.guides.slugs
    .map((slug) => guideFor(slug, lang))
    .filter((g): g is NonNullable<typeof g> => g != null);
  const faq = HOME_FAQ_IDS.map((id) =>
    faqItems(lang).find((item) => item.id === id),
  ).filter((item): item is NonNullable<typeof item> => item != null);
  const voices = EDITORIAL_REVIEWS.slice(0, 4);

  return (
    <>
      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-12">
          <div className="lg:col-span-5">
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {h.intro.kicker}
            </p>
            <h2 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {h.intro.title}
            </h2>
            <p className="mt-4 text-text-secondary">{h.intro.lead}</p>
          </div>
          <div className="space-y-4 text-sm leading-relaxed text-text-secondary lg:col-span-7">
            {h.intro.paragraphs.map((p) => (
              <p key={p.slice(0, 24)}>{p}</p>
            ))}
            <div className="flex flex-wrap gap-4 pt-2 text-sm font-semibold">
              <Link href="/produkt" className="text-text-secondary hover:text-chrome hover:underline">
                {h.ui.productMap} →
              </Link>
              <Link href="/ueber" className="text-text-secondary hover:text-chrome hover:underline">
                {chrome.aboutFlowLine} →
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold sm:text-3xl">{h.ui.bikesTitle}</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            {h.ui.bikesLead}
          </p>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {h.disciplines.map((d) => (
              <Link
                key={d.href}
                href={d.href}
                className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <h3 className="font-semibold">{d.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{d.body}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold sm:text-3xl">{h.ui.doorsTitle}</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            {h.ui.doorsLead}
          </p>
          <div className="mt-10 grid gap-4 lg:grid-cols-2">
            {h.doors.slice(0, 2).map((door, i) => {
              const Icon = DOOR_ICONS[i];
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-background/60 p-6 transition hover:border-chrome/50"
                >
                  <Icon className="h-5 w-5 text-sage" />
                  <p className="mt-4 text-[11px] font-bold tracking-wide text-text-secondary">
                    {door.kicker}
                  </p>
                  <h3 className="mt-1 text-xl font-semibold">{door.title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                    {door.body}
                  </p>
                </Link>
              );
            })}
          </div>
          <div className="mt-4 grid gap-4 sm:grid-cols-3">
            {h.doors.slice(2).map((door, i) => {
              const Icon = DOOR_ICONS[i + 2];
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-background/60 p-5 transition hover:border-chrome/50"
                >
                  <Icon className="h-5 w-5 text-sage" />
                  <p className="mt-3 text-[11px] font-bold tracking-wide text-text-secondary">
                    {door.kicker}
                  </p>
                  <h3 className="mt-1 font-semibold">{door.title}</h3>
                  <p className="mt-2 text-sm text-text-secondary">{door.body}</p>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <Suspense fallback={<KartenCoverageFallback />}>
        <KartenCoverageSection />
      </Suspense>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {h.split.kicker}
          </p>
          <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.split.title}</h2>
          <div className="mt-8 grid gap-6 md:grid-cols-2">
            <div className="rounded-2xl border border-border bg-surface p-8">
              <Map className="h-8 w-8 text-sage" />
              <h3 className="mt-4 text-xl font-bold">{h.ui.onWebsite}</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {h.split.webLead}
              </p>
              <ul className="mt-4 space-y-2 text-sm text-text-secondary">
                {h.webSurfaces.map((s) => (
                  <li key={s.title}>
                    <span className="font-medium text-foreground">{s.title}.</span>{" "}
                    {s.body}
                  </li>
                ))}
              </ul>
              <div className="mt-6 flex flex-wrap gap-4">
                <Link href="/home" className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline">
                  {chrome.toHof} →
                </Link>
                <Link href="/discover" className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline">
                  {chrome.hofNav.karte} →
                </Link>
              </div>
            </div>
            <div className="rounded-2xl border border-border bg-surface p-8">
              <Smartphone className="h-8 w-8 text-sage" />
              <h3 className="mt-4 text-xl font-bold">{h.ui.inApp}</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {h.split.appLead}
              </p>
              <ul className="mt-4 space-y-2 text-sm text-text-secondary">
                {h.appSurfaces.map((s) => (
                  <li key={s.title}>
                    <span className="font-medium text-foreground">{s.title}.</span>{" "}
                    {s.body}
                  </li>
                ))}
              </ul>
              <div className="mt-6 flex flex-wrap gap-4">
                <Link
                  href="/download"
                  className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
                >
                  {chrome.loadApp} →
                </Link>
                <Link
                  href="/guides/web-vs-app"
                  className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
                >
                  {chrome.webVsApp} →
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {h.tours.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.tours.title}</h2>
              <p className="mt-3 text-sm text-text-secondary">{h.tours.lead}</p>
            </div>
            <Link href="/regions" className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline">
              {h.ui.allRegions} →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {featured.map((t) => (
              <Link
                key={t.id}
                href={`/tours/${t.id}`}
                className="rounded-2xl border border-border bg-background/60 p-4 transition hover:border-chrome/40"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                  {bikeCategoryLabel(t.primaryCategory)}
                </p>
                <p className="mt-1 font-medium">{t.name}</p>
                <p className="mt-2 line-clamp-3 text-xs text-text-secondary">
                  {t.summary}
                </p>
                <p className="mt-3 text-xs tabular-nums text-text-secondary">
                  {t.distanceKm} km · {t.elevationM} hm
                </p>
              </Link>
            ))}
          </div>
          <div className="mt-6 flex flex-wrap gap-2">
            {REGION_CHIPS.map((r) => (
              <Link
                key={r.slug}
                href={`/regions/${r.slug}`}
                className="rounded-full border border-border px-3 py-1 text-xs font-medium transition hover:border-chrome/40"
              >
                {r.name}
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <p className="text-center text-[11px] font-bold tracking-wide text-text-secondary">
            {h.journey.kicker}
          </p>
          <h2 className="mt-2 text-center text-3xl font-bold">{h.journey.title}</h2>
          <p className="mx-auto mt-3 max-w-xl text-center text-sm text-text-secondary">
            {h.journey.lead}
          </p>
          <ol className="mt-12 space-y-8">
            {h.journeySteps.map((s) => (
              <li key={s.n} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-border text-lg font-bold text-foreground">
                  {s.n}
                </span>
                <div>
                  <h3 className="font-semibold">{s.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{s.body}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {h.voices.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.voices.title}</h2>
              <p className="mt-3 text-sm text-text-secondary">{h.voices.lead}</p>
            </div>
            <Link href="/community" className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline">
              {h.ui.community} →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2">
            {voices.map((r) => {
              const tour = getPublicTour(r.tourId);
              return (
                <blockquote
                  key={r.id}
                  className="rounded-2xl border border-border bg-background/60 p-5"
                >
                  <p className="text-sm leading-relaxed text-foreground/90">
                    „{r.body}“
                  </p>
                  <footer className="mt-4 text-xs text-text-secondary">
                    {r.authorHandle ? (
                      <Link
                        href={`/u/${r.authorHandle}`}
                        className="font-semibold text-text-secondary hover:text-chrome hover:underline"
                      >
                        {r.authorLabel}
                      </Link>
                    ) : (
                      <span className="font-semibold">{r.authorLabel}</span>
                    )}
                    <span> · {h.ui.editorial}</span>
                    {tour ? (
                      <>
                        {" · "}
                        <Link
                          href={`/tours/${tour.id}`}
                          className="text-text-secondary hover:text-chrome hover:underline"
                        >
                          {tour.name}
                        </Link>
                      </>
                    ) : null}
                  </footer>
                </blockquote>
              );
            })}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-text-secondary">
                {h.guides.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.guides.title}</h2>
              <p className="mt-3 text-sm text-text-secondary">{h.guides.lead}</p>
            </div>
            <Link href="/guides" className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline">
              {h.ui.allGuides} →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {guides.map((g) => (
              <Link
                key={g.slug}
                href={`/guides/${g.slug}`}
                className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <p className="text-[11px] text-text-secondary">
                  {h.ui.readMin(g.readMin)}
                </p>
                <h3 className="mt-1 font-semibold">{g.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{g.teaser}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-2">
          <div>
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {h.ui.faqKicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.ui.faqTitle}</h2>
            <p className="mt-3 text-sm text-text-secondary">{h.ui.faqLead}</p>
            <dl className="mt-8 space-y-4">
              {faq.map((item) => (
                <div
                  key={item.id}
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
          <div>
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {h.pricing.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.pricing.title}</h2>
            <p className="mt-3 text-sm text-text-secondary">{h.pricing.lead}</p>
            <div className="mt-8 grid gap-3">
              <div className="rounded-2xl border border-border bg-background/60 p-5">
                <p className="text-sm font-semibold">{h.ui.free}</p>
                <p className="mt-2 text-sm text-text-secondary">{h.pricing.free}</p>
              </div>
              <div className="rounded-2xl border border-chrome/40 bg-chrome/10 p-5">
                <p className="text-sm font-semibold">{h.ui.pro}</p>
                <p className="mt-2 text-sm text-text-secondary">{h.pricing.pro}</p>
              </div>
            </div>
            <p className="mt-6 text-sm font-semibold">
              <Link href="/pricing" className="text-text-secondary hover:text-chrome hover:underline">
                {h.ui.pricesDetail} →
              </Link>
            </p>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {h.honesty.kicker}
          </p>
          <h2 className="mt-2 text-2xl font-bold sm:text-3xl">{h.honesty.title}</h2>
          <p className="mt-3 max-w-2xl text-sm text-text-secondary">{h.honesty.lead}</p>
          <div className="mt-8 grid gap-4 md:grid-cols-2">
            <div className="rounded-2xl border border-border bg-surface p-6">
              <h3 className="font-semibold">{h.ui.alreadyHere}</h3>
              <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                {h.honesty.live.map((line) => (
                  <li key={line}>· {line}</li>
                ))}
              </ul>
            </div>
            <div className="rounded-2xl border border-border bg-surface p-6">
              <h3 className="font-semibold">{h.ui.notYetTitle}</h3>
              <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                {h.honesty.notYet.map((line) => (
                  <li key={line}>· {line}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

export function HomePageCta() {
  const lang = useChromeLang();
  const h = useHomepageCopy();
  const chrome = webChrome(lang);

  return (
    <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-2xl text-center">
        <h2 className="text-2xl font-bold sm:text-3xl">{h.cta.title}</h2>
        <p className="mt-4 text-text-secondary">{h.cta.body}</p>
        <div className="mt-8 flex flex-col items-center gap-4">
          <div className="flex flex-wrap justify-center gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center justify-center rounded-xl bg-chrome px-8 text-sm font-semibold text-on-accent hover:bg-chrome/90"
            >
              {chrome.toHof}
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              {chrome.loadApp}
            </Link>
            <Link
              href="/anmelden"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              {chrome.signIn}
            </Link>
          </div>
          <AppDownloadButtons size="lg" />
        </div>
        <p className="mt-6 text-sm text-text-secondary">
          <Link href="/garage" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.hofNav.werkstatt}
          </Link>
          {" · "}
          <Link href="/guides" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.marketingNav["/guides"]}
          </Link>
          {" · "}
          <Link href="/karten" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.marketingNav["/karten"]}
          </Link>
          {" · "}
          <Link href="/produkt" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.marketingNav["/produkt"]}
          </Link>
          {" · "}
          <Link href="/kontakt" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.contact}
          </Link>
        </p>
      </div>
    </section>
  );
}
