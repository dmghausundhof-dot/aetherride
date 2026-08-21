"use client";

import { useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { AddBikeWizard } from "@/components/garage/AddBikeWizard";
import { InstallComponentSheet } from "@/components/garage/InstallComponentSheet";
import { GarageComponentsTab } from "@/components/garage/GarageComponentsTab";
import { GarageSetupsTab } from "@/components/garage/GarageSetupsTab";
import { GarageMaintenanceTab } from "@/components/garage/GarageMaintenanceTab";
import { DieBoxSurface } from "@/components/garage/DieBoxSurface";
import { BikeIdentityCard } from "@/components/garage/BikeIdentityCard";
import { BikeRideLog } from "@/components/garage/BikeRideLog";
import { GaragePartsCta } from "@/components/garage/GaragePartsCta";
import { RadBikeChip } from "@/components/garage/RadBikeChip";
import { RadEmpty } from "@/components/garage/RadEmpty";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { RadSectionLabel } from "@/components/garage/RadSectionLabel";
import { FamilyRiderStrip } from "@/components/garage/FamilyRiderStrip";
import { FadeEdgeRow } from "@/components/garage/FadeEdgeRow";
import { BikeSchemaHotspots } from "@/components/garage/BikeSchemaHotspots";
import { SagGuideForBike } from "@/components/garage/SagGuidePanel";
import { getMaintenanceSummary } from "@/lib/maintenance/summary";
import { buildServiceReport, downloadServiceReport } from "@/lib/garage/serviceReport";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import type { ComponentSlot, SetupCondition } from "@/types";

type Tab = "overview" | "components" | "maintenance" | "setups";
const TABS: Tab[] = ["overview", "components", "maintenance", "setups"];

function parseTab(raw: string | null): Tab | null {
  if (raw && (TABS as string[]).includes(raw)) return raw as Tab;
  return null;
}

function parseWizard(raw: string | null): boolean {
  return raw != null && raw.length > 0;
}

function GaragePageInner() {
  const copy = useHofCopy();
  const lang = useChromeLang();

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
    () => parseTab(tabParam) ?? "overview"
  );
  const [showWizard, setShowWizard] = useState(() => parseWizard(wizardParam));
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
    if (parseWizard(wizardParam)) {
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

  const spareParts = selected
    ? selected.components.filter((c) => !!c.removedAt)
    : [];

  const intervals = selected
    ? maintenanceIntervals.filter((i) => i.bikeId === selected.id)
    : [];
  const logs = selected
    ? maintenanceLogs.filter((l) => l.bikeId === selected.id)
    : [];
  const dueSlot = selected
    ? getMaintenanceSummary(selected, maintenanceIntervals).topItem?.slot
    : undefined;

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
      lang,
    });
    const slug = selected.name.replace(/\s+/g, "-").toLowerCase();
    downloadServiceReport(`aetherride-service-${slug}.txt`, text);
  };

  return (
    <div className="mx-auto w-full max-w-5xl p-4 pt-6 lg:p-6 lg:px-10">
      <header className="mb-5 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight lg:text-3xl">
            {copy.workshopTitle}
          </h1>
          <p className="mt-1 max-w-xl text-sm text-text-secondary">
            {copy.workshopHint}
          </p>
        </div>
        <div className="flex items-center gap-1 pr-[max(0.75rem,env(safe-area-inset-right,0px))]">
          {selected ? (
            <Link
              href="/download"
              title={copy.workshopCscBar}
              aria-label={copy.workshopCscBar}
              className="rounded-full p-2 text-text-secondary hover:bg-surface-elevated hover:text-chrome"
            >
              <RadGlyph name="battery" size={22} />
            </Link>
          ) : null}
          {selected ? (
          <button
            type="button"
            onClick={() => setShowWizard(true)}
            className="flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm font-medium text-chrome hover:border-chrome"
          >
            <RadGlyph name="add" size={16} /> {copy.workshopAddAnother}
          </button>
          ) : null}
        </div>
      </header>

      {!selected ? (
        <RadEmpty title={copy.workshopEmpty} hint={copy.workshopEmptyHint}>
          <button
            type="button"
            onClick={() => setShowWizard(true)}
            className="mt-6 inline-flex items-center gap-2 rounded-xl bg-chrome px-5 py-3 text-sm font-semibold text-on-accent"
          >
            <RadGlyph name="add" size={16} /> {copy.workshopAdd}
          </button>
        </RadEmpty>
      ) : (
        <div className={`flex flex-col gap-5 ${bikes.length > 1 ? "lg:grid lg:grid-cols-[240px_minmax(0,1fr)] lg:items-start lg:gap-6" : ""}`}>
          {bikes.length > 1 ? (
          <aside className="lg:sticky lg:top-20 lg:self-start">
            <div className="mb-2 hidden lg:block">
              <RadSectionLabel mark="stand">
                {copy.workshopBikes} ({bikes.length})
              </RadSectionLabel>
            </div>
            <FadeEdgeRow
              testId="garage-bike-scroller"
              fadeFromClass="from-background"
              className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:overflow-visible lg:pb-0"
            >
              {bikes.map((bike) => (
                <RadBikeChip
                  key={bike.id}
                  bike={bike}
                  selected={selected?.id === bike.id}
                  onSelect={() => selectBike(bike.id)}
                />
              ))}
              <button
                type="button"
                onClick={() => setShowWizard(true)}
                className="flex min-w-[7rem] flex-shrink-0 items-center justify-center gap-1 rounded-xl border border-dashed border-border px-3 py-3 text-xs font-medium text-text-secondary hover:border-chrome/40 hover:text-chrome lg:min-w-0 lg:w-full"
              >
                <RadGlyph name="add" size={14} /> {copy.workshopAddAnother}
              </button>
            </FadeEdgeRow>
          </aside>
          ) : null}

          <div className="min-w-0 space-y-4">
          <DieBoxSurface
            bike={selected}
            compact
            onInstallSlot={(slot) => setInstallSlot(slot)}
            onOpenMaintenance={() => setTab("maintenance")}
          />
          <FamilyRiderStrip bikeId={selected.id} />
          <div role="tablist" aria-label={copy.workshopTitle}>
            <FadeEdgeRow
              testId="garage-tab-scroller"
              fadeFromClass="from-background"
              className="flex gap-1 overflow-x-auto text-sm"
            >
              {(
                [
                  ["overview", copy.workshopTabOverview],
                  ["components", copy.workshopTabParts],
                  ["maintenance", copy.workshopTabCare],
                  ["setups", copy.workshopTabSetups],
                ] as const
              ).map(([id, label]) => {
                const on = tab === id;
                return (
                  <button
                    key={id}
                    type="button"
                    role="tab"
                    aria-selected={on}
                    onClick={() => setTab(id)}
                    className={`min-h-11 shrink-0 rounded-xl px-3 py-2.5 font-bold ${
                      on
                        ? "bg-chrome text-on-accent"
                        : "border border-border bg-surface text-foreground hover:border-chrome/40"
                    }`}
                  >
                    {label}
                  </button>
                );
              })}
            </FadeEdgeRow>
          </div>

          {tab === "overview" && (
            <div className="space-y-4">
              <BikeRideLog bikeId={selected.id} omitLatestPeek />
              <BikeIdentityCard bike={selected} />
            </div>
          )}

          {tab === "components" && (
            <div className="space-y-4">
              <BikeSchemaHotspots
                bike={selected}
                dueSlots={dueSlot ? [dueSlot] : []}
                onTapSlot={(slot) => setInstallSlot(slot)}
              />
              <GaragePartsCta bikeId={selected.id} lookupOnly />
              <GarageComponentsTab
                selected={selected}
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
            </div>
          )}

          {tab === "setups" && (
            <div className="space-y-4">
              {(selected.travelFrontMm ?? 0) > 0 ||
              (selected.travelRearMm ?? 0) > 0 ? (
                <SagGuideForBike bike={selected} />
              ) : null}
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
            </div>
          )}

          {tab === "maintenance" && (
            <div className="space-y-4">
            <GarageMaintenanceTab
              selected={selected}
              rides={rides}
              intervals={intervals}
              logs={logs}
              costSum={logs.reduce((s, l) => s + (l.costEur ?? 0), 0)}
              markIntervalDone={markIntervalDone}
              exportReport={exportReport}
            />
            <GaragePartsCta
              bikeId={selected.id}
              lookupOnly
              slot={dueSlot}
            />
            </div>
          )}
          </div>
        </div>
      )}

      {showWizard && (
        <AddBikeWizard initialCategory={wizardCategory} onClose={() => setShowWizard(false)} />
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
