import type { Metadata } from "next";
import { Suspense } from "react";
import { AnmeldenForm } from "@/components/auth/AnmeldenForm";
import { AnmeldenIntro } from "@/components/auth/AnmeldenIntro";
import { AnmeldenFoot, AnmeldenLoading } from "@/components/auth/AnmeldenFoot";

export const metadata: Metadata = {
  title: "Anmelden",
  description:
    "Am Hof ankommen: Konto, Sync mit der App, Pro. Ohne Konto bleibt der Hof lokal nutzbar.",
};

export default function AnmeldenPage() {
  return (
    <div className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-md">
        <AnmeldenIntro />
        <div className="mt-8 rounded-2xl border border-border bg-surface p-5">
          <Suspense fallback={<AnmeldenLoading />}>
            <AnmeldenForm />
          </Suspense>
        </div>
        <AnmeldenFoot />
      </div>
    </div>
  );
}
