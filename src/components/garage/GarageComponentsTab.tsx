"use client";

import { Wrench, Package, ArrowRightLeft, Plus } from "lucide-react";
import { SLOT_GROUPS } from "@/types";
import { slotLabel } from "@/lib/catalog/slots";
import { getComponentModel, modelDisplayName } from "@/lib/catalog/components";
import { addableSlotsFor, planDieBox, werkstattKindFor } from "@/lib/garage/dieBox";
import type { Bike, ComponentSlot, BikeComponent, Ride } from "@/types";

interface Props {
  selected: Bike;
  spareParts: BikeComponent[];
  rides: Ride[];
  bikes: Bike[];
  moveTargetId: string;
  setMoveTargetId: (id: string) => void;
  setInstallSlot: (slot: ComponentSlot) => void;
  removeComponent: (bikeId: string, componentId: string) => void;
  reinstallComponent: (bikeId: string, componentId: string) => void;
  moveComponent: (componentId: string, fromBikeId: string, toBikeId: string) => void;
}

function defaultInstallSlot(bike: Bike, active: BikeComponent[]): ComponentSlot {
  const kind = werkstattKindFor(bike.category);
  const addable = addableSlotsFor({
    kind,
    hasSuspension:
      (bike.travelFrontMm ?? 0) > 0 || (bike.travelRearMm ?? 0) > 0,
    hasElectricAssist:
      bike.isEbike || bike.category === "emtb" || bike.category === "etrekking",
  });
  const filled = new Set(active.map((c) => c.slot));
  return addable.find((s) => !filled.has(s)) ?? addable[0] ?? "chain";
}

