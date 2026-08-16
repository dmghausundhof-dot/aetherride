import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getGuide, listGuideSlugs } from "@/lib/content/guides";
import {
  breadcrumbJsonLd,
  guideArticleJsonLd,
  siteOrigin,
} from "@/lib/content/siteJsonLd";
import { GuideArticleBody } from "@/components/landing/GuideArticleBody";

type Props = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return listGuideSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const g = getGuide(slug);
  if (!g) return { title: "Guide" };
  return {
    title: g.title,
    description: g.teaser,
    openGraph: { title: g.title, description: g.teaser },
  };
}

export default async function GuidePage({ params }: Props) {
  const { slug } = await params;
  const g = getGuide(slug);
  if (!g) notFound();
  const origin = siteOrigin();

  return (
    <article className="mx-auto max-w-2xl px-4 py-12 sm:px-6">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(guideArticleJsonLd(origin, g)),
        }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd(origin, [
              { name: "Guides", path: "/guides" },
              { name: g.title, path: `/guides/${g.slug}` },
            ]),
          ),
        }}
      />
      <GuideArticleBody slug={slug} />
    </article>
  );
}
