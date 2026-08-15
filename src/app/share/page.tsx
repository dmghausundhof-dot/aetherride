import type { Metadata } from "next";
import Link from "next/link";
import { SHARE_DEMO_TOKEN } from "@/lib/community/shareCodec";

export const metadata: Metadata = {
  title: "Teilen – Tour-Link und Mappe",
  description:
    "FlowLine teilt per Link: eine Tour oder eine Mappe. Kein Feed, kein Account-Zwang, GPS nur mit Opt-in.",
};

export default function ShareIndexPage() {
  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <p className="text-[11px] font-bold tracking-wide text-chrome">Teilen</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          Link statt Feed
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">
          Wer den Link hat, kann die Tour in die eigene Mappe legen. Es gibt
          keine Timeline und keine stillen GPS-Anhänge.
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2">
          <article className="rounded-2xl border border-border bg-surface p-6">
            <h2 className="font-semibold">Tour-Link</h2>
            <p className="mt-2 text-sm text-text-secondary">
              Eine Tour, Name und Stats. Eine Spur nur, wenn sie bewusst im
              Link steckt — sonst bleibt’s Pin und Katalog.
            </p>
            <Link
              href={`/share/t/${SHARE_DEMO_TOKEN}`}
              className="mt-4 inline-block text-sm font-semibold text-chrome hover:underline"
            >
              Beispiel-Tour öffnen →
            </Link>
          </article>
          <article className="rounded-2xl border border-border bg-surface p-6">
            <h2 className="font-semibold">Mappe</h2>
            <p className="mt-2 text-sm text-text-secondary">
              Mehrere Katalog-Touren als Sammlung. Immer ohne Tracks. Anlegen
              auf dem Platz.
            </p>
            <Link
              href={`/share/c/${SHARE_DEMO_TOKEN}`}
              className="mt-4 inline-block text-sm font-semibold text-chrome hover:underline"
            >
              Beispiel-Mappe öffnen →
            </Link>
          </article>
        </div>

        <ol className="mt-12 list-decimal space-y-3 pl-5 text-sm text-text-secondary">
          <li>
            Tour auf der{" "}
            <Link href="/regions" className="text-chrome hover:underline">
              Regionen-Seite
            </Link>{" "}
            oder im{" "}
            <Link href="/library" className="text-chrome hover:underline">
              Platz
            </Link>{" "}
            öffnen.
          </li>
          <li>Link kopieren. Der Empfänger braucht kein Konto.</li>
          <li>Übernehmen legt die Tour lokal in diesem Browser in die Mappe.</li>
        </ol>

        <p className="mt-8 text-sm text-text-secondary">
          Gruppen und Stimmen bleiben am Platz.{" "}
          <Link href="/community" className="text-chrome hover:underline">
            Community
          </Link>
          {" · "}
          <Link href="/faq" className="text-chrome hover:underline">
            FAQ
          </Link>
        </p>
      </div>
    </div>
  );
}
