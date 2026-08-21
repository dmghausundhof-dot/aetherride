"use client";

import { useMemo, useState } from "react";
import { slotLabel } from "@/lib/catalog/slots";
import { rideSportLabel } from "@/lib/i18n/rideSportLabel";
import { isQuietFitSlot, planDieBox, type DieBoxTodayItem } from "@/lib/garage/dieBox";
import { BikePhotoControl } from "@/components/garage/BikePhotoControl";
import { BikeValueStrip } from "@/components/garage/BikeValueStrip";
import { BikeStandEditor } from "@/components/garage/BikeStandEditor";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { RadSectionLabel } from "@/components/garage/RadSectionLabel";
import { GaragePartsCta } from "@/components/garage/GaragePartsCta";
import {
  radMarkForChip,
  radMarkForItem,
  radMarkForMeasure,
  radMarkForReadiness,
  radMarkForSlot,
} from "@/lib/garage/radMark";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import {
  dieBoxChipLabel,
  dieBoxCopy,
  dieBoxMeasureSpec,
  dieBoxReadinessUi,
  dieBoxSentenceUi,
  lastRideHeroUiForBike,
  localizeDieBoxItem,
} from "@/lib/i18n/dieBoxCopy";
import { enteredPressureToPsi, formatLoggedTirePressure, pressureUnitLabel, pressureUsesBar } from "@/lib/garage/pressureUnit";
import {
  formatStripDate,
  planStripService,
} from "@/lib/garage/bikeValueStrip";
import { maintRemainingLabel } from "@/lib/i18n/maintDomainCopy";
import { getMaintenanceSummary, lastRideForBike } from "@/lib/maintenance/summary";
import { buildRideTelemetry } from "@/lib/ride/rideTelemetry";
import { terrainCaption } from "@/lib/ride/terrainCaption";
import { RideTerrainPeek } from "@/components/ride/ActivitySparkline";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import Link from "next/link";
import { planWerkstattCoach } from "@/lib/setup/werkstattCoach";
import { useAppStore } from "@/store/useAppStore";
import type { Bike, ComponentSlot } from "@/types";

function partName(
  c: { manufacturer?: string; model?: string; freeText?: string },
  fallback: string
) {
  return [c.manufacturer, c.model, c.freeText].filter(Boolean).join(" ") || fallback;
}

type MeasureKind = "pressure" | "sag" | "travel";

