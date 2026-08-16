import type { Metadata } from "next";
import Link from "next/link";
import { listRegions } from "@/lib/catalog/regions";
import { listToursByRegion } from "@/lib/catalog/publicTours";

export const metadata: Metadata = {
  title: "Regionen – Tour-Ideen, Nähe, keine Füll-Routen",
  description:
    "Touren-Ideen nach Region: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Elsass und mehr. Die Kartenabdeckung steht unter Karten.",
};

export default function RegionsIndexPage() {
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
          Regionen
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">
          Redaktionelle Tour-Ideen nach Gebiet: Baden-Württemberg, Schwarzwald,
          Bayern, Bodensee, Norddeutschland, Berlin, NRW, Österreich, Schweiz.
          Die Stunde vor dem Tor kommt aus echten Nähe-Seeds — Hamburg Alster,
          nicht pauschal Alpen. Wo noch keine Touren stehen, gilt die Karte vor
          Ort. Es gibt keine Füll-Routen, damit die Liste voll wirkt.
        </p>
        <p className="mt-4 max-w-2xl text-sm text-text-secondary">
          Wo MapLibre wirklich ein Blatt hat — DACH, Frankreich, Alpen-Süd,
          Benelux, Norditalien, Katalonien/Pyrenäen, Südengland — steht unter{" "}
          <Link href="/karten" className="font-semibold text-chrome hover:underline">
            Karten
          </Link>
          . Regionen hier sind Ideen, keine Länder-Downloads.
        </p>
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
                <p className="mt-4 text-xs font-medium text-chrome">
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
