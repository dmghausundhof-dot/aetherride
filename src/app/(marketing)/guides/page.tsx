import type { Metadata } from "next";
import Link from "next/link";
import { listGuidesGrouped } from "@/lib/content/guides";

export const metadata: Metadata = {
  title: "Guides – Planung, Setup & E-Bike",
  description:
    "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite, Setup, Hof und Platz — ehrlich erklärt.",
};

export default function GuidesIndexPage() {
  const groups = listGuidesGrouped();

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Guides
        </h1>
        <p className="mt-3 text-text-secondary">
          Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen,
          Reichweite als Spanne, Setup nach Gewicht, der Hof mit fünf Türen,
          Teilen per Link, der Laden ohne zweite Kasse. Kein Affiliate-Clickbait
          — was im Produkt fehlt, steht hier nicht als Versprechen.
        </p>
        <div className="mt-10 space-y-10">
          {groups.map((group) => (
            <section key={group.category}>
              <h2 className="text-sm font-semibold uppercase tracking-wide text-chrome">
                {group.label}
              </h2>
              <ul className="mt-3 space-y-3">
                {group.guides.map((g) => (
                  <li key={g.slug}>
                    <Link
                      href={`/guides/${g.slug}`}
                      className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                    >
                      <p className="text-[11px] text-text-secondary">
                        {g.readMin} Min. Lesezeit
                      </p>
                      <h3 className="mt-1 text-lg font-semibold">{g.title}</h3>
                      <p className="mt-1 text-sm text-text-secondary">
                        {g.teaser}
                      </p>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </div>
    </div>
  );
}
