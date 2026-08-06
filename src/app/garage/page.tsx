"use client";

import { useMemo, useState } from "react";
import {
  Bike as BikeIcon,
  Plus,
  Settings2,
  Wrench,
  ShieldCheck,
  History,
  ArrowRightLeft,
} from "lucide-react";
import { AddBikeWizard } from "@/components/garage/AddBikeWizard";
import { BikeSilhouette } from "@/components/garage/BikeSilhouette";
import { BracketingPanel } from "@/components/garage/BracketingPanel";
import { InstallComponentSheet } from "@/components/garage/InstallComponentSheet";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { SLOT_GROUPS } from "@/types";
import { bikeCategoryLabel, slotLabel } from "@/lib/catalog/slots";
import { getComponentModel, modelDisplayName } from "@/lib/catalog/components";
import {
  aggregateVerdict,
  checkBikeCompatibility,
} from "@/lib/compatibility/engine";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import { recommendedSagPct } from "@/lib/setup/ranges";
import { templatesForCategory } from "@/lib/setup/templates";
import {
  bikeCompletenessPct,
  getActiveComponents,
  getMissingSlots,
  useAppStore,
} from "@/store/useAppStore";
import type { ComponentSlot, SetupCondition } from "@/types";

type Tab = "overview" | "components" | "setups" | "maintenance";

