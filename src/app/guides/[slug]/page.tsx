import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  GUIDE_CATEGORY_LABEL,
  getGuide,
  listGuideSlugs,
} from "@/lib/content/guides";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";

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

  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1 px-4 py-12 sm:px-6">
        <article className="mx-auto max-w-2xl">
          <div className="text-xs text-text-secondary">
            <Link href="/guides" className="hover:text-accent">
              Guides
            </Link>
            <span className="mx-1.5">/</span>
            <span>{GUIDE_CATEGORY_LABEL[g.category]}</span>
          </div>
          <h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">
            {g.title}
          </h1>
          <p className="mt-3 text-text-secondary">{g.teaser}</p>
          <p className="mt-2 text-[11px] text-text-secondary">
            {g.readMin} Min. Lesezeit
          </p>
          <div className="mt-10 space-y-5 text-sm leading-relaxed text-foreground/95">
            {g.body.map((p, i) => (
              <p key={i} className="text-text-secondary">
                {p}
              </p>
            ))}
          </div>
          {g.relatedHrefs && g.relatedHrefs.length > 0 && (
            <div className="mt-12 rounded-2xl border border-border bg-surface p-5">
              <h2 className="text-sm font-semibold">Weiter</h2>
              <ul className="mt-3 space-y-2">
                {g.relatedHrefs.map((r) => (
                  <li key={r.href}>
                    <Link
                      href={r.href}
                      className="text-sm font-medium text-accent hover:underline"
                    >
                      {r.label} →
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </article>
      </main>
      <LandingFooter />
    </div>
  );
}
