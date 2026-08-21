import type { Metadata } from "next";
import { isAppLaunched } from "@/lib/config/appStage";
import { legalContactEmail, legalPrivacyOverride } from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "Datenschutz",
  description:
    "Welche Daten FlowLine verarbeitet: Konto, Fahrten, Rad, optionale Community.",
};

export default function LegalDatenschutzPage() {
  const email = legalContactEmail();
  const custom = legalPrivacyOverride();

  return (
    <div className="flex flex-col gap-4 pt-6">
      <h1 className="text-2xl font-bold">Datenschutzerklärung</h1>
      {!isAppLaunched() ? (
        <p className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm text-text-secondary">
          Entwicklungsstand — kein öffentlicher Dienst, keine Zahlungen.
        </p>
      ) : null}
      {custom ? (
        <p className="whitespace-pre-wrap text-sm text-text-secondary">
          {custom}
        </p>
      ) : (
        <div className="flex flex-col gap-3 text-sm text-text-secondary">
          <p>
            FlowLine verarbeitet personenbezogene Daten, um Fahrten, Rad,
            Sync und optionale Community-Funktionen bereitzustellen. Es gibt
            kein Marketing-Pixel und kein Cookie-Banner für Drittwerbung —
            Analytics nur nach Opt-in im Profil.
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Verantwortlich
          </h2>
          <p>
            Angaben zum Verantwortlichen stehen im{" "}
            <a className="text-chrome" href="/legal/impressum">
              Impressum
            </a>
            . Kontakt:{" "}
            <a className="text-chrome" href={`mailto:${email}`}>
              {email}
            </a>
            .
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Welche Daten wir verarbeiten
          </h2>
          <ul className="list-disc space-y-1 pl-5">
            <li>Konto: E-Mail und Authentifizierungsdaten (Supabase Auth)</li>
            <li>
              Fahrtdaten: GPS-Tracks, Sensor-/Cadence-Werte, wenn du eine Fahrt
              aufzeichnest
            </li>
            <li>
              Rad: Fahrrad- und Setup-Angaben, optional Fotos
            </li>
            <li>
              Community (optional): Stimmen, Mappe-Links, Public Profile ohne
              GPS-Spuren
            </li>
            <li>
              Kartenkacheln: OpenStreetMap-Daten, ausgeliefert über Protomaps
              (PMTiles). Kein Google-Kartenlayer.
            </li>
            <li>
              Einwilligungen: z.&nbsp;B. Heatmap-Beitrag, Analytics,
              Produktempfehlungen (jeweils opt-in)
            </li>
            <li>
              Zahlungen: Abwicklung über Stripe (Web) bzw. Google Play (Android)
            </li>
          </ul>
          <h2 className="text-base font-semibold text-foreground">
            Rechtsgrundlagen
          </h2>
          <p>
            Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO), Einwilligung (Art. 6
            Abs. 1 lit. a) für optionale Features, berechtigtes Interesse an
            sicherem Betrieb (Art. 6 Abs. 1 lit. f).
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Speicherung
          </h2>
          <p>
            Daten liegen lokal auf dem Gerät (Offline-First) und — nach Login —
            synchronisiert auf Servern von Supabase bzw. unserem API-Host
            (Vercel). GPS-Tracks können vor Upload um Start/Ziel und
            Privatbereiche gekürzt werden.
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Kartenmaterial
          </h2>
          <p>
            Die Karte im Browser und in der App nutzt OpenStreetMap-Daten
            (© Mitwirkende), aufbereitet mit Protomaps. Es gibt keinen
            Google-Kartenlayer. Details zur Abdeckung stehen unter{" "}
            <a className="text-chrome" href="/karten">
              Karten
            </a>
            .
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Deine Rechte
          </h2>
          <p>
            Auskunft, Berichtigung, Löschung, Einschränkung,
            Datenübertragbarkeit und Widerspruch. Konto löschen kannst du unter
            Profil. Beschwerde bei einer Datenschutzaufsichtsbehörde ist
            möglich.
          </p>
          <p className="text-xs">
            Stand: produktnaher Text. Eine anwaltlich geprüfte Fassung kann
            diesen Inhalt ersetzen.
          </p>
        </div>
      )}
    </div>
  );
}
