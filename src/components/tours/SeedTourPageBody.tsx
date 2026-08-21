"use client";

import Link from "next/link";
import { getP0SeedById } from "@/lib/discover/berlinLoops";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { TourLiveMap } from "@/components/tours/TourLiveMap";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { discoverUi } from "@/lib/i18n/discoverUi";
import { webChrome } from "@/lib/i18n/webChrome";
import { formatDistanceElevation, sanitizeElevationM } from "@/lib/discover/elevationGuard";

export function SeedTourPageBody({ id }: { id: string }) {
  const lang = useChromeLang();
  const copy = catalogCopy(lang);
  const chrome = webChrome(lang);
  const d = discoverUi(lang);
  const seed = getP0SeedById(id);
  if (!seed) return null;

  const tour = seed.suggestion;
  const hasTrack = (seed.geometry?.length ?? 0) >= 2;
  const tourElev = sanitizeElevationM(tour.elevationM, tour.distanceKm);
  const center = tour.center;

  return (
    <div>
      <div className="border-b border-border bg-surface/50">
        <div className="mx-auto grid max-w-6xl gap-0 lg:grid-cols-2">
          <div className="flex flex-col justify-center px-4 py-10 sm:px-6 lg:py-14">
            <div className="flex flex-wrap items-center gap-2 text-xs text-text-secondary">
              <Link href="/discover" className="hover:text-chrome">
                {chrome.hofNav.karte}
              </Link>
              <span>/</span>
              <span className="text-foreground">{tour.name}</span>
            </div>
            <p className="mt-4 text-[11px] font-bold tracking-wide text-text-secondary">
              {copy.tour.seedKicker}
            </p>
            <p className="mt-1 text-xs font-medium uppercase tracking-wide text-text-secondary">
              {bikeCategoryLabel(tour.category)}
              {tour.loop ? ` · ${copy.tour.loop}` : ` · ${copy.tour.stage}`}
            </p>
            <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {tour.name}
            </h1>
            {seed.notes ? (
              <p className="mt-3 text-text-secondary">{seed.notes}</p>
            ) : null}
            <dl className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
              <Stat label={copy.tour.distance} value={`${tour.distanceKm} km`} />
              <Stat
                label={copy.tour.elevation}
                value={tourElev != null ? `${tourElev} hm` : "—"}
              />
              <Stat
                label={copy.tour.duration}
                value={`${tour.durationMin} min`}
              />
              <Stat
                label={copy.tour.difficulty}
                value={
                  tour.mtbScale !== "—" ? tour.mtbScale : copy.tour.roadPath
                }
              />
            </dl>
            <div className="mt-3 flex flex-wrap gap-2 text-[11px]">
              <span className="rounded-full bg-surface-elevated px-2.5 py-1">
                {tour.surface}
              </span>
              <span className="rounded-full border border-border px-2.5 py-1 text-text-secondary">
                {formatDistanceElevation(tour.distanceKm, tourElev)}
              </span>
            </div>
            <div className="mt-8 flex flex-wrap gap-2">
              <Link
                href={`/discover?route=${encodeURIComponent(tour.id)}`}
                className="inline-flex items-center justify-center rounded-xl bg-accent px-4 py-3 text-sm font-semibold text-on-accent"
              >
                {copy.tour.inTours}
              </Link>
              <Link
                href={`/discover?panel=plan&tour=${encodeURIComponent(tour.id)}`}
                className="inline-flex items-center justify-center rounded-xl border border-border px-4 py-3 text-sm font-medium"
              >
                {copy.tour.openPlanner}
              </Link>
            </div>
          </div>
          <div className="relative min-h-[360px] lg:min-h-[560px]">
            {center ? (
              <TourLiveMap
                tourId={tour.id}
                center={center}
                name={tour.name}
                profile={profileForBikeCategory(tour.category)}
                category={tour.category}
                loop={tour.loop}
              />
            ) : (
              <div className="flex h-full min-h-[360px] items-center justify-center bg-surface text-sm text-text-secondary">
                {d.pinOnlyHint}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-10 sm:px-6">
        {!hasTrack ? (
          <p className="text-sm text-text-secondary">{d.pinOnlyHint}</p>
        ) : null}
        {tour.poiStops && tour.poiStops.length > 0 ? (
          <section>
            <h2 className="text-lg font-semibold">{copy.tour.fn.places}</h2>
            <ol className="mt-3 space-y-2 text-sm">
              {tour.poiStops
                .filter((p) => p.atMin > 0)
                .slice(0, 8)
                .map((p) => (
                  <li key={p.id} className="text-text-secondary">
                    <span className="font-semibold text-foreground">
                      {p.atMin} min
                    </span>
                    {" · "}
                    {p.title}
                  </li>
                ))}
            </ol>
          </section>
        ) : null}
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h2 className="text-sm font-semibold">{copy.tour.honestTitle}</h2>
          <p className="mt-2 text-xs leading-relaxed text-text-secondary">
            {copy.tour.seedHonestBody}
          </p>
        </section>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-background/60 px-3 py-2">
      <dt className="text-[10px] uppercase tracking-wide text-text-secondary">
        {label}
      </dt>
      <dd className="mt-0.5 text-sm font-semibold tabular-nums">{value}</dd>
    </div>
  );
}
