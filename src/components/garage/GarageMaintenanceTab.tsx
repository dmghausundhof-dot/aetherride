"use client";

import { useState } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { evaluateIntervalDue } from "@/lib/maintenance/intervals";
import { forecastWear } from "@/lib/maintenance/wearPrediction";
import {
  maintIntervalLabel,
  maintRemainingLabel,
  presentWear,
  presentMaintActivity,
} from "@/lib/i18n/maintDomainCopy";
import { slotLabel } from "@/lib/catalog/slots";
import { useAppStore } from "@/store/useAppStore";
import type {
  Bike,
  Ride,
  MaintenanceInterval,
  MaintenanceLogEntry,
} from "@/types";

interface Props {
  selected: Bike;
  rides: Ride[];
  intervals: MaintenanceInterval[];
  logs: MaintenanceLogEntry[];
  costSum: number;
  markIntervalDone: (id: string) => void;
  exportReport: () => void;
}

export function GarageMaintenanceTab({
  selected,
  rides,
  intervals,
  logs,
  costSum,
  markIntervalDone,
  exportReport,
}: Props) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const updateBike = useAppStore((s) => s.updateBike);
  const wear = forecastWear(selected, rides);
  return (
    <div className="flex flex-col gap-4">
      <section>
        <h3 className="mb-2 font-semibold">{copy.workshopNextService}</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {copy.workshopNextServiceHint}
        </p>
        <input
          type="date"
          data-testid="bike-next-service"
          value={selected.nextServiceAt ?? ""}
          onChange={(e) =>
            updateBike(selected.id, {
              nextServiceAt: e.target.value || undefined,
            })
          }
          className="min-h-11 w-full rounded-xl border border-border bg-surface-elevated px-3 text-sm"
        />
      </section>
      <section>
        <h3 className="mb-2 font-semibold">{copy.workshopWearTitle}</h3>
        <p className="mb-2 text-xs text-text-secondary">
          {copy.workshopWearHint}
        </p>
        <div className="flex flex-col gap-2">
          {wear.map((f) => {
            const ui = presentWear(f, lang);
            return (
            <div
              key={f.kind}
              className={`rounded-xl border p-3 text-sm ${
                f.dueSoon
                  ? "border-warning/50 bg-warning/10"
                  : "border-border bg-surface"
              }`}
            >
              <div className="font-medium">{ui.label}</div>
              <p className="mt-1 text-xs text-text-secondary">{ui.reasoning}</p>
              <p className="mt-1 text-[10px] text-text-secondary">
                {f.sourceLabel}
              </p>
            </div>
            );
          })}
          {wear.length === 0 && (
            <p className="text-sm text-text-secondary">
              {copy.workshopWearEmpty}
            </p>
          )}
        </div>
      </section>

      <section>
        <h3 className="mb-2 font-semibold">{copy.workshopDueTitle}</h3>
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
                      {maintIntervalLabel(interval.label, lang)}
                    </div>
                    <div className="text-xs text-text-secondary">
                      {slotLabel(interval.slot, lang)} · {interval.sourceLabel}
                      {interval.overriddenByUser
                        ? ` · ${copy.workshopDueAdjusted}`
                        : ""}
                    </div>
                    <div className="mt-1 text-xs">
                      {maintRemainingLabel(due.remainingLabel, lang)} · {due.progressPct}%
                      {due.status === "overdue" && (
                        <span className="text-error">
                          {" "}
                          · {copy.workshopDueOverdue}
                        </span>
                      )}
                      {due.status === "due_soon" && (
                        <span className="text-warning">
                          {" "}
                          · {copy.workshopDueSoon}
                        </span>
                      )}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => markIntervalDone(interval.id)}
                    className="min-h-11 rounded-xl bg-chrome px-3 py-1 text-xs font-semibold text-on-accent"
                  >
                    {copy.workshopDueDone}
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
              {copy.workshopDueEmpty}
            </p>
          )}
        </div>
      </section>

      <section>
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <RadGlyph name="care" size={16} />
          {copy.workshopReceiptTitle}
        </h3>
        <ReceiptNoteForm
          bikeId={selected.id}
          odometerKm={selected.totalOdometerKm}
          hours={selected.totalHours}
        />
      </section>

      <section>
        <h3 className="mb-2 flex items-center justify-between gap-2 font-semibold">
          <span className="inline-flex items-center gap-2">
            <RadGlyph name="care" size={16} />
            {copy.workshopMaintLog}
          </span>
          <button
            type="button"
            onClick={exportReport}
            className="inline-flex min-h-11 items-center gap-1 text-xs font-medium text-chrome"
          >
            <RadGlyph name="identity" size={14} /> {copy.workshopReport}
          </button>
        </h3>
        {costSum > 0 && (
          <p className="mb-2 text-xs text-text-secondary">
            {copy.workshopMaintCost(costSum.toFixed(2))}
          </p>
        )}
        <div className="flex flex-col gap-2">
          {logs.map((log) => (
            <div
              key={log.id}
              className="rounded-xl border border-border bg-surface p-3 text-sm"
            >
              <div className="font-medium">
                {presentMaintActivity(log.activity, lang)}
              </div>
              <div className="text-xs text-text-secondary">
                {log.date} ·{" "}
                {log.performer === "workshop"
                  ? copy.workshopPerformerWorkshop
                  : copy.workshopPerformerSelf}
                {log.odometerKm !== undefined
                  ? ` · ${log.odometerKm.toFixed(0)} km`
                  : ""}
                {log.costEur !== undefined ? ` · ${log.costEur} €` : ""}
              </div>
              {log.notes && (
                <p className="mt-1 text-xs text-text-secondary">{log.notes}</p>
              )}
              {log.photoDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={log.photoDataUrl}
                  alt=""
                  className="mt-2 h-20 w-auto rounded-lg object-cover"
                />
              ) : null}
            </div>
          ))}
          {logs.length === 0 && (
            <p className="text-sm text-text-secondary">
              {copy.workshopMaintEmpty}
            </p>
          )}
        </div>
      </section>

      <p className="text-xs text-text-secondary">{copy.workshopMaintDefaults}</p>
    </div>
  );
}

