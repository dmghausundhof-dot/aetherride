import type { Metadata } from "next";
import {
  legalContactEmail,
  legalWithdrawalOverride,
} from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "Widerruf",
  description:
    "Widerrufsbelehrung für FlowLine Pro — digitaler Dienst, keine Ware.",
};

export default function LegalWiderrufPage() {
  const email = legalContactEmail();
  const custom = legalWithdrawalOverride();

  return (
    <div className="mx-auto flex max-w-lg flex-col gap-4 p-4 pt-8">
      <h1 className="text-2xl font-bold">Widerruf</h1>
      {custom ? (
        <p className="whitespace-pre-wrap text-sm text-text-secondary">
          {custom}
        </p>
      ) : (
        <div className="flex flex-col gap-3 text-sm text-text-secondary">
          <p>
            FlowLine Pro ist ein digitaler Dienst (Abo), keine körperliche Ware.
            Es gibt nichts zurückzusenden.
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Widerrufsrecht
          </h2>
          <p>
            Verbraucher haben das Recht, binnen vierzehn Tagen ohne Angabe von
            Gründen den Vertrag über FlowLine Pro zu widerrufen. Die Frist
            beginnt mit Vertragsschluss.
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Ausübung
          </h2>
          <p>
            Der Widerruf ist an die im{" "}
            <a className="text-chrome" href="/legal/impressum">
              Impressum
            </a>{" "}
            genannten Kontaktdaten zu richten, per E-Mail an{" "}
            <a className="text-chrome" href={`mailto:${email}`}>
              {email}
            </a>
            . Eine eindeutige Erklärung genügt.
          </p>
          <h2 className="text-base font-semibold text-foreground">Folgen</h2>
          <p>
            Wir erstatten alle Zahlungen unverzüglich, spätestens binnen
            vierzehn Tagen ab Zugang des Widerrufs, über dasselbe Zahlungsmittel.
          </p>
          <h2 className="text-base font-semibold text-foreground">
            Vorzeitiges Erlöschen
          </h2>
          <p>
            Bei digitalen Inhalten, die nicht auf einem körperlichen Datenträger
            geliefert werden, erlischt das Widerrufsrecht, wenn du ausdrücklich
            zustimmst, dass wir vor Fristablauf mit der Ausführung beginnen, und
            zur Kenntnis nimmst, dass du damit dein Widerrufsrecht verlierst.
          </p>
          <h2 className="text-base font-semibold text-foreground">Laden</h2>
          <p>
            Physische Ware über den Laden unterliegt der Belehrung des jeweiligen
            Händlers, sobald der Marktplatz aktiv ist.
          </p>
        </div>
      )}
      <a href="/legal/impressum" className="text-sm text-chrome">
        Zum Impressum
      </a>
    </div>
  );
}
