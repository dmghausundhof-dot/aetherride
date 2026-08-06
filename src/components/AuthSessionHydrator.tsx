"use client";

import { useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";
import { fetchServerSession } from "@/lib/auth/clientAuth";

/**
 * Hydriert Server-Session (Cookie) in den Client-Store.
 * Lokale anonymous Sessions bleiben erhalten, wenn kein Cookie.
 */
export function AuthSessionHydrator() {
  const applyServerSession = useAppStore((s) => s.applyServerSession);
  const authSession = useAppStore((s) => s.authSession);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const s = await fetchServerSession();
        if (cancelled) return;
        if (s.user) {
          applyServerSession({
            user: s.user,
            syncEnabled: s.syncEnabled,
          });
        }
      } catch {
        // offline / SSR — ignore
      }
    })();
    return () => {
      cancelled = true;
    };
    // nur einmal beim Mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  void authSession;
  return null;
}
