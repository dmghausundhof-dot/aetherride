"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { fetchServerSession } from "@/lib/auth/clientAuth";
import { useAppStore } from "@/store/useAppStore";

/**
 * Nach OAuth-Callback: Session in Client-Store übernehmen, dann weiterleiten.
 */
function CompleteInner() {
  const router = useRouter();
  const params = useSearchParams();
  const next = params.get("next") || "/";
  const applyServerSession = useAppStore((s) => s.applyServerSession);
  const setOnboardingCompleted = useAppStore((s) => s.setOnboardingCompleted);
  const [msg, setMsg] = useState("Anmeldung wird abgeschlossen…");

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const s = await fetchServerSession();
        if (cancelled) return;
        if (!s.user) {
          setMsg("Keine Session — bitte erneut anmelden.");
          router.replace("/login?error=auth_callback");
          return;
        }
        applyServerSession({
          user: s.user,
          syncEnabled: s.syncEnabled,
        });
        setOnboardingCompleted(true);
        router.replace(next.startsWith("/") ? next : "/");
      } catch {
        if (!cancelled) {
          router.replace("/login?error=auth_callback");
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [applyServerSession, next, router, setOnboardingCompleted]);

  return (
    <div className="flex min-h-[50vh] items-center justify-center p-6 text-sm text-text-secondary">
      {msg}
    </div>
  );
}

export default function AuthCompletePage() {
  return (
    <Suspense fallback={<div className="p-6 text-center">Lade…</div>}>
      <CompleteInner />
    </Suspense>
  );
}
