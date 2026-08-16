import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getRegion, listRegions, neighborRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { relatedGuidesForRegion } from "@/lib/content/guides";
import { listEditorialProfilesForRegion } from "@/lib/community/editorialProfiles";
import { COMMUNITY_EVENTS } from "@/lib/community/seed";
import {
  breadcrumbJsonLd,
  siteOrigin,
} from "@/lib/content/siteJsonLd";

type Props = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return listRegions().map((r) => ({ slug: r.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const region = getRegion(slug);
  if (!region) return { title: "Region" };
  return {
    title: `${region.name} – Radtouren & Ideen`,
    description: region.description,
    openGraph: {
      title: `Radtouren ${region.name}`,
      description: region.teaser,
    },
  };
}

export default async function RegionPage({ params }: Props) {
  const { slug } = await params;
  const region = getRegion(slug);
  if (!region) notFound();

  const tours = listToursByRegion(slug);
  const nearby = neighborRegions(slug);
  const guides = relatedGuidesForRegion(region.sports);
  const profiles = listEditorialProfilesForRegion(slug);
  const events = COMMUNITY_EVENTS.filter((e) => e.regionSlug === slug);
  const origin = siteOrigin();

  return (
    <div>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd(origin, [
              { name: "Regionen", path: "/regions" },
              { name: region.name, path: `/regions/${region.slug}` },
            ]),
          ),
        }}
      />
        <section className="border-b border-border bg-gradient-to-b from-primary/15 to-background px-4 py-14 sm:px-6">
          <div className="mx-auto max-w-6xl">
            <div className="text-xs text-text-secondary">
              <Link href="/regions" className="hover:text-chrome">
                Regionen
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
                className="rounded-xl bg-chrome px-4 py-2.5 text-sm font-semibold text-background"
              >
                Auf der Karte öffnen
              </Link>
              <Link
                href="/planner"
                className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium"
              >
                Planen
              </Link>
            </div>
          </div>
        </section>

        <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
          <h2 className="text-xl font-bold">
            Touren in {region.name}{" "}
            <span className="text-text-secondary">({tours.length})</span>
          </h2>
          {tours.length === 0 ? (
            <div className="mt-4">
              <p className="text-sm text-text-secondary">
                Noch keine redaktionellen Touren in dieser Region. Auf der Karte
                siehst du Nähe vor Ort — ohne Dummy-Routen.
              </p>
              <div className="mt-4 flex flex-wrap gap-3">
                <Link
                  href="/discover"
                  className="text-sm font-semibold text-chrome hover:underline"
                >
                  Karte öffnen →
                </Link>
                <Link
                  href="/planner"
                  className="text-sm font-semibold text-chrome hover:underline"
                >
                  Planen →
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
                  <p className="text-[11px] font-medium uppercase tracking-wide text-chrome">
                    {bikeCategoryLabel(t.primaryCategory)}
                  </p>
                  <h3 className="mt-1 text-lg font-semibold">{t.name}</h3>
                  <p className="mt-2 line-clamp-2 text-xs text-text-secondary">
                    {t.summary}
                  </p>
                  <p className="mt-3 text-xs tabular-nums text-text-secondary">
                    {t.distanceKm} km · {t.elevationM} hm · {t.durationMin} min
                    {t.difficulty !== "—" ? ` · ${t.difficulty}` : ""}
                  </p>
                </Link>
              ))}
            </div>
          )}
        </section>

        {profiles.length > 0 ? (
          <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
            <h2 className="text-xl font-bold">Stimmen aus der Region</h2>
            <p className="mt-1 text-sm text-text-secondary">
              Editorial-Profile, keine GPS-Spuren.
            </p>
            <ul className="mt-4 grid gap-3 sm:grid-cols-2">
              {profiles.map((p) => (
                <li key={p.handle}>
                  <Link
                    href={`/u/${p.handle}`}
                    className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                  >
                    <p className="font-semibold">{p.displayName}</p>
                    <p className="text-xs text-chrome">@{p.handle}</p>
                    <p className="mt-2 text-sm text-text-secondary">{p.bio}</p>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ) : null}

        {events.length > 0 ? (
          <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
            <h2 className="text-xl font-bold">Termine</h2>
            <p className="mt-1 text-sm text-text-secondary">
              Redaktionell — kein erfundenes RSVP.
            </p>
            <ul className="mt-4 space-y-3">
              {events.map((e) => (
                <li
                  key={e.id}
                  className="rounded-2xl border border-border bg-surface p-5"
                >
                  <p className="text-[11px] font-medium uppercase tracking-wide text-chrome">
                    {e.sport} · {e.dateLabel}
                  </p>
                  <h3 className="mt-1 text-lg font-semibold">{e.title}</h3>
                  <p className="mt-2 text-sm text-text-secondary">{e.blurb}</p>
                </li>
              ))}
            </ul>
            <p className="mt-4 text-sm">
              <Link href="/community#events" className="font-semibold text-chrome hover:underline">
                Alle Termine →
              </Link>
            </p>
          </section>
        ) : null}

        {guides.length > 0 ? (
          <section className="mx-auto max-w-6xl px-4 pb-12 sm:px-6">
            <h2 className="text-xl font-bold">Passende Guides</h2>
            <ul className="mt-4 grid gap-3 sm:grid-cols-2">
              {guides.map((g) => (
                <li key={g.slug}>
                  <Link
                    href={`/guides/${g.slug}`}
                    className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                  >
                    <p className="text-[11px] text-text-secondary">
                      {g.readMin} Min.
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
            <h2 className="text-xl font-bold">Nachbarregionen</h2>
            <p className="mt-1 text-sm text-text-secondary">
              Weiterlesen in der Nähe — nicht als GPS-Fill.
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