export function DieBoxSurface({
  bike,
  onInstallSlot,
  compact = false,
  onOpenMaintenance,
}: {
  bike: Bike;
  onInstallSlot: (slot: ComponentSlot) => void;
  /** Garage page: photo, sentence, primary — rest lives in the tabs. */
  compact?: boolean;
  onOpenMaintenance?: () => void;
}) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const box = dieBoxCopy(lang);

  const setActiveBike = useAppStore((s) => s.setActiveBike);
  const setCurrentSetup = useAppStore((s) => s.setCurrentSetup);
  const createSetupVersion = useAppStore((s) => s.createSetupVersion);
  const addMaintenanceLog = useAppStore((s) => s.addMaintenanceLog);
  const updateBike = useAppStore((s) => s.updateBike);
  const logs = useAppStore((s) => s.maintenanceLogs);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const rides = useAppStore((s) => s.rides);
  const riderWeightKg = useAppStore((s) => s.riderProfile.riderWeightKg) ?? 78;
  const [busy, setBusy] = useState(false);
  const [snoozed, setSnoozed] = useState<Set<string>>(new Set());
  const [measure, setMeasure] = useState<{
    kind: MeasureKind;
    front: string;
    rear: string;
  } | null>(null);
  const [stand, setStand] = useState<"km" | "hours" | null>(null);

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
  const primaryUi = primary ? localizeDieBoxItem(primary, lang) : null;
  const rest = visible.slice(1);
  const knownChips = plan.chips.filter((c) => c.known);
  const lastRideLine = lastRideHeroUiForBike(rides, bike.id, lang);
  const telCopy = rideTelemetryCopy(lang);
  const lastRide = lastRideForBike(
    rides.filter((r) => Boolean(r.endTime)),
    bike.id
  );
  const lastTel = lastRide ? buildRideTelemetry(lastRide.track) : null;
  const pressureUnit = pressureUnitLabel(bike.category);
  const pressureLabel = formatLoggedTirePressure(
    bike.setups,
    pressureUsesBar(bike.category)
  );
  const dueSummary = useMemo(
    () => getMaintenanceSummary(bike, intervals),
    [bike, intervals]
  );
  const service = planStripService({
    appointmentLabel: bike.nextServiceAt
      ? formatStripDate(bike.nextServiceAt)
      : null,
    intervalStatus:
      dueSummary.topItem?.status === "overdue"
        ? "overdue"
        : dueSummary.topItem?.status === "due_soon"
          ? "due_soon"
          : null,
    intervalRemaining: dueSummary.topItem
      ? maintRemainingLabel(dueSummary.topItem.remainingLabel, lang)
      : null,
    appointmentCaption: copy.workshopStatService,
    careCaption: copy.workshopStatCare,
    dueNow: copy.workshopStatDueNow,
    dash: copy.workshopStatDash,
  });
  const coach = useMemo(
    () => planWerkstattCoach({ bike, riderWeightKg }),
    [bike, riderWeightKg]
  );
  const measureSpec = measure
    ? dieBoxMeasureSpec(
        measure.kind,
        lang,
        measure.kind === "pressure" ? pressureUnit : undefined,
        measure.kind === "sag" && coach.forkOnly
      )
    : null;

  return (
    <div className="space-y-5" data-testid="die-box-surface">
      <section className="overflow-hidden rounded-2xl border border-border bg-surface">
        <BikePhotoControl bikeId={bike.id} photoUrl={bike.photoUrl} bike={bike} />
        <BikeValueStrip
          km={bike.totalOdometerKm}
          hours={bike.totalHours}
          pressure={pressureLabel}
          serviceLabel={service.value}
          serviceCaption={service.caption}
          onKm={() => setStand("km")}
          onHours={() => setStand("hours")}
          onPressure={() =>
            setMeasure({ kind: "pressure", front: "", rear: "" })
          }
          onService={onOpenMaintenance}
        />
        <div className="p-4">
        <div className="flex items-center gap-2 text-xs font-semibold">
          <RadGlyph name={radMarkForReadiness(plan.readiness)} size={16} />
          <span className="text-chrome">{dieBoxReadinessUi(plan.readiness, lang)}</span>
          <span className="text-text-secondary">
            {rideSportLabel(bike.category, lang)}
          </span>
        </div>
        <p className="mt-2 text-lg font-semibold leading-snug">
          {dieBoxSentenceUi(plan, bike, lang)}
        </p>
        {lastRideLine ? (
          <p className="mt-1.5 flex items-center gap-1.5 text-xs text-text-secondary">
            <RadGlyph name="stand" size={12} />
            {lastRideLine}
          </p>
        ) : null}
        {lastRide && lastTel?.channels.elev ? (
          <Link
            href={`/activities/${lastRide.id}`}
            className="mt-3 block"
          >
            <RideTerrainPeek
              telemetry={lastTel}
              caption={terrainCaption(lastTel, telCopy.hm)}
            />
          </Link>
        ) : null}
        {knownChips.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-1.5">
            {knownChips.map((c) => (
              <span
                key={c.label}
                className="inline-flex items-center gap-1 rounded-full border border-chrome/40 px-2.5 py-1 text-[11px] font-semibold text-chrome"
              >
                <RadGlyph name={radMarkForChip(c.label)} size={12} />
                {dieBoxChipLabel(c.label, lang)}
              </span>
            ))}
          </div>
        )}
        {primary && primaryUi ? (
          <button
            type="button"
            disabled={busy}
            onClick={() => void run(primary)}
            className="mt-4 w-full rounded-xl bg-chrome py-3 text-sm font-bold text-on-accent"
          >
            {primaryUi.cta}
          </button>
        ) : plan.isReady ? (
          <p className="mt-4 text-center text-sm font-semibold text-chrome">
            {plan.kind === "urban" ? box.nothingDueMonday : box.nothingDue}
          </p>
        ) : null}
        </div>
      </section>

      {!compact && rest.length > 0 && (
      <section>
        <RadSectionLabel mark="care">{copy.workshopZoneToday}</RadSectionLabel>
          <div className="space-y-2">
            {rest.map((item) => {
              const ui = localizeDieBoxItem(item, lang);
              return (
              <div
                key={`${item.id}-${item.title}`}
                className="flex w-full items-start justify-between gap-3 rounded-2xl border border-border bg-surface p-3 text-left"
              >
                <RadGlyph
                  name={radMarkForItem(item.id)}
                  size={20}
                  className="mt-0.5 shrink-0"
                />
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void run(item)}
                  className="min-w-0 flex-1 text-left"
                >
                  <span className="block text-sm font-semibold">{ui.title}</span>
                  <span className="mt-0.5 block text-xs text-text-secondary">{ui.hint}</span>
                </button>
                <div className="flex shrink-0 flex-col items-end gap-1">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void run(item)}
                    className="text-xs font-bold text-chrome"
                  >
                    {ui.cta}
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
              );
            })}
          </div>
      </section>
      )}

      {!compact ? (
      <section>
        <RadSectionLabel mark="parts">{copy.workshopZoneOnBike}</RadSectionLabel>
        {plan.onBike.length === 0 ? (
          <p className="text-sm text-text-secondary">
            {box.emptyHint}
          </p>
        ) : (
          <ul className="space-y-1.5">
            {plan.onBike.map((c) => (
              <li
                key={c.id}
                className="flex items-center gap-2 rounded-xl border border-border bg-surface px-3 py-2 text-sm font-medium"
              >
                <RadGlyph name={radMarkForSlot(c.slot)} size={16} />
                {slotLabel(c.slot, lang)} · {partName(c, box.partLogged)}
              </li>
            ))}
          </ul>
        )}
        {plan.addableSlots.length > 0 && (
          <button
            type="button"
            onClick={() => {
              const next = plan.addableSlots.find(
                (s) =>
                  !plan.onBike.some((c) => c.slot === s) && !isQuietFitSlot(s)
              );
              onInstallSlot(next ?? plan.addableSlots[0]);
            }}
            className="mt-2 inline-flex items-center gap-1.5 text-sm font-semibold text-chrome"
          >
            <RadGlyph name="add" size={14} />
            {box.addMore}
          </button>
        )}
        <div className="mt-3">
          <GaragePartsCta bikeId={bike.id} bikeName={bike.name} />
        </div>
      </section>
      ) : null}

      <p className="text-xs text-text-secondary">
        {copy.workshopNoWatch}
      </p>
      {plan.hasElectricAssist && (
        <p className="text-xs text-text-secondary">
          {box.batteryHint}
        </p>
      )}

      {stand ? (
        <BikeStandEditor
          km={bike.totalOdometerKm}
          hours={bike.totalHours}
          focusHours={stand === "hours"}
          onClose={() => setStand(null)}
          onSave={({ km, hours }) => {
            updateBike(bike.id, {
              totalOdometerKm: km,
              totalHours: hours,
            });
            addMaintenanceLog({
              bikeId: bike.id,
              date: new Date().toISOString().slice(0, 10),
              activity: "Kilometerstand aktualisiert",
              performer: "self",
              notes: `Manuell: ${km.toFixed(0)} km · ${hours.toFixed(1)} h`,
              odometerKm: km,
              hours,
            });
            setStand(null);
          }}
        />
      ) : null}

      {measure && measureSpec && (
        <div
          className="fixed inset-0 z-[80] flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4"
          role="dialog"
          aria-modal
          aria-labelledby="die-box-measure-title"
          onClick={() => setMeasure(null)}
        >
          <div
            className="w-full max-w-md rounded-t-2xl border border-border bg-surface p-5 sm:rounded-2xl max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <h3
              id="die-box-measure-title"
              className="flex items-center gap-2 text-lg font-bold"
            >
              <RadGlyph name={radMarkForMeasure(measure.kind)} size={22} />
              {measureSpec.title}
            </h3>
            <p className="mt-1 text-sm text-text-secondary">
              {measureSpec.hint}
            </p>
            {measure.kind === "sag" && coach.sag ? (
              <div className="mt-3 space-y-1 text-sm">
                <p className="font-medium">
                  {box.coachForkLine(
                    String(coach.sag.fork.targetPct),
                    coach.sag.fork.sagMm != null
                      ? String(coach.sag.fork.sagMm)
                      : "",
                    String(coach.sag.fork.psiTarget)
                  )}
                </p>
                {coach.sag.shock ? (
                  <p className="font-medium">
                    {box.coachShockLine(
                      String(coach.sag.shock.targetPct),
                      coach.sag.shock.sagMm != null
                        ? String(coach.sag.shock.sagMm)
                        : "",
                      String(coach.sag.shock.psiTarget)
                    )}
                  </p>
                ) : null}
                <ol className="mt-2 list-decimal space-y-0.5 pl-4 text-xs text-text-secondary">
                  <li>{box.sagStep1}</li>
                  <li>{box.sagStep2}</li>
                  <li>{box.sagStep3}</li>
                </ol>
              </div>
            ) : null}
            {measure.kind === "pressure" && coach.tires ? (
              <p className="mt-3 text-sm font-medium">
                {box.coachPressureLine(
                  coach.tires.unit === "bar"
                    ? coach.tires.front.toFixed(1)
                    : String(coach.tires.front),
                  coach.tires.unit === "bar"
                    ? coach.tires.rear.toFixed(1)
                    : String(coach.tires.rear),
                  coach.tires.unit
                )}
              </p>
            ) : null}
            <div
              className={`mt-4 grid gap-3 ${
                measure.kind === "sag" && coach.forkOnly
                  ? "grid-cols-1"
                  : "grid-cols-2"
              }`}
            >
              <label className="block text-sm">
                {measureSpec.front}
                <input
                  type="number"
                  inputMode="decimal"
                  value={measure.front}
                  placeholder={
                    measure.kind === "sag"
                      ? String(coach.sag?.fork.targetPct ?? "")
                      : measure.kind === "pressure" && coach.tires
                        ? String(
                            coach.tires.unit === "bar"
                              ? coach.tires.front.toFixed(1)
                              : coach.tires.front
                          )
                        : undefined
                  }
                  onChange={(e) =>
                    setMeasure({ ...measure, front: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
                />
              </label>
              {!(measure.kind === "sag" && coach.forkOnly) ? (
              <label className="block text-sm">
                {measureSpec.rear}
                <input
                  type="number"
                  inputMode="decimal"
                  value={measure.rear}
                  placeholder={
                    measure.kind === "sag" && coach.sag?.shock
                      ? String(coach.sag.shock.targetPct)
                      : measure.kind === "pressure" && coach.tires
                        ? String(
                            coach.tires.unit === "bar"
                              ? coach.tires.rear.toFixed(1)
                              : coach.tires.rear
                          )
                        : undefined
                  }
                  onChange={(e) =>
                    setMeasure({ ...measure, rear: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-3"
                />
              </label>
              ) : null}
            </div>
            <div className="mt-4 flex flex-col gap-2">
              <button
                type="button"
                onClick={applyMeasure}
                className="w-full rounded-xl bg-chrome py-3 text-sm font-semibold text-on-accent"
              >
                {measureSpec.save}
              </button>
              <button
                type="button"
                onClick={() => setMeasure(null)}
                className="py-2 text-sm text-text-secondary"
              >
                {box.cancel}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
