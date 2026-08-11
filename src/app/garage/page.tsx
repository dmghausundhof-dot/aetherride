"use client";

import { useMemo, useState, useEffect, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import {
  Plus,
  ShieldCheck,
  Download,
  AlertTriangle,
} from "lucide-react";
import { AddBikeWizard } from "@/components/garage/AddBikeWizard";
import { BikeSilhouette } from "@/components/garage/BikeSilhouette";
import { InstallComponentSheet } from "@/components/garage/InstallComponentSheet";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { SagGuideForBike } from "@/components/garage/SagGuidePanel";
import { BikePhotoControl } from "@/components/garage/BikePhotoControl";
import { OdometerImportPanel } from "@/components/garage/OdometerImportPanel";
import { SetupFingerprint } from "@/components/SetupFingerprint";
import { GarageComponentsTab } from "@/components/garage/GarageComponentsTab";
import { GarageSetupsTab } from "@/components/garage/GarageSetupsTab";
import { GarageMaintenanceTab } from "@/components/garage/GarageMaintenanceTab";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import {
  aggregateVerdict,
  checkBikeCompatibility,
} from "@/lib/compatibility/engine";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import {
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
    <div className="mx-auto w-full max-w-7xl p-4 pt-6 lg:p-6">
      <header className="mb-5 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Garage</h1>
          <p className="mt-1 text-sm text-text-secondary">
            Multi-Bike, Kompatibilität und Setup — Rennrad bis E-MTB.
          </p>
        </div>
        <button
          type="button"
          onClick={() => {
            setWizardMode("catalog");
            setShowWizard(true);
          }}
          className="flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-medium text-white"
        >
          <Plus className="h-4 w-4" /> Bike hinzufügen
        </button>
      </header>

      {!selected ? (
        <section className="rounded-2xl border border-border bg-surface p-6 text-center lg:p-10">
          <h2 className="text-lg font-semibold">Lege dein erstes Bike an</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
            Katalog mit OEM-Teilen, schnelle Basis für Road/City, oder
            Platzhalter. GPX und Touren unter Explore/Planner — kein Auto-Demo-Bike.
          </p>
          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            {(
              [
                ["catalog", "Katalog", "Modell wählen, Slots vorgefüllt"],
                ["basic", "Basis", "Ideal für Road, City, Trekking"],
                ["import", "Platzhalter", "Ohne Teile — Track via Explore"],
              ] as const
            ).map(([mode, title, desc]) => (
              <button
                key={mode}
                type="button"
                onClick={() => {
                  setWizardMode(mode);
                  setShowWizard(true);
                }}
                className="rounded-xl border border-border bg-surface-elevated p-4 text-left transition hover:border-accent/40"
              >
                <div className="text-sm font-medium">{title}</div>
                <div className="mt-1 text-xs text-text-secondary">{desc}</div>
              </button>
            ))}
          </div>
        </section>
      ) : (
        <div className="flex flex-col gap-5 lg:grid lg:grid-cols-[240px_minmax(0,1fr)] lg:items-start lg:gap-6">
          {/* Desktop: sticky Bike-Leiste · Mobile: horizontal */}
          <aside className="lg:sticky lg:top-20 lg:self-start">
            <p className="mb-2 hidden text-[10px] font-semibold uppercase tracking-wide text-text-secondary lg:block">
              Deine Bikes ({bikes.length})
            </p>
            <div className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:overflow-visible lg:pb-0">
              {bikes.map((bike) => (
                <button
                  key={bike.id}
                  type="button"
                  onClick={() => selectBike(bike.id)}
                  className={`min-w-[9.5rem] flex-shrink-0 rounded-xl border px-3 py-3 text-left transition lg:min-w-0 lg:w-full ${
                    selected?.id === bike.id
                      ? "border-accent bg-accent/10"
                      : "border-border bg-surface hover:border-border"
                  }`}
                >
                  <div className="truncate font-medium">{bike.name}</div>
                  <div className="text-xs text-text-secondary">
                    {bikeCategoryLabel(bike.category)}
                    {bike.isActive ? " · aktiv" : ""}
                  </div>
                  <div className="mt-1 text-[11px] tabular-nums text-text-secondary">
                    {bike.totalOdometerKm.toFixed(0)} km
                  </div>
                </button>
              ))}
              <button
                type="button"
                onClick={() => {
                  setWizardMode("basic");
                  setShowWizard(true);
                }}
                className="flex min-w-[7rem] flex-shrink-0 items-center justify-center gap-1 rounded-xl border border-dashed border-border px-3 py-3 text-xs font-medium text-text-secondary hover:border-accent/40 hover:text-accent lg:min-w-0 lg:w-full"
              >
                <Plus className="h-3.5 w-3.5" /> Weiteres Bike
              </button>
            </div>
          </aside>

          <div className="min-w-0 space-y-4">
          <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-xs sm:text-sm">
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
                className={`rounded-lg py-2.5 font-medium ${
                  tab === id ? "bg-accent text-white" : "text-text-secondary"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "overview" && (
            <div className="flex flex-col gap-4 xl:grid xl:grid-cols-2 xl:gap-6">
              <div className="flex flex-col gap-4">
                <BikePhotoControl bikeId={selected.id} photoUrl={selected.photoUrl} />
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
                      <div className="tabular-nums text-lg font-bold">{selected.totalOdometerKm.toFixed(0)}</div>
                      <div className="text-[10px] text-text-secondary">km</div>
                    </div>
                    <div className="rounded-xl bg-surface-elevated p-2">
                      <div className="tabular-nums text-lg font-bold">{selected.totalHours.toFixed(1)}</div>
                      <div className="text-[10px] text-text-secondary">Stunden</div>
                    </div>
                    <div className="rounded-xl bg-surface-elevated p-2">
                      <div className="tabular-nums text-lg font-bold">{costSum > 0 ? `${costSum.toFixed(0)}€` : "—"}</div>
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
                {currentSetup && (
                  <section className="rounded-2xl border border-border bg-surface p-4">
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="font-semibold">Aktives Setup</h3>
                      <button type="button" className="text-xs font-medium text-accent" onClick={() => setTab("setups")}>
                        Wechseln
                      </button>
                    </div>
                    <p className="mt-1 text-sm">„{currentSetup.label}“ · {setupConditionLabel(currentSetup.conditions)}</p>
                    <div className="mt-2"><SetupFingerprint setup={currentSetup} /></div>
                  </section>
                )}
              </div>

              <div className="flex flex-col gap-4">
                <BikeSilhouette
                  bike={selected}
                  maintenanceSlots={intervals
                    .filter((i) => {
                      const d = evaluateIntervalDue(i, selected.totalOdometerKm, selected.totalHours);
                      return d.status !== "ok";
                    })
                    .map((i) => i.slot)}
                  onSelectSlot={(slot) => {
                    setTab("components");
                    setInstallSlot(slot);
                  }}
                />
                <section className="rounded-2xl border border-border bg-surface p-4">
                  <button type="button" className="flex w-full items-center justify-between gap-2 text-left" onClick={() => setCompatOpen((v) => !v)}>
                    <h3 className="flex items-center gap-2 font-semibold">
                      <ShieldCheck className="h-4 w-4 text-accent" />
                      Kompatibilität
                    </h3>
                    <VerdictPill verdict={overallVerdict} />
                  </button>
                  <p className="mt-2 text-xs text-text-secondary">{verdictSummaryDe(overallVerdict)} · regelbasiert, kein ML.</p>
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
                        </details>
                      ))}
                    </div>
                  )}
                </section>
                <SagGuideForBike bike={selected} defaultWeightKg={riderWeight} />
                <OdometerImportPanel bikeId={selected.id} odometerKm={selected.totalOdometerKm} hours={selected.totalHours} />
                <button type="button" onClick={exportReport} className="inline-flex items-center justify-center gap-2 rounded-xl border border-border bg-surface py-3 text-sm font-medium">
                  <Download className="h-4 w-4 text-accent" />
                  Service-Report exportieren
                </button>
              </div>
            </div>
          )}

          {tab === "components" && (
            <GarageComponentsTab
              selected={selected}
              activeComponents={activeComponents}
              missing={missing}
              spareParts={spareParts}
              rides={rides}
              bikes={bikes}
              moveTargetId={moveTargetId}
              setMoveTargetId={setMoveTargetId}
              setInstallSlot={setInstallSlot}
              removeComponent={removeComponent}
              reinstallComponent={reinstallComponent}
              moveComponent={moveComponent}
            />
          )}

          {tab === "setups" && (
            <GarageSetupsTab
              selected={selected}
              setupLabel={setupLabel}
              setSetupLabel={setSetupLabel}
              setupCondition={setupCondition}
              setSetupCondition={setSetupCondition}
              createSetup={createSetup}
              setCurrentSetup={setCurrentSetup}
              applySetupTemplate={applySetupTemplate}
            />
          )}

          {tab === "maintenance" && (
            <GarageMaintenanceTab
              selected={selected}
              rides={rides}
              intervals={intervals}
              logs={logs}
              costSum={costSum}
              markIntervalDone={markIntervalDone}
              exportReport={exportReport}
            />
          )}
          </div>
        </div>
      )}

      {showWizard && (
        <AddBikeWizard initialMode={wizardMode} initialCategory={wizardCategory} onClose={() => setShowWizard(false)} />
      )}
      {selected && installSlot && (
        <InstallComponentSheet bike={selected} slot={installSlot} onClose={() => setInstallSlot(null)} />
      )}
    </div>
  );
}

export default function GaragePage() {
  return (
    <Suspense fallback={<div className="p-6 text-center">Garage wird geladen…</div>}>
      <GaragePageInner />
    </Suspense>
  );
}
