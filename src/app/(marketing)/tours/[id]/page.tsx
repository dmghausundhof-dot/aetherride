import type { Metadata } from "next";
import { notFound } from "next/navigation";
import {
  listPublicTourIds,
  tourJsonLd,
} from "@/lib/catalog/publicTours";
import { getRegion } from "@/lib/catalog/regions";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { TourPageBody } from "@/components/tours/TourPageBody";
import { SeedTourPageBody } from "@/components/tours/SeedTourPageBody";
import { resolveTourPage } from "@/lib/tours/tourPageResolve";
import { breadcrumbJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

type Props = { params: Promise<{ id: string }> };

export function generateStaticParams() {
  return listPublicTourIds().map((id) => ({ id }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const resolved = resolveTourPage(id);
  if (!resolved) return { title: "Tour nicht gefunden" };
  if (resolved.kind === "seed") {
    const seed = resolved.seed.suggestion;
    const summary = resolved.seed.notes || seed.name;
    return {
      title: `${seed.name} – ${bikeCategoryLabel(seed.category)}`,
      description: summary,
      openGraph: {
        title: seed.name,
        description: summary,
        type: "article",
        locale: "de_DE",
      },
    };
  }
  const tour = resolved.tour;
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
  const resolved = resolveTourPage(id);
  if (!resolved) notFound();

  if (resolved.kind === "seed") {
    return <SeedTourPageBody id={id} />;
  }

  const tour = resolved.tour;
  const region = getRegion(tour.regionSlug);
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
      <TourPageBody id={id} />
    </div>
  );
}
