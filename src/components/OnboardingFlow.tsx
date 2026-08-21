"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useAppStore } from "@/store/useAppStore";
import type { BikeCategory } from "@/types";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { profileCopy } from "@/lib/i18n/profileCopy";
import { onboardCopy } from "@/lib/i18n/onboardCopy";
import { X } from "lucide-react";

const SPORTS: BikeCategory[] = [
  "urban",
  "gravel",
  "road",
  "mtb_am",
  "mtb_enduro",
  "emtb",
  "etrekking",
];

/**
 * Flow A light: Sport → Gewicht → Rad anlegen oder Freeride.
 * Einmalig, bis abgeschlossen oder übersprungen.
 */
export function OnboardingFlow({ onDone }: { onDone: () => void }) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const o = onboardCopy(lang);
  const p = profileCopy(lang);
  const router = useRouter();
  const updateRiderProfile = useAppStore((s) => s.updateRiderProfile);
  const markOnboardingDone = useAppStore((s) => s.markOnboardingDone);
  const [step, setStep] = useState<1 | 2>(1);
  const [sport, setSport] = useState<BikeCategory>("urban");
  const [weight, setWeight] = useState(78);

  const finish = (next: "garage" | "discover" | "skip") => {
    updateRiderProfile({ riderWeightKg: weight });
    markOnboardingDone(sport);
    onDone();
    if (next === "garage") {
      router.push(`/garage?wizard=1&category=${sport}`);
    } else if (next === "discover") {
      router.push("/discover");
    }
  };

  return (
    <div className="fixed inset-0 z-[70] flex items-end justify-center bg-black/70 p-0 sm:items-center sm:p-4">
      <div className="max-h-[92dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-5 sm:rounded-2xl">
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-accent">
              {o.welcome}
            </p>
            <h2 className="text-xl font-bold">
              {step === 1 ? o.howYouRide : o.yourWeight}
            </h2>
            <p className="mt-1 text-sm text-text-secondary">
              {step === 1 ? o.sportHint : o.weightHint}
            </p>
          </div>
          <button
            type="button"
            onClick={() => finish("skip")}
            className="touch-target p-2 text-text-secondary"
            aria-label={o.skip}
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {step === 1 && (
          <div className="grid grid-cols-2 gap-2">
            {SPORTS.map((id) => (
              <button
                key={id}
                type="button"
                onClick={() => setSport(id)}
                className={`rounded-xl border p-3 text-left ${
                  sport === id
                    ? "border-accent bg-accent/15"
                    : "border-border bg-surface-elevated"
                }`}
              >
                <div className="text-sm font-semibold">
                  {bikeCategoryLabel(id, lang)}
                </div>
                <div className="mt-0.5 text-[11px] text-text-secondary">
                  {o.blurbs[id]}
                </div>
              </button>
            ))}
          </div>
        )}

        {step === 2 && (
          <label className="block text-sm">
            {p.riderWeight}
            <input
              type="number"
              min={40}
              max={160}
              value={weight}
              onChange={(e) => setWeight(Number(e.target.value) || 78)}
              className="mt-2 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3 text-lg"
            />
            <p className="mt-2 text-xs text-text-secondary">
              {o.chosen(bikeCategoryLabel(sport, lang))}
            </p>
          </label>
        )}

        <div className="mt-5 flex flex-col gap-2">
          {step === 1 ? (
            <button
              type="button"
              onClick={() => setStep(2)}
              className="w-full rounded-xl bg-accent py-3 font-semibold text-on-accent"
            >
              {o.next}
            </button>
          ) : (
            <>
              <button
                type="button"
                onClick={() => finish("garage")}
                className="w-full rounded-xl bg-accent py-3 font-semibold text-on-accent"
              >
                {copy.workshopAdd}
              </button>
              <button
                type="button"
                onClick={() => finish("discover")}
                className="w-full rounded-xl border border-border py-3 text-sm font-medium"
              >
                {copy.showTours}
              </button>
            </>
          )}
          <button
            type="button"
            onClick={() => finish("skip")}
            className="py-2 text-xs text-text-secondary"
          >
            {o.later}
          </button>
        </div>
      </div>
    </div>
  );
}
