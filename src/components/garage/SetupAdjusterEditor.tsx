"use client";

import { useState } from "react";
import { getComponentModel } from "@/lib/catalog/components";
import { slotLabel } from "@/lib/catalog/slots";
import { isOutOfSpec } from "@/lib/setup/ranges";
import type { Bike } from "@/types";

/**
 * Editierbare Setup-Adjuster (slot.key → Zahl).
 * Speichern läuft über createSetupVersion(valueOverrides).
 * psi↔bar Toggle; Klicks mit Referenz „von geschlossen/offen“.
 */
export function SetupAdjusterEditor({
  bike,
  values,
  onChange,
}: {
  bike: Bike;
  values: Record<string, number>;
  onChange: (next: Record<string, number>) => void;
}) {
  const [pressureUnit, setPressureUnit] = useState<"psi" | "bar">("psi");

  const rows = bike.components
    .filter((c) => !c.removedAt)
    .flatMap((comp) => {
      const model = comp.componentModelId
        ? getComponentModel(comp.componentModelId)
        : undefined;
      const adjusters = model?.adjusters ?? [];
      return adjusters.map((adj) => {
        const key = `${comp.slot}.${adj.key}`;
        const fromSettings = comp.currentSettings[adj.key];
        const fallback =
          typeof fromSettings === "number"
            ? fromSettings
            : typeof fromSettings === "string" &&
                !Number.isNaN(Number(fromSettings))
              ? Number(fromSettings)
              : adj.min ?? 0;
        const value = values[key] ?? fallback;
        const oos = isOutOfSpec(comp.componentModelId, adj.key, value);
        const isPsi = adj.unit === "psi";
        const isClicks = adj.unit === "clicks";
        return {
          key,
          label: `${slotLabel(comp.slot)} · ${adj.label}`,
          unit: adj.unit,
          min: adj.min,
          max: adj.max ?? adj.totalClicks,
          step: adj.step ?? 1,
          value,
          oos,
          isPsi,
          isClicks,
          totalClicks: adj.totalClicks,
          reference: adj.reference,
        };
      });
    });

  if (rows.length === 0) {
    return (
      <p className="text-xs text-text-secondary">
        Keine Adjuster am Bike — Gabel/Dämpfer/Reifen mit Modell-ID nötig.
      </p>
    );
  }

  const displayValue = (r: (typeof rows)[0]) => {
    if (r.isPsi && pressureUnit === "bar") {
      return (r.value / 14.5038).toFixed(2);
    }
    return String(r.value);
  };

  const displayUnit = (r: (typeof rows)[0]) => {
    if (r.isPsi) return pressureUnit;
    if (r.isClicks) return "clicks";
    return r.unit;
  };

  return (
    <div className="flex max-h-72 flex-col gap-2 overflow-y-auto">
      <div className="flex items-center justify-between text-[11px]">
        <span className="text-text-secondary">Luftdruck-Einheit</span>
        <div className="flex gap-1">
          {(["psi", "bar"] as const).map((u) => (
            <button
              key={u}
              type="button"
              onClick={() => setPressureUnit(u)}
              className={`rounded px-2 py-0.5 ${
                pressureUnit === u
                  ? "bg-accent text-white"
                  : "bg-surface-elevated text-text-secondary"
              }`}
            >
              {u}
            </button>
          ))}
        </div>
      </div>
      {rows.map((r) => (
        <label key={r.key} className="text-xs">
          <span className="flex justify-between gap-2">
            <span>
              {r.label}
              {r.isClicks && r.totalClicks != null && (
                <span className="ml-1 text-text-secondary">
                  ({r.value}/{r.totalClicks}
                  {r.reference === "from_open"
                    ? " von offen"
                    : " von geschlossen"}
                  )
                </span>
              )}
            </span>
            <span
              className={`tabular-nums font-medium ${
                r.oos ? "text-warning" : "text-foreground"
              }`}
            >
              {displayValue(r)} {displayUnit(r)}
              {r.oos ? " · außerhalb Spec" : ""}
            </span>
          </span>
          <input
            type="range"
            min={r.min ?? 0}
            max={r.max ?? 100}
            step={r.step}
            value={r.value}
            onChange={(e) =>
              onChange({ ...values, [r.key]: Number(e.target.value) })
            }
            className="mt-1 w-full"
          />
        </label>
      ))}
    </div>
  );
}

export function seedAdjusterValuesFromBike(bike: Bike): Record<string, number> {
  const out: Record<string, number> = {};
  for (const comp of bike.components.filter((c) => !c.removedAt)) {
    const model = comp.componentModelId
      ? getComponentModel(comp.componentModelId)
      : undefined;
    for (const adj of model?.adjusters ?? []) {
      const key = `${comp.slot}.${adj.key}`;
      const fromSettings = comp.currentSettings[adj.key];
      if (typeof fromSettings === "number") out[key] = fromSettings;
      else if (
        typeof fromSettings === "string" &&
        !Number.isNaN(Number(fromSettings))
      ) {
        out[key] = Number(fromSettings);
      } else if (adj.min !== undefined) out[key] = adj.min;
    }
  }
  return out;
}
