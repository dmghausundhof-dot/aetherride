"use client";

/**
 * Home / Garage Wartungs-Status Card (T-WA-00).
 * Always free — no Pro gate. Empty / Ok / Due + 7-day snooze.
 */

import { useCallback, useMemo, useSyncExternalStore } from "react";
import Link from "next/link";
import {
  AlertTriangle,
  CheckCircle2,
  ChevronRight,
  Plus,
  Wrench,
  X,
} from "lucide-react";
import {
  getMaintenanceSummary,
  lastRideForBike,
  type MaintenanceSummary,
} from "@/lib/maintenance/summary";
import {
  clearMaintenanceCardSnooze,
  isMaintenanceCardSnoozed,
  snoozeMaintenanceCard,
  subscribeMaintenanceCardSnooze,
} from "@/lib/home/maintenanceCardSnooze";
import { useAppStore } from "@/store/useAppStore";
import { shopPartsHref } from "@/lib/shop/partsCatalog";
import { cn } from "@/lib/utils";

type Props = {
  /** Prefer active bike; falls back to first */
  className?: string;
  /** Compact layout for Garage overview */
  compact?: boolean;
  /** Force show even when snoozed (e.g. Garage tab) */
  ignoreSnooze?: boolean;
};

function getSnoozeSnapshot() {
  return isMaintenanceCardSnoozed();
}

function getSnoozeServerSnapshot() {
  return false;
}

export function MaintenanceStatusCard({
  className,
  compact = false,
  ignoreSnooze = false,
}: Props) {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const rides = useAppStore((s) => s.rides);
  const intervals = useAppStore((s) => s.maintenanceIntervals);

  const snoozed = useSyncExternalStore(
    subscribeMaintenanceCardSnooze,
    getSnoozeSnapshot,
    getSnoozeServerSnapshot
  );

  const bike =
    bikes.find((b) => b.id === activeBikeId) || bikes[0] || null;

  const summary: MaintenanceSummary = useMemo(() => {
    if (bikes.length === 0) {
      return getMaintenanceSummary(null, intervals);
    }
    const last = bike ? lastRideForBike(rides, bike.id) : undefined;
    return getMaintenanceSummary(bike, intervals, {
      lastRideAt: last?.startTime,
      lastRideDistanceKm: last ? last.distanceM / 1000 : null,
    });
  }, [bikes.length, bike, intervals, rides]);

  const onSnooze = useCallback(() => {
    snoozeMaintenanceCard(7);
  }, []);

  const onClearSnooze = useCallback(() => {
    clearMaintenanceCardSnooze();
  }, []);

  if (snoozed && !ignoreSnooze && summary.status !== "empty") {
    return (
      <section
        className={cn(
          "rounded-2xl border border-dashed border-border bg-surface/60 px-4 py-3",
          className
        )}
        data-testid="maintenance-card-snoozed"
      >
        <div className="flex items-center justify-between gap-2 text-sm text-text-secondary">
          <span>Wartungs-Hinweis für 7 Tage ausgeblendet</span>
          <button
            type="button"
            onClick={onClearSnooze}
            className="text-xs font-medium text-accent hover:underline"
          >
            Wieder anzeigen
          </button>
        </div>
      </section>
    );
  }

  const tone =
    summary.status === "overdue"
      ? "error"
      : summary.status === "due_soon"
        ? "warning"
        : summary.status === "ok"
          ? "success"
          : "neutral";

  const borderCls =
    tone === "error"
      ? "border-error/40"
      : tone === "warning"
        ? "border-warning/40"
        : tone === "success"
          ? "border-success/30"
          : "border-border";

  const Icon =
    summary.status === "empty"
      ? Plus
      : summary.status === "ok"
        ? CheckCircle2
        : summary.status === "overdue"
          ? AlertTriangle
          : Wrench;

  const iconCls =
    tone === "error"
      ? "text-error"
      : tone === "warning"
        ? "text-warning"
        : tone === "success"
          ? "text-success"
          : "text-accent";

  const ctaLabel =
    summary.status === "empty"
      ? "Rad hinzufügen"
      : "Status ansehen";

  return (
    <section
      className={cn(
        "relative rounded-2xl border bg-surface p-4",
        borderCls,
        className
      )}
      data-testid="maintenance-status-card"
      data-status={summary.status}
      id="wartung"
    >
      <div className="flex items-start gap-3">
        <div
          className={cn(
            "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-surface-elevated",
            iconCls
          )}
        >
          <Icon className="h-5 w-5" aria-hidden />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
            Wartungs-Status
            {bike && summary.status !== "empty" ? (
              <span className="font-normal"> · {bike.name}</span>
            ) : null}
          </p>
          <h2
            className={cn(
              "mt-0.5 font-semibold leading-snug",
              compact ? "text-base" : "text-lg"
            )}
          >
            {summary.headline}
          </h2>
          <p className="mt-1 text-sm text-text-secondary">{summary.detail}</p>
          {summary.dueCount > 1 && (
            <p className="mt-1 text-xs text-text-secondary">
              {summary.overdueCount > 0
                ? `${summary.overdueCount} überfällig`
                : null}
              {summary.overdueCount > 0 && summary.dueSoonCount > 0
                ? " · "
                : null}
              {summary.dueSoonCount > 0
                ? `${summary.dueSoonCount} bald fällig`
                : null}
            </p>
          )}
        </div>
        {summary.status !== "empty" && !ignoreSnooze && (
          <button
            type="button"
            onClick={onSnooze}
            className="shrink-0 rounded-lg p-1.5 text-text-secondary hover:bg-surface-elevated hover:text-foreground"
            aria-label="7 Tage ausblenden"
            title="7 Tage ausblenden"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      <div className={cn("mt-3 flex flex-wrap gap-2", compact && "mt-2")}>
        <Link
          href={summary.href}
          className="inline-flex flex-1 items-center justify-center gap-1 rounded-xl bg-accent px-4 py-2.5 text-sm font-semibold text-white hover:bg-accent-hover sm:flex-none"
        >
          {ctaLabel}
          <ChevronRight className="h-4 w-4" />
        </Link>
        {(summary.status === "overdue" || summary.status === "due_soon") &&
        bike ? (
          <Link
            href={shopPartsHref({ bike: bike.id, fit: "bike" })}
            className="inline-flex items-center justify-center rounded-xl border border-accent/40 bg-accent/10 px-3 py-2.5 text-xs font-semibold text-accent"
            data-testid="maintenance-parts-cta"
          >
            Passende Teile
          </Link>
        ) : null}
        {summary.status !== "empty" && !ignoreSnooze && (
          <button
            type="button"
            onClick={onSnooze}
            className="inline-flex items-center justify-center rounded-xl border border-border px-3 py-2.5 text-xs font-medium text-text-secondary hover:bg-surface-elevated"
          >
            Später (7 Tage)
          </button>
        )}
      </div>
    </section>
  );
}
