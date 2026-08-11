import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import Link from "next/link";
import {
  Bike,
  Compass,
  Map,
  Settings2,
  Smartphone,
  Wrench,
} from "lucide-react";

const sports = [
  {
    href: "/discover?sport=road",
    label: "Rennrad",
    blurb: "Asphalt, Radwege, Höhenmeter",
  },
  {
    href: "/discover?sport=gravel",
    label: "Gravel",
    blurb: "Schotter, Forstwege, Mix",
  },
  {
    href: "/discover?sport=mtb",
    label: "Mountainbike",
    blurb: "Trails, Singletracks, Parks",
  },
  {
    href: "/discover?sport=urban",
    label: "City & Alltag",
    blurb: "Pendeln, Radinfra, kurze Runden",
  },
  {
    href: "/discover?sport=ebike",
    label: "E-Bike",
    blurb: "Touring, E-MTB, Reichweite",
  },
  {
    href: "/discover?sport=touring",
    label: "Radreise",
    blurb: "Etappen, Fernradwege, Planung",
  },
];

const features = [
  {
    icon: Compass,
    title: "Touren & planen",
    description:
      "Touren entdecken, filtern und am großen Bildschirm planen — MTB, Gravel, Rennrad, City, E-Bike.",
  },
  {
    icon: Smartphone,
    title: "Navigieren in der App",
    description:
      "Turn-by-turn, Offline und Sensoren laufen nativ auf Android & iOS — nicht im Browser.",
  },
  {
    icon: Settings2,
    title: "Garage & Setup",
    description:
      "Mehrere Bikes, Kompatibilität, OEM-Vorlagen und ehrliche Verschleißspannen.",
  },
  {
    icon: Wrench,
    title: "Honesty-first",
    description:
      "Keine Fake-Community-Daten. Begründete Vorschläge. Demo klar gekennzeichnet.",
  },
];

const steps = [
  {
    n: "1",
    title: "Disziplin wählen & Tour finden",
    body: "Touren öffnen — Rennrad, Gravel, MTB, City oder E-Bike. Filter und Karte am Desktop.",
  },
  {
    n: "2",
    title: "Bike in der Garage anlegen",
    body: "Katalog oder Basis — Setup und Wartung, die zu deinem Rad passen.",
  },
  {
    n: "3",
    title: "In der App fahren",
    body: "Route speichern, App laden, navigieren und aufzeichnen. Danach Analyse & Setup.",
  },
];

