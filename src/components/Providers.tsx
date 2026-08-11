"use client";

import { useEffect, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { OnboardingFlow } from "@/components/OnboardingFlow";
import { SyncProvider } from "@/components/sync/SyncProvider";

export function Providers({ children }: { children: React.ReactNode }) {
  const onboardingDone = useAppStore((s) => s.onboardingDone);
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

  // Kein Auto-Demo-Bike/Ride — leere Garage nach Freeride/Skip bleibt leer.
  const showOnboarding = ready && !onboardingDone;

  return (
    <SyncProvider>
      {children}
      {showOnboarding && <OnboardingFlow onDone={() => undefined} />}
    </SyncProvider>
  );
}
