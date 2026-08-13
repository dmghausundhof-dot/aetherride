"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { OnboardingFlow } from "@/components/OnboardingFlow";
import { SyncProvider } from "@/components/sync/SyncProvider";

export function Providers({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
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

  // Marketing, Legal und Checkout bleiben lesbar — Overlay nur auf Kernflows.
  const hideOnboarding =
    pathname === "/" ||
    pathname.startsWith("/legal") ||
    pathname === "/privacy" ||
    pathname.startsWith("/privacy/") ||
    pathname === "/checkout" ||
    pathname.startsWith("/checkout/") ||
    pathname === "/pricing" ||
    pathname === "/download";
  const showOnboarding = ready && !onboardingDone && !hideOnboarding;

  return (
    <SyncProvider>
      {children}
      {showOnboarding && <OnboardingFlow onDone={() => undefined} />}
    </SyncProvider>
  );
}
