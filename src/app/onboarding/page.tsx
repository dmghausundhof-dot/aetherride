"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAppStore } from "@/store/useAppStore";
import { webDemoCapabilities } from "@/lib/platform/nativeContracts";
import { G0StatusPanel } from "@/components/G0StatusPanel";
import { SetupLiabilityNotice } from "@/components/SetupLiabilityNotice";
import {
  SETUP_LIABILITY,
  setA08AcceptedNow,
} from "@/lib/legal/setupLiability";
import { AUTH_DEMO_BANNER } from "@/lib/auth/session";
import { PROFESSIONAL_ROADMAP_STEPS } from "@/lib/platform/professionalRoadmap";

/**
 * Flow A — Onboarding bis erster Ride (Ziel &lt; 4 Minuten)
 */
export default function OnboardingPage() {
  const router = useRouter();
  const continueLocal = useAppStore((s) => s.continueLocal);
  const authSession = useAppStore((s) => s.authSession);
  const setOnboardingCompleted = useAppStore((s) => s.setOnboardingCompleted);
  const setAppMode = useAppStore((s) => s.setAppMode);
  const seedDemoData = useAppStore((s) => s.seedDemoData);
  const [step, setStep] = useState(authSession.user ? 1 : 0);
  const [a08Ok, setA08Ok] = useState(false);
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
            Tracking & Garage funktionieren ohne Konto. Sync erfordert
            Server-Anmeldung (F-ACC-002).
          </p>
          <p className="rounded-lg border border-accent/30 bg-accent/10 px-3 py-2 text-xs">
            {AUTH_DEMO_BANNER}
          </p>
          <Link
            href="/login?mode=register&next=/onboarding"
            className="block w-full rounded-xl bg-accent py-2.5 text-center text-sm font-semibold text-white"
          >
            Konto erstellen / Anmelden
          </Link>
          <p className="text-center text-[11px] text-text-secondary">
            E-Mail + Passwort · HTTP-only Session
          </p>
          <button
            type="button"
            disabled
            className="w-full rounded-xl bg-foreground/70 py-2.5 text-sm text-background opacity-50"
          >
            Apple / Google — OAuth folgt (Schritt 3)
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
          <p className="text-[10px] text-text-secondary">
            Roadmap: {PROFESSIONAL_ROADMAP_STEPS[0].titleDe} →{" "}
            {PROFESSIONAL_ROADMAP_STEPS[1].titleDe}
          </p>
        </section>
      )}

      {step === 1 && (
        <section className="space-y-3 rounded-2xl border border-border bg-surface p-4">
          <h2 className="font-semibold">Modus</h2>
          {authSession.user && (
            <p className="text-xs text-text-secondary">
              Angemeldet als {authSession.user.displayName}
              {authSession.user.email ? ` (${authSession.user.email})` : ""}
            </p>
          )}
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
              checked={a08Ok}
              onChange={(e) => setA08Ok(e.target.checked)}
              className="mt-1"
            />
            <span>
              Ich habe die Hinweise gelesen ({SETUP_LIABILITY.version}). Legal
              Sign-off (A-08) bleibt offen.
            </span>
          </label>
          <button
            type="button"
            disabled={!a08Ok}
            onClick={finish}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white disabled:opacity-40"
          >
            Los geht&apos;s
          </button>
        </section>
      )}

      <G0StatusPanel compact />
      <p className="text-[10px] text-text-secondary">
        Web-Demo Caps: Flutter={String(caps.flutter)} · G0 closed=
        {String(caps.g0Closed)}
      </p>
      <Link href="/login" className="text-center text-xs text-accent">
        Zum Login
      </Link>
    </div>
  );
}
