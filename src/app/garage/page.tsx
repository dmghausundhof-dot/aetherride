"use client";

import { useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Bluetooth, Plus } from "lucide-react";
import { AddBikeWizard } from "@/components/garage/AddBikeWizard";
import { InstallComponentSheet } from "@/components/garage/InstallComponentSheet";
import { GarageComponentsTab } from "@/components/garage/GarageComponentsTab";
import { GarageSetupsTab } from "@/components/garage/GarageSetupsTab";
import { GarageMaintenanceTab } from "@/components/garage/GarageMaintenanceTab";
import { DieBoxSurface } from "@/components/garage/DieBoxSurface";
import { BikeRideLog } from "@/components/garage/BikeRideLog";
import { GaragePartsCta } from "@/components/garage/GaragePartsCta";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { buildServiceReport, downloadServiceReport } from "@/lib/garage/serviceReport";
import {
  getActiveComponents,
  useAppStore,
} from "@/store/useAppStore";
import { HofPageHeader } from "@/components/hof/HofPageHeader";
import { useHofCopy } from "@/hooks/useHofCopy";
import type { ComponentSlot, SetupCondition } from "@/types";

type Tab = "components" | "setups" | "maintenance";
const TABS: Tab[] = ["components", "setups", "maintenance"];

function parseTab(raw: string | null): Tab | null {
  if (raw === "overview") return "components";
  if (raw && (TABS as string[]).includes(raw)) return raw as Tab;
  return null;
}

type WizardMode = "catalog" | "basic" | "import";

function parseWizard(raw: string | null): WizardMode | null {
  if (raw === "catalog" || raw === "basic" || raw === "import") return raw;
  return null;
}

