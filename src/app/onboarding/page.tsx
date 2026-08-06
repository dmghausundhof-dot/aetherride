"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { webDemoCapabilities } from "@/lib/platform/nativeContracts";
import { G0StatusPanel } from "@/components/G0StatusPanel";
import { SetupLiabilityNotice } from "@/components/SetupLiabilityNotice";
import {
  SETUP_LIABILITY,
  setA08AcceptedNow,
} from "@/lib/legal/setupLiability";
import {
  AUTH_DEMO_BANNER,
  isPlausibleEmail,
} from "@/lib/auth/session";
import Link from "next/link";

/**
 * Flow A — Onboarding bis erster Ride (Ziel &lt; 4 Minuten)
 */
export default function OnboardingPage() {
  const router = useRouter();
  const signIn = useAppStore((s) => s.signIn);
  const continueLocal = useAppStore((s) => s.continueLocal);
  const setOnboardingCompleted = useAppStore((s) => s.setOnboardingCompleted);
  const setAppMode = useAppStore((s) => s.setAppMode);
  const seedDemoData = useAppStore((s) => s.seedDemoData);
  const [step, setStep] = useState(0);
  const [a08Ok, setA08Ok] = useState(false);
  const [email, setEmail] = useState("");
  const [emailErr, setEmailErr] = useState<string | null>(null);
  const caps = webDemoCapabilities();

  const finish = () => {
    if (a08Ok) setA08AcceptedNow();
    setOnboardingCompleted(true);
    seedDemoData();
    router.push("/ride");
  };

  return (
    <div className="flex min-h-[80vh] flex-col gap-5 p-4 pt-8">
      <header>
        <p className="text-xs uppercase tracking-wide text-text-secondary">
          AetherRide
        </p>
        <h1 className="text-2xl font-bold">Willkommen</h1>
        <p className="text-sm text-text-secondary">
          Onboarding Flow A · Ziel unter 4 Minuten
        </p>
      </header>

      {step === 0 && (
        <section className="space-y-3 rounded-2xl border border-border bg-surface p-4">
          <h2 className="font-semibold">Konto oder lokal?</h2>
          <p className="text-sm text-text-secondary">
            Tracking & Garage funktionieren ohne Konto. Sync erfordert Anmeldung
            (F-ACC-002).
          </p>
          <p className="rounded-lg border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
            {AUTH_DEMO_BANNER}
          </p>
          <button
            type="button"
            onClick={() => {
              signIn("apple");
              setStep(1);
            }}
            className="w-full rounded-xl bg-foreground py-2.5 text-sm font-medium text-background"
          >
            Mit Apple fortfahren (lokaler Mock)
          </button>
          <button
            type="button"
            onClick={() => {
              signIn("google");
              setStep(1);
            }}
            className="w-full rounded-xl border border-border py-2.5 text-sm"
          >
            Mit Google fortfahren (lokaler Mock)
          </button>
          <label className="block text-sm">
            E-Mail (Format-Check, kein Versand)
            <input
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setEmailErr(null);
              }}
              placeholder="name@domain.tld"
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
          </label>
          {emailErr && <p className="text-xs text-error">{emailErr}</p>}
          <button
            type="button"
            onClick={() => {
              if (!isPlausibleEmail(email)) {
                setEmailErr("Bitte gültige E-Mail eingeben.");
                return;
              }
              signIn("email", email.trim());
              setStep(1);
            }}
            className="w-full rounded-xl border border-border py-2.5 text-sm"
          >
            E-Mail (lokaler Mock)
          </button>
          <button
            type="button"
            onClick={() => {
              continueLocal();
              setStep(1);
            }}
            className="w-full rounded-xl bg-surface-elevated py-2.5 text-sm"
          >
            Ohne Konto lokal starten
          </button>
        </section>
      )}

      {step === 1 && (
        <section className="space-y-3 rounded-2xl border border-border bg-surface p-4">
          <h2 className="font-semibold">Modus</h2>
          <button
            type="button"
            onClick={() => {
              setAppMode("bike");
              setStep(2);
            }}
            className="w-full rounded-xl bg-accent py-3 text-sm font-medium text-white"
          >
            Bike / E-Bike
          </button>
          <button
            type="button"
            onClick={() => {
              setAppMode("hiking");
              setStep(2);
            }}
            className="w-full rounded-xl border border-border py-3 text-sm"
          >
            Wandern (Bike-UI ausgeblendet)
          </button>
        </section>
      )}

      {step === 2 && (
        <section className="space-y-3 rounded-2xl border border-border bg-surface p-4">
          <h2 className="font-semibold">Setup-Hinweise (A-08)</h2>
          <SetupLiabilityNotice variant="long" />
          <label className="flex items-start gap-2 text-sm">
            <input
              type="checkbox"
              className="mt-1"
              checked={a08Ok}
              onChange={(e) => setA08Ok(e.target.checked)}
            />
            <span>{SETUP_LIABILITY.acceptancePromptDe}</span>
          </label>
          <button
            type="button"
            disabled={!a08Ok}
            onClick={() => setStep(3)}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white disabled:opacity-40"
          >
            Weiter
          </button>
        </section>
      )}

      {step === 3 && (
        <section className="space-y-3 rounded-2xl border border-border bg-surface p-4">
          <h2 className="font-semibold">Garage vorbereiten</h2>
          <p className="text-sm text-text-secondary">
            Demo legt Katalog-Bikes an. Kalibrierung (45 s) ist überspringbar und
            später in der Garage möglich.
          </p>
          <G0StatusPanel compact />
          <ul className="list-inside list-disc text-xs text-text-secondary">
            {caps.notes.slice(0, 4).map((n) => (
              <li key={n}>{n}</li>
            ))}
          </ul>
          <button
            type="button"
            onClick={finish}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
          >
            Demo starten & zum Ride
          </button>
          <Link href="/garage" className="block text-center text-sm text-accent">
            Zur Garage
          </Link>
          <Link href="/profile" className="block text-center text-xs text-text-secondary">
            G-0 Details im Profil
          </Link>
        </section>
      )}
    </div>
  );
}
