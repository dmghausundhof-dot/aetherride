"use client";

import Link from "next/link";
import { getRegion, neighborRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { relatedGuidesForRegion } from "@/lib/content/guides";
import { listEditorialProfilesForRegion } from "@/lib/community/editorialProfiles";
import { COMMUNITY_EVENTS } from "@/lib/community/seed";
import { RegionToursMap } from "@/components/tours/RegionToursMap";
import { tourHrefForEvent } from "@/lib/tours/tourFunctions";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { guideFor } from "@/lib/i18n/guidesCopy";
import { webChrome } from "@/lib/i18n/webChrome";
import { formatDistanceElevation } from "@/lib/discover/elevationGuard";

export function RegionPageBody({ slug }: { slug: string }) {
  const lang = useChromeLang();
  const copy = catalogCopy(lang);
  const chrome = webChrome(lang);
  const h = useHomepageCopy();
  const region = getRegion(slug);
  if (!region) return null;

  const tours = listToursByRegion(slug);
  const nearby = neighborRegions(slug);
  const guides = relatedGuidesForRegion(region.sports)
    .map((g) => guideFor(g.slug, lang))
    .filter((g): g is NonNullable<typeof g> => g != null);
  const profiles = listEditorialProfilesForRegion(slug);
  const events = COMMUNITY_EVENTS.filter((e) => e.regionSlug === slug);

  return (
    <div>
      <section className="border-b border-border bg-gradient-to-b from-primary/15 to-background px-4 py-14 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="text-xs text-text-secondary">
            <Link href="/regions" className="hover:text-chrome">
              {chrome.marketingNav["/regions"]}
            </Link>
            <span className="mx-1.5">/</span>
            <span className="text-foreground">{region.name}</span>
          </div>
          <h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">
            {region.name}
          </h1>
          <p className="mt-3 max-w-2xl text-text-secondary">
            {region.description}
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            {region.sports.map((s) => (
              <Link
                key={s}
                href={`/discover?sport=${s}`}
                className="rounded-full border border-border bg-surface px-3 py-1 text-xs capitalize hover:border-chrome/40"
              >
                {s}
              </Link>
            ))}
          </div>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link
              href={`/discover`}
              className="rounded-xl bg-chrome px-4 py-2.5 text-sm font-semibold text-on-accent"
            >
              {copy.region.openMap}
            </Link>
            <Link
              href="/discover?panel=plan"
              className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium"
            >
              {chrome.plan}
            </Link>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <h2 className="text-xl font-bold">
          {copy.region.toursIn(region.name)}{" "}
          <span className="text-text-secondary">({tours.length})</span>
        </h2>
        {tours.length > 0 ? (
          <div className="mt-6">
            <RegionToursMap tours={tours} center={region.center} />
          </div>
        ) : null}
        {tours.length === 0 ? (
          <div className="mt-4">
            <p className="text-sm text-text-secondary">{copy.region.empty}</p>
            <div className="mt-4 flex flex-wrap gap-3">
              <Link
                href="/discover"
                className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
              >
                {copy.region.openMapCta}
              </Link>
              <Link
                href="/discover?panel=plan"
                className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
              >
                {copy.region.planCta}
              </Link>
            </div>
          </div>
        ) : (
          <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {tours.map((t) => (
              <Link
                key={t.id}
                href={`/tours/${t.id}`}
                className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                  {bikeCategoryLabel(t.primaryCategory)}
                </p>
                <h3 className="mt-1 text-lg font-semibold">{t.name}</h3>
                <p className="mt-2 line-clamp-2 text-xs text-text-secondary">
                  {t.summary}
                </p>
                <p className="mt-3 text-xs tabular-nums text-text-secondary">
                  {[
                    formatDistanceElevation(t.distanceKm, t.elevationM),
                    `${t.durationMin} min`,
                    t.difficulty !== "—" ? t.difficulty : null,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
              </Link>
            ))}
          </div>
        )}
      </section>

      {profiles.length > 0 ? (
        <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
          <h2 className="text-xl font-bold">{copy.region.voicesTitle}</h2>
          <p className="mt-1 text-sm text-text-secondary">
            {copy.region.voicesLead}
          </p>
          <ul className="mt-4 grid gap-3 sm:grid-cols-2">
            {profiles.map((p) => (
              <li key={p.handle}>
                <Link
                  href={`/u/${p.handle}`}
                  className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                >
                  <p className="font-semibold">{p.displayName}</p>
                  <p className="text-xs text-text-secondary">@{p.handle}</p>
                  <p className="mt-2 text-sm text-text-secondary">{p.bio}</p>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {events.length > 0 ? (
        <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
          <h2 className="text-xl font-bold">{copy.region.datesTitle}</h2>
          <p className="mt-1 text-sm text-text-secondary">
            {copy.region.datesLead}
          </p>
          <ul className="mt-4 space-y-3">
            {events.map((e) => (
              <li
                key={e.id}
                className="rounded-2xl border border-border bg-surface p-5"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                  {e.sport} · {e.dateLabel}
                </p>
                <h3 className="mt-1 text-lg font-semibold">{e.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{e.blurb}</p>
                {e.catalogTourId ? (
                  <Link
                    href={tourHrefForEvent(e)}
                    className="mt-3 inline-block text-xs font-semibold text-chrome hover:underline"
                  >
                    {copy.tour.eventOpen}
                  </Link>
                ) : null}
              </li>
            ))}
          </ul>
          <p className="mt-4 text-sm">
            <Link
              href="/community#events"
              className="font-semibold text-text-secondary hover:text-chrome hover:underline"
            >
              {copy.region.allDates}
            </Link>
          </p>
        </section>
      ) : null}

      {guides.length > 0 ? (
        <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
          <h2 className="text-xl font-bold">{copy.region.guidesTitle}</h2>
          <ul className="mt-4 grid gap-3 sm:grid-cols-2">
            {guides.map((g) => (
              <li key={g.slug}>
                <Link
                  href={`/guides/${g.slug}`}
                  className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                >
                  <p className="text-[11px] text-text-secondary">
                    {h.ui.readMin(g.readMin)}
                  </p>
                  <p className="mt-1 font-semibold">{g.title}</p>
                  <p className="mt-1 text-sm text-text-secondary">{g.teaser}</p>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {nearby.length > 0 ? (
        <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
          <h2 className="text-xl font-bold">{copy.region.neighborsTitle}</h2>
          <p className="mt-1 text-sm text-text-secondary">
            {copy.region.neighborsLead}
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            {nearby.map((n) => (
              <Link
                key={n.slug}
                href={`/regions/${n.slug}`}
                className="rounded-full border border-border px-3 py-1.5 text-sm hover:border-chrome/40"
              >
                {n.name}
              </Link>
            ))}
          </div>
        </section>
      ) : null}
    </div>
  );
}
