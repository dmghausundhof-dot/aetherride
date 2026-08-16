"use client";

import Link from "next/link";
import { listRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";

export function RegionsIndexBody() {
  const c = catalogCopy(useChromeLang()).regions;
  const regions = listRegions()
    .map((r) => ({ region: r, count: listToursByRegion(r.slug).length }))
    .sort(
      (a, b) =>
        b.count - a.count || a.region.name.localeCompare(b.region.name, "de"),
    );

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {c.title}
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">{c.lead}</p>
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {regions.map(({ region: r, count }) => {
            return (
              <Link
                key={r.slug}
                href={`/regions/${r.slug}`}
                className="rounded-2xl border border-border bg-surface p-6 transition hover:border-chrome/40"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                  {r.country}
                </p>
                <h2 className="mt-1 text-xl font-semibold">{r.name}</h2>
                <p className="mt-2 text-sm text-text-secondary">{r.teaser}</p>
                <p className="mt-4 text-xs font-medium text-text-secondary">
                  {count === 0
                    ? c.noneOnMap
                    : c.toursLine(count, r.sports.join(" · "))}
                </p>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}
