"use client";

/**
 * App-Home — Der Hof. Landing bleibt unter /; hier der Stand.
 */

import { useEffect, useRef, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { HofStand } from "@/components/home/HofStand";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { useAppStore } from "@/store/useAppStore";

function HomeInner() {
  const searchParams = useSearchParams();
  const seedDemoData = useAppStore((s) => s.seedDemoData);
  const seedDemoMaintenanceDue = useAppStore(
    (s) => s.seedDemoMaintenanceDue
  );
  const demoSeeded = useRef(false);

  const isDemoMaintenance =
    allowDemoContent() && searchParams.get("demo") === "maintenance";

  useEffect(() => {
    if (!isDemoMaintenance || demoSeeded.current) return;
    demoSeeded.current = true;
    try {
      seedDemoMaintenanceDue();
    } catch {
      /* free-tier multi-bike etc. */
    }
  }, [isDemoMaintenance, seedDemoMaintenanceDue]);

  return (
    <div>
      {isDemoMaintenance && (
        <p className="mx-auto mb-0 mt-3 max-w-2xl rounded-xl border border-warning/30 bg-warning/10 px-5 py-2 text-xs text-warning lg:max-w-3xl">
          Demo: Rad mit fälliger Wartung geladen (
          <code className="text-[11px]">?demo=maintenance</code>).
        </p>
      )}

      <HofStand />

      {allowDemoContent() && (
        <div className="mx-auto mb-10 max-w-2xl px-5 lg:max-w-3xl lg:px-6">
          <div className="rounded-2xl border border-dashed border-border p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              QA / Demo (nur Dev)
            </p>
            <p className="mt-1 text-xs text-text-secondary">
              Zuverlässiger Overdue-Pfad ohne Fake-Produktionsdaten:{" "}
              <code className="text-[11px]">/home?demo=maintenance</code>
            </p>
            <div className="mt-3 flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => {
                  try {
                    seedDemoMaintenanceDue();
                  } catch {
                    /* ignore */
                  }
                }}
                className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface-elevated"
              >
                Demo: Wartung fällig
              </button>
              <button
                type="button"
                onClick={() => {
                  try {
                    seedDemoData();
                  } catch {
                    /* ignore */
                  }
                }}
                className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface-elevated"
              >
                Demo: leeres OEM-Rad
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-2xl p-4 pt-6 text-sm text-text-secondary">
          Laden…
        </div>
      }
    >
      <HomeInner />
    </Suspense>
  );
}