export default function GaragePage() {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const setCurrentSetup = useAppStore((s) => s.setCurrentSetup);
  const createSetupVersion = useAppStore((s) => s.createSetupVersion);
  const removeComponent = useAppStore((s) => s.removeComponent);
  const moveComponent = useAppStore((s) => s.moveComponent);
  const maintenanceLogs = useAppStore((s) => s.maintenanceLogs);
  const maintenanceIntervals = useAppStore((s) => s.maintenanceIntervals);
  const markIntervalDone = useAppStore((s) => s.markIntervalDone);
  const applySetupTemplate = useAppStore((s) => s.applySetupTemplate);
  const rides = useAppStore((s) => s.rides);

  const [selectedId, setSelectedId] = useState<string | null>(activeBikeId);
  const [tab, setTab] = useState<Tab>("overview");
  const [showWizard, setShowWizard] = useState(false);
  const [installSlot, setInstallSlot] = useState<ComponentSlot | null>(null);
  const [setupLabel, setSetupLabel] = useState("");
  const [setupCondition, setSetupCondition] =
    useState<SetupCondition>("general");

  const selected =
    bikes.find((b) => b.id === (selectedId || activeBikeId)) || bikes[0];

  const compat = useMemo(
    () => (selected ? checkBikeCompatibility(selected) : []),
    [selected]
  );
  const overallVerdict = compat.length
    ? aggregateVerdict(compat)
    : ("INSUFFICIENT_DATA" as const);

  const activeComponents = selected ? getActiveComponents(selected) : [];
  const missing = selected ? getMissingSlots(selected) : [];
  const completeness = selected ? bikeCompletenessPct(selected) : 0;

  const intervals = selected
    ? maintenanceIntervals.filter((i) => i.bikeId === selected.id)
    : [];
  const logs = selected
    ? maintenanceLogs.filter((l) => l.bikeId === selected.id)
    : [];

  const selectBike = (id: string) => {
    setSelectedId(id);
    setActiveBike(id);
  };

  const createSetup = () => {
    if (!selected || !setupLabel.trim()) return;
    createSetupVersion({
      bikeId: selected.id,
      label: setupLabel.trim(),
      conditions: setupCondition,
      description: "Neue immutable Version",
    });
    setSetupLabel("");
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Garage</h1>
        <button
          type="button"
          onClick={() => setShowWizard(true)}
          className="flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-medium text-white"
        >
          <Plus className="h-4 w-4" /> Bike
        </button>
      </header>

      <div className="flex gap-2 overflow-x-auto pb-1 -mx-4 px-4">
        {bikes.map((bike) => (
          <button
            key={bike.id}
            type="button"
            onClick={() => selectBike(bike.id)}
            className={`flex-shrink-0 rounded-xl border px-4 py-3 text-left ${
              selected?.id === bike.id
                ? "border-accent bg-accent/10"
                : "border-border bg-surface"
            }`}
          >
            <div className="font-medium">{bike.name}</div>
            <div className="text-xs text-text-secondary">
              {bikeCategoryLabel(bike.category)}
              {bike.isActive ? " · aktiv" : ""}
            </div>
          </button>
        ))}
      </div>

      {!selected ? (
        <div className="py-12 text-center text-text-secondary">
          Noch kein Bike — Katalog, Basis oder Import nutzen.
        </div>
      ) : (
        <>
          <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-xs">
            {(
              [
                ["overview", "Übersicht"],
                ["components", "Teile"],
                ["setups", "Setups"],
                ["maintenance", "Wartung"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setTab(id)}
                className={`rounded-lg py-2 font-medium ${
                  tab === id ? "bg-accent text-white" : "text-text-secondary"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "overview" && (
            <div className="flex flex-col gap-4">
              <BikeSilhouette
                bike={selected}
                maintenanceSlots={intervals
                  .filter((i) => {
                    const d = evaluateIntervalDue(
                      i,
                      selected.totalOdometerKm,
                      selected.totalHours
                    );
                    return d.status !== "ok";
                  })
                  .map((i) => i.slot)}
                onSelectSlot={(slot) => {
                  setTab("components");
                  setInstallSlot(slot);
                }}
              />

              <section className="rounded-2xl border border-border bg-surface p-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/30 text-accent">
                    <BikeIcon className="h-7 w-7" />
                  </div>
                  <div className="flex-1">
                    <h2 className="text-xl font-semibold">{selected.name}</h2>
                    <p className="text-sm text-text-secondary">
                      {bikeCategoryLabel(selected.category)}
                      {selected.year ? ` · ${selected.year}` : ""}
                      {selected.frameSize ? ` · ${selected.frameSize}` : ""}
                      {selected.travelFrontMm
                        ? ` · ${selected.travelFrontMm}/${selected.travelRearMm ?? "–"} mm`
                        : ""}
                    </p>
                  </div>
                </div>
                <div className="mt-3 grid grid-cols-3 gap-2 text-center text-sm">
                  <div className="rounded-xl bg-surface-elevated p-2">
                    <div className="tabular-nums text-lg font-bold">
                      {completeness}%
                    </div>
                    <div className="text-[10px] text-text-secondary">Erfasst</div>
                  </div>
                  <div className="rounded-xl bg-surface-elevated p-2">
                    <div className="tabular-nums text-lg font-bold">
                      {selected.totalOdometerKm.toFixed(0)}
                    </div>
                    <div className="text-[10px] text-text-secondary">km</div>
                  </div>
                  <div className="rounded-xl bg-surface-elevated p-2">
                    <div className="tabular-nums text-lg font-bold">
                      {selected.totalHours.toFixed(1)}
                    </div>
                    <div className="text-[10px] text-text-secondary">Stunden</div>
                  </div>
                </div>
                {missing[0] && (
                  <p className="mt-3 text-sm text-warning">
                    Fehlt: {slotLabel(missing[0])} —{" "}
                    <button
                      type="button"
                      className="text-accent underline"
                      onClick={() => {
                        setTab("components");
                        setInstallSlot(missing[0]);
                      }}
                    >
                      ergänzen
                    </button>
                  </p>
                )}
              </section>

              <section className="rounded-2xl border border-border bg-surface p-4">
                <div className="mb-2 flex items-center justify-between">
                  <h3 className="flex items-center gap-2 font-semibold">
                    <ShieldCheck className="h-4 w-4 text-accent" />
                    Kompatibilität
                  </h3>
                  <VerdictPill verdict={overallVerdict} />
                </div>
                <p className="mb-2 text-xs text-text-secondary">
                  Regelbasiert, kein ML. Fehlt ein Attribut → Daten fehlen, nie
                  raten.
                </p>
                <div className="flex max-h-56 flex-col gap-2 overflow-y-auto">
                  {compat.slice(0, 12).map((r) => (
                    <details
                      key={r.ruleCode}
                      className="rounded-xl border border-border bg-surface-elevated p-2 text-xs"
                    >
                      <summary className="flex cursor-pointer list-none items-center justify-between gap-2">
                        <span className="font-medium">
                          {r.ruleCode}: {r.title}
                        </span>
                        <VerdictPill verdict={r.verdict} />
                      </summary>
                      <p className="mt-2 text-text-secondary">{r.explainDe}</p>
                      {r.evidence.map((e, i) => (
                        <p key={i} className="mt-1 tabular-nums">
                          {e.attributeKey}: {String(e.valueA)} vs{" "}
                          {String(e.valueB)}
                          {e.sourceA ? ` (${e.sourceA})` : ""}
                        </p>
                      ))}
                      {r.torqueSpecs.map((t) => (
                        <p key={t.fastener} className="mt-1">
                          {t.fastener}: {t.nm} Nm — {t.sourceLabel}
                        </p>
                      ))}
                      {r.sourceUrl && (
                        <a
                          href={r.sourceUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="mt-1 inline-block text-accent"
                        >
                          Quelle
                        </a>
                      )}
                    </details>
                  ))}
                  {compat.length === 0 && (
                    <p className="text-xs text-text-secondary">
                      Noch keine prüfbaren Slot-Paare.
                    </p>
                  )}
                </div>
              </section>

              <section className="rounded-2xl border border-border bg-surface p-4 text-sm">
                <h3 className="mb-2 font-semibold">SAG-Richtwerte (Magazine)</h3>
                <p className="text-xs text-text-secondary">
                  Enduro MTB Mag / Simplon / Dirt: Gabel{" "}
                  {recommendedSagPct(selected.category, "fork").min}–
                  {recommendedSagPct(selected.category, "fork").max} %, Dämpfer{" "}
                  {recommendedSagPct(selected.category, "shock").min}–
                  {recommendedSagPct(selected.category, "shock").max} %
                </p>
              </section>
            </div>
          )}

          {tab === "components" && (
            <div className="flex flex-col gap-4">
              {SLOT_GROUPS.filter((g) =>
                g.slots.some(
                  (slot) =>
                    activeComponents.some((c) => c.slot === slot) ||
                    missing.includes(slot) ||
                    (g.id === "ebike" && selected.isEbike) ||
                    (g.id === "hiking" && selected.category === "hiking") ||
                    (g.id !== "ebike" && g.id !== "hiking")
                )
              ).map((group) => {
                if (group.id === "hiking" && selected.category !== "hiking")
                  return null;
                if (group.id === "ebike" && !selected.isEbike) return null;
                return (
                  <section key={group.id}>
                    <h3 className="mb-2 flex items-center gap-2 font-semibold">
                      <Wrench className="h-4 w-4 text-accent" />
                      {group.label}
                    </h3>
                    <div className="flex flex-col gap-2">
                      {group.slots.map((slot) => {
                        const comp = activeComponents.find(
                          (c) => c.slot === slot
                        );
                        if (!comp && !missing.includes(slot)) return null;
                        if (!comp) {
                          return (
                            <button
                              key={slot}
                              type="button"
                              onClick={() => setInstallSlot(slot)}
                              className="rounded-xl border border-dashed border-warning/50 bg-warning/5 p-3 text-left"
                            >
                              <div className="text-xs uppercase tracking-wide text-warning">
                                {slotLabel(slot)}
                              </div>
                              <div className="text-sm">Ergänzen</div>
                            </button>
                          );
                        }
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
                                <div className="text-xs uppercase tracking-wide text-text-secondary">
                                  {slotLabel(slot)}
                                </div>
                                <div className="font-medium">
                                  {model
                                    ? modelDisplayName(model)
                                    : comp.freeText ||
                                      `${comp.manufacturer ?? ""} ${comp.model ?? ""}`}
                                </div>
                                <div className="mt-1 text-xs text-text-secondary">
                                  Einbau {new Date(comp.installedAt).toLocaleDateString("de-DE")}{" "}
                                  · ≈ {usageKm.toFixed(0)} km Laufleistung
                                  {!comp.componentModelId &&
                                    " · Freitext (keine Kompat-Prüfung)"}
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
                                <button
                                  type="button"
                                  onClick={() => {
                                    const other = bikes.find(
                                      (b) => b.id !== selected.id
                                    );
                                    if (other)
                                      moveComponent(
                                        comp.id,
                                        selected.id,
                                        other.id
                                      );
                                  }}
                                  className="inline-flex items-center gap-1 rounded-lg bg-muted px-2 py-1 text-xs"
                                >
                                  <ArrowRightLeft className="h-3 w-3" />
                                  Verschieben
                                </button>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </section>
                );
              })}
            </div>
          )}

          {tab === "setups" && (
            <div className="flex flex-col gap-4">
              <section className="rounded-2xl border border-border bg-surface p-4">
                <h3 className="mb-2 font-semibold">Setup-Vorlagen (F-SET-002)</h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Ausgangspunkte — keine Empfehlung. Fox/RockShox-Gewichtstabellen
                  & Editorial-Presets.
                </p>
                <div className="flex flex-col gap-2">
                  {templatesForCategory(selected.category).map((tpl) => (
                    <button
                      key={tpl.id}
                      type="button"
                      onClick={() =>
                        applySetupTemplate(selected.id, tpl.id)
                      }
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
                  Neues Setup (immutable)
                </h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Jede Änderung erzeugt eine neue Version mit Parent-Referenz
                  (F-SET-001).
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
                    {(
                      [
                        "general",
                        "dry",
                        "wet",
                        "mixed",
                        "bikepark",
                        "race",
                      ] as SetupCondition[]
                    ).map((c) => (
                      <option key={c} value={c}>
                        {c}
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
                        {setup.conditions}
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
          )}

          {tab === "maintenance" && (
            <div className="flex flex-col gap-4">
              <section>
                <h3 className="mb-2 font-semibold">
                  Verschleißprognose (Spanne)
                </h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Belastungsgewichtet · nie Punktwert (F-GAR-005 P1)
                </p>
                <div className="flex flex-col gap-2">
                  {forecastWear(selected, rides).map((f) => (
                    <div
                      key={f.kind}
                      className={`rounded-xl border p-3 text-sm ${
                        f.dueSoon
                          ? "border-warning/50 bg-warning/10"
                          : "border-border bg-surface"
                      }`}
                    >
                      <div className="font-medium">{f.label}</div>
                      <p className="mt-1 text-xs text-text-secondary">
                        {f.reasoning}
                      </p>
                      <p className="mt-1 text-[10px] text-text-secondary">
                        {f.sourceLabel}
                      </p>
                    </div>
                  ))}
                  {forecastWear(selected, rides).length === 0 && (
                    <p className="text-sm text-text-secondary">
                      Keine Verschleißteile mit Historie.
                    </p>
                  )}
                </div>
              </section>

              <section>
                <h3 className="mb-2 font-semibold">Fälligkeiten</h3>
                <div className="flex flex-col gap-2">
                  {intervals.map((interval) => {
                    const due = evaluateIntervalDue(
                      interval,
                      selected.totalOdometerKm,
                      selected.totalHours
                    );
                    return (
                      <div
                        key={interval.id}
                        className="rounded-xl border border-border bg-surface p-3"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <div className="font-medium text-sm">
                              {interval.label}
                            </div>
                            <div className="text-xs text-text-secondary">
                              {slotLabel(interval.slot)} · {interval.sourceLabel}
                              {interval.overriddenByUser ? " · angepasst" : ""}
                            </div>
                            <div className="mt-1 text-xs">
                              {due.remainingLabel} · {due.progressPct}%
                              {due.status === "overdue" && (
                                <span className="text-error"> · überfällig</span>
                              )}
                              {due.status === "due_soon" && (
                                <span className="text-warning"> · bald</span>
                              )}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => markIntervalDone(interval.id)}
                            className="rounded-lg bg-accent px-2 py-1 text-xs font-semibold text-white"
                          >
                            Erledigt
                          </button>
                        </div>
                        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-muted">
                          <div
                            className={`h-full ${
                              due.status === "overdue"
                                ? "bg-error"
                                : due.status === "due_soon"
                                  ? "bg-warning"
                                  : "bg-success"
                            }`}
                            style={{ width: `${Math.min(100, due.progressPct)}%` }}
                          />
                        </div>
                      </div>
                    );
                  })}
                  {intervals.length === 0 && (
                    <p className="text-sm text-text-secondary">
                      Keine Intervalle — Komponenten einbauen.
                    </p>
                  )}
                </div>
              </section>

              <section>
                <h3 className="mb-2 flex items-center gap-2 font-semibold">
                  <History className="h-4 w-4 text-accent" />
                  Wartungslog
                </h3>
                <div className="flex flex-col gap-2">
                  {logs.map((log) => (
                    <div
                      key={log.id}
                      className="rounded-xl border border-border bg-surface p-3 text-sm"
                    >
                      <div className="font-medium">{log.activity}</div>
                      <div className="text-xs text-text-secondary">
                        {log.date} ·{" "}
                        {log.performer === "workshop" ? "Werkstatt" : "Eigen"}
                        {log.odometerKm !== undefined
                          ? ` · ${log.odometerKm.toFixed(0)} km`
                          : ""}
                        {log.costEur !== undefined ? ` · ${log.costEur} €` : ""}
                      </div>
                      {log.notes && (
                        <p className="mt-1 text-xs text-text-secondary">
                          {log.notes}
                        </p>
                      )}
                    </div>
                  ))}
                  {logs.length === 0 && (
                    <p className="text-sm text-text-secondary">Noch kein Log.</p>
                  )}
                </div>
              </section>

              <p className="text-xs text-text-secondary">
                Defaults u. a. RockShox 50 h Lower Leg / 200 h Full, Kette prüfen
                ~1000 km, Tubeless-Milch ~120 Tage.
              </p>
            </div>
          )}
        </>
      )}

      {showWizard && <AddBikeWizard onClose={() => setShowWizard(false)} />}
      {selected && installSlot && (
        <InstallComponentSheet
          bike={selected}
          slot={installSlot}
          onClose={() => setInstallSlot(null)}
        />
      )}
    </div>
  );
}
