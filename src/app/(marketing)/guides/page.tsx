import type { Metadata } from "next";
import Link from "next/link";
import {
  GUIDE_CATEGORY_LABEL,
  listGuides,
} from "@/lib/content/guides";

export const metadata: Metadata = {
  title: "Guides – Planung, Setup & E-Bike",
  description:
    "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite, Setup und Wartung — ehrlich erklärt.",
};

export default function GuidesIndexPage() {
  const guides = listGuides();

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Guides
        </h1>
        <p className="mt-3 text-text-secondary">
          Ratgeber für Rennrad, Gravel, MTB und E-Bike. Hof, Karte, Werkstatt
          — ehrlich erklärt, kein Affiliate-Clickbait.
        </p>
        <ul className="mt-10 space-y-4">
          {guides.map((g) => (
            <li key={g.slug}>
              <Link
                href={`/guides/${g.slug}`}
                className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <div className="flex flex-wrap items-center gap-2 text-[11px] text-text-secondary">
                  <span className="font-medium uppercase tracking-wide text-chrome">
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
    </div>
  );
}
