"use client";

import { useMemo, useState, useEffect, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import {
  Plus,
  Settings2,
  Wrench,
  ShieldCheck,
  History,
  ArrowRightLeft,
  Download,
  AlertTriangle,
  Package,
} from "lucide-react";
import { AddBikeWizard } from "@/components/garage/AddBikeWizard";
import { BikeSilhouette } from "@/components/garage/BikeSilhouette";
import { BracketingPanel } from "@/components/garage/BracketingPanel";
import { InstallComponentSheet } from "@/components/garage/InstallComponentSheet";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { SagGuideForBike } from "@/components/garage/SagGuidePanel";
import { BikePhotoControl } from "@/components/garage/BikePhotoControl";
import { OdometerImportPanel } from "@/components/garage/OdometerImportPanel";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { SLOT_GROUPS } from "@/types";
import { bikeCategoryLabel, slotLabel } from "@/lib/catalog/slots";
import { getComponentModel, modelDisplayName } from "@/lib/catalog/components";
import {
  aggregateVerdict,
  checkBikeCompatibility,
} from "@/lib/compatibility/engine";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import { templatesForCategory } from "@/lib/setup/templates";
import {
  SETUP_CONDITION_OPTIONS,
  setupConditionLabel,
} from "@/lib/setup/conditionLabels";
import {
  buildMaintenanceAlerts,
  bikeReadyStatus,
} from "@/lib/home/maintenanceAlerts";
import {
  readinessLabel,
  verdictSummaryDe,
} from "@/lib/garage/readiness";
import {
  buildServiceReport,
  downloadServiceReport,
} from "@/lib/garage/serviceReport";
import {
  getActiveComponents,
  getMissingSlots,
  useAppStore,
} from "@/store/useAppStore";
import type { ComponentSlot, SetupCondition } from "@/types";

type Tab = "overview" | "components" | "setups" | "maintenance";

function GaragePageInner() {
  const searchParams = useSearchParams();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const setCurrentSetup = useAppStore((s) => s.setCurrentSetup);
  const createSetupVersion = useAppStore((s) => s.createSetupVersion);
  const removeComponent = useAppStore((s) => s.removeComponent);
  const reinstallComponent = useAppStore((s) => s.reinstallComponent);
  const moveComponent = useAppStore((s) => s.moveComponent);
  const maintenanceLogs = useAppStore((s) => s.maintenanceLogs);
  const maintenanceIntervals = useAppStore((s) => s.maintenanceIntervals);
  const markIntervalDone = useAppStore((s) => s.markIntervalDone);
  const applySetupTemplate = useAppStore((s) => s.applySetupTemplate);
  const rides = useAppStore((s) => s.rides);
  const riderWeight = useAppStore((s) => s.riderProfile.riderWeightKg);

  const [selectedId, setSelectedId] = useState<string | null>(activeBikeId);
  const initialTab = (searchParams.get("tab") as Tab | null) || "overview";
  const [tab, setTab] = useState<Tab>(
    ["overview", "components", "setups", "maintenance"].includes(initialTab)
      ? initialTab
      : "overview"
  );

  const [showWizard, setShowWizard] = useState(false);
  const [wizardMode, setWizardMode] = useState<
    "catalog" | "basic" | "import"
  >("catalog");
  const [wizardCategory, setWizardCategory] = useState<
    import("@/types").BikeCategory | undefined
  >(undefined);
  const [installSlot, setInstallSlot] = useState<ComponentSlot | null>(null);
  const [setupLabel, setSetupLabel] = useState("");
  const [setupCondition, setSetupCondition] =
    useState<SetupCondition>("dry");
  const [compatOpen, setCompatOpen] = useState(false);
  const [moveTargetId, setMoveTargetId] = useState<string>("");

  useEffect(() => {
    const t = searchParams.get("tab") as Tab | null;
    if (t && ["overview", "components", "setups", "maintenance"].includes(t)) {
      setTab(t);
    }
    const wizard = searchParams.get("wizard");
    if (
      wizard === "catalog" ||
      wizard === "basic" ||
      wizard === "import"
    ) {
      setWizardMode(wizard);
      setShowWizard(true);
    }
    const cat = searchParams.get("category");
    if (cat) setWizardCategory(cat as import("@/types").BikeCategory);
  }, [searchParams]);

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
  const spareParts = selected
    ? selected.components.filter((c) => !!c.removedAt)
    : [];

  const intervals = selected
    ? maintenanceIntervals.filter((i) => i.bikeId === selected.id)
    : [];
  const logs = selected
    ? maintenanceLogs.filter((l) => l.bikeId === selected.id)
    : [];

  const alerts = useMemo(
    () =>
      selected
        ? buildMaintenanceAlerts({
            bike: selected,
            rides,
            intervals: maintenanceIntervals,
            max: 3,
          })
        : [],
    [selected, rides, maintenanceIntervals]
  );
  const ready = bikeReadyStatus(alerts);
  const currentSetup = selected?.setups.find((s) => s.isCurrent);
  const nextAction = alerts[0];
  const costSum = logs
    .filter((l) => l.costEur != null)
    .reduce((s, l) => s + (l.costEur ?? 0), 0);

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

  const exportReport = () => {
    if (!selected) return;
    const text = buildServiceReport({
      bike: selected,
      logs: maintenanceLogs,
      rides,
    });
    const slug = selected.name.replace(/\s+/g, "-").toLowerCase();
    downloadServiceReport(`aetherride-service-${slug}.txt`, text);
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Garage</h1>
        <button
          type="button"
          onClick={() => {
            setWizardMode("catalog");
            setShowWizard(true);
          }}
          className="flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-medium text-white"
        >
          <Plus className="h-4 w-4" /> Bike
        </button>
      </header>

      {bikes.length > 0 && (
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
      )}

      {!selected ? (
        <section className="rounded-2xl border border-border bg-surface p-6 text-center">
          <h2 className="text-lg font-semibold">Lege dein erstes Bike an</h2>
          <p className="mt-2 text-sm text-text-secondary">
            Katalog mit OEM-Teilen, schnelle Basis, oder Bike-Platzhalter.
            GPX-Routen importierst du unter Discover — kein Auto-Demo-Bike.
          </p>
          <div className="mt-4 grid gap-2 sm:grid-cols-3">
            {(
              [
                ["catalog", "Katalog", "Modell wählen, Slots vorgefüllt"],
                ["basic", "Basis", "Name + Kategorie, später ergänzen"],
                ["import", "Platzhalter", "Bike ohne Komponenten — Track via Discover"],
              ] as const
            ).map(([mode, title, desc]) => (
              <button
                key={mode}
                type="button"
                onClick={() => {
                  setWizardMode(mode);
                  setShowWizard(true);
                }}
                className="rounded-xl border border-border bg-surface-elevated p-3 text-left"
              >
                <div className="font-medium text-sm">{title}</div>
                <div className="mt-1 text-xs text-text-secondary">{desc}</div>
              </button>
            ))}
          </div>
        </section>
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
              <BikePhotoControl
                bikeId={selected.id}
                photoUrl={selected.photoUrl}
              />

              <section className="rounded-2xl border border-border bg-surface p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
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
                  <span
                    className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
                      ready === "ready"
                        ? "bg-success/15 text-success"
                        : "bg-warning/15 text-warning"
                    }`}
                  >
                    {readinessLabel(ready)}
                  </span>
                </div>

                <div className="mt-3 grid grid-cols-3 gap-2 text-center text-sm">
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
                  <div className="rounded-xl bg-surface-elevated p-2">
                    <div className="tabular-nums text-lg font-bold">
                      {costSum > 0 ? `${costSum.toFixed(0)}€` : "—"}
                    </div>
                    <div className="text-[10px] text-text-secondary">Kosten</div>
                  </div>
                </div>
              </section>

              {alerts.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {alerts.map((a) => (
                    <button
                      key={a.id}
                      type="button"
                      onClick={() => setTab("maintenance")}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium ${
                        a.severity === "overdue"
                          ? "border-error/40 bg-error/10 text-error"
                          : "border-warning/40 bg-warning/10 text-warning"
                      }`}
                    >
                      {a.title}
                    </button>
                  ))}
                </div>
              )}

              {nextAction && (
                <button
                  type="button"
                  onClick={() => setTab("maintenance")}
                  className="flex items-start gap-3 rounded-2xl border border-warning/40 bg-warning/10 p-4 text-left"
                >
                  <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-warning" />
                  <div>
                    <div className="text-xs font-semibold uppercase tracking-wide text-warning">
                      Nächste Aktion
                    </div>
                    <div className="mt-1 font-semibold">{nextAction.title}</div>
                    <p className="mt-0.5 text-sm text-text-secondary">
                      {nextAction.detail}
                    </p>
                  </div>
                </button>
              )}

              {currentSetup && (
                <section className="rounded-2xl border border-border bg-surface p-4">
                  <div className="flex items-center justify-between gap-2">
                    <h3 className="font-semibold">Aktives Setup</h3>
                    <button
                      type="button"
                      className="text-xs font-medium text-accent"
                      onClick={() => setTab("setups")}
                    >
                      Wechseln
                    </button>
                  </div>
                  <p className="mt-1 text-sm">
                    „{currentSetup.label}“ ·{" "}
                    {setupConditionLabel(currentSetup.conditions)}
                  </p>
                  <div className="mt-2">
                    <SetupFingerprint setup={currentSetup} />
                  </div>
                  {selected.setups.filter((s) => !s.isCurrent).length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-2">
                      {selected.setups
                        .filter((s) => !s.isCurrent)
                        .slice(0, 3)
                        .map((s) => (
                          <button
                            key={s.id}
                            type="button"
                            onClick={() => setCurrentSetup(selected.id, s.id)}
                            className="rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-xs"
                          >
                            → {s.label}
                          </button>
                        ))}
                    </div>
                  )}
                </section>
              )}

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

              {missing[0] && (
                <p className="text-sm text-warning">
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

              <section className="rounded-2xl border border-border bg-surface p-4">
                <button
                  type="button"
                  className="flex w-full items-center justify-between gap-2 text-left"
                  onClick={() => setCompatOpen((v) => !v)}
                >
                  <h3 className="flex items-center gap-2 font-semibold">
                    <ShieldCheck className="h-4 w-4 text-accent" />
                    Kompatibilität
                  </h3>
                  <div className="flex items-center gap-2">
                    <VerdictPill verdict={overallVerdict} />
                    <span className="text-xs text-text-secondary">
                      {compatOpen ? "zuklappen" : "Details"}
                    </span>
                  </div>
                </button>
                <p className="mt-2 text-xs text-text-secondary">
                  {verdictSummaryDe(overallVerdict)} · regelbasiert, kein ML.
                  Fehlt ein Attribut → Daten fehlen, nie raten.
                </p>
                {compatOpen && (
                  <div className="mt-3 flex max-h-56 flex-col gap-2 overflow-y-auto">
                    {compat.slice(0, 12).map((r) => (
                      <details
                        key={r.ruleCode}
                        className="rounded-xl border border-border bg-surface-elevated p-2 text-xs"
                      >
                        <summary className="flex cursor-pointer list-none items-center justify-between gap-2">
                          <span className="font-medium">{r.title}</span>
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
                )}
              </section>

              <SagGuideForBike
                bike={selected}
                defaultWeightKg={riderWeight}
              />

              <OdometerImportPanel
                bikeId={selected.id}
                odometerKm={selected.totalOdometerKm}
                hours={selected.totalHours}
              />

              <button
                type="button"
                onClick={exportReport}
                className="inline-flex items-center justify-center gap-2 rounded-xl border border-border bg-surface py-3 text-sm font-medium"
              >
                <Download className="h-4 w-4 text-accent" />
                Service-Report exportieren
              </button>
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
                                  Einbau{" "}
                                  {new Date(comp.installedAt).toLocaleDateString(
                                    "de-DE"
                                  )}{" "}
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
                                    <ArrowRightLeft className="h-3 w-3" />
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
                );
              })}

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
                        <div className="text-xs uppercase tracking-wide text-text-secondary">
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
                          className="mt-2 rounded-lg bg-accent px-2 py-1 text-xs font-semibold text-white"
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
          )}

          {tab === "setups" && (
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
          )}

          {tab === "maintenance" && (
            <div className="flex flex-col gap-4">
              <section>
                <h3 className="mb-2 font-semibold">Verschleißprognose</h3>
                <p className="mb-2 text-xs text-text-secondary">
                  Belastungsgewichtet · Spanne, nie Punktwert.
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
                            style={{
                              width: `${Math.min(100, due.progressPct)}%`,
                            }}
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
                <h3 className="mb-2 flex items-center justify-between gap-2 font-semibold">
                  <span className="inline-flex items-center gap-2">
                    <History className="h-4 w-4 text-accent" />
                    Wartungslog
                  </span>
                  <button
                    type="button"
                    onClick={exportReport}
                    className="inline-flex items-center gap-1 text-xs font-medium text-accent"
                  >
                    <Download className="h-3.5 w-3.5" /> Report
                  </button>
                </h3>
                {costSum > 0 && (
                  <p className="mb-2 text-xs text-text-secondary">
                    Kosten gesamt: {costSum.toFixed(2)} €
                  </p>
                )}
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
                        {log.costEur !== undefined
                          ? ` · ${log.costEur} €`
                          : ""}
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

      {showWizard && (
        <AddBikeWizard
          initialMode={wizardMode}
          initialCategory={wizardCategory}
          onClose={() => setShowWizard(false)}
        />
      )}
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

export default function GaragePage() {
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center">Garage wird geladen…</div>
      }
    >
      <GaragePageInner />
    </Suspense>
  );
}
