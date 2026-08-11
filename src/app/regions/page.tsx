import type { Metadata } from "next";
import Link from "next/link";
import { listRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";

export const metadata: Metadata = {
  title: "Regionen – Radtouren entdecken",
  description:
    "Touren-Ideen nach Region: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Elsass und mehr.",
};

export default function RegionsIndexPage() {
  const regions = listRegions();

  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1 px-4 py-12 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Regionen
          </h1>
          <p className="mt-3 max-w-2xl text-text-secondary">
            Redaktionelle Tour-Ideen nach Gebiet — Rennrad, Gravel, MTB, City und
            Touring gleichwertig. Plane im Desktop-Planner, fahre in der App.
          </p>
          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {regions.map((r) => {
              const count = listToursByRegion(r.slug).length;
              return (
                <Link
                  key={r.slug}
                  href={`/regions/${r.slug}`}
                  className="rounded-2xl border border-border bg-surface p-6 transition hover:border-accent/40"
                >
                  <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                    {r.country}
                  </p>
                  <h2 className="mt-1 text-xl font-semibold">{r.name}</h2>
                  <p className="mt-2 text-sm text-text-secondary">{r.teaser}</p>
                  <p className="mt-4 text-xs font-medium text-accent">
                    {count} Touren · {r.sports.join(" · ")}
                  </p>
                </Link>
              );
            })}
          </div>
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