function ReceiptNoteForm({
  bikeId,
  odometerKm,
  hours,
}: {
  bikeId: string;
  odometerKm: number;
  hours: number;
}) {
  const copy = useHofCopy();
  const addMaintenanceLog = useAppStore((s) => s.addMaintenanceLog);
  const [activity, setActivity] = useState("");
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [photo, setPhoto] = useState<string | undefined>();
  const [saved, setSaved] = useState(false);

  const onFile = (file: File | null) => {
    if (!file || !file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = () => {
      const raw = String(reader.result);
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        const max = 900;
        const scale = Math.min(1, max / Math.max(img.width, img.height));
        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);
        const ctx = canvas.getContext("2d");
        if (!ctx) return;
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        setPhoto(canvas.toDataURL("image/jpeg", 0.72));
      };
      img.src = raw;
    };
    reader.readAsDataURL(file);
  };

  const save = () => {
    const title = activity.trim();
    if (!title && !photo) return;
    const cost = Number(amount.replace(",", "."));
    addMaintenanceLog({
      bikeId,
      date: new Date().toISOString().slice(0, 10),
      activity: title || copy.workshopReceiptPhoto,
      performer: "workshop",
      notes: note.trim() || undefined,
      costEur: Number.isFinite(cost) && cost > 0 ? cost : undefined,
      odometerKm,
      hours,
      photoDataUrl: photo,
    });
    setActivity("");
    setAmount("");
    setNote("");
    setPhoto(undefined);
    setSaved(true);
    window.setTimeout(() => setSaved(false), 1600);
  };

  return (
    <div className="space-y-2 rounded-xl border border-border bg-surface p-3">
      <input
        value={activity}
        onChange={(e) => setActivity(e.target.value)}
        placeholder={copy.workshopReceiptPlaceholder}
        className="min-h-11 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
      />
      <div className="grid grid-cols-2 gap-2">
        <input
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder={copy.workshopReceiptAmount}
          inputMode="decimal"
          className="min-h-11 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
        />
        <input
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder={copy.workshopReceiptNote}
          className="min-h-11 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
        />
      </div>
      <label className="flex min-h-11 cursor-pointer items-center justify-center rounded-xl border border-dashed border-border px-3 py-2 text-sm font-medium text-chrome">
        {copy.workshopReceiptPhoto}
        <input
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(e) => onFile(e.target.files?.[0] ?? null)}
        />
      </label>
      {photo ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={photo}
          alt=""
          className="h-24 w-auto rounded-lg object-cover"
        />
      ) : null}
      <button
        type="button"
        onClick={save}
        className="min-h-11 w-full rounded-xl bg-chrome py-2 text-sm font-semibold text-on-accent"
      >
        {saved ? copy.workshopReceiptSaved : copy.workshopReceiptSave}
      </button>
    </div>
  );
}
