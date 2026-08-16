"use client";

import { useMemo, useState } from "react";
import { slotLabel } from "@/lib/catalog/slots";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import {
  dieBoxReadinessLabel,
  planDieBox,
  type DieBoxTodayItem,
} from "@/lib/garage/dieBox";
import { BikePhotoControl } from "@/components/garage/BikePhotoControl";
import { GaragePartsCta } from "@/components/garage/GaragePartsCta";
import { useHofCopy } from "@/hooks/useHofCopy";
import { lastRideHeroLineForBike } from "@/lib/garage/lastRideHero";
import { enteredPressureToPsi, pressureUnitLabel } from "@/lib/garage/pressureUnit";
import { getMaintenanceSummary } from "@/lib/maintenance/summary";
import { useAppStore } from "@/store/useAppStore";
import type { Bike, ComponentSlot } from "@/types";

function partName(c: { manufacturer?: string; model?: string; freeText?: string }) {
  return [c.manufacturer, c.model, c.freeText].filter(Boolean).join(" ") || "eingetragen";
}

type MeasureKind = "pressure" | "sag" | "travel";

const MEASURE: Record<
  MeasureKind,
  { title: string; hint: string; front: string; rear: string; unit: string }
> = {
  pressure: {
    title: "Druck merken",
    hint: "Vorn und hinten am Ventil ablesen.",
    front: "Vorn",
    rear: "Hinten",
    unit: "",
  },
  sag: {
    title: "Federung merken",
    hint: "Prozent an Gabel und Dämpfer. SAG ist, wie weit die Federung mit dir einsinkt.",
    front: "Gabel",
    rear: "Dämpfer",
    unit: "%",
  },
  travel: {
    title: "Federweg merken",
    hint: "Nur der Federweg, der am Rad steht.",
    front: "Vorn",
    rear: "Hinten",
    unit: "mm",
  },
};

