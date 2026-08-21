import type { Metadata } from "next";
import { legalContactEmail } from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "AGB",
  description:
    "Allgemeine Geschäftsbedingungen für FlowLine Web, App und Pro.",
};

export default function LegalAgbPage() {
  const email = legalContactEmail();

  return (
    <div className="flex flex-col gap-4 pt-6">
      <h1 className="text-2xl font-bold">Allgemeine Geschäftsbedingungen</h1>
      <p className="text-sm text-text-secondary">
        Für die Nutzung von FlowLine im Browser und in der nativen App.
        Vertragspartner ist der im{" "}
        <a className="text-chrome" href="/legal/impressum">
          Impressum
        </a>{" "}
        genannte Anbieter.
      </p>

      <h2 className="text-base font-semibold">1. Leistung</h2>
      <p className="text-sm text-text-secondary">
        FlowLine ist eine Outdoor-Cycling-Anwendung: Hof (Planen, Touren,
        Rad, Teilen) im Web; Ride-HUD, GPS, Sensoren und Offline in der
        App. Free umfasst Karte, Planen, ein Rad und Offline-Routing (Pack) in
        der App. Pro vertieft mehrere Räder, Bracketing und Reichweite.
      </p>

      <h2 className="text-base font-semibold">2. Konto</h2>
      <p className="text-sm text-text-secondary">
        Für Sync und Pro ist ein Konto (E-Mail) nötig. Zugangsdaten sind
        geheim zu halten. Du darfst die Dienste nicht missbrauchen
        (Scraping, Störung, fremde Inhalte ohne Recht).
      </p>

      <h2 className="text-base font-semibold">3. Pro-Abo</h2>
      <p className="text-sm text-text-secondary">
        Pro ist ein digitaler Dienst. Zahlung im Web über Stripe, in der
        Android-App über Google Play. Laufzeit monatlich oder jährlich, wie im
        Checkout angezeigt. Kündigung zum Periodenende im Kundenportal bzw. über
        den Store. Widerruf: siehe{" "}
        <a className="text-chrome" href="/legal/widerruf">
          Widerrufsbelehrung
        </a>
        .
      </p>

      <h2 className="text-base font-semibold">4. Inhalte und Karte</h2>
      <p className="text-sm text-text-secondary">
        Touren, Routing und Karten sind Planungshilfen, keine Garantie für
        Wegezustand, Betretungsrecht oder Sicherheit. Verantwortung für die
        Fahrt bleibt bei dir. Nutzerinhalte (Stimmen, Gruppen, geteilte Touren)
        dürfen wir zur Bereitstellung hosten und bei Rechtsverstoß entfernen.
      </p>

      <h2 className="text-base font-semibold">5. Laden</h2>
      <p className="text-sm text-text-secondary">
        Der Laden ist ein Gateway. Kaufverträge über Ware kommen mit dem
        jeweiligen Händler zustande, nicht automatisch mit FlowLine.
      </p>

      <h2 className="text-base font-semibold">6. Verfügbarkeit und Haftung</h2>
      <p className="text-sm text-text-secondary">
        Wir bemühen uns um einen stabilen Betrieb, schulden aber keine
        ununterbrochene Verfügbarkeit. Haftung für Vorsatz und grobe
        Fahrlässigkeit unbeschränkt; im Übrigen nach geltendem Recht, bei
        Verbrauchern ohne Verkürzung zwingender Rechte.
      </p>

      <h2 className="text-base font-semibold">7. Schluss</h2>
      <p className="text-sm text-text-secondary">
        Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des
        UN-Kaufrechts, soweit zwingendes Verbraucherschutzrecht am Wohnsitz
        nichts anderes vorschreibt. Kontakt:{" "}
        <a className="text-chrome" href={`mailto:${email}`}>
          {email}
        </a>
        .
      </p>
    </div>
  );
}
