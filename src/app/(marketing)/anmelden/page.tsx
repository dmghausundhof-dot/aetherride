import type { Metadata } from "next";
import { Suspense } from "react";
import Link from "next/link";
import { AnmeldenForm } from "@/components/auth/AnmeldenForm";
import { HOF_COPY } from "@/lib/home/hofCopy";

export const metadata: Metadata = {
  title: "Anmelden",
  description:
    "Am Hof ankommen: Konto, Sync mit der App, Pro. Ohne Konto bleibt der Hof lokal nutzbar.",
};

export default function AnmeldenPage() {
  return (
    <div className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-md">
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          {HOF_COPY.profileKicker}
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight">
          {HOF_COPY.profileArrive}
        </h1>
        <p className="mt-3 text-sm text-text-secondary">{HOF_COPY.profileHint}</p>
        <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
          <Suspense
            fallback={
              <p className="text-sm text-text-secondary">Laden…</p>
            }
          >
            <AnmeldenForm />
          </Suspense>
        </div>
        <p className="mt-6 text-center text-xs text-text-secondary">
          Ohne Konto geht der Hof lokal.{" "}
          <Link href="/home" className="text-chrome hover:underline">
            Trotzdem zum Hof
          </Link>
          {" · "}
          <Link href="/pricing" className="text-chrome hover:underline">
            Preise
          </Link>
          {" · "}
          <Link href="/faq" className="text-chrome hover:underline">
            FAQ
          </Link>
        </p>
        <p className="mt-3 text-center text-xs text-text-secondary">
          <Link href="/legal/datenschutz" className="text-chrome hover:underline">
            Datenschutz
          </Link>
          {" · "}
          <Link href="/legal/agb" className="text-chrome hover:underline">
            AGB
          </Link>
        </p>
      </div>
    </div>
  );
}
