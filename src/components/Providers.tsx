"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { OnboardingFlow } from "@/components/OnboardingFlow";
import { SyncProvider } from "@/components/sync/SyncProvider";
import { ChromeLangProvider } from "@/components/i18n/ChromeLangProvider";
import { isPublicMarketingPath } from "@/lib/nav/marketingNav";
import type { ChromeLang } from "@/lib/i18n/chromeLang";

export function Providers({
  children,
  initialLang,
  initialOverride = null,
}: {
  children: React.ReactNode;
  initialLang: ChromeLang;
  initialOverride?: ChromeLang | null;
}) {
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

  const hideOnboarding = isPublicMarketingPath(pathname);
  const showOnboarding = ready && !onboardingDone && !hideOnboarding;

  return (
    <ChromeLangProvider
      initialLang={initialLang}
      initialOverride={initialOverride}
    >
      <SyncProvider>
        {children}
        {showOnboarding && <OnboardingFlow onDone={() => undefined} />}
      </SyncProvider>
    </ChromeLangProvider>
  );
}
