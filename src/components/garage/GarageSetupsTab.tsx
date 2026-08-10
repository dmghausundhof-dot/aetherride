"use client";

import { Settings2 } from "lucide-react";
import { BracketingPanel } from "@/components/garage/BracketingPanel";
import { templatesForCategory } from "@/lib/setup/templates";
import {
  SETUP_CONDITION_OPTIONS,
  setupConditionLabel,
} from "@/lib/setup/conditionLabels";
import type { Bike, SetupCondition } from "@/types";

interface Props {
  selected: Bike;
  setupLabel: string;
  setSetupLabel: (v: string) => void;
  setupCondition: SetupCondition;
  setSetupCondition: (v: SetupCondition) => void;
  createSetup: () => void;
  setCurrentSetup: (bikeId: string, setupId: string) => void;
  applySetupTemplate: (bikeId: string, templateId: string) => void;
}

export function GarageSetupsTab({
  selected,
  setupLabel,
  setSetupLabel,
  setupCondition,
  setSetupCondition,
  createSetup,
  setCurrentSetup,
  applySetupTemplate,
}: Props) {
  return (
            <div className="flex flex-col gap-4">
              <section className="rounded-2xl border border-border bg-surface p-4">
                <h3 className="mb-2 font-semibold">Setup-Vorlagen</h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Ausgangspunkte — keine Empfehlung. Fox/RockShox-Gewichtstabellen
                  & Editorial-Presets.
                </p>
                <div className="flex flex-col gap-2">
                  {templatesForCategory(selected.category).map((tpl) => (
                    <button
                      key={tpl.id}
                      type="button"
                      onClick={() => applySetupTemplate(selected.id, tpl.id)}
                      className="rounded-xl border border-border bg-surface-elevated p-3 text-left text-sm"
                    >
                      <div className="font-medium">{tpl.label}</div>
                      <div className="mt-1 text-[11px] text-warning">
                        {tpl.disclaimer}
                      </div>
                      <a
                        href={tpl.sourceUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="mt-1 inline-block text-[11px] text-accent"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {tpl.sourceLabel}
                      </a>
                    </button>
                  ))}
                </div>
              </section>

              <section className="rounded-2xl border border-border bg-surface p-4">
                <h3 className="mb-2 flex items-center gap-2 font-semibold">
                  <Settings2 className="h-4 w-4 text-accent" />
                  Neues Setup
                </h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Jede Änderung erzeugt eine neue Version mit Vorgänger-Referenz.
                </p>
                <div className="flex flex-col gap-2">
                  <input
                    value={setupLabel}
                    onChange={(e) => setSetupLabel(e.target.value)}
                    placeholder="Name z. B. Bikepark nass"
                    className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
                  />
                  <select
                    value={setupCondition}
                    onChange={(e) =>
                      setSetupCondition(e.target.value as SetupCondition)
                    }
                    className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
                  >
                    {SETUP_CONDITION_OPTIONS.map((c) => (
                      <option key={c.value} value={c.value}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    onClick={createSetup}
                    className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                  >
                    Version anlegen
                  </button>
                </div>
              </section>

              <div className="flex flex-col gap-2">
                {[...selected.setups]
                  .sort((a, b) => b.version - a.version)
                  .map((setup) => (
                    <button
                      key={setup.id}
                      type="button"
                      onClick={() => setCurrentSetup(selected.id, setup.id)}
                      className={`rounded-xl border p-3 text-left ${
                        setup.isCurrent
                          ? "border-accent bg-accent/10"
                          : "border-border bg-surface"
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div className="font-medium">
                          v{setup.version} · {setup.label}
                        </div>
                        {setup.isCurrent && (
                          <span className="rounded-full bg-accent px-2 py-0.5 text-[10px] font-semibold text-white">
                            AKTUELL
                          </span>
                        )}
                      </div>
                      <p className="mt-1 text-xs text-text-secondary">
                        {setupConditionLabel(setup.conditions)}
                        {setup.parentSetupId ? " · hat Vorgänger" : " · Wurzel"}
                        {setup.riderWeightKg
                          ? ` · Fahrer ${setup.riderWeightKg} kg`
                          : ""}
                      </p>
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {setup.values.slice(0, 8).map((v) => (
                          <span
                            key={`${v.slot}.${v.adjusterKey}`}
                            className={`rounded bg-surface-elevated px-1.5 py-0.5 text-[11px] tabular-nums ${
                              v.outOfSpec ? "text-error" : "text-text-secondary"
                            }`}
                          >
                            {v.slot}.{v.adjusterKey}: {v.valueNum}
                            {v.unit === "clicks" ? " clk" : ` ${v.unit}`}
                          </span>
                        ))}
                      </div>
                    </button>
                  ))}
              </div>

              <BracketingPanel bike={selected} />
            </div>
  );
}