export function GarageComponentsTab({
  selected,
  spareParts,
  rides,
  bikes,
  moveTargetId,
  setMoveTargetId,
  setInstallSlot,
  removeComponent,
  reinstallComponent,
  moveComponent,
}: Props) {
  const listed = planDieBox({ bike: selected }).onBike;
  const groups = SLOT_GROUPS.filter((g) =>
    g.slots.some((slot) => listed.some((c) => c.slot === slot))
  );

  return (
            <div className="flex flex-col gap-4">
              <button
                type="button"
                onClick={() =>
                  setInstallSlot(defaultInstallSlot(selected, listed))
                }
                className="flex items-center justify-center gap-1.5 rounded-xl border border-dashed border-border px-3 py-2.5 text-sm font-medium text-chrome hover:border-chrome/40"
              >
                <Plus className="h-4 w-4" /> Teil selbst anlegen
              </button>
              {listed.length === 0 && (
                <p className="text-sm text-text-secondary">
                  Noch keine Teile. Katalog ist Suche — nichts muss vollständig
                  sein.
                </p>
              )}
              {groups.map((group) => (
                  <section key={group.id}>
                    <h3 className="mb-2 flex items-center gap-2 font-semibold">
                      <Wrench className="h-4 w-4 text-accent" />
                      {group.label}
                    </h3>
                    <div className="flex flex-col gap-2">
                      {group.slots.map((slot) => {
                        const comp = listed.find(
                          (c) => c.slot === slot
                        );
                        if (!comp) return null;
                        const model = comp.componentModelId
                          ? getComponentModel(comp.componentModelId)
                          : undefined;
                        const usageKm = rides
                          .filter((r) => r.bikeId === selected.id)
                          .filter(
                            (r) =>
                              new Date(r.startTime) >= new Date(comp.installedAt)
                          )
                          .reduce((s, r) => s + r.distanceM / 1000, 0);
                        return (
                          <div
                            key={comp.id}
                            className="rounded-xl border border-border bg-surface p-3"
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div>
                                <div className="text-xs tracking-wide text-text-secondary">
                                  {slotLabel(slot)}
                                </div>
                                <div className="font-medium">
                                  {model
                                    ? modelDisplayName(model)
                                    : comp.freeText ||
                                      `${comp.manufacturer ?? ""} ${comp.model ?? ""}`}
                                </div>
                                <div className="mt-1 text-xs text-text-secondary">
                                  Einbau{" "}
                                  {new Date(comp.installedAt).toLocaleDateString(
                                    "de-DE"
                                  )}{" "}
                                  · ≈ {usageKm.toFixed(0)} km Laufleistung
                                  {!comp.componentModelId &&
                                    " · selbst angelegt"}
                                </div>
                              </div>
                            </div>
                            {Object.keys(comp.currentSettings).length > 0 && (
                              <div className="mt-2 flex flex-wrap gap-1.5">
                                {Object.entries(comp.currentSettings).map(
                                  ([k, v]) => (
                                    <span
                                      key={k}
                                      className="rounded-md bg-surface-elevated px-2 py-0.5 text-xs tabular-nums"
                                    >
                                      {k}: {v}
                                    </span>
                                  )
                                )}
                              </div>
                            )}
                            <div className="mt-2 flex flex-wrap gap-2">
                              <button
                                type="button"
                                onClick={() => setInstallSlot(slot)}
                                className="rounded-lg bg-muted px-2 py-1 text-xs"
                              >
                                Ersetzen
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  removeComponent(selected.id, comp.id)
                                }
                                className="rounded-lg bg-muted px-2 py-1 text-xs"
                              >
                                Ausbauen
                              </button>
                              {bikes.length > 1 && (
                                <div className="inline-flex items-center gap-1">
                                  <select
                                    className="rounded-lg border border-border bg-muted px-1 py-1 text-xs"
                                    value={moveTargetId}
                                    onChange={(e) =>
                                      setMoveTargetId(e.target.value)
                                    }
                                  >
                                    <option value="">Ziel-Bike…</option>
                                    {bikes
                                      .filter((b) => b.id !== selected.id)
                                      .map((b) => (
                                        <option key={b.id} value={b.id}>
                                          {b.name}
                                        </option>
                                      ))}
                                  </select>
                                  <button
                                    type="button"
                                    disabled={!moveTargetId}
                                    onClick={() => {
                                      if (!moveTargetId) return;
                                      moveComponent(
                                        comp.id,
                                        selected.id,
                                        moveTargetId
                                      );
                                      setMoveTargetId("");
                                    }}
                                    className="inline-flex items-center gap-1 rounded-lg bg-muted px-2 py-1 text-xs disabled:opacity-40"
                                  >
                                    <ArrowRightLeft className="h-3.5 w-3.5" />
                                    Verschieben
                                  </button>
                                </div>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </section>
              ))}

              <section>
                <h3 className="mb-2 flex items-center gap-2 font-semibold">
                  <Package className="h-4 w-4 text-accent" />
                  Ersatzteil-Regal
                </h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Ausgebaute Teile bleiben hier — z. B. zweites Laufrad oder
                  Trainingskette. Wiedereinbau ersetzt den aktiven Slot.
                </p>
                <div className="flex flex-col gap-2">
                  {spareParts.map((comp) => {
                    const model = comp.componentModelId
                      ? getComponentModel(comp.componentModelId)
                      : undefined;
                    return (
                      <div
                        key={comp.id}
                        className="rounded-xl border border-dashed border-border bg-surface p-3"
                      >
                        <div className="text-xs tracking-wide text-text-secondary">
                          {slotLabel(comp.slot)}
                        </div>
                        <div className="font-medium">
                          {model
                            ? modelDisplayName(model)
                            : comp.freeText ||
                              `${comp.manufacturer ?? ""} ${comp.model ?? ""}`}
                        </div>
                        <div className="mt-1 text-xs text-text-secondary">
                          Ausgebaut{" "}
                          {comp.removedAt
                            ? new Date(comp.removedAt).toLocaleDateString(
                                "de-DE"
                              )
                            : ""}
                        </div>
                        <button
                          type="button"
                          onClick={() =>
                            reinstallComponent(selected.id, comp.id)
                          }
                          className="mt-2 rounded-xl bg-accent px-2 py-1 text-xs font-semibold text-on-accent"
                        >
                          Wieder einbauen
                        </button>
                      </div>
                    );
                  })}
                  {spareParts.length === 0 && (
                    <p className="text-sm text-text-secondary">
                      Regal leer — Teile ausbauen, um sie hier zu lagern.
                    </p>
                  )}
                </div>
              </section>
            </div>
  );
}
