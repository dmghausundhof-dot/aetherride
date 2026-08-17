import type { Metadata } from "next";
import { isAppLaunched } from "@/lib/config/appStage";
import {
  hasTmgImprint,
  legalContactEmail,
  legalImprintText,
} from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "Impressum",
  description: "Anbieterkennzeichnung von FlowLine nach § 5 TMG.",
};

export default function LegalImpressumPage() {
  const imprint = legalImprintText();
  const email = legalContactEmail();
  const complete = hasTmgImprint();

  return (
    <div className="flex flex-col gap-4 pt-6">
      <h1 className="text-2xl font-bold">Impressum</h1>
      <p className="text-sm text-text-secondary">
        Angaben gemäß § 5 TMG und § 18 MStV.
      </p>
      {!isAppLaunched() ? (
        <p className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm text-text-secondary">
          Dies ist ein Entwicklungsstand, kein öffentliches Angebot und kein
          geschäftsmäßiger Dienst.
        </p>
      ) : null}

      {imprint ? (
        <p className="whitespace-pre-wrap text-sm text-text-secondary">
          {imprint}
        </p>
      ) : (
        <div className="flex flex-col gap-3 text-sm text-text-secondary">
          <h2 className="text-base font-semibold text-foreground">
            Diensteanbieter
          </h2>
          <p>
            Name, ladungsfähige Anschrift und ggf. Register- oder
            Umsatzsteuerangaben sind noch nicht hinterlegt. Diese Felder werden
            nicht frei erfunden.
          </p>
          <h2 className="text-base font-semibold text-foreground">Kontakt</h2>
          <p>
            E-Mail:{" "}
            <a className="text-chrome" href={`mailto:${email}`}>
              {email}
            </a>
          </p>
        </div>
      )}

      {imprint ? (
        <p className="text-sm">
          Kontakt:{" "}
          <a className="text-chrome" href={`mailto:${email}`}>
            {email}
          </a>
        </p>
      ) : null}

      {!complete ? (
        <p className="text-xs text-text-secondary">
          Bis Name und Anschrift stehen, ist diese Seite nach TMG unvollständig.
          Der Marktplatz-Checkout bleibt deshalb gesperrt.
        </p>
      ) : null}
    </div>
  );
}
