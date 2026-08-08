"use client";

import { useEffect, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { OnboardingFlow } from "@/components/OnboardingFlow";

export function Providers({ children }: { children: React.ReactNode }) {
  const seedDemoData = useAppStore((s) => s.seedDemoData);
  const onboardingDone = useAppStore((s) => s.onboardingDone);
  const bikes = useAppStore((s) => s.bikes);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const finish = () => setReady(true);
    const unsub = useAppStore.persist.onFinishHydration(finish);
    if (useAppStore.persist.hasHydrated()) finish();
    // Fallback falls Persist-API nicht feuert
    const t = window.setTimeout(finish, 400);
    return () => {
      unsub();
      window.clearTimeout(t);
    };
  }, []);

  useEffect(() => {
    if (!ready) return;
    if (onboardingDone && bikes.length === 0) {
      seedDemoData();
    }
  }, [ready, onboardingDone, bikes.length, seedDemoData]);

  const showOnboarding = ready && !onboardingDone;

  return (
    <>
      {children}
      {showOnboarding && <OnboardingFlow onDone={() => undefined} />}
    </>
  );
}
