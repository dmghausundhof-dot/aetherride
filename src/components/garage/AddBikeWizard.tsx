"use client";

import { useState } from "react";
import {
  addCategories,
  addTileSelected,
  assistModeFor,
  coerceCategory,
  defaultWheelFor,
  persistCategory,
  persistIsEbike,
  subtypeLabel,
  type BikeAssistMode,
} from "@/lib/garage/bikeAssist";
import { hofSportLabel } from "@/lib/home/hofSportLabel";
import { useAppStore } from "@/store/useAppStore";
import { notifyGarageBikeShopify, garageBikeInputFromBike } from "@/lib/shop/notifyGarageBikeShopify";
import { useHofCopy } from "@/hooks/useHofCopy";
import { radSilhouetteSrc } from "@/lib/garage/radMark";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import { RadGlyph } from "@/components/garage/RadGlyph";
import type { BikeCategory } from "@/types";
import { X } from "lucide-react";

export function AddBikeWizard({
  onClose,
  initialCategory,
}: {
  onClose: () => void;
  initialCategory?: BikeCategory;
}) {
  const copy = useHofCopy();
  const addBikeBasic = useAppStore((s) => s.addBikeBasic);
  const bikes = useAppStore((s) => s.bikes);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);

  const seedCategory = initialCategory ?? "urban";
  const [assistMode, setAssistMode] = useState<BikeAssistMode>(() =>
    assistModeFor(seedCategory)
  );
  const [category, setCategory] = useState<BikeCategory>(seedCategory);
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);

  const freeBlocked = subscriptionTier === "free" && bikes.length >= 1;
  const types = addCategories(assistMode);
  const isEbike = persistIsEbike(category, assistMode);
  const persisted = persistCategory(category, assistMode);

  const onAssistChange = (next: BikeAssistMode) => {
    setAssistMode(next);
    setCategory((c) => coerceCategory(c, next));
  };

  const submit = () => {
    setError(null);
    if (freeBlocked) {
      setError("Im Free-Tarif nur ein Rad. Pro unter Profil freischalten.");
      return;
    }
    try {
      const wheel = defaultWheelFor(persisted);
      const createdId = addBikeBasic({
        name: name.trim(),
        category: persisted,
        isEbike,
        wheelSizeFront: wheel,
        wheelSizeRear: wheel,
      });
      if (createdId) {
        const created = useAppStore.getState().bikes.find((b) => b.id === createdId);
        if (created) notifyGarageBikeShopify(garageBikeInputFromBike(created));
      }
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Anlegen fehlgeschlagen");
    }
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4">
      <div className="w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="flex items-center gap-2 text-lg font-bold">
            <RadGlyph name="add" size={20} />
            {copy.workshopAdd}
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Schließen"
            className="touch-target p-2"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        {freeBlocked && (
          <div className="mb-3 rounded-xl border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
            Im Free-Tarif bereits ein Rad. Weitere Räder sind Pro — unter Profil
            freischalten.
          </div>
        )}
        {error && (
          <div className="mb-3 rounded-xl border border-error/40 bg-error/10 px-3 py-2 text-xs text-error">
            {error}
          </div>
        )}

        <div className="mb-4 overflow-hidden rounded-2xl border border-border">
          <RadStandFrame
            src={radSilhouetteSrc({ category: persisted, isEbike })}
            alt=""
            heightClass="h-28"
          />
        </div>

        <label className="mb-4 block text-sm">
          Name (optional)
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={hofSportLabel(persisted, isEbike)}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        <div className="mb-4">
          <span className="mb-1 block text-sm tracking-wide">Antrieb</span>
          <div className="grid grid-cols-2 gap-2">
            {(
              [
                ["muscle", "Muskel"],
                ["ebike", "E-Bike"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => onAssistChange(id)}
                className={`rounded-xl px-2 py-2 text-sm font-medium ${
                  assistMode === id
                    ? "bg-accent text-on-accent"
                    : "bg-surface-elevated text-text-secondary"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <span className="mb-1 block text-sm tracking-wide">Typ</span>
          <div className="grid grid-cols-3 gap-2">
            {types.map((c) => {
              const on = addTileSelected(c, category, assistMode);
              return (
                <button
                  key={`${assistMode}-${c}`}
                  type="button"
                  onClick={() => setCategory(c)}
                  className={`overflow-hidden rounded-xl border text-left ${
                    on
                      ? "border-chrome bg-chrome/10"
                      : "border-border bg-surface-elevated"
                  }`}
                >
                  <RadStandFrame
                    src={radSilhouetteSrc({
                      category: c,
                      isEbike: assistMode === "ebike",
                    })}
                    alt=""
                    heightClass="h-12"
                  />
                  <span className="block truncate px-2 py-1.5 text-[11px] font-medium">
                    {assistMode === "muscle"
                      ? hofSportLabel(c)
                      : subtypeLabel(c, assistMode)}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        <button
          type="button"
          onClick={submit}
          className="mt-5 w-full rounded-xl bg-chrome py-3 font-semibold text-on-accent"
        >
          {copy.workshopAdd}
        </button>
      </div>
    </div>
  );
}