export function DieBoxSurface({
  bike,
  onInstallSlot,
}: {
  bike: Bike;
  onInstallSlot: (slot: ComponentSlot) => void;
}) {
  const copy = useHofCopy();

  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const setCurrentSetup = useAppStore((s) => s.setCurrentSetup);
  const createSetupVersion = useAppStore((s) => s.createSetupVersion);
  const addMaintenanceLog = useAppStore((s) => s.addMaintenanceLog);
  const updateBike = useAppStore((s) => s.updateBike);
  const logs = useAppStore((s) => s.maintenanceLogs);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const rides = useAppStore((s) => s.rides);
  const [busy, setBusy] = useState(false);
  const [snoozed, setSnoozed] = useState<Set<string>>(new Set());
  const [measure, setMeasure] = useState<{
    kind: MeasureKind;
    front: string;
    rear: string;
  } | null>(null);

  const plan = useMemo(() => {
    const summary = getMaintenanceSummary(bike, intervals);
    return planDieBox({
      bike,
      logs: logs.filter((l) => l.bikeId === bike.id),
      due: summary.items.map((i) => ({
        slot: i.slot,
        label: i.label,
        remainingLabel: i.remainingLabel,
      })),
    });
  }, [bike, logs, intervals]);

  const run = async (item: DieBoxTodayItem) => {
    if (busy) return;
    if (item.id === "pressureUnknown") {
      setMeasure({ kind: "pressure", front: "", rear: "" });
      return;
    }
    if (item.id === "sagUnknown") {
      setMeasure({ kind: "sag", front: "", rear: "" });
      return;
    }
    if (item.id === "travelUnknown") {
      setMeasure({ kind: "travel", front: "", rear: "" });
      return;
    }
    setBusy(true);
    try {
      if (item.id === "setActive") {
        setActiveBike(bike.id);
        return;
      }
      if (item.slot && ["lightsMissing", "lockMissing", "rackMissing", "bagsMissing", "brakesUnknown"].includes(item.id)) {
        onInstallSlot(item.slot);
        return;
      }
      if (item.id === "chainTeach" || item.id === "dueCare") {
        addMaintenanceLog({
          bikeId: bike.id,
          date: new Date().toISOString().slice(0, 10),
          activity: item.id === "chainTeach" ? "Kette gemessen" : item.title,
          performer: "self",
          notes: item.hint,
        });
        return;
      }
      if (item.id === "parkTrail" && plan.parkSetup && plan.trailSetup) {
        const next = plan.parkSetup.isCurrent ? plan.trailSetup : plan.parkSetup;
        setCurrentSetup(bike.id, next.id);
      }
    } finally {
      setBusy(false);
    }
  };

  const applyMeasure = () => {
    if (!measure) return;
    const f = measure.front ? Number(measure.front.replace(",", ".")) : NaN;
    const r = measure.rear ? Number(measure.rear.replace(",", ".")) : NaN;
    if (!Number.isFinite(f) && !Number.isFinite(r)) return;

    if (measure.kind === "pressure") {
      const toPsi = (n: number) => enteredPressureToPsi(n, bike.category);
      createSetupVersion({
        bikeId: bike.id,
        label: "Druck gemerkt",
        conditions: "general",
        valueOverrides: {
          ...(Number.isFinite(f) ? { "tire_front.pressure_psi": toPsi(f) } : {}),
          ...(Number.isFinite(r) ? { "tire_rear.pressure_psi": toPsi(r) } : {}),
        },
      });
      addMaintenanceLog({
        bikeId: bike.id,
        date: new Date().toISOString().slice(0, 10),
        activity: "Druck gemerkt",
        performer: "self",
      });
    } else if (measure.kind === "sag") {
      createSetupVersion({
        bikeId: bike.id,
        label: "SAG gemerkt",
        conditions: "general",
        valueOverrides: {
          ...(Number.isFinite(f) ? { "fork.sag_pct": f } : {}),
          ...(Number.isFinite(r) ? { "shock.sag_pct": r } : {}),
        },
      });
    } else {
      updateBike(bike.id, {
        travelFrontMm: Number.isFinite(f) ? f : bike.travelFrontMm,
        travelRearMm: Number.isFinite(r) ? r : bike.travelRearMm,
      });
    }
    setMeasure(null);
  };

  const itemKey = (item: DieBoxTodayItem) =>
    item.id === "dueCare" ? `due:${item.title}` : item.id;
  const visible = plan.today.filter((item) => !snoozed.has(itemKey(item)));
  const primary = visible[0] ?? null;
  const rest = visible.slice(1);
  const knownChips = plan.chips.filter((c) => c.known);
  const lastRideLine = lastRideHeroLineForBike(rides, bike.id);
  const pressureUnit = pressureUnitLabel(bike.category);
  const measureSpec = measure
    ? measure.kind === "pressure"
      ? { ...MEASURE.pressure, unit: pressureUnit }
      : MEASURE[measure.kind]
    : null;

  return (
    <div className="space-y-5" data-testid="die-box-surface">
      <BikePhotoControl bikeId={bike.id} photoUrl={bike.photoUrl} />
      {lastRideLine ? (
        <p className="-mt-3 px-1 text-xs text-text-secondary">{lastRideLine}</p>
      ) : null}
      <section className="rounded-2xl border border-border bg-surface p-4">
        <div className="flex items-center gap-2 text-xs font-semibold">
          <span className="text-chrome">{dieBoxReadinessLabel(plan.readiness)}</span>
          <span className="text-text-secondary">{bikeCategoryLabel(bike.category)}</span>
        </div>
        <p className="mt-2 text-lg font-semibold leading-snug">{plan.sentence}</p>
        {knownChips.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-1.5">
            {knownChips.map((c) => (
              <span
                key={c.label}
                className="rounded-full border border-chrome/40 px-2.5 py-1 text-[11px] font-semibold text-chrome"
              >
                {c.label}
              </span>
            ))}
          </div>
        )}
        {primary ? (
          <button
            type="button"
            disabled={busy}
            onClick={() => void run(primary)}
            className="mt-4 w-full rounded-xl bg-chrome py-3 text-sm font-bold text-background"
          >
            {primary.cta}
          </button>
        ) : plan.isReady ? (
          <p className="mt-4 text-center text-sm font-semibold text-chrome">
            {plan.kind === "urban"
              ? "Montag-bereit — Licht und Kette sitzen."
              : "Bereit — nichts liegt an."}
          </p>
        ) : null}
      </section>

      {rest.length > 0 && (
      <section>
        <h3 className="mb-2 text-[11px] font-bold uppercase tracking-wide text-text-secondary">
          {copy.workshopZoneToday}
        </h3>
          <div className="space-y-2">
            {rest.map((item) => (
              <div
                key={`${item.id}-${item.title}`}
                className="flex w-full items-start justify-between gap-3 rounded-2xl border border-border bg-surface p-3 text-left"
              >
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void run(item)}
                  className="min-w-0 flex-1 text-left"
                >
                  <span className="block text-sm font-semibold">{item.title}</span>
                  <span className="mt-0.5 block text-xs text-text-secondary">{item.hint}</span>
                </button>
                <div className="flex shrink-0 flex-col items-end gap-1">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void run(item)}
                    className="text-xs font-bold text-chrome"
                  >
                    {item.cta}
                  </button>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() =>
                      setSnoozed((prev) => new Set(prev).add(itemKey(item)))
                    }
                    className="text-xs text-text-secondary"
                  >
                    {copy.workshopLater}
                  </button>
                </div>
              </div>
            ))}
          </div>
      </section>
      )}

      <section>
        <h3 className="mb-2 text-[11px] font-bold uppercase tracking-wide text-text-secondary">
          {copy.workshopZoneOnBike}
        </h3>
        {plan.onBike.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Noch nichts eingetragen. Name und Typ reichen — Teile nur, wenn sie
            wirklich dran sind.
          </p>
        ) : (
          <ul className="space-y-1.5">
            {plan.onBike.map((c) => (
              <li
                key={c.id}
                className="rounded-xl border border-border bg-surface px-3 py-2 text-sm font-medium"
              >
                {slotLabel(c.slot)} · {partName(c)}
              </li>
            ))}
          </ul>
        )}
        {plan.addableSlots.length > 0 && (
          <button
            type="button"
            onClick={() => {
              const next = plan.addableSlots.find((s) => !plan.onBike.some((c) => c.slot === s));
              onInstallSlot(next ?? plan.addableSlots[0]);
            }}
            className="mt-2 text-sm font-semibold text-chrome"
          >
            Weiteres eintragen
          </button>
        )}
      </section>

      <p className="text-xs text-text-secondary">
        {copy.workshopNoWatch}
      </p>
      {plan.hasElectricAssist && (
        <p className="text-xs text-text-secondary">
          Akkustand erscheint, sobald ein Sensor am Rad koppelt. Bis dahin keine Zahl.
        </p>
      )}

      <GaragePartsCta bikeId={bike.id} bikeName={bike.name} />

      {measure && measureSpec && (
        <div
          className="fixed inset-0 z-[80] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4"
          role="dialog"
          aria-modal
          aria-labelledby="die-box-measure-title"
          onClick={() => setMeasure(null)}
        >
          <div
            className="w-full max-w-md rounded-t-2xl border border-border bg-surface p-5 sm:rounded-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 id="die-box-measure-title" className="text-lg font-bold">
              {measureSpec.title}
            </h3>
            <p className="mt-1 text-sm text-text-secondary">
              {measureSpec.hint}
            </p>
            <div className="mt-4 grid grid-cols-2 gap-3">
              <label className="block text-sm">
                {measureSpec.front}
                {measureSpec.unit ? ` (${measureSpec.unit})` : ""}
                <input
                  type="number"
                  inputMode="decimal"
                  value={measure.front}
                  onChange={(e) =>
                    setMeasure({ ...measure, front: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
                />
              </label>
              <label className="block text-sm">
                {measureSpec.rear}
                {measureSpec.unit ? ` (${measureSpec.unit})` : ""}
                <input
                  type="number"
                  inputMode="decimal"
                  value={measure.rear}
                  onChange={(e) =>
                    setMeasure({ ...measure, rear: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
                />
              </label>
            </div>
            <div className="mt-4 flex flex-col gap-2">
              <button
                type="button"
                onClick={applyMeasure}
                className="w-full rounded-xl bg-chrome py-3 text-sm font-semibold text-background"
              >
                Merken
              </button>
              <button
                type="button"
                onClick={() => setMeasure(null)}
                className="py-2 text-sm text-text-secondary"
              >
                Abbrechen
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
