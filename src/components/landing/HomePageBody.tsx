import Link from "next/link";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { Home, Map, BookOpen, Smartphone, Store, Wrench } from "lucide-react";
import {
  APP_SURFACES,
  JOURNEY,
  WEB_SURFACES,
} from "@/lib/content/productMap";
import { FAQ_ITEMS } from "@/lib/content/faq";
import { getGuide } from "@/lib/content/guides";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { getPublicTour, featuredPublicTours } from "@/lib/catalog/publicTours";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import {
  HOME_CTA,
  HOME_DISCIPLINES,
  HOME_DOOR_STORIES,
  HOME_FAQ_IDS,
  HOME_GUIDES,
  HOME_HONESTY,
  HOME_INTRO,
  HOME_JOURNEY,
  HOME_PRICING,
  HOME_SPLIT,
  HOME_TOURS,
  HOME_VOICES,
} from "@/lib/content/homepage";

const DOOR_ICONS = [Home, Map, BookOpen, Wrench, Store] as const;

export function HomePageBody() {
  const featured = featuredPublicTours();
  const guides = HOME_GUIDES.slugs
    .map((slug) => getGuide(slug))
    .filter((g): g is NonNullable<typeof g> => g != null);
  const faq = HOME_FAQ_IDS.map((id) => FAQ_ITEMS.find((item) => item.id === id)).filter(
    (item): item is (typeof FAQ_ITEMS)[number] => item != null,
  );
  const voices = EDITORIAL_REVIEWS.slice(0, 4);

  return (
    <>
      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-12">
          <div className="lg:col-span-5">
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              {HOME_INTRO.kicker}
            </p>
            <h2 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {HOME_INTRO.title}
            </h2>
            <p className="mt-4 text-text-secondary">{HOME_INTRO.lead}</p>
          </div>
          <div className="space-y-4 text-sm leading-relaxed text-text-secondary lg:col-span-7">
            {HOME_INTRO.paragraphs.map((p) => (
              <p key={p.slice(0, 24)}>{p}</p>
            ))}
            <div className="flex flex-wrap gap-4 pt-2 text-sm font-semibold">
              <Link href="/produkt" className="text-chrome hover:underline">
                Produktkarte →
              </Link>
              <Link href="/ueber" className="text-chrome hover:underline">
                Über FlowLine →
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold sm:text-3xl">Für welche Räder</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            Eine Anwendung, fünf Türen — nicht fünf Apps. Sport-Filter auf der
            Karte, Setup in der Werkstatt.
          </p>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {HOME_DISCIPLINES.map((d) => (
              <Link
                key={d.title}
                href={d.href}
                className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <h3 className="font-semibold">{d.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{d.body}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold sm:text-3xl">Fünf Türen am Hof</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            Der Hof ist der Stand. Alles andere ist eine Tür — nicht ein Stapel
            Karten. Ride ist kein Tab.
          </p>
          <div className="mt-10 grid gap-4 lg:grid-cols-2">
            {HOME_DOOR_STORIES.slice(0, 2).map((door, i) => {
              const Icon = DOOR_ICONS[i];
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-background/60 p-6 transition hover:border-chrome/50"
                >
                  <Icon className="h-5 w-5 text-chrome" />
                  <p className="mt-4 text-[11px] font-bold tracking-wide text-chrome">
                    {door.kicker}
                  </p>
                  <h3 className="mt-1 text-xl font-semibold">{door.title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                    {door.body}
                  </p>
                </Link>
              );
            })}
          </div>
          <div className="mt-4 grid gap-4 sm:grid-cols-3">
            {HOME_DOOR_STORIES.slice(2).map((door, i) => {
              const Icon = DOOR_ICONS[i + 2];
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-background/60 p-5 transition hover:border-chrome/50"
                >
                  <Icon className="h-5 w-5 text-chrome" />
                  <p className="mt-3 text-[11px] font-bold tracking-wide text-chrome">
                    {door.kicker}
                  </p>
                  <h3 className="mt-1 font-semibold">{door.title}</h3>
                  <p className="mt-2 text-sm text-text-secondary">{door.body}</p>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-chrome">
            {HOME_SPLIT.kicker}
          </p>
          <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
            {HOME_SPLIT.title}
          </h2>
          <div className="mt-8 grid gap-6 md:grid-cols-2">
            <div className="rounded-2xl border border-border bg-surface p-8">
              <Map className="h-8 w-8 text-chrome" />
              <h3 className="mt-4 text-xl font-bold">Auf der Website</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {HOME_SPLIT.webLead}
              </p>
              <ul className="mt-4 space-y-2 text-sm text-text-secondary">
                {WEB_SURFACES.map((s) => (
                  <li key={s.title}>
                    <span className="font-medium text-foreground">{s.title}.</span>{" "}
                    {s.body}
                  </li>
                ))}
              </ul>
              <div className="mt-6 flex flex-wrap gap-4">
                <Link href="/home" className="text-sm font-semibold text-chrome hover:underline">
                  Zum Hof →
                </Link>
                <Link href="/discover" className="text-sm font-semibold text-chrome hover:underline">
                  Karte →
                </Link>
              </div>
            </div>
            <div className="rounded-2xl border border-border bg-surface p-8">
              <Smartphone className="h-8 w-8 text-chrome" />
              <h3 className="mt-4 text-xl font-bold">In der App</h3>
              <p className="mt-3 text-sm leading-relaxed text-text-secondary">
                {HOME_SPLIT.appLead}
              </p>
              <ul className="mt-4 space-y-2 text-sm text-text-secondary">
                {APP_SURFACES.map((s) => (
                  <li key={s.title}>
                    <span className="font-medium text-foreground">{s.title}.</span>{" "}
                    {s.body}
                  </li>
                ))}
              </ul>
              <div className="mt-6 flex flex-wrap gap-4">
                <Link
                  href="/download"
                  className="text-sm font-semibold text-chrome hover:underline"
                >
                  App laden →
                </Link>
                <Link
                  href="/guides/web-vs-app"
                  className="text-sm font-semibold text-chrome hover:underline"
                >
                  Web vs. App →
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-chrome">
                {HOME_TOURS.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
                {HOME_TOURS.title}
              </h2>
              <p className="mt-3 text-sm text-text-secondary">{HOME_TOURS.lead}</p>
            </div>
            <Link href="/regions" className="text-sm font-semibold text-chrome hover:underline">
              Alle Regionen →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {featured.map((t) => (
              <Link
                key={t.id}
                href={`/tours/${t.id}`}
                className="rounded-2xl border border-border bg-background/60 p-4 transition hover:border-chrome/40"
              >
                <p className="text-[11px] font-medium uppercase tracking-wide text-chrome">
                  {bikeCategoryLabel(t.primaryCategory)}
                </p>
                <p className="mt-1 font-medium">{t.name}</p>
                <p className="mt-2 line-clamp-3 text-xs text-text-secondary">
                  {t.summary}
                </p>
                <p className="mt-3 text-xs tabular-nums text-text-secondary">
                  {t.distanceKm} km · {t.elevationM} hm
                </p>
              </Link>
            ))}
          </div>
          <div className="mt-6 flex flex-wrap gap-2">
            {[
              { slug: "norddeutschland", name: "Norddeutschland" },
              { slug: "berlin-brandenburg", name: "Berlin" },
              { slug: "rhein-neckar", name: "Rhein-Neckar" },
              { slug: "schwarzwald", name: "Schwarzwald" },
              { slug: "nrw", name: "NRW" },
              { slug: "oesterreich", name: "Österreich" },
              { slug: "schweiz", name: "Schweiz" },
            ].map((r) => (
              <Link
                key={r.slug}
                href={`/regions/${r.slug}`}
                className="rounded-full border border-border px-3 py-1 text-xs font-medium transition hover:border-chrome/40"
              >
                {r.name}
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <p className="text-center text-[11px] font-bold tracking-wide text-chrome">
            {HOME_JOURNEY.kicker}
          </p>
          <h2 className="mt-2 text-center text-3xl font-bold">
            {HOME_JOURNEY.title}
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-center text-sm text-text-secondary">
            {HOME_JOURNEY.lead}
          </p>
          <ol className="mt-12 space-y-8">
            {JOURNEY.map((s) => (
              <li key={s.n} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-border text-lg font-bold text-chrome">
                  {s.n}
                </span>
                <div>
                  <h3 className="font-semibold">{s.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{s.body}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-chrome">
                {HOME_VOICES.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
                {HOME_VOICES.title}
              </h2>
              <p className="mt-3 text-sm text-text-secondary">{HOME_VOICES.lead}</p>
            </div>
            <Link href="/community" className="text-sm font-semibold text-chrome hover:underline">
              Community →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2">
            {voices.map((r) => {
              const tour = getPublicTour(r.tourId);
              return (
                <blockquote
                  key={r.id}
                  className="rounded-2xl border border-border bg-background/60 p-5"
                >
                  <p className="text-sm leading-relaxed text-foreground/90">
                    „{r.body}“
                  </p>
                  <footer className="mt-4 text-xs text-text-secondary">
                    {r.authorHandle ? (
                      <Link
                        href={`/u/${r.authorHandle}`}
                        className="font-semibold text-chrome hover:underline"
                      >
                        {r.authorLabel}
                      </Link>
                    ) : (
                      <span className="font-semibold">{r.authorLabel}</span>
                    )}
                    <span> · Editorial</span>
                    {tour ? (
                      <>
                        {" · "}
                        <Link
                          href={`/tours/${tour.id}`}
                          className="text-chrome hover:underline"
                        >
                          {tour.name}
                        </Link>
                      </>
                    ) : null}
                  </footer>
                </blockquote>
              );
            })}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="max-w-2xl">
              <p className="text-[11px] font-bold tracking-wide text-chrome">
                {HOME_GUIDES.kicker}
              </p>
              <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
                {HOME_GUIDES.title}
              </h2>
              <p className="mt-3 text-sm text-text-secondary">{HOME_GUIDES.lead}</p>
            </div>
            <Link href="/guides" className="text-sm font-semibold text-chrome hover:underline">
              Alle Guides →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {guides.map((g) => (
              <Link
                key={g.slug}
                href={`/guides/${g.slug}`}
                className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
              >
                <p className="text-[11px] text-text-secondary">
                  {g.readMin} Min.
                </p>
                <h3 className="mt-1 font-semibold">{g.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{g.teaser}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-2">
          <div>
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              FAQ
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
              Kurz und ehrlich
            </h2>
            <p className="mt-3 text-sm text-text-secondary">
              Keine Store-Versprechen, keine erfundenen Adressen.
            </p>
            <dl className="mt-8 space-y-4">
              {faq.map((item) => (
                <div
                  key={item.id}
                  className="rounded-2xl border border-border bg-background/60 p-5"
                >
                  <dt className="font-semibold">{item.q}</dt>
                  <dd className="mt-2 text-sm text-text-secondary">{item.a}</dd>
                </div>
              ))}
            </dl>
            <p className="mt-6 text-sm font-semibold">
              <Link href="/faq" className="text-chrome hover:underline">
                Alle Fragen →
              </Link>
            </p>
          </div>
          <div>
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              {HOME_PRICING.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
              {HOME_PRICING.title}
            </h2>
            <p className="mt-3 text-sm text-text-secondary">{HOME_PRICING.lead}</p>
            <div className="mt-8 grid gap-3">
              <div className="rounded-2xl border border-border bg-background/60 p-5">
                <p className="text-sm font-semibold">Free</p>
                <p className="mt-2 text-sm text-text-secondary">
                  {HOME_PRICING.free}
                </p>
              </div>
              <div className="rounded-2xl border border-chrome/40 bg-chrome/10 p-5">
                <p className="text-sm font-semibold">Pro</p>
                <p className="mt-2 text-sm text-text-secondary">
                  {HOME_PRICING.pro}
                </p>
              </div>
            </div>
            <p className="mt-6 text-sm font-semibold">
              <Link href="/pricing" className="text-chrome hover:underline">
                Preise im Detail →
              </Link>
            </p>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-chrome">
            {HOME_HONESTY.kicker}
          </p>
          <h2 className="mt-2 text-2xl font-bold sm:text-3xl">
            {HOME_HONESTY.title}
          </h2>
          <p className="mt-3 max-w-2xl text-sm text-text-secondary">
            {HOME_HONESTY.lead}
          </p>
          <div className="mt-8 grid gap-4 md:grid-cols-2">
            <div className="rounded-2xl border border-border bg-surface p-6">
              <h3 className="font-semibold">Schon da</h3>
              <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                {HOME_HONESTY.live.map((line) => (
                  <li key={line}>· {line}</li>
                ))}
              </ul>
            </div>
            <div className="rounded-2xl border border-border bg-surface p-6">
              <h3 className="font-semibold">Noch nicht — und nicht erfunden</h3>
              <ul className="mt-3 space-y-2 text-sm text-text-secondary">
                {HOME_HONESTY.notYet.map((line) => (
                  <li key={line}>· {line}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

export function HomePageCta() {
  return (
    <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-2xl text-center">
        <h2 className="text-2xl font-bold sm:text-3xl">{HOME_CTA.title}</h2>
        <p className="mt-4 text-text-secondary">{HOME_CTA.body}</p>
        <div className="mt-8 flex flex-col items-center gap-4">
          <div className="flex flex-wrap justify-center gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center justify-center rounded-xl bg-chrome px-8 text-sm font-semibold text-background hover:bg-chrome/90"
            >
              Zum Hof
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              App laden
            </Link>
            <Link
              href="/anmelden"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              Anmelden
            </Link>
          </div>
          <AppDownloadButtons size="lg" />
        </div>
        <p className="mt-6 text-sm text-text-secondary">
          <Link href="/garage" className="text-chrome hover:underline">
            Werkstatt
          </Link>
          {" · "}
          <Link href="/guides" className="text-chrome hover:underline">
            Guides
          </Link>
          {" · "}
          <Link href="/produkt" className="text-chrome hover:underline">
            Produkt
          </Link>
          {" · "}
          <Link href="/kontakt" className="text-chrome hover:underline">
            Kontakt
          </Link>
        </p>
      </div>
    </section>
  );
}
