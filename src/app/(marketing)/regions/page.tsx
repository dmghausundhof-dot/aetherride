import type { Metadata } from "next";
import Link from "next/link";
import { listRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";

export const metadata: Metadata = {
  title: "Regionen – Radtouren entdecken",
  description:
    "Touren-Ideen nach Region: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Elsass und mehr.",
};

export default function RegionsIndexPage() {
  const regions = listRegions();

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Regionen
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">
          Redaktionelle Tour-Ideen nach Gebiet. Die Stunde vor dem Tor kommt
          aus echten Nähe-Seeds — Hamburg Alster, nicht pauschal Alpen. Wo
          noch keine Touren stehen, gilt die Karte vor Ort — keine Füll-Routen.
        </p>
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {regions.map((r) => {
            const count = listToursByRegion(r.slug).length;
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
                <p className="mt-4 text-xs font-medium text-accent">
                  {count === 0
                    ? `Noch keine Touren · auf der Karte suchen`
                    : `${count} Touren · ${r.sports.join(" · ")}`}
                </p>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}
