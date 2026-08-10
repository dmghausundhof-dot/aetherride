import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import Link from "next/link";

const features = [
  {
    title: "Multi-Bike-Garage",
    description:
      "Kompatibilitäts-Engine mit klaren Urteilen und Begründungskette. Mehrere Bikes, Setups und Historie.",
  },
  {
    title: "Bosch LDI + Sensor-Fusion",
    description:
      "Live-Hints, Impact-Detection und Flow-Score – nativ auf dem Gerät, nicht im Browser.",
  },
  {
    title: "Verschleiß & Setup",
    description:
      "Prognose als Spanne, Bracketing und OEM-Vorlagen. Keine Fake-Punktwerte.",
  },
  {
    title: "Honesty-First",
    description:
      "Keine Demo-Daten-Leaks. Klare Opt-ins. Spec-konform und offline-first.",
  },
];

export default function LandingPage() {
  return (
    <>
      {/* Hero */}
      <section className="relative flex min-h-[85vh] items-center justify-center px-4">
        <div className="absolute inset-0 bg-gradient-to-b from-surface/40 to-background" />
        <div className="relative z-10 mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
            Dein Bike. Deine Sensoren.
            <br />
            <span className="text-accent">Dein Setup.</span>
          </h1>
          <p className="mt-6 text-lg text-text-secondary sm:text-xl">
            Die erste App, die dein Bike wirklich kennt – mit Bosch LDI,
            Multi-Bike-Garage und ehrlicher Verschleißprognose.
          </p>
          <div className="mt-10">
            <AppDownloadButtons size="lg" />
          </div>
          <p className="mt-6 text-sm text-text-secondary">
            Die App läuft nativ auf Android & iOS. Die Website ist dein
            Desktop-Cockpit für Planung und Garage.
          </p>
        </div>
      </section>

      {/* Features */}
      <section className="border-t border-border bg-surface py-20 px-4">
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
                <h3 className="text-lg font-semibold">{f.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{f.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 px-4">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-center text-3xl font-bold">So funktioniert’s</h2>
          <ol className="mt-12 space-y-8">
            <li className="flex gap-4">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-accent text-lg font-bold text-white">
                1
              </span>
              <div>
                <h3 className="font-semibold">Bike in der Garage anlegen</h3>
                <p className="mt-1 text-sm text-text-secondary">
                  Katalog, Basis oder Import – OEM-Teile werden vorgefüllt.
                </p>
              </div>
            </li>
            <li className="flex gap-4">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-accent text-lg font-bold text-white">
                2
              </span>
              <div>
                <h3 className="font-semibold">In der App fahren</h3>
                <p className="mt-1 text-sm text-text-secondary">
                  Sensoren verbinden, Live-Hints und echte Offline-Navigation –
                  nur in der nativen App.
                </p>
              </div>
            </li>
            <li className="flex gap-4">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-accent text-lg font-bold text-white">
                3
              </span>
              <div>
                <h3 className="font-semibold">Setup optimieren & Verschleiß sehen</h3>
                <p className="mt-1 text-sm text-text-secondary">
                  Auf dem Desktop die Garage vertiefen, Bracketing und
                  Service-Reports nutzen.
                </p>
              </div>
            </li>
          </ol>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-border bg-surface py-16 px-4">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-2xl font-bold sm:text-3xl">
            Bereit für die App, die dein Bike kennt?
          </h2>
          <p className="mt-4 text-text-secondary">
            Lade AetherRide herunter und lege dein erstes Bike an.
          </p>
          <div className="mt-8">
            <AppDownloadButtons size="lg" />
          </div>
          <p className="mt-6 text-sm text-text-secondary">
            Schon einen Account?{" "}
            <Link href="/garage" className="text-accent hover:underline">
              Zur Garage
            </Link>
          </p>
        </div>
      </section>
    </>
  );
}
