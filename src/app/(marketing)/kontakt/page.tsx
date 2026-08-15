import type { Metadata } from "next";
import Link from "next/link";
import { legalContactEmail, hasTmgImprint } from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "Kontakt",
  description:
    "FlowLine per E-Mail erreichen. Keine erfundene Anschrift, kein Chat-Bot.",
};

export default function KontaktPage() {
  const email = legalContactEmail();
  const complete = hasTmgImprint();

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-lg">
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          Kontakt
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          Schreib uns
        </h1>
        <p className="mt-3 text-text-secondary">
          Kein Formular-Bot, keine Fake-Hotline. Eine Adresse reicht.
        </p>

        <div className="mt-8 rounded-2xl border border-border bg-surface p-6">
          <p className="text-sm text-text-secondary">E-Mail</p>
          <a
            href={`mailto:${email}`}
            className="mt-1 inline-block text-lg font-semibold text-chrome hover:underline"
          >
            {email}
          </a>
          <p className="mt-4 text-sm text-text-secondary">
            Werkstatt-Interesse am Service-Check: dieselbe Adresse, Betreff
            „Werkstatt-Interesse“.
          </p>
        </div>

        <ul className="mt-8 space-y-2 text-sm text-text-secondary">
          <li>
            <Link href="/legal/impressum" className="text-chrome hover:underline">
              Impressum
            </Link>
            {!complete
              ? " — Name und Anschrift stehen, sobald sie hinterlegt sind."
              : null}
          </li>
          <li>
            <Link
              href="/legal/datenschutz"
              className="text-chrome hover:underline"
            >
              Datenschutz
            </Link>
          </li>
          <li>
            <Link href="/legal/agb" className="text-chrome hover:underline">
              AGB
            </Link>
            {" · "}
            <Link href="/legal/widerruf" className="text-chrome hover:underline">
              Widerruf
            </Link>
          </li>
          <li>
            <Link href="/faq" className="text-chrome hover:underline">
              FAQ
            </Link>
          </li>
        </ul>
      </div>
    </div>
  );
}
