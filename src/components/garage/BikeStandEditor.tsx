"use client";

import { useEffect, useRef, useState } from "react";
import { useHofCopy } from "@/hooks/useHofCopy";

/** km and hours in one sheet — no jump into the Setups tab. */
export function BikeStandEditor({
  km,
  hours,
  focusHours = false,
  onClose,
  onSave,
}: {
  km: number;
  hours: number;
  focusHours?: boolean;
  onClose: () => void;
  onSave: (next: { km: number; hours: number }) => void;
}) {
  const copy = useHofCopy();
  const [kmRaw, setKmRaw] = useState(
    km > 0 ? String(Math.round(km)) : ""
  );
  const [hoursRaw, setHoursRaw] = useState(
    hours > 0 ? hours.toFixed(1) : ""
  );
  const kmRef = useRef<HTMLInputElement>(null);
  const hoursRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    (focusHours ? hoursRef : kmRef).current?.focus();
  }, [focusHours]);

  const apply = () => {
    const nextKm = Math.max(0, Number(kmRaw.replace(",", ".")) || 0);
    const nextH = Math.max(0, Number(hoursRaw.replace(",", ".")) || 0);
    onSave({ km: nextKm, hours: nextH });
  };

  return (
    <div
      className="fixed inset-0 z-[80] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal
      aria-labelledby="bike-stand-editor-title"
      data-testid="bike-stand-editor"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-t-2xl border border-border bg-surface p-5 sm:rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 id="bike-stand-editor-title" className="text-lg font-bold">
          {copy.workshopStandTitle}
        </h3>
        <p className="mt-1 text-sm text-text-secondary">
          {copy.workshopStandHint}
        </p>
        <p className="mt-1 text-xs text-text-secondary">
          {copy.workshopStandStravaHint}
        </p>
        <div className="mt-4 grid grid-cols-2 gap-3">
          <label className="block text-sm">
            {copy.workshopStatKm}
            <input
              ref={kmRef}
              type="number"
              min={0}
              inputMode="decimal"
              value={kmRaw}
              onChange={(e) => setKmRaw(e.target.value)}
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
              data-testid="bike-stand-km"
            />
          </label>
          <label className="block text-sm">
            {copy.workshopStatHours}
            <input
              ref={hoursRef}
              type="number"
              min={0}
              step={0.1}
              inputMode="decimal"
              value={hoursRaw}
              onChange={(e) => setHoursRaw(e.target.value)}
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
              data-testid="bike-stand-hours"
            />
          </label>
        </div>
        <div className="mt-4 flex gap-2">
          <button
            type="button"
            onClick={onClose}
            className="min-h-11 flex-1 rounded-xl border border-border px-3 text-sm font-semibold"
          >
            {copy.shopCancel}
          </button>
          <button
            type="button"
            onClick={apply}
            className="min-h-11 flex-1 rounded-xl bg-chrome px-3 text-sm font-semibold text-on-accent"
          >
            {copy.workshopStandSave}
          </button>
        </div>
      </div>
    </div>
  );
}
