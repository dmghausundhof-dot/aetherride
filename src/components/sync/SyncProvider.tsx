"use client";

/**
 * Nach Login: einmal pull/push.
 * Debounced Push bei Library/Garage/Activities-Änderungen.
 */

import { useEffect, useRef } from "react";
import { useAppStore } from "@/store/useAppStore";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { runWebSync } from "@/lib/sync/webSync";

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const hydrated = useRef(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastPush = useRef(0);

  // Initial sync after store hydrate
  useEffect(() => {
    if (!isSupabaseConfigured()) return;
    const unsub = useAppStore.persist.onFinishHydration(() => {
      hydrated.current = true;
      void (async () => {
        try {
          const me = await fetch("/api/auth/me").then((r) => r.json());
          if (!me?.user) return;
          await runWebSync();
        } catch {
          /* offline / no session */
        }
      })();
    });
    if (useAppStore.persist.hasHydrated()) {
      hydrated.current = true;
      void (async () => {
        try {
          const me = await fetch("/api/auth/me").then((r) => r.json());
          if (!me?.user) return;
          await runWebSync();
        } catch {
          /* ignore */
        }
      })();
    }
    return unsub;
  }, []);

  // Debounced auto-push when key slices change
  useEffect(() => {
    if (!isSupabaseConfigured()) return;
    const unsub = useAppStore.subscribe((state, prev) => {
      if (!hydrated.current) return;
      const changed =
        state.bikes !== prev.bikes ||
        state.rides !== prev.rides ||
        state.savedRoutes !== prev.savedRoutes ||
        state.routeCollections !== prev.routeCollections ||
        state.maintenanceLogs !== prev.maintenanceLogs ||
        state.rideFeedbacks !== prev.rideFeedbacks ||
        state.riderProfile !== prev.riderProfile ||
        state.activeBikeId !== prev.activeBikeId;
      if (!changed) return;
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => {
        const now = Date.now();
        if (now - lastPush.current < 4000) return;
        lastPush.current = now;
        void (async () => {
          try {
            const me = await fetch("/api/auth/me").then((r) => r.json());
            if (!me?.user) return;
            await runWebSync();
          } catch {
            /* silent */
          }
        })();
      }, 2500);
    });
    return () => {
      unsub();
      if (timer.current) clearTimeout(timer.current);
    };
  }, []);

  return <>{children}</>;
}
