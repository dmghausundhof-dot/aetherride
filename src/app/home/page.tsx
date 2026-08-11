"use client";

/**
 * App-Home (T-WA-00) — Wartungs-Status als USP.
 * Landing bleibt unter /; hier der eingeloggte / lokale App-Hub.
 */

import { useEffect, useRef, useState, Suspense } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import {
  Bike,
  ChevronRight,
  Compass,
  Play,
  Wrench,
} from "lucide-react";
import { MaintenanceStatusCard } from "@/components/home/MaintenanceStatusCard";
import { greetingLine } from "@/lib/home/greeting";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { useAppStore } from "@/store/useAppStore";

function HomeInner() {
  const searchParams = useSearchParams();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const seedDemoData = useAppStore((s) => s.seedDemoData);
  const seedDemoMaintenanceDue = useAppStore(
    (s) => s.seedDemoMaintenanceDue
  );
  const [displayName, setDisplayName] = useState<string | null>(null);
  const demoSeeded = useRef(false);

  const isDemoMaintenance =
    allowDemoContent() && searchParams.get("demo") === "maintenance";

  const activeBike =
    bikes.find((b) => b.id === activeBikeId) || bikes[0] || null;

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const res = await fetch("/api/auth/me");
        const data = await res.json();
        if (cancelled) return;
        if (data.user?.displayName) {
          setDisplayName(data.user.displayName);
        } else if (data.user?.email) {
          setDisplayName(String(data.user.email).split("@")[0]);
        }
      } catch {
        /* anon */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  // Demo/smoke path: ?demo=maintenance seeds overdue bike (dev / ALLOW_DEMO_CONTENT)
  useEffect(() => {
    if (!isDemoMaintenance || demoSeeded.current) return;
    demoSeeded.current = true;
    // Store update only — message is derived from isDemoMaintenance (no setState)
    try {
      seedDemoMaintenanceDue();
    } catch {
      /* free-tier multi-bike etc. */
    }
  }, [isDemoMaintenance, seedDemoMaintenanceDue]);

  return (
    <div className="mx-auto w-full max-w-2xl p-4 pt-6 lg:max-w-3xl lg:p-6">
      <header className="mb-5">
        <h1 className="text-2xl font-bold tracking-tight">
          {greetingLine(displayName)}
        </h1>
        <p className="mt-1 text-sm text-text-secondary">
          Wartungs-Status und nächste Schritte — immer kostenlos.
        </p>
      </header>

      {isDemoMaintenance && (
        <p className="mb-3 rounded-xl border border-warning/30 bg-warning/10 px-3 py-2 text-xs text-warning">
          Demo: Bike mit fälliger Wartung geladen (
          <code className="text-[11px]">?demo=maintenance</code>).
        </p>
      )}

      {/* T-WA-00 primary card */}
      <MaintenanceStatusCard className="mb-5" />

      {activeBike ? (
        <section className="mb-5 rounded-2xl border border-border bg-surface p-4">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
            Aktives Bike
          </p>
          <div className="mt-1 flex items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/30 text-accent">
                <Bike className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <h2 className="truncate font-semibold">{activeBike.name}</h2>
                <p className="text-xs tabular-nums text-text-secondary">
                  {activeBike.totalOdometerKm.toFixed(0)} km ·{" "}
                  {activeBike.totalHours.toFixed(1)} h
                </p>
              </div>
            </div>
            <Link
              href="/garage"
              className="inline-flex shrink-0 items-center gap-1 text-sm font-medium text-accent"
            >
              Garage <ChevronRight className="h-4 w-4" />
            </Link>
          </div>
        </section>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-3">
        <Link
          href="/discover"
          className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-4 transition hover:border-accent/40"
        >
          <Compass className="h-5 w-5 text-accent" />
          <div>
            <div className="text-sm font-semibold">Touren</div>
            <div className="text-xs text-text-secondary">Entdecken</div>
          </div>
        </Link>
        <Link
          href="/garage?tab=maintenance"
          className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-4 transition hover:border-accent/40"
        >
          <Wrench className="h-5 w-5 text-accent" />
          <div>
            <div className="text-sm font-semibold">Service-Check</div>
            <div className="text-xs text-text-secondary">Garage · Wartung</div>
          </div>
        </Link>
        <Link
          href="/download"
          className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-4 transition hover:border-accent/40"
        >
          <Play className="h-5 w-5 text-accent" />
          <div>
            <div className="text-sm font-semibold">App laden</div>
            <div className="text-xs text-text-secondary">Nav & Sensoren</div>
          </div>
        </Link>
      </div>

      {allowDemoContent() && (
        <div className="mt-8 rounded-2xl border border-dashed border-border p-4">
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
              Demo: leeres OEM-Bike
            </button>
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
