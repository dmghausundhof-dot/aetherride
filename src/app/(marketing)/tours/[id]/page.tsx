import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  getPublicTour,
  listPublicTourIds,
  relatedTours,
  tourJsonLd,
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
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { breadcrumbJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

type Props = { params: Promise<{ id: string }> };

export function generateStaticParams() {
  return listPublicTourIds().map((id) => ({ id }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const tour = getPublicTour(id);
  if (!tour) return { title: "Tour nicht gefunden" };
  const region = getRegion(tour.regionSlug);
  return {
    title: `${tour.name} – ${bikeCategoryLabel(tour.primaryCategory)}`,
    description: tour.summary,
    openGraph: {
      title: tour.name,
      description: tour.summary,
      type: "article",
      locale: "de_DE",
    },
    keywords: [
      tour.name,
      bikeCategoryLabel(tour.primaryCategory),
      region?.name ?? "",
      ...tour.tags,
      "Radtour",
      "FlowLine",
    ].filter(Boolean),
  };
}

export default async function TourPage({ params }: Props) {
  const { id } = await params;
  const tour = getPublicTour(id);
  if (!tour) notFound();

  const region = getRegion(tour.regionSlug);
  const related = relatedTours(tour, 4);
  const guides = relatedGuidesForTour(tour);
  const origin = siteOrigin();
  const jsonLd = tourJsonLd(tour, origin);
  const crumbs = breadcrumbJsonLd(origin, [
    { name: "Regionen", path: "/regions" },
    ...(region
      ? [{ name: region.name, path: `/regions/${region.slug}` }]
      : []),
    { name: tour.name, path: `/tours/${tour.id}` },
  ]);

  return (
    <div>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(crumbs) }}
      />
      <div>
        <div className="border-b border-border bg-surface/50">
          <div className="mx-auto grid max-w-6xl gap-0 lg:grid-cols-2">
            <div className="flex flex-col justify-center px-4 py-10 sm:px-6 lg:py-14">
              <div className="flex flex-wrap items-center gap-2 text-xs text-text-secondary">
                <Link href="/discover" className="hover:text-chrome">
                  Karte
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
              <p className="mt-4 text-[11px] font-bold tracking-wide text-chrome">
                Vor dem Tor
              </p>
              <p className="mt-1 text-xs font-medium uppercase tracking-wide text-text-secondary">
                {bikeCategoryLabel(tour.primaryCategory)}
                {tour.loop ? " · Rundkurs" : " · Etappe"}
              </p>
              <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
                {tour.name}
              </h1>
              <p className="mt-3 text-text-secondary">{tour.summary}</p>
              <dl className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
                <Stat label="Distanz" value={`${tour.distanceKm} km`} />
                <Stat label="Höhenmeter" value={`${tour.elevationM} hm`} />
                <Stat label="Dauer" value={`${tour.durationMin} min`} />
                <Stat
                  label="Schwierigkeit"
                  value={
                    tour.difficulty !== "—" ? tour.difficulty : "Straße/Weg"
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
            <div className="relative min-h-[280px] lg:min-h-[420px]">
              <TourLiveMap
                tourId={tour.id}
                center={tour.center}
                name={tour.name}
                profile={profileForBikeCategory(tour.primaryCategory)}
              />
            </div>
          </div>
        </div>

        <div className="mx-auto grid max-w-6xl gap-8 px-4 py-10 sm:px-6 lg:grid-cols-3">
          <div className="space-y-6 lg:col-span-2">
            <section>
              <h2 className="text-lg font-semibold">Über diese Tour</h2>
              <p className="mt-2 text-sm leading-relaxed text-text-secondary">
                {tour.description}
              </p>
            </section>
            <TourElevationClient tour={tour} />
            <TourReviews tourId={tour.id} />
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Ehrlicher Hinweis</h2>
              <p className="mt-2 text-xs leading-relaxed text-text-secondary">
                Das ist eine redaktionelle Tour-Idee, kein Community-Track mit
                vermessener GPS-Linie. Unter Planen oder Touren wird die Route mit
                dem gewählten Sport-Profil berechnet. Navigation und Offline nur
                in der nativen App. Stimmen sind moderiert und enthalten keine
                Tracks.
              </p>
            </section>
          </div>
          <aside className="space-y-4">
            <WeatherPanel lat={tour.center[1]} lng={tour.center[0]} />
            {region && (
              <div className="rounded-2xl border border-border bg-surface p-4">
                <h2 className="text-sm font-semibold">Region</h2>
                <p className="mt-1 text-sm font-medium">{region.name}</p>
                <p className="mt-1 text-xs text-text-secondary">
                  {region.teaser}
                </p>
                <Link
                  href={`/regions/${region.slug}`}
                  className="mt-3 inline-block text-xs font-semibold text-chrome hover:underline"
                >
                  Alle Touren in {region.name} →
                </Link>
              </div>
            )}
            <div className="rounded-2xl border border-border bg-surface p-4">
              <h2 className="text-sm font-semibold">Disziplinen</h2>
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
              <h2 className="text-sm font-semibold">Guides</h2>
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
              <h2 className="text-xl font-bold">Ähnliche Touren</h2>
              <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {related.map((r) => (
                  <Link
                    key={r.id}
                    href={`/tours/${r.id}`}
                    className="rounded-2xl border border-border bg-background p-4 transition hover:border-chrome/40"
                  >
                    <p className="text-[11px] uppercase tracking-wide text-chrome">
                      {bikeCategoryLabel(r.primaryCategory)}
                    </p>
                    <h3 className="mt-1 font-semibold">{r.name}</h3>
                    <p className="mt-1 text-xs text-text-secondary">
                      {r.distanceKm} km · {r.elevationM} hm
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
