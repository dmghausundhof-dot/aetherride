"use client";

import Link from "next/link";
import {
  getPublicTour,
  relatedTours,
} from "@/lib/catalog/publicTours";
import { getRegion } from "@/lib/catalog/regions";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { relatedGuidesForTour } from "@/lib/content/guides";
import { TourActions } from "@/components/tours/TourActions";
import { WeatherPanel } from "@/components/tours/WeatherPanel";
import { TourElevationClient } from "@/components/tours/TourElevationClient";
import { TourLiveMap } from "@/components/tours/TourLiveMap";
import { TourReviews } from "@/components/community/TourReviews";
import { TourCommunityChip } from "@/components/community/TourCommunityChip";
import { ShareCatalogTourButton } from "@/components/tours/ShareCatalogTourButton";
import { TourFunctionKit } from "@/components/tours/TourFunctionKit";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { guideFor } from "@/lib/i18n/guidesCopy";
import { webChrome } from "@/lib/i18n/webChrome";
import { formatDistanceElevation, sanitizeElevationM } from "@/lib/discover/elevationGuard";

export function TourPageBody({ id }: { id: string }) {
  const lang = useChromeLang();
  const copy = catalogCopy(lang);
  const chrome = webChrome(lang);
  const tour = getPublicTour(id);
  if (!tour) return null;

  const region = getRegion(tour.regionSlug);
  const related = relatedTours(tour, 4);
  const tourElev = sanitizeElevationM(tour.elevationM, tour.distanceKm);
  const guides = relatedGuidesForTour(tour)
    .map((g) => guideFor(g.slug, lang))
    .filter((g): g is NonNullable<typeof g> => g != null);

  return (
    <div>
      <div className="border-b border-border bg-surface/50">
        <div className="mx-auto grid max-w-6xl gap-0 lg:grid-cols-2">
          <div className="flex flex-col justify-center px-4 py-10 sm:px-6 lg:py-14">
            <div className="flex flex-wrap items-center gap-2 text-xs text-text-secondary">
              <Link href="/discover" className="hover:text-chrome">
                {chrome.hofNav.karte}
              </Link>
              <span>/</span>
              {region && (
                <>
                  <Link
                    href={`/regions/${region.slug}`}
                    className="hover:text-chrome"
                  >
                    {region.name}
                  </Link>
                  <span>/</span>
                </>
              )}
              <span className="text-foreground">{tour.name}</span>
            </div>
            <p className="mt-4 text-[11px] font-bold tracking-wide text-text-secondary">
              {copy.tour.atGate}
            </p>
            <p className="mt-1 text-xs font-medium uppercase tracking-wide text-text-secondary">
              {bikeCategoryLabel(tour.primaryCategory)}
              {tour.loop ? ` · ${copy.tour.loop}` : ` · ${copy.tour.stage}`}
            </p>
            <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {tour.name}
            </h1>
            <p className="mt-3 text-text-secondary">{tour.summary}</p>
            <dl className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
              <Stat
                label={copy.tour.distance}
                value={`${tour.distanceKm} km`}
              />
              <Stat
                label={copy.tour.elevation}
                value={tourElev != null ? `${tourElev} hm` : "—"}
              />
              <Stat
                label={copy.tour.duration}
                value={`${tour.durationMin} min`}
              />
              <Stat
                label={copy.tour.difficulty}
                value={
                  tour.difficulty !== "—"
                    ? tour.difficulty
                    : copy.tour.roadPath
                }
              />
            </dl>
            <div className="mt-3 flex flex-wrap gap-2 text-[11px]">
              <span className="rounded-full bg-surface-elevated px-2.5 py-1">
                {tour.surface}
              </span>
              {tour.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full border border-border px-2.5 py-1 text-text-secondary"
                >
                  {tag}
                </span>
              ))}
            </div>
            <div className="mt-8">
              <TourActions tour={tour} />
              <ShareCatalogTourButton tour={tour} />
            </div>
            <div className="mt-4">
              <TourCommunityChip tourId={tour.id} />
            </div>
          </div>
          <div className="relative min-h-[360px] lg:min-h-[560px]">
            <TourLiveMap
              tourId={tour.id}
              center={tour.center}
              name={tour.name}
              profile={profileForBikeCategory(tour.primaryCategory)}
              category={tour.primaryCategory}
              loop={tour.loop}
            />
          </div>
        </div>
      </div>

      <div className="mx-auto grid max-w-6xl gap-8 px-4 py-10 sm:px-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <section>
            <h2 className="text-lg font-semibold">{copy.tour.about}</h2>
            <p className="mt-2 text-sm leading-relaxed text-text-secondary">
              {tour.description}
            </p>
          </section>
          <TourElevationClient tour={tour} />
          <TourReviews tourId={tour.id} />
          <section className="rounded-2xl border border-border bg-surface p-4">
            <h2 className="text-sm font-semibold">{copy.tour.honestTitle}</h2>
            <p className="mt-2 text-xs leading-relaxed text-text-secondary">
              {copy.tour.honestBody}
            </p>
          </section>
        </div>
        <aside className="space-y-4">
          <TourFunctionKit tour={tour} />
          <WeatherPanel
            lat={tour.center[1]}
            lng={tour.center[0]}
            profile={profileForBikeCategory(tour.primaryCategory)}
          />
          {region && (
            <div className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">{copy.tour.region}</h2>
              <p className="mt-1 text-sm font-medium">{region.name}</p>
              <p className="mt-1 text-xs text-text-secondary">{region.teaser}</p>
              <Link
                href={`/regions/${region.slug}`}
                className="mt-3 inline-block text-xs font-semibold text-chrome hover:underline"
              >
                {copy.tour.allToursIn(region.name)}
              </Link>
            </div>
          )}
          <div className="rounded-2xl border border-border bg-surface p-4">
            <h2 className="text-sm font-semibold">{copy.tour.disciplines}</h2>
            <ul className="mt-2 flex flex-wrap gap-1.5">
              {tour.categories.map((c) => (
                <li
                  key={c}
                  className="rounded-full bg-surface-elevated px-2.5 py-1 text-[11px]"
                >
                  {bikeCategoryLabel(c)}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-4">
            <h2 className="text-sm font-semibold">
              {chrome.marketingNav["/guides"]}
            </h2>
            <ul className="mt-3 space-y-2">
              {guides.map((g) => (
                <li key={g.slug}>
                  <Link
                    href={`/guides/${g.slug}`}
                    className="text-xs font-semibold text-chrome hover:underline"
                  >
                    {g.title} →
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </aside>
      </div>

      {related.length > 0 && (
        <section className="border-t border-border bg-surface/40 py-12">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <h2 className="text-xl font-bold">{copy.tour.similar}</h2>
            <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {related.map((r) => (
                <Link
                  key={r.id}
                  href={`/tours/${r.id}`}
                  className="rounded-2xl border border-border bg-background p-4 transition hover:border-chrome/40"
                >
                  <p className="text-[11px] uppercase tracking-wide text-text-secondary">
                    {bikeCategoryLabel(r.primaryCategory)}
                  </p>
                  <h3 className="mt-1 font-semibold">{r.name}</h3>
                  <p className="mt-1 text-xs text-text-secondary">
                    {formatDistanceElevation(r.distanceKm, r.elevationM)}
                  </p>
                  <div className="mt-2">
                    <TourCommunityChip tourId={r.id} />
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-background/60 px-3 py-2">
      <dt className="text-[10px] uppercase tracking-wide text-text-secondary">
        {label}
      </dt>
      <dd className="mt-0.5 text-sm font-semibold tabular-nums">{value}</dd>
    </div>
  );
}
