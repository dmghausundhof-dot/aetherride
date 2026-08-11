/**
 * T-WA-00b — Landing Service-Check Waitlist (DE).
 * USP + mock status card + workshop interest CTA.
 * Does NOT claim live workshop partners exist.
 */

import Link from "next/link";
import { CheckCircle2, Mail, Wrench } from "lucide-react";

const WORKSHOP_MAIL =
  "mailto:hello@aetherride.app?subject=Werkstatt-Interesse%20Service-Check&body=Hallo%20AetherRide-Team%2C%0A%0Awir%20sind%20eine%20Werkstatt%20und%20interessieren%20uns%20f%C3%BCr%20den%20Service-Check.%0A%0AName%3A%0AOrt%3A%0AWebsite%3A%0A";

export function ServiceCheckSection() {
  return (
    <section
      id="service-check"
      className="border-t border-border bg-surface py-16 px-4"
      aria-labelledby="service-check-heading"
    >
      <div className="mx-auto grid max-w-6xl items-center gap-10 lg:grid-cols-2 lg:gap-14">
        <div>
          <p className="text-sm font-medium uppercase tracking-wider text-accent">
            Service-Check
          </p>
          <h2
            id="service-check-heading"
            className="mt-2 text-2xl font-bold sm:text-3xl"
          >
            Dein Bike sagt dir, was fällig ist.
          </h2>
          <p className="mt-4 text-text-secondary">
            AetherRide rechnet Wartungsintervalle aus deinem Kilometerstand und
            deinen Stunden — mit Quellen aus Hersteller- und Industriepraxis
            (RockShox, Fox, Park Tool u. a.). Keine Blackbox, keine Fake-Partner.
          </p>
          <ul className="mt-5 space-y-2 text-sm text-text-secondary">
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              Status auf Home &amp; in der Garage — immer kostenlos
            </li>
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              Quellen sichtbar pro Intervall (kein „KI hat gesagt“)
            </li>
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              Deep-Link: gleicher Status wie in der App-Garage
            </li>
          </ul>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/home#wartung"
              className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-6 text-sm font-semibold text-white hover:bg-accent-hover"
            >
              Service-Check öffnen
            </Link>
            <Link
              href="/garage?tab=maintenance"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold hover:bg-background"
            >
              Zur Garage · Wartung
            </Link>
          </div>
        </div>

        {/* Mock / demo card — illustrative only */}
        <div className="mx-auto w-full max-w-md">
          <div className="rounded-2xl border border-warning/40 bg-background p-5 shadow-lg shadow-black/20">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-warning/15 text-warning">
                <Wrench className="h-5 w-5" />
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
                  Wartungs-Status · Beispiel
                </p>
                <h3 className="mt-0.5 text-lg font-semibold">
                  Kette · 180 km · bald checken
                </h3>
                <p className="mt-1 text-sm text-text-secondary">
                  Kettenverschleiß prüfen · Quelle: Park Tool / Industriepraxis
                </p>
              </div>
            </div>
            <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-muted">
              <div className="h-full w-[82%] rounded-full bg-warning" />
            </div>
            <p className="mt-2 text-[11px] text-text-secondary">
              Demo-Darstellung — echte Werte kommen aus deinem Bike in der Garage.
            </p>
            <Link
              href="/home#wartung"
              className="mt-4 flex w-full items-center justify-center rounded-xl bg-accent py-2.5 text-sm font-semibold text-white hover:bg-accent-hover"
            >
              Eigenen Status ansehen
            </Link>
          </div>

          <div className="mt-6 rounded-2xl border border-border bg-background/60 p-5">
            <h3 className="flex items-center gap-2 font-semibold">
              <Mail className="h-4 w-4 text-accent" />
              Werkstätten: Interesse melden
            </h3>
            <p className="mt-2 text-sm text-text-secondary">
              Wir bauen eine Warteliste für Werkstatt-Partner. Es gibt{" "}
              <strong className="font-medium text-foreground">
                noch keine Live-Partner-Buchung
              </strong>{" "}
              — bei Interesse melde dich unverbindlich.
            </p>
            <a
              href={WORKSHOP_MAIL}
              className="mt-4 inline-flex h-11 items-center justify-center rounded-xl border border-border px-5 text-sm font-semibold hover:border-accent/40 hover:bg-surface"
            >
              Interesse per E-Mail
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
