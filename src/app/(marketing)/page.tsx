import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { LandingHero } from "@/components/landing/LandingHero";
import { ServiceCheckSection } from "@/components/landing/ServiceCheckSection";
import Link from "next/link";
import { Home, Map, BookOpen, Smartphone, Store, Wrench } from "lucide-react";
import {
  PRODUCT_DOORS,
  JOURNEY,
  WEB_SURFACES,
  APP_SURFACES,
} from "@/lib/content/productMap";

const DOOR_ICONS = [Home, Map, BookOpen, Wrench, Store] as const;

export default function LandingPage() {
  return (
    <>
      <LandingHero />

      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-2xl font-bold sm:text-3xl">
            Fünf Türen am Hof
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-center text-sm text-text-secondary">
            Der Hof ist der Stand. Alles andere ist eine Tür — nicht ein Stapel
            Karten auf derselben Fläche. Ride ist kein Tab.
          </p>
          <div className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {PRODUCT_DOORS.map((p, i) => {
              const Icon = DOOR_ICONS[i];
              return (
                <Link
                  key={p.title}
                  href={p.href}
                  className="group rounded-2xl border border-border bg-background/60 p-5 transition hover:border-chrome/50 hover:bg-background"
                >
                  <Icon className="h-5 w-5 text-chrome" />
                  <h3 className="mt-3 font-semibold">{p.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{p.body}</p>
                </Link>
              );
            })}
          </div>
          <p className="mt-8 text-center text-sm">
            <Link href="/produkt" className="font-semibold text-chrome hover:underline">
              Alle Screens und Abläufe →
            </Link>
          </p>
        </div>
      </section>

      <section className="py-16 px-4">
        <div className="mx-auto grid max-w-6xl gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-border bg-surface p-8">
            <Map className="h-8 w-8 text-chrome" />
            <h3 className="mt-4 text-xl font-bold">Auf der Website</h3>
            <ul className="mt-4 space-y-2 text-sm text-text-secondary">
              {WEB_SURFACES.map((s) => (
                <li key={s.title}>
                  · {s.title} — {s.body}
                </li>
              ))}
            </ul>
            <div className="mt-6 flex flex-wrap gap-4">
              <Link
                href="/home"
                className="text-sm font-semibold text-chrome hover:underline"
              >
                Zum Hof →
              </Link>
              <Link
                href="/discover"
                className="text-sm font-semibold text-chrome hover:underline"
              >
                Karte →
              </Link>
            </div>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-8">
            <Smartphone className="h-8 w-8 text-chrome" />
            <h3 className="mt-4 text-xl font-bold">In der App</h3>
            <ul className="mt-4 space-y-2 text-sm text-text-secondary">
              {APP_SURFACES.map((s) => (
                <li key={s.title}>
                  · {s.title} — {s.body}
                </li>
              ))}
            </ul>
            <Link
              href="/download"
              className="mt-6 inline-block text-sm font-semibold text-chrome hover:underline"
            >
              App herunterladen →
            </Link>
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface py-14 px-4">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <h2 className="text-2xl font-bold sm:text-3xl">Vor dem Tor</h2>
              <p className="mt-2 text-sm text-text-secondary">
                Echte DACH-Nähe — Hamburg Alster, nicht pauschal Alpen.
              </p>
            </div>
            <Link
              href="/regions"
              className="text-sm font-semibold text-chrome hover:underline"
            >
              Regionen →
            </Link>
          </div>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {[
              { slug: "schwarzwald", name: "Schwarzwald" },
              { slug: "rhein-neckar", name: "Rhein-Neckar" },
              { slug: "bayern", name: "Bayern" },
              { slug: "bodensee", name: "Bodensee" },
            ].map((r) => (
              <Link
                key={r.slug}
                href={`/regions/${r.slug}`}
                className="rounded-2xl border border-border bg-background/60 px-4 py-4 font-medium transition hover:border-chrome/40"
              >
                {r.name}
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="py-16 px-4">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-center text-3xl font-bold">So funktioniert’s</h2>
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

      <ServiceCheckSection />

      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-2xl font-bold sm:text-3xl">
            Das Rad steht. Du kommst zurück.
          </h2>
          <p className="mt-4 text-text-secondary">
            Öffne den Hof im Browser oder lade die App für Navigation und Uhr.
          </p>
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
            </div>
            <AppDownloadButtons size="lg" />
          </div>
          <p className="mt-6 text-sm text-text-secondary">
            Schon ein Rad?{" "}
            <Link href="/garage" className="text-chrome hover:underline">
              Zur Werkstatt
            </Link>
            {" · "}
            <Link href="/guides" className="text-chrome hover:underline">
              Guides
            </Link>
            {" · "}
            <Link href="/produkt" className="text-chrome hover:underline">
              Produkt
            </Link>
          </p>
        </div>
      </section>
    </>
  );
}
