"use client";

import { useState } from "react";
import type { Bike, ComponentSlot } from "@/types";
import { getActiveComponents } from "@/store/useAppStore";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { cn } from "@/lib/utils";
import {
  resolveGaragePrimaryAction,
  garagePrimaryActionLabelDe,
  type GaragePrimaryAction,
} from "@/lib/garage/primaryCta";

/**
 * Einfache Bike-Übersicht (Einsteiger-Default).
 * Kein Komponenten-/Silhouette-Schema — Name, Typ, km und Wartungsstatus.
 * Technische Specs hinter „Technische Details“.
 */
export function BikeSchema({
  bike,
  maintenanceSlots = [],
  onPrimaryAction,
}: {
  bike: Bike;
  /** Slots mit fälliger Wartung — nur für Status-Zähler, keine Hotspots. */
  maintenanceSlots?: ComponentSlot[];
  onPrimaryAction?: (action: GaragePrimaryAction) => void;
  /** @deprecated Hotspot-Auswahl entfernt; Prop bleibt für Call-Sites. */
  onSelectSlot?: (slot: ComponentSlot) => void;
  selectedSlot?: ComponentSlot | null;
}) {
  const [techOpen, setTechOpen] = useState(false);
  const active = getActiveComponents(bike);

  const dueCount = maintenanceSlots.length;
  const statusLabel =
    dueCount === 0
      ? "Alles in Ordnung"
      : dueCount === 1
        ? "1 Wartung fällig"
        : `${dueCount} Wartungen fällig`;
  const statusTone = dueCount === 0 ? "text-success" : "text-warning";

  const category = bikeCategoryLabel(bike.category);
  const showEbike =
    bike.isEbike ||
    bike.category === "emtb" ||
    bike.category === "etrekking";
  const ebikeBadge =
    showEbike &&
    !category.toLowerCase().startsWith("e-") &&
    !category.toLowerCase().startsWith("e ");

  const action = resolveGaragePrimaryAction({
    isActive: bike.isActive,
    dueCount,
    partsCount: active.length,
  });

  const techRows: [string, string][] = [];
  if (bike.year) techRows.push(["Jahr", String(bike.year)]);
  if (bike.frameSize) techRows.push(["Rahmen", bike.frameSize]);
  if (bike.wheelSizeFront || bike.wheelSizeRear) {
    techRows.push([
      "Laufrad",
      [bike.wheelSizeFront, bike.wheelSizeRear].filter(Boolean).join(" / "),
    ]);
  }
  if (bike.travelFrontMm != null) {
    techRows.push([
      "Federweg",
      `${bike.travelFrontMm}/${bike.travelRearMm ?? "–"} mm`,
    ]);
  }
  if (bike.totalHours > 0) {
    techRows.push(["Stunden", bike.totalHours.toFixed(1)]);
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-surface p-4">
      <div className="mb-2 flex flex-wrap gap-1.5">
        <span className="rounded-full bg-accent/15 px-2.5 py-0.5 text-[11px] font-bold text-accent">
          {category}
        </span>
        {ebikeBadge && (
          <span className="rounded-full bg-surface-elevated px-2.5 py-0.5 text-[11px] font-bold text-text-primary">
            E-Bike
          </span>
        )}
        {bike.isActive && (
          <span className="rounded-full bg-accent px-2.5 py-0.5 text-[11px] font-bold text-white">
            Aktiv
          </span>
        )}
      </div>
      <div className="space-y-1.5">
        <h3 className="text-base font-semibold">{bike.name}</h3>
        <p className={cn("text-sm font-semibold", statusTone)}>{statusLabel}</p>
        <p className="text-xs text-text-secondary">
          {[
            `${bike.totalOdometerKm.toFixed(0)} km`,
            active.length > 0 ? `${active.length} Teile` : null,
            bike.frameSize || null,
          ]
            .filter(Boolean)
            .join(" · ")}
        </p>
      </div>
      {onPrimaryAction && (
        <button
          type="button"
          onClick={() => onPrimaryAction(action)}
          className="mt-3 w-full rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
        >
          {garagePrimaryActionLabelDe(action)}
        </button>
      )}
      {techRows.length > 0 && (
        <div className="mt-3 border-t border-border pt-2">
          <button
            type="button"
            onClick={() => setTechOpen((v) => !v)}
            className="flex w-full items-center justify-between text-left text-sm font-semibold"
          >
            Technische Details
            <span className="text-xs font-normal text-text-secondary">
              {techOpen ? "Zuklappen" : "Federweg, Rahmen…"}
            </span>
          </button>
          {techOpen && (
            <dl className="mt-2 space-y-1.5">
              {techRows.map(([k, v]) => (
                <div key={k} className="flex justify-between gap-3 text-xs">
                  <dt className="text-text-secondary">{k}</dt>
                  <dd className="font-medium tabular-nums">{v}</dd>
                </div>
              ))}
            </dl>
          )}
        </div>
      )}
    </div>
  );
}

/** @deprecated Alias — gleiche einfache Übersicht. */
export { BikeSchema as BikeSilhouette };
