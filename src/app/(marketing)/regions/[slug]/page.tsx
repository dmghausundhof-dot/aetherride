import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getRegion, listRegions } from "@/lib/catalog/regions";
import { RegionPageBody } from "@/components/landing/RegionPageBody";
import { breadcrumbJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

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
      <RegionPageBody slug={slug} />
    </div>
  );
}
