"use client";

import { useState } from "react";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useAppStore } from "@/store/useAppStore";

export function FamilyRiderStrip({ bikeId }: { bikeId: string }) {
  const copy = useHofCopy();
  const riders = useAppStore((s) => s.familyRiders);
  const activeId = useAppStore((s) => s.activeFamilyRiderId);
  const setActive = useAppStore((s) => s.setActiveFamilyRider);
  const addFamilyRider = useAppStore((s) => s.addFamilyRider);
  const [adding, setAdding] = useState(false);
  const [name, setName] = useState("");
  const [kg, setKg] = useState("70");

  const submit = () => {
    const n = name.trim();
    const w = Number(kg);
    if (!n || !Number.isFinite(w) || w < 20 || w > 200) return;
    const wasIch = activeId == null;
    addFamilyRider(n, w);
    if (wasIch) setActive(null, bikeId);
    setName("");
    setKg("70");
    setAdding(false);
  };

  return (
    <div className="space-y-1.5" data-testid="garage-family-strip">
      <p className="text-[11px] text-text-secondary">
        {riders.length === 0
          ? copy.workshopFamilyHintEmpty
          : copy.workshopFamilyHint}
      </p>
      <div className="flex flex-wrap gap-1.5">
        <button
          type="button"
          onClick={() => setActive(null, bikeId)}
          className={`min-h-11 rounded-full border px-3 py-1.5 text-xs font-semibold ${
            activeId == null
              ? "border-chrome bg-chrome text-on-accent"
              : "border-border bg-surface text-text-secondary"
          }`}
        >
          {copy.workshopFamilyYou}
        </button>
        {riders.map((r) => (
          <button
            key={r.id}
            type="button"
            onClick={() => setActive(r.id, bikeId)}
            className={`min-h-11 rounded-full border px-3 py-1.5 text-xs font-semibold ${
              activeId === r.id
                ? "border-chrome bg-chrome text-on-accent"
                : "border-border bg-surface text-text-secondary"
            }`}
          >
            {r.displayName} · {Math.round(r.weightKg)} kg
          </button>
        ))}
        <button
          type="button"
          onClick={() => setAdding((v) => !v)}
          className="min-h-11 rounded-full border border-dashed border-border px-3 py-1.5 text-xs font-semibold text-text-secondary"
        >
          {copy.workshopFamilyAdd}
        </button>
      </div>
      {adding ? (
        <div className="flex flex-wrap items-center gap-2">
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={copy.workshopFamilyName}
            className="min-h-11 min-w-[8rem] flex-1 rounded-xl border border-border bg-surface-elevated px-3 text-sm"
          />
          <input
            type="number"
            value={kg}
            onChange={(e) => setKg(e.target.value)}
            aria-label={copy.workshopFamilyWeight}
            className="min-h-11 w-20 rounded-xl border border-border bg-surface-elevated px-2 text-sm"
          />
          <button
            type="button"
            onClick={submit}
            className="min-h-11 rounded-xl bg-chrome px-3 text-xs font-semibold text-on-accent"
          >
            {copy.workshopFamilyAdd}
          </button>
        </div>
      ) : null}
    </div>
  );
}
