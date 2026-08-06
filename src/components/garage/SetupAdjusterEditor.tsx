"use client";

import { getComponentModel } from "@/lib/catalog/components";
import { slotLabel } from "@/lib/catalog/slots";
import { isOutOfSpec } from "@/lib/setup/ranges";
import type { Bike } from "@/types";

/**
 * Editierbare Setup-Adjuster (slot.key → Zahl).
 * Speichern läuft über createSetupVersion(valueOverrides).
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
        return {
          key,
          label: `${slotLabel(comp.slot)} · ${adj.label}`,
          unit: adj.unit,
          min: adj.min,
          max: adj.max ?? adj.totalClicks,
          step: adj.step ?? 1,
          value,
          oos,
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

  return (
    <div className="flex max-h-64 flex-col gap-2 overflow-y-auto">
      {rows.map((r) => (
        <label key={r.key} className="text-xs">
          <span className="flex justify-between gap-2">
            <span>{r.label}</span>
            <span
              className={`tabular-nums font-medium ${
                r.oos ? "text-warning" : "text-foreground"
              }`}
            >
              {r.value}
              {r.unit ? ` ${r.unit}` : ""}
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
