import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getRegion, listRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";

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

  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1">
        <section className="border-b border-border bg-gradient-to-b from-primary/15 to-background px-4 py-14 sm:px-6">
          <div className="mx-auto max-w-6xl">
            <div className="text-xs text-text-secondary">
              <Link href="/regions" className="hover:text-accent">
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
                  className="rounded-full border border-border bg-surface px-3 py-1 text-xs capitalize hover:border-accent/40"
                >
                  {s}
                </Link>
              ))}
            </div>
            <div className="mt-6 flex flex-wrap gap-3">
              <Link
                href={`/discover`}
                className="rounded-xl bg-accent px-4 py-2.5 text-sm font-semibold text-white"
              >
                In Explore öffnen
              </Link>
              <Link
                href="/planner"
                className="rounded-xl border border-border px-4 py-2.5 text-sm font-medium"
              >
                Planner
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
            <p className="mt-4 text-sm text-text-secondary">
              Noch keine redaktionellen Touren — schau im Planner vorbei.
            </p>
          ) : (
            <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {tours.map((t) => (
                <Link
                  key={t.id}
                  href={`/tours/${t.id}`}
                  className="rounded-2xl border border-border bg-surface p-5 transition hover:border-accent/40"
                >
                  <p className="text-[11px] font-medium uppercase tracking-wide text-accent">
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
      </main>
      <LandingFooter />
    </div>
  );
}
