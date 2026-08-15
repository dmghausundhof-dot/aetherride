/**
 * Aggregated Wartungs-Status for Home card + Garage badge (T-WA-00).
 * Reuses evaluateIntervalDue — does not reimplement interval math.
 */

import type { Bike, MaintenanceInterval, Ride } from "@/types";
import { slotLabel } from "@/lib/catalog/slots";
import {
  evaluateIntervalDue,
  type DueStatus,
} from "@/lib/maintenance/intervals";

export type MaintenanceSummaryStatus = "empty" | "ok" | "due_soon" | "overdue";

export interface MaintenanceSummaryItem {
  intervalId: string;
  bikeId: string;
  slot: MaintenanceInterval["slot"];
  label: string;
  /** Short German slot name e.g. "Kette" */
  shortLabel: string;
  status: Exclude<DueStatus, "ok">;
  progressPct: number;
  remainingLabel: string;
}

export interface MaintenanceSummary {
  status: MaintenanceSummaryStatus;
  overdueCount: number;
  dueSoonCount: number;
  /** overdue + due_soon */
  dueCount: number;
  okCount: number;
  totalIntervals: number;
  topItem: MaintenanceSummaryItem | null;
  items: MaintenanceSummaryItem[];
  /** German one-liner for the card body */
  headline: string;
  /** Secondary line (last ride, remaining, etc.) */
  detail: string;
  /** Deep-link into Garage maintenance tab (optional bike) */
  href: string;
}

export interface MaintenanceSummaryOptions {
  now?: Date;
  /** ISO startTime of last ride on this bike (for Ok copy) */
  lastRideAt?: string | null;
  lastRideDistanceKm?: number | null;
}

function rankStatus(s: DueStatus): number {
  if (s === "overdue") return 0;
  if (s === "due_soon") return 1;
  return 2;
}

function formatLastRide(
  lastRideAt?: string | null,
  lastRideDistanceKm?: number | null
): string {
  if (!lastRideAt) return "noch keine Fahrt geloggt";
  const d = new Date(lastRideAt);
  if (Number.isNaN(d.getTime())) return "noch keine Fahrt geloggt";
  const dateStr = d.toLocaleDateString("de-DE", {
    day: "numeric",
    month: "short",
  });
  if (lastRideDistanceKm != null && lastRideDistanceKm > 0) {
    return `letzte Fahrt ${dateStr} · ${Math.round(lastRideDistanceKm)} km`;
  }
  return `letzte Fahrt ${dateStr}`;
}

/**
 * Aggregate interval due status for one bike.
 * Empty when bike is null/undefined (caller may also treat bikes.length === 0).
 */
export function getMaintenanceSummary(
  bike: Bike | null | undefined,
  intervals: MaintenanceInterval[],
  options: MaintenanceSummaryOptions = {}
): MaintenanceSummary {
  const now = options.now ?? new Date();

  if (!bike) {
    return {
      status: "empty",
      overdueCount: 0,
      dueSoonCount: 0,
      dueCount: 0,
      okCount: 0,
      totalIntervals: 0,
      topItem: null,
      items: [],
      headline: "Noch kein Rad in der Werkstatt.",
      detail: "Rad abstellen → Service-Check in 2 Min",
      href: "/garage?wizard=catalog",
    };
  }

  const bikeIntervals = intervals.filter((i) => i.bikeId === bike.id);
  const items: MaintenanceSummaryItem[] = [];
  let okCount = 0;

  for (const interval of bikeIntervals) {
    const due = evaluateIntervalDue(
      interval,
      bike.totalOdometerKm,
      bike.totalHours,
      now
    );
    if (due.status === "ok") {
      okCount += 1;
      continue;
    }
    items.push({
      intervalId: interval.id,
      bikeId: bike.id,
      slot: interval.slot,
      label: interval.label,
      shortLabel: slotLabel(interval.slot),
      status: due.status,
      progressPct: due.progressPct,
      remainingLabel: due.remainingLabel,
    });
  }

  items.sort((a, b) => {
    const r = rankStatus(a.status) - rankStatus(b.status);
    if (r !== 0) return r;
    return b.progressPct - a.progressPct;
  });

  const overdueCount = items.filter((i) => i.status === "overdue").length;
  const dueSoonCount = items.filter((i) => i.status === "due_soon").length;
  const topItem = items[0] ?? null;
  const href = `/garage?tab=maintenance&bike=${encodeURIComponent(bike.id)}`;

  if (overdueCount > 0 || dueSoonCount > 0) {
    const status: MaintenanceSummaryStatus =
      overdueCount > 0 ? "overdue" : "due_soon";
    let headline: string;
    if (topItem) {
      if (topItem.status === "overdue") {
        headline = `${topItem.shortLabel} · überfällig · jetzt checken`;
      } else {
        // e.g. "Kette · 180 km · bald checken" — remaining from engine
        const rem = topItem.remainingLabel.split(" · ")[0] || topItem.remainingLabel;
        headline = `${topItem.shortLabel} · ${rem} · bald checken`;
      }
    } else {
      headline = "Wartung fällig";
    }
    const extra =
      items.length > 1
        ? ` · +${items.length - 1} weitere`
        : "";
    return {
      status,
      overdueCount,
      dueSoonCount,
      dueCount: overdueCount + dueSoonCount,
      okCount,
      totalIntervals: bikeIntervals.length,
      topItem,
      items,
      headline,
      detail: `${topItem?.label ?? "Service"}${extra}`,
      href,
    };
  }

  const lastRide = formatLastRide(options.lastRideAt, options.lastRideDistanceKm);
  return {
    status: "ok",
    overdueCount: 0,
    dueSoonCount: 0,
    dueCount: 0,
    okCount,
    totalIntervals: bikeIntervals.length,
    topItem: null,
    items: [],
    headline: `Alles ok · ${lastRide}`,
    detail: okCount > 0 ? `${okCount} Intervalle im Blick` : "Status ansehen",
    href,
  };
}

/** Last ride for a bike from a rides list (newest first assumed or sorted). */
export function lastRideForBike(
  rides: Ride[],
  bikeId: string
): Ride | undefined {
  const forBike = rides.filter((r) => r.bikeId === bikeId);
  if (forBike.length === 0) return undefined;
  return [...forBike].sort(
    (a, b) =>
      new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
  )[0];
}

/**
 * Fleet-level due counts for nav badge (all bikes).
 * Counts unique intervals that are overdue or due_soon.
 */
export function getFleetMaintenanceDueCount(
  bikes: Bike[],
  intervals: MaintenanceInterval[],
  now = new Date()
): { overdue: number; dueSoon: number; dueTotal: number } {
  let overdue = 0;
  let dueSoon = 0;
  for (const bike of bikes) {
    const s = getMaintenanceSummary(bike, intervals, { now });
    overdue += s.overdueCount;
    dueSoon += s.dueSoonCount;
  }
  return { overdue, dueSoon, dueTotal: overdue + dueSoon };
}
