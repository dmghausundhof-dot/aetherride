import Link from "next/link";
import { ONLINE_BASEMAP_RIDER } from "@/lib/map/onlineBasemap";
import {
  loadOfflineCoverageStats,
  type OfflineCoverageStats,
} from "@/lib/map/offlineCoverage";
import { HOME_MAPS } from "@/lib/content/homepage";
import { offlinePacksSentence } from "@/lib/content/kartenCopy";

function KartenCoverageView({
  stats,
}: {
  stats: OfflineCoverageStats | null;
}) {
  const envelopeRegions = stats?.envelopeRegions ?? 0;
  const packsLine = offlinePacksSentence({
    readyPacks: stats?.readyPacks ?? null,
    envelopeRegions,
  });

  return (
    <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div className="max-w-2xl">
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              {HOME_MAPS.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
              {HOME_MAPS.title}
            </h2>
            <p className="mt-3 text-sm text-text-secondary">{HOME_MAPS.lead}</p>
          </div>
          <Link
            href="/karten"
            className="text-sm font-semibold text-chrome hover:underline"
          >
            Karten im Detail →
          </Link>
        </div>

        <div className="mt-8 grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl border border-border bg-background/60 p-6">
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              Online
            </p>
            <h3 className="mt-1 text-lg font-semibold">Basemap, gestreamt</h3>
            <p className="mt-2 text-sm text-text-secondary">
              Neun Blätter auf dem CDN. In DACH: Atlas plus Wege ab Zoom 12
              für DE, AT, CH und LI. Die Karte wechselt mit dem Ausschnitt —
              das ist kein Download von Europa.
            </p>
          </div>
          <div className="rounded-2xl border border-border bg-background/60 p-6">
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              Offline
            </p>
            <h3 className="mt-1 text-lg font-semibold">Packs für die Stadt</h3>
            <p className="mt-2 text-sm text-text-secondary">{packsLine}</p>
          </div>
        </div>

        <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {ONLINE_BASEMAP_RIDER.map((r) => (
            <Link
              key={r.id}
              href={`/karten#${r.id}`}
              className="rounded-2xl border border-border bg-background/60 p-5 transition hover:border-chrome/40"
            >
              <h3 className="font-semibold">{r.name}</h3>
              <p className="mt-1 text-[11px] text-text-secondary">{r.area}</p>
              <p className="mt-2 text-sm text-text-secondary">{r.teaser}</p>
              <p className="mt-3 text-xs text-text-secondary">{r.hole}</p>
            </Link>
          ))}
        </div>

        <p className="mt-6 text-sm text-text-secondary">
          <Link href="/discover" className="font-semibold text-chrome hover:underline">
            Karte öffnen
          </Link>
          {" · "}
          <Link href="/regions" className="font-semibold text-chrome hover:underline">
            Tour-Ideen
          </Link>
          {" · "}
          <Link href="/download" className="font-semibold text-chrome hover:underline">
            Packs in der App
          </Link>
        </p>
      </div>
    </section>
  );
}

export function KartenCoverageFallback() {
  return <KartenCoverageView stats={null} />;
}

export async function KartenCoverageSection() {
  const stats = await loadOfflineCoverageStats();
  return <KartenCoverageView stats={stats} />;
}
