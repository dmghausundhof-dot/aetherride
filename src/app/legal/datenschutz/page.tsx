export default function LegalDatenschutzPage() {
  const email = process.env.NEXT_PUBLIC_LEGAL_EMAIL?.trim();
  const custom = process.env.NEXT_PUBLIC_LEGAL_PRIVACY?.trim();

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-4 p-4 pt-8">
      <h1 className="text-2xl font-bold">Datenschutzerklärung</h1>
      {custom ? (
        <p className="whitespace-pre-wrap text-sm text-text-secondary">{custom}</p>
      ) : (
        <div className="flex flex-col gap-3 text-sm text-text-secondary">
          <p>
            AetherRide verarbeitet personenbezogene Daten, um Fahrten, Garage,
            Sync und optionale Community-Funktionen bereitzustellen.
          </p>
          <h2 className="text-base font-semibold text-foreground">Verantwortlich</h2>
          <p>
            Angaben zum Verantwortlichen stehen im{" "}
            <a className="text-accent" href="/legal/impressum">
              Impressum
            </a>
            .
            {email ? (
              <>
                {" "}
                Kontakt Datenschutz:{" "}
                <a className="text-accent" href={`mailto:${email}`}>
                  {email}
                </a>
                .
              </>
            ) : null}
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
            <li>Garage: Fahrrad- und Setup-Angaben, optional Fotos</li>
            <li>
              Einwilligungen: z.&nbsp;B. Heatmap-Beitrag, Analytics, Drittanbieter
              (opt-in)
            </li>
            <li>Zahlungen: Abwicklung über Stripe bzw. Google Play</li>
          </ul>
          <h2 className="text-base font-semibold text-foreground">Rechtsgrundlagen</h2>
          <p>
            Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO), Einwilligung
            (Art. 6 Abs. 1 lit. a) für optionale Features, berechtigtes Interesse
            an sicherem Betrieb (Art. 6 Abs. 1 lit. f).
          </p>
          <h2 className="text-base font-semibold text-foreground">Speicherung</h2>
          <p>
            Daten liegen lokal auf dem Gerät (Offline-First) und — nach Login —
            synchronisiert auf Servern von Supabase bzw. unserem API-Host
            (Vercel). GPS-Tracks können vor Upload um Start/Ziel und
            Privatbereiche gekürzt werden.
          </p>
          <h2 className="text-base font-semibold text-foreground">Deine Rechte</h2>
          <p>
            Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit
            und Widerspruch. Konto löschen kannst du in der App unter Profil.
            Beschwerde bei einer Datenschutzaufsichtsbehörde ist möglich.
          </p>
          <p className="text-xs">
            Platzhalter-Text — finalen Inhalt über{" "}
            <code>NEXT_PUBLIC_LEGAL_PRIVACY</code> setzen (Anwalt prüfen lassen).
          </p>
        </div>
      )}
    </div>
  );
}
