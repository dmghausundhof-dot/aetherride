"use client";

import { useMemo, useState } from "react";
import type { Bike, BikeCategory } from "@/types";
import { estimateAirPsi, sagMeasureSteps } from "@/lib/setup/sagGuide";
import { recommendedSagPct } from "@/lib/setup/ranges";

export function SagGuidePanel({
  category,
  travelFrontMm,
  travelRearMm,
  defaultWeightKg,
  bikeWeightKg,
}: {
  category: BikeCategory;
  travelFrontMm?: number;
  travelRearMm?: number;
  defaultWeightKg?: number;
  bikeWeightKg?: number;
}) {
  const [weight, setWeight] = useState(defaultWeightKg ?? 75);
  const [gear, setGear] = useState(5);
  const [end, setEnd] = useState<"fork" | "shock">("fork");

  const estimate = useMemo(
    () =>
      estimateAirPsi({
        riderWeightKg: weight,
        gearWeightKg: gear,
        bikeWeightKg,
        category,
        end,
        travelMm: end === "fork" ? travelFrontMm : travelRearMm,
      }),
    [weight, gear, bikeWeightKg, category, end, travelFrontMm, travelRearMm]
  );

  const steps = sagMeasureSteps(end);
  const forkSag = recommendedSagPct(category, "fork");
  const shockSag = recommendedSagPct(category, "shock");

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="font-semibold">SAG einstellen</h3>
      <p className="mt-1 text-xs text-text-secondary">
        Gewicht → Luft-Richtwert → am Rad messen. Quellen: Enduro MTB Mag /
        Simplon / Dirt (SAG-Spannen).
      </p>

      <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
        <label className="flex flex-col gap-1">
          <span className="text-xs text-text-secondary">Fahrer (kg)</span>
          <input
            type="number"
            min={40}
            max={150}
            value={weight}
            onChange={(e) => setWeight(Number(e.target.value) || 75)}
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-xs text-text-secondary">Ausrüstung (kg)</span>
          <input
            type="number"
            min={0}
            max={30}
            value={gear}
            onChange={(e) => setGear(Number(e.target.value) || 0)}
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
      </div>

      <div className="mt-2 grid grid-cols-2 gap-1 rounded-xl bg-surface-elevated p-1 text-xs">
        {(
          [
            ["fork", "Gabel"],
            ["shock", "Dämpfer"],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setEnd(id)}
            className={`rounded-lg py-2 font-medium ${
              end === id ? "bg-accent text-on-accent" : "text-text-secondary"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="mt-3 grid grid-cols-3 gap-2 text-center text-sm">
        <div className="rounded-xl bg-surface-elevated p-2">
          <div className="tabular-nums text-lg font-bold">
            {estimate.sag.target}%
            {estimate.sagMm != null ? ` · ${estimate.sagMm}` : ""}
          </div>
          <div className="text-[10px] text-text-secondary">
            SAG-Ziel ({estimate.sag.min}–{estimate.sag.max}
            {estimate.sagMm != null ? " %, mm" : ""})
          </div>
        </div>
        <div className="rounded-xl bg-surface-elevated p-2">
          <div className="tabular-nums text-lg font-bold">
            {estimate.psiTarget}
          </div>
          <div className="text-[10px] text-text-secondary">psi Start</div>
        </div>
        <div className="rounded-xl bg-surface-elevated p-2">
          <div className="tabular-nums text-lg font-bold">
            {estimate.psiMin}–{estimate.psiMax}
          </div>
          <div className="text-[10px] text-text-secondary">psi Spanne</div>
        </div>
      </div>

      <p className="mt-2 text-[11px] text-text-secondary">{estimate.note}</p>

      <ol className="mt-3 list-decimal space-y-1 pl-4 text-xs text-text-secondary">
        {steps.map((s) => (
          <li key={s}>{s}</li>
        ))}
      </ol>

      <p className="mt-3 text-[11px] text-text-secondary">
        Magazin-Spannen: Gabel {forkSag.min}–{forkSag.max} % · Dämpfer{" "}
        {shockSag.min}–{shockSag.max} %
      </p>
    </section>
  );
}

/** Optional helper if parent only has bike */
export function SagGuideForBike({
  bike,
  defaultWeightKg,
}: {
  bike: Bike;
  defaultWeightKg?: number;
}) {
  return (
    <SagGuidePanel
      category={bike.category}
      travelFrontMm={bike.travelFrontMm}
      travelRearMm={bike.travelRearMm}
      defaultWeightKg={defaultWeightKg}
      bikeWeightKg={bike.weightKg}
    />
  );
}
