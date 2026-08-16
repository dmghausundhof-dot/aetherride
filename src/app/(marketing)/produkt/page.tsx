import type { Metadata } from "next";
import Link from "next/link";
import {
  PRODUCT_DOORS,
  WEB_SURFACES,
  APP_SURFACES,
  WEB_APP_MATRIX,
  JOURNEY,
  WORKFLOWS,
  SCREEN_GROUPS,
} from "@/lib/content/productMap";
import { ScreenGallery } from "@/components/landing/ScreenGallery";
import { Home, Map, BookOpen, Wrench, Store, Smartphone } from "lucide-react";

export const metadata: Metadata = {
  title: "Produkt – Screens, Abläufe, Web und App",
  description:
    "FlowLine: fünf Türen am Hof, Fahrt in der App. Alle Screens, Prozesse und Workflows — ehrlich getrennt.",
};

const DOOR_ICONS = [Home, Map, BookOpen, Wrench, Store] as const;

export default function ProduktPage() {
  return (
    <div>
      <section className="border-b border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-chrome">
            Produkt
          </p>
          <h1 className="mt-2 max-w-3xl text-3xl font-bold tracking-tight sm:text-4xl">
            Web ist der Hof. Die App fährt.
          </h1>
          <p className="mt-4 max-w-2xl text-text-secondary">
            Dieselbe Anwendung, zwei Oberflächen. Im Browser planst, pflegst und
            teilst du: Hof, Karte, Platz, Werkstatt, Laden-Tür. Auf dem Gerät
            navigierst, zeichnest und koppelst du. Es gibt keinen Feed, keine
            zweite Kasse und kein Fake-GPS im Tab — leere Flächen bleiben leer.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-background"
            >
              Zum Hof
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              App laden
            </Link>
            <Link
              href="/anmelden"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              Anmelden
            </Link>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Fünf Türen am Hof</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            Ride ist kein Tab. Der Laden ist eine Tür zu Shopify, kein zweiter
            Shop.
          </p>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {PRODUCT_DOORS.map((door, i) => {
              const Icon = DOOR_ICONS[i];
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/50"
                >
                  <Icon className="h-5 w-5 text-chrome" />
                  <h3 className="mt-3 font-semibold">{door.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{door.body}</p>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <ScreenGallery
        heading="Screens"
        hint="Design-System aus Logo und Bilder, zugeordnet zu den Türen. Ride-HUD bleibt die App."
      />

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-border bg-background/60 p-8">
            <Map className="h-8 w-8 text-chrome" />
            <h2 className="mt-4 text-xl font-bold">Auf der Website</h2>
            <ul className="mt-4 space-y-3 text-sm text-text-secondary">
              {WEB_SURFACES.map((s) => (
                <li key={s.title}>
                  <span className="font-medium text-foreground">{s.title}.</span>{" "}
                  {s.body}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-2xl border border-border bg-background/60 p-8">
            <Smartphone className="h-8 w-8 text-chrome" />
            <h2 className="mt-4 text-xl font-bold">In der App</h2>
            <ul className="mt-4 space-y-3 text-sm text-text-secondary">
              {APP_SURFACES.map((s) => (
                <li key={s.title}>
                  <span className="font-medium text-foreground">{s.title}.</span>{" "}
                  {s.body}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Was wo läuft</h2>
          <div className="mt-8 overflow-x-auto rounded-2xl border border-border">
            <table className="w-full min-w-[420px] text-left text-sm">
              <thead>
                <tr className="border-b border-border bg-surface">
                  <th className="px-4 py-3 font-semibold">Fläche</th>
                  <th className="px-4 py-3 font-semibold">Web</th>
                  <th className="px-4 py-3 font-semibold">App</th>
                </tr>
              </thead>
              <tbody>
                {WEB_APP_MATRIX.map((row) => (
                  <tr key={row.feature} className="border-b border-border/80">
                    <td className="px-4 py-3 text-text-secondary">
                      {row.feature}
                    </td>
                    <td className="px-4 py-3">{row.web}</td>
                    <td className="px-4 py-3">{row.app}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-center text-2xl font-bold">So kommst du raus</h2>
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

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Prozesse</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            Jeder Ablauf endet an einer echten Tür — nicht an einer leeren
            Seite.
          </p>
          <div className="mt-8 grid gap-4 lg:grid-cols-2">
            {WORKFLOWS.map((flow) => (
              <article
                key={flow.id}
                className="rounded-2xl border border-border bg-surface p-6"
              >
                <h3 className="font-semibold">{flow.title}</h3>
                <p className="mt-1 text-sm text-text-secondary">{flow.hint}</p>
                <ol className="mt-4 flex flex-wrap gap-2">
                  {flow.steps.map((step, i) => (
                    <li key={step.href} className="flex items-center gap-2">
                      {i > 0 ? (
                        <span className="text-text-secondary" aria-hidden>
                          →
                        </span>
                      ) : null}
                      <Link
                        href={step.href}
                        className="rounded-full border border-border px-3 py-1 text-xs font-semibold hover:border-chrome hover:text-chrome"
                      >
                        {step.label}
                      </Link>
                    </li>
                  ))}
                </ol>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Alle Screens</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            Öffentliche Website und Hof-App. Ride-HUD bleibt nativ.
          </p>
          <div className="mt-10 space-y-10">
            {SCREEN_GROUPS.map((group) => (
              <div key={group.title}>
                <h3 className="text-lg font-semibold">{group.title}</h3>
                <p className="mt-1 text-sm text-text-secondary">{group.hint}</p>
                <ul className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  {group.screens.map((screen) => (
                    <li key={`${group.title}-${screen.href}`}>
                      <Link
                        href={screen.href}
                        className="block rounded-2xl border border-border bg-background/60 p-4 transition hover:border-chrome/40"
                      >
                        <p className="font-medium">{screen.name}</p>
                        <p className="mt-1 text-xs text-text-secondary">
                          {screen.role}
                        </p>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-2xl font-bold">Das Rad steht. Du kommst zurück.</h2>
          <p className="mt-4 text-text-secondary">
            Öffne den Hof im Browser oder lade die App für Navigation und Uhr.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center rounded-xl bg-chrome px-8 text-sm font-semibold text-background"
            >
              Zum Hof
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              App laden
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