export default function LandingPage() {
  return (
    <>
      {/* Hero */}
      <section className="relative flex min-h-[78vh] items-center justify-center px-4 py-16">
        <div className="absolute inset-0 bg-gradient-to-b from-primary/20 via-background to-background" />
        <div className="relative z-10 mx-auto max-w-4xl text-center">
          <p className="mb-4 text-sm font-medium uppercase tracking-wider text-accent">
            Für alle Fahrradfahrer
          </p>
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
            Touren planen.
            <br />
            <span className="text-accent">Bike verstehen.</span>
            <br />
            Besser fahren.
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-text-secondary sm:text-xl">
            AetherRide verbindet Discover, Multi-Bike-Garage und Setup — für
            Rennrad, Gravel, MTB, E-Bike und City. Navigation und Sensoren laufen
            in der nativen App.
          </p>
          <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <Link
              href="/discover"
              className="inline-flex h-14 items-center justify-center rounded-xl bg-accent px-8 text-base font-semibold text-white transition hover:bg-accent-hover"
            >
              Touren entdecken
            </Link>
            <Link
              href="/download"
              className="inline-flex h-14 items-center justify-center rounded-xl border border-border bg-surface px-8 text-base font-semibold text-foreground transition hover:bg-surface-elevated"
            >
              App laden
            </Link>
          </div>
          <p className="mt-6 text-sm text-text-secondary">
            Website = Planung & Garage · App = Navigation & Sensoren
          </p>
        </div>
      </section>

      {/* Sport picker */}
      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-2xl font-bold sm:text-3xl">
            Deine Disziplin. Gleichwertig.
          </h2>
          <p className="mx-auto mt-3 max-w-xl text-center text-sm text-text-secondary">
            Kein MTB-only-Produkt — Filter, Profile und Touren für jede Art zu
            fahren.
          </p>
          <div className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {sports.map((s) => (
              <Link
                key={s.label}
                href={s.href}
                className="group rounded-2xl border border-border bg-background/60 p-5 transition hover:border-accent/50 hover:bg-background"
              >
                <div className="flex items-center gap-3">
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/30 text-accent group-hover:bg-accent/20">
                    <Bike className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="font-semibold">{s.label}</h3>
                    <p className="text-sm text-text-secondary">{s.blurb}</p>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Platform split */}
      <section className="py-16 px-4">
        <div className="mx-auto grid max-w-6xl gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-border bg-surface p-8">
            <Map className="h-8 w-8 text-accent" />
            <h3 className="mt-4 text-xl font-bold">Auf der Website</h3>
            <ul className="mt-4 space-y-2 text-sm text-text-secondary">
              <li>· Touren entdecken & Desktop-Planer</li>
              <li>· Öffentliche Tour- & Regionenseiten</li>
              <li>· Multi-Bike-Garage, Setup, Wartung</li>
              <li>· Bibliothek, GPX, Sammlungen</li>
              <li>· Shop mit Kompatibilitäts-Urteil</li>
            </ul>
            <div className="mt-6 flex flex-wrap gap-4">
              <Link
                href="/discover"
                className="text-sm font-semibold text-accent hover:underline"
              >
                Touren →
              </Link>
              <Link
                href="/planner"
                className="text-sm font-semibold text-accent hover:underline"
              >
                Planen →
              </Link>
              <Link
                href="/regions"
                className="text-sm font-semibold text-accent hover:underline"
              >
                Regionen →
              </Link>
            </div>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-8">
            <Smartphone className="h-8 w-8 text-accent" />
            <h3 className="mt-4 text-xl font-bold">In der App</h3>
            <ul className="mt-4 space-y-2 text-sm text-text-secondary">
              <li>· Turn-by-turn Navigation & Offline</li>
              <li>· GPS-Aufzeichnung im Hintergrund</li>
              <li>· Sensor-Fusion & Bosch LDI</li>
              <li>· Live-Hints während der Fahrt</li>
            </ul>
            <Link
              href="/download"
              className="mt-6 inline-block text-sm font-semibold text-accent hover:underline"
            >
              App herunterladen →
            </Link>
          </div>
        </div>
      </section>

      {/* Regions teaser */}
      <section className="border-t border-border bg-surface py-14 px-4">
        <div className="mx-auto max-w-6xl">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <h2 className="text-2xl font-bold sm:text-3xl">Regionen</h2>
              <p className="mt-2 text-sm text-text-secondary">
                SEO-Touren nach Gebiet — Schwarzwald, Rhein-Neckar, Bayern und mehr.
              </p>
            </div>
            <Link
              href="/regions"
              className="text-sm font-semibold text-accent hover:underline"
            >
              Alle Regionen →
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
                className="rounded-2xl border border-border bg-background/60 px-4 py-4 font-medium transition hover:border-accent/40"
              >
                {r.name}
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-bold">
            Warum AetherRide anders ist
          </h2>
          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((f) => (
              <div
                key={f.title}
                className="rounded-2xl border border-border bg-background/50 p-6"
              >
                <f.icon className="h-6 w-6 text-accent" />
                <h3 className="mt-3 text-lg font-semibold">{f.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">
                  {f.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-16 px-4">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-center text-3xl font-bold">So funktioniert’s</h2>
          <ol className="mt-12 space-y-8">
            {steps.map((s) => (
              <li key={s.n} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-accent text-lg font-bold text-white">
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

      {/* CTA */}
      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-2xl font-bold sm:text-3xl">
            Bereit für die nächste Tour?
          </h2>
          <p className="mt-4 text-text-secondary">
            Entdecke Touren im Browser oder lade die App für Navigation und
            Sensoren.
          </p>
          <div className="mt-8 flex flex-col items-center gap-4">
            <div className="flex flex-wrap justify-center gap-3">
              <Link
                href="/discover"
                className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-8 text-sm font-semibold text-white hover:bg-accent-hover"
              >
                Touren starten
              </Link>
              <Link
                href="/pricing"
                className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold"
              >
                Preise
              </Link>
            </div>
            <AppDownloadButtons size="lg" />
          </div>
          <p className="mt-6 text-sm text-text-secondary">
            Schon einen Account?{" "}
            <Link href="/garage" className="text-accent hover:underline">
              Zur Garage
            </Link>
            {" · "}
            <Link href="/guides" className="text-accent hover:underline">
              Guides
            </Link>
          </p>
        </div>
      </section>
    </>
  );
}