function GaragePageInner() {
  const copy = useHofCopy();

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

  const tabParam = searchParams.get("tab");
  const wizardParam = searchParams.get("wizard");
  const categoryParam = searchParams.get("category");
  const bikeParam = searchParams.get("bike");

  const [selectedId, setSelectedId] = useState<string | null>(
    () => bikeParam || activeBikeId
  );
  const [tab, setTab] = useState<Tab>(
    () => parseTab(tabParam) ?? "components"
  );
  const [showWizard, setShowWizard] = useState(
    () => parseWizard(wizardParam) != null
  );
  const [wizardMode, setWizardMode] = useState<WizardMode>(
    () => parseWizard(wizardParam) ?? "basic"
  );
  const [wizardCategory, setWizardCategory] = useState<
    import("@/types").BikeCategory | undefined
  >(() =>
    categoryParam
      ? (categoryParam as import("@/types").BikeCategory)
      : undefined
  );

  // Sync URL → local state when deep-link params change (React-recommended pattern)
  const [trackedParams, setTrackedParams] = useState(
    () => `${tabParam}|${wizardParam}|${categoryParam}|${bikeParam}`
  );
  const paramKey = `${tabParam}|${wizardParam}|${categoryParam}|${bikeParam}`;
  if (paramKey !== trackedParams) {
    setTrackedParams(paramKey);
    const nextTab = parseTab(tabParam);
    if (nextTab) setTab(nextTab);
    const nextWizard = parseWizard(wizardParam);
    if (nextWizard) {
      setWizardMode(nextWizard);
      setShowWizard(true);
    }
    if (categoryParam) {
      setWizardCategory(categoryParam as import("@/types").BikeCategory);
    }
    if (bikeParam && bikes.some((b) => b.id === bikeParam)) {
      setSelectedId(bikeParam);
    }
  }

  const [installSlot, setInstallSlot] = useState<ComponentSlot | null>(null);
  const [setupLabel, setSetupLabel] = useState("");
  const [setupCondition, setSetupCondition] =
    useState<SetupCondition>("dry");
  const [moveTargetId, setMoveTargetId] = useState<string>("");

  const selected =
    bikes.find((b) => b.id === (selectedId || activeBikeId)) || bikes[0];

  const activeComponents = selected ? getActiveComponents(selected) : [];
  const spareParts = selected
    ? selected.components.filter((c) => !!c.removedAt)
    : [];

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
    <div className="mx-auto w-full max-w-5xl p-4 pt-6 lg:p-6 lg:px-10">
      <header className="mb-5 flex flex-wrap items-start justify-between gap-3">
        <HofPageHeader
          kicker={copy.workshopKicker}
          title={copy.workshopTitle}
          hint={copy.workshopHint}
        />
        <div className="flex items-center gap-1 pr-[max(0.75rem,env(safe-area-inset-right,0px))]">
          {selected ? (
            <Link
              href="/download"
              title={copy.workshopCscBar}
              aria-label={copy.workshopCscBar}
              className="rounded-full p-2 text-text-secondary hover:bg-surface-elevated hover:text-chrome"
            >
              <Bluetooth className="h-[22px] w-[22px]" strokeWidth={1.75} />
            </Link>
          ) : null}
          {selected ? (
          <button
            type="button"
            onClick={() => {
              setWizardMode("basic");
              setShowWizard(true);
            }}
            className="flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm font-medium text-chrome hover:border-chrome"
          >
            <Plus className="h-4 w-4" /> {copy.workshopAddAnother}
          </button>
          ) : null}
        </div>
      </header>

      {/* Wartungs-Status: auf Übersicht übernimmt BikeSchema — sonst Doppelung */}
      {selected && (
        <p className="mb-5 text-[11px] text-text-secondary">
          {copy.workshopNoWatch}
        </p>
      )}

      {!selected ? (
        <section className="rounded-2xl border border-border bg-surface p-6 text-center lg:p-10">
          <h2 className="text-lg font-semibold">{copy.workshopEmpty}</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
            {copy.workshopEmptyHint}
          </p>
          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            {(
              [
                ["basic", copy.workshopAdd, copy.workshopAddBasicHint],
                ["catalog", copy.workshopAddCatalog, copy.workshopAddCatalogHint],
                ["import", copy.workshopAddPlaceholder, copy.workshopAddPlaceholderHint],
              ] as const
            ).map(([mode, title, desc]) => (
              <button
                key={mode}
                type="button"
                onClick={() => {
                  setWizardMode(mode);
                  setShowWizard(true);
                }}
                className="rounded-xl border border-border bg-surface-elevated p-4 text-left transition hover:border-chrome/40"
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
            <p className="mb-2 hidden text-[10px] font-semibold tracking-wide text-text-secondary lg:block">
              {copy.workshopBikes} ({bikes.length})
            </p>
            <div className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:overflow-visible lg:pb-0">
              {bikes.map((bike) => (
                <button
                  key={bike.id}
                  type="button"
                  onClick={() => selectBike(bike.id)}
                  className={`min-w-[9.5rem] flex-shrink-0 rounded-xl border px-3 py-3 text-left transition lg:min-w-0 lg:w-full ${
                    selected?.id === bike.id
                      ? "border-chrome bg-chrome/10"
                      : "border-border bg-surface hover:border-border"
                  }`}
                >
                  <div className="truncate font-medium">{bike.name}</div>
                  <div className="text-xs text-text-secondary">
                    {bikeCategoryLabel(bike.category)}
                    {bike.isActive ? " · aktiv" : ""}
                  </div>
                </button>
              ))}
              <button
                type="button"
                onClick={() => {
                  setWizardMode("basic");
                  setShowWizard(true);
                }}
                className="flex min-w-[7rem] flex-shrink-0 items-center justify-center gap-1 rounded-xl border border-dashed border-border px-3 py-3 text-xs font-medium text-text-secondary hover:border-chrome/40 hover:text-chrome lg:min-w-0 lg:w-full"
              >
                <Plus className="h-3.5 w-3.5" /> {copy.workshopAddAnother}
              </button>
            </div>
          </aside>

          <div className="min-w-0 space-y-4">
          <DieBoxSurface
            bike={selected}
            onInstallSlot={(slot) => setInstallSlot(slot)}
          />
          <GaragePartsCta bikeId={selected.id} bikeName={selected.name} />
          <BikeRideLog bikeId={selected.id} />
          <details className="rounded-2xl border border-border bg-surface p-4">
            <summary className="cursor-pointer list-none font-semibold">
              {copy.workshopMore}
              <span className="mt-0.5 block text-xs font-normal text-text-secondary">
                Teile, Setup-Versionen, Wartung — hinter der Box
              </span>
            </summary>
            <div className="mt-4 space-y-4">
          <GaragePartsCta
            bikeId={selected.id}
            lookupOnly
          />
          <div className="grid grid-cols-3 gap-1 rounded-xl bg-surface-elevated p-1 text-xs sm:text-sm">
            {(
              [
                ["components", copy.workshopTabParts],
                ["setups", copy.workshopTabSetups],
                ["maintenance", copy.workshopTabCare],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setTab(id)}
                className={`rounded-lg py-2.5 font-medium ${
                  tab === id ? "bg-chrome text-on-accent" : "text-text-secondary"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "components" && (
            <GarageComponentsTab
              selected={selected}
              activeComponents={activeComponents}
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
              costSum={logs.reduce((s, l) => s + (l.costEur ?? 0), 0)}
              markIntervalDone={markIntervalDone}
              exportReport={exportReport}
            />
          )}
            </div>
          </details>
          </div>
        </div>
      )}

      {showWizard && (
        <AddBikeWizard initialMode={wizardMode} initialCategory={wizardCategory} onClose={() => setShowWizard(false)} />
      )}
      {selected && installSlot && (
        <InstallComponentSheet
          key={installSlot}
          bike={selected}
          slot={installSlot}
          onClose={() => setInstallSlot(null)}
        />
      )}
    </div>
  );
}

export default function GaragePage() {
  const copy = useHofCopy();

  return (
    <Suspense fallback={<div className="p-6 text-center text-sm text-text-secondary">{copy.workshopLoading}</div>}>
      <GaragePageInner />
    </Suspense>
  );
}
