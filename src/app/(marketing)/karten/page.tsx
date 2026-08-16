import type { Metadata } from "next";
import Link from "next/link";
import { KartenPreview } from "@/components/landing/KartenPreview";
import { KARTEN_PAGE, offlinePacksSentence } from "@/lib/content/kartenCopy";
import {
  MAP_ATTRIBUTION,
  MAP_ATTRIBUTION_HREF,
  ONLINE_BASEMAP_RIDER,
} from "@/lib/map/onlineBasemap";
import { loadOfflineCoverageStats } from "@/lib/map/offlineCoverage";
import { breadcrumbJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

export const metadata: Metadata = {
  title: "Karten – Abdeckung online und offline",
  description: KARTEN_PAGE.description,
};

export default async function KartenPage() {
  const origin = siteOrigin();
  const stats = await loadOfflineCoverageStats();
  const packsLine = offlinePacksSentence({
    readyPacks: stats.readyPacks,
    envelopeRegions: stats.envelopeRegions,
  });

  return (
    <div>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(
            breadcrumbJsonLd(origin, [
              { name: "Karten", path: "/karten" },
            ]),
          ),
        }}
      />

      <section className="border-b border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-chrome">
            {KARTEN_PAGE.kicker}
          </p>
          <h1 className="mt-2 max-w-3xl text-3xl font-bold tracking-tight sm:text-4xl">
            {KARTEN_PAGE.title}
          </h1>
          <p className="mt-4 max-w-2xl text-text-secondary">{KARTEN_PAGE.lead}</p>
          <p className="mt-4 max-w-2xl text-sm text-text-secondary">
            {KARTEN_PAGE.splitNote}
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/discover"
              className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-background"
            >
              Karte öffnen
            </Link>
            <Link
              href="/regions"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              Tour-Ideen
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              App / Packs
            </Link>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{KARTEN_PAGE.onlineTitle}</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            {KARTEN_PAGE.onlineLead}
          </p>
          <div className="mt-8">
            <KartenPreview />
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {ONLINE_BASEMAP_RIDER.map((r) => (
              <article
                key={r.id}
                id={r.id}
                className="scroll-mt-24 rounded-2xl border border-border bg-background/60 p-6"
              >
                <h2 className="text-xl font-semibold">{r.name}</h2>
                <p className="mt-1 text-[11px] uppercase tracking-wide text-text-secondary">
                  {r.area}
                </p>
                <p className="mt-3 text-sm text-text-secondary">{r.teaser}</p>
                <p className="mt-3 text-sm text-text-secondary">{r.hole}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-6 lg:grid-cols-2">
          <div className="rounded-2xl border border-border bg-surface p-8">
            <h2 className="text-xl font-bold">{KARTEN_PAGE.offlineTitle}</h2>
            <p className="mt-3 text-sm leading-relaxed text-text-secondary">
              {KARTEN_PAGE.offlineLead}
            </p>
            <p className="mt-4 text-sm leading-relaxed text-text-secondary">
              {packsLine}
            </p>
            <p className="mt-6 text-sm font-semibold">
              <Link href="/download" className="text-chrome hover:underline">
                Packs in der App →
              </Link>
            </p>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-8">
            <h2 className="text-xl font-bold">{KARTEN_PAGE.holesTitle}</h2>
            <p className="mt-3 text-sm text-text-secondary">
              {KARTEN_PAGE.holesLead}
            </p>
            <ul className="mt-4 space-y-2 text-sm text-text-secondary">
              {KARTEN_PAGE.holes.map((line) => (
                <li key={line}>· {line}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="border-t border-border px-4 py-12 sm:px-6">
        <div className="mx-auto max-w-6xl text-sm text-text-secondary">
          <p>{KARTEN_PAGE.attributionNote}</p>
          <p className="mt-2">
            {MAP_ATTRIBUTION}
            {" · "}
            <a
              href={MAP_ATTRIBUTION_HREF.osm}
              className="text-chrome hover:underline"
              rel="noreferrer"
            >
              OpenStreetMap
            </a>
            {" · "}
            <a
              href={MAP_ATTRIBUTION_HREF.protomaps}
              className="text-chrome hover:underline"
              rel="noreferrer"
            >
              Protomaps
            </a>
          </p>
        </div>
      </section>
    </div>
  );
}
