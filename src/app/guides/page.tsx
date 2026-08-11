import type { Metadata } from "next";
import Link from "next/link";
import {
  GUIDE_CATEGORY_LABEL,
  listGuides,
} from "@/lib/content/guides";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";

export const metadata: Metadata = {
  title: "Guides – Planung, Setup & E-Bike",
  description:
    "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite, Setup und Wartung — ehrlich erklärt.",
};

export default function GuidesIndexPage() {
  const guides = listGuides();

  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1 px-4 py-12 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Guides
          </h1>
          <p className="mt-3 text-text-secondary">
            Redaktionelle Artikel für alle Fahrradfahrer — Planung, Garage und
            App-Trennung. Keine Affiliate-Clickbait-Versprechen.
          </p>
          <ul className="mt-10 space-y-4">
            {guides.map((g) => (
              <li key={g.slug}>
                <Link
                  href={`/guides/${g.slug}`}
                  className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-accent/40"
                >
                  <div className="flex flex-wrap items-center gap-2 text-[11px] text-text-secondary">
                    <span className="font-medium uppercase tracking-wide text-accent">
                      {GUIDE_CATEGORY_LABEL[g.category]}
                    </span>
                    <span>·</span>
                    <span>{g.readMin} Min. Lesezeit</span>
                  </div>
                  <h2 className="mt-2 text-lg font-semibold">{g.title}</h2>
                  <p className="mt-1 text-sm text-text-secondary">{g.teaser}</p>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
