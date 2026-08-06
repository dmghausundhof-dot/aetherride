export default function LegalWiderrufPage() {
  const text =
    process.env.NEXT_PUBLIC_LEGAL_WITHDRAWAL?.trim() ||
    `Widerrufsbelehrung (Kurzfassung)

Verbraucher haben ein vierzehntägiges Widerrufsrecht ab Erhalt der Ware.
Der Widerruf ist an die im Impressum genannte Adresse zu richten.

Ausnahmen und Muster-Widerrufsformular: vollständigen Textst von Legal prüfen lassen
und hier über NEXT_PUBLIC_LEGAL_WITHDRAWAL hinterlegen.`;

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-4 p-4 pt-8">
      <h1 className="text-2xl font-bold">Widerruf</h1>
      <p className="whitespace-pre-wrap text-sm text-text-secondary">{text}</p>
      <a href="/legal/impressum" className="text-sm text-accent">
        Zum Impressum
      </a>
    </div>
  );
}
