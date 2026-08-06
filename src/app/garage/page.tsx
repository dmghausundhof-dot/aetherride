"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel, categoryLabel } from "@/lib/utils";
import { Bike, Plus, ChevronRight, Settings2, Wrench } from "lucide-react";
import Link from "next/link";

export default function GaragePage() {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const addBike = useAppStore((s) => s.addBike);
  const setActiveSetup = useAppStore((s) => s.setActiveSetup);

  const [selectedId, setSelectedId] = useState<string | null>(activeBikeId);
  const selected = bikes.find((b) => b.id === (selectedId || activeBikeId));

  const handleAddDemoBike = () => {
    const id = addBike({
      name: "Neues Bike",
      type: "all_mountain",
      year: 2025,
      isDefault: false,
    });
    setSelectedId(id);
    setActiveBike(id);
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Garage</h1>
        <button
          onClick={handleAddDemoBike}
          className="flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-medium text-white"
        >
          <Plus className="h-4 w-4" /> Bike
        </button>
      </header>

      {/* Bike List */}
      <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4">
        {bikes.map((bike) => (
          <button
            key={bike.id}
            onClick={() => {
              setSelectedId(bike.id);
              setActiveBike(bike.id);
            }}
            className={`flex-shrink-0 rounded-xl border px-4 py-3 text-left transition ${
              (selectedId || activeBikeId) === bike.id
                ? "border-accent bg-accent/10"
                : "border-border bg-surface"
            }`}
          >
            <div className="font-medium">{bike.name}</div>
            <div className="text-xs text-text-secondary">{bikeTypeLabel(bike.type)}</div>
          </button>
        ))}
      </div>

      {selected ? (
        <div className="flex flex-col gap-4">
          {/* Bike Header */}
          <section className="rounded-2xl bg-surface border border-border p-4">
            <div className="flex items-center gap-3">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/30 text-accent">
                <Bike className="h-7 w-7" />
              </div>
              <div className="flex-1">
                <h2 className="text-xl font-semibold">{selected.name}</h2>
                <p className="text-sm text-text-secondary">
                  {bikeTypeLabel(selected.type)}
                  {selected.year ? ` · ${selected.year}` : ""}
                  {selected.frameSize ? ` · ${selected.frameSize}` : ""}
                </p>
              </div>
            </div>
            {selected.weightKg && (
              <div className="mt-3 text-sm text-text-secondary">
                Gewicht: <span className="tabular-nums text-foreground">{selected.weightKg} kg</span>
              </div>
            )}
          </section>

          {/* Components */}
          <section>
            <h3 className="mb-2 flex items-center gap-2 font-semibold">
              <Wrench className="h-4 w-4 text-accent" /> Komponenten
            </h3>
            <div className="flex flex-col gap-2">
              {selected.components.length === 0 ? (
                <p className="text-sm text-text-secondary">Noch keine Komponenten</p>
              ) : (
                selected.components.map((c) => (
                  <div
                    key={c.id}
                    className="rounded-xl bg-surface border border-border p-3"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-xs text-text-secondary uppercase tracking-wide">
                          {categoryLabel(c.category)}
                        </div>
                        <div className="font-medium">
                          {c.manufacturer} {c.model}
                        </div>
                      </div>
                      <ChevronRight className="h-4 w-4 text-text-secondary" />
                    </div>
                    {Object.keys(c.currentSettings).length > 0 && (
                      <div className="mt-2 flex flex-wrap gap-2">
                        {Object.entries(c.currentSettings).map(([k, v]) => (
                          <span
                            key={k}
                            className="rounded-md bg-surface-elevated px-2 py-0.5 text-xs tabular-nums"
                          >
                            {k}: {v}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          </section>

          {/* Setups */}
          <section>
            <h3 className="mb-2 flex items-center gap-2 font-semibold">
              <Settings2 className="h-4 w-4 text-accent" /> Setups
            </h3>
            <div className="flex flex-col gap-2">
              {selected.setups.map((setup) => (
                <button
                  key={setup.id}
                  onClick={() => setActiveSetup(selected.id, setup.id)}
                  className={`rounded-xl border p-3 text-left transition ${
                    setup.isActive
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="font-medium">{setup.name}</div>
                    {setup.isActive && (
                      <span className="rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold text-white">
                        AKTIV
                      </span>
                    )}
                  </div>
                  {setup.description && (
                    <p className="mt-1 text-sm text-text-secondary">{setup.description}</p>
                  )}
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {Object.entries(setup.settingsSnapshot).map(([k, v]) => (
                      <span
                        key={k}
                        className="rounded bg-surface-elevated px-1.5 py-0.5 text-[11px] tabular-nums text-text-secondary"
                      >
                        {k}: {v}
                      </span>
                    ))}
                  </div>
                </button>
              ))}
            </div>
          </section>
        </div>
      ) : (
        <div className="py-12 text-center text-text-secondary">
          Wähle oder erstelle ein Bike
        </div>
      )}
    </div>
  );
}
