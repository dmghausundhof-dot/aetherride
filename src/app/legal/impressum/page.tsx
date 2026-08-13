export default function LegalImpressumPage() {
  const imprint =
    process.env.NEXT_PUBLIC_LEGAL_IMPRINT?.trim() ||
    "Impressum nicht konfiguriert. Bitte NEXT_PUBLIC_LEGAL_IMPRINT setzen.";
  const email = process.env.NEXT_PUBLIC_LEGAL_EMAIL?.trim();

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-4 p-4 pt-8">
      <h1 className="text-2xl font-bold">Impressum</h1>
      <p className="whitespace-pre-wrap text-sm text-text-secondary">{imprint}</p>
      {email && (
        <p className="text-sm">
          Kontakt:{" "}
          <a className="text-chrome" href={`mailto:${email}`}>
            {email}
          </a>
        </p>
      )}
      <p className="text-xs text-text-secondary">
        Pflichtangaben nach § 5 TMG / § 18 MStV — Inhalt aus Umgebungsvariablen.
      </p>
    </div>
  );
}
