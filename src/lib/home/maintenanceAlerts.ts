/**
 * Home-Wartungszeilen (Spec 4.7.1): max. 2 Hinweise.
 * Kombiniert Intervall-Fälligkeit + Wear-Forecast.
 */

import type { Bike, MaintenanceInterval, Ride } from "@/types";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import { shopHref, wearKindToShopSlot } from "@/lib/shop/catalog";

export interface MaintenanceAlert {
  id: string;
  severity: "overdue" | "due_soon";
  title: string;
  detail: string;
  reasoning: string;
  sourceLabel: string;
  href: string;
  /** Optionaler Shop-Deep-Link bei Verschleiß */
  shopHref?: string;
}

export function buildMaintenanceAlerts(input: {
  bike: Bike;
  rides: Ride[];
  intervals: MaintenanceInterval[];
  max?: number;
}): MaintenanceAlert[] {
  const max = input.max ?? 2;
  const alerts: MaintenanceAlert[] = [];

  for (const interval of input.intervals.filter((i) => i.bikeId === input.bike.id)) {
    const due = evaluateIntervalDue(
      interval,
      input.bike.totalOdometerKm,
      input.bike.totalHours
    );
    if (due.status === "ok") continue;
    alerts.push({
      id: `iv-${interval.id}`,
      severity: due.status,
      title: interval.label,
      detail:
        due.status === "overdue"
          ? `Überfällig · ${due.remainingLabel}`
          : `Bald fällig · noch ${due.remainingLabel}`,
      reasoning: `Fortschritt ${due.progressPct}%. Quelle: ${interval.sourceLabel}`,
      sourceLabel: interval.sourceLabel,
      href: "/garage?tab=maintenance",
      shopHref: shopHref({
        slot: wearKindToShopSlot(interval.slot),
        job: "replace",
        bike: input.bike.id,
      }),
    });
  }

  for (const w of forecastWear(input.bike, input.rides)) {
    if (!w.dueSoon && w.usedRatio < 0.8) continue;
    const severity: "overdue" | "due_soon" =
      w.usedRatio >= 1 || w.remainingKmHigh <= 0 ? "overdue" : "due_soon";
    const slot = wearKindToShopSlot(w.kind);
    alerts.push({
      id: `wear-${w.kind}`,
      severity,
      title: w.label,
      detail: `${w.slotLabel} · ${w.remainingKmLow}–${w.remainingKmHigh} km Rest`,
      reasoning: w.reasoning,
      sourceLabel: w.sourceLabel,
      href: "/garage?tab=maintenance",
      // S-FLOW-05: wear → parts with bike soft-fit (never bare /shop)
      shopHref: shopHref({
        slot: slot ?? undefined,
        job: "replace",
        bike: input.bike.id,
      }),
    });
  }

  const rank = (s: MaintenanceAlert["severity"]) => (s === "overdue" ? 0 : 1);
  alerts.sort((a, b) => rank(a.severity) - rank(b.severity));

  // Dedup by title prefix similarity
  const seen = new Set<string>();
  const unique: MaintenanceAlert[] = [];
  for (const a of alerts) {
    const key = a.title.toLowerCase().slice(0, 24);
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(a);
    if (unique.length >= max) break;
  }
  return unique;
}

export function bikeReadyStatus(
  alerts: MaintenanceAlert[]
): "ready" | "attention" | "blocked" {
  if (alerts.some((a) => a.severity === "overdue")) return "attention";
  if (alerts.some((a) => a.severity === "due_soon")) return "attention";
  return "ready";
}
