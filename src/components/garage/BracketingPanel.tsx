"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import type { Bike, BracketingParameter } from "@/types";
import { allowDemoContent } from "@/lib/config/allowDemoContent";
import { bracketingCopy, presentBracketingSummary } from "@/lib/i18n/bracketingCopy";
import { useChromeLang } from "@/hooks/useChromeLang";

const SUSPENSION_PARAMS: BracketingParameter[] = [
  "fork.rebound",
  "fork.lsc",
  "fork.sag_pct",
  "fork.air_pressure_psi",
  "shock.rebound",
  "shock.sag_pct",
];

const TIRE_PARAMS: BracketingParameter[] = [
  "tire.front_psi",
  "tire.rear_psi",
];

function bikeHasSuspension(bike: Bike): boolean {
  const travel =
    (bike.travelFrontMm ?? 0) > 0 || (bike.travelRearMm ?? 0) > 0;
  if (travel) return true;
  return bike.components.some(
    (c) => !c.removedAt && (c.slot === "fork" || c.slot === "rear_shock")
  );
}

export function BracketingPanel({ bike }: { bike: Bike }) {
  const lang = useChromeLang();
  const copy = bracketingCopy(lang);
  const bracketingSeries = useAppStore((s) => s.bracketingSeries);
  const seriesList = bracketingSeries.filter((x) => x.bikeId === bike.id);
  const startBracketing = useAppStore((s) => s.startBracketing);
  const addBracketingRun = useAppStore((s) => s.addBracketingRun);
  const evaluateBracketing = useAppStore((s) => s.evaluateBracketing);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const pro = canUseProFeature("bracketing");
  const params = bikeHasSuspension(bike)
    ? [...SUSPENSION_PARAMS, ...TIRE_PARAMS]
    : TIRE_PARAMS;

  const [parameter, setParameter] = useState<BracketingParameter>(
    params[0] ?? "tire.front_psi"
  );
  const [from, setFrom] = useState(6);
  const [to, setTo] = useState(10);
  const [step, setStep] = useState(2);
  const [segment, setSegment] = useState(copy.defaultSegment);

  const active = seriesList[0];
  const paramLabel = active
    ? copy.param(active.parameter)
    : copy.param(parameter);

  const statusLabel =
    active?.status === "open"
      ? copy.running
      : active?.status === "evaluated"
        ? copy.done
        : copy.ready;

  const create = () => {
    if (!pro) return;
    startBracketing({
      bikeId: bike.id,
      parameter,
      rangeFrom: from,
      rangeTo: to,
      step,
      referenceSegmentLabel: segment,
    });
  };

  const addDemoRuns = (seriesId: string, value: number) => {
    for (let i = 0; i < 2; i++) {
      addBracketingRun(seriesId, {
        configValue: value,
        runIndex: i + 1,
        segmentTimeSec: 95 + Math.random() * 4 + (value - from) * 0.3,
        flowScore: 70 + Math.random() * 6 - Math.abs(value - (from + to) / 2),
        impactHardness: 3 + Math.random(),
        subjectiveRating: 3 + Math.round(Math.random()),
        matchQuality: 0.85 + Math.random() * 0.1,
      });
    }
  };

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="mb-1 font-semibold">{copy.title}</h3>
      <p className="mb-3 text-xs text-text-secondary">{copy.hint}</p>
      {!pro && (
        <div className="mb-3 rounded-xl border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
          {copy.pro}
        </div>
      )}

      <div className="grid grid-cols-2 gap-2 text-sm">
        <label className="col-span-2">
          {copy.what}
          <select
            value={parameter}
            disabled={!pro}
            onChange={(e) =>
              setParameter(e.target.value as BracketingParameter)
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 disabled:opacity-50"
          >
            {params.map((p) => (
              <option key={p} value={p}>
                {copy.param(p)}
              </option>
            ))}
          </select>
        </label>
        <label>
          {copy.from}
          <input
            type="number"
            value={from}
            onChange={(e) => setFrom(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          {copy.to}
          <input
            type="number"
            value={to}
            onChange={(e) => setTo(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          {copy.step}
          <input
            type="number"
            value={step}
            onChange={(e) => setStep(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          {copy.segment}
          <input
            value={segment}
            onChange={(e) => setSegment(e.target.value)}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
      </div>

      <button
        type="button"
        onClick={create}
        disabled={!pro}
        className="mt-3 w-full rounded-xl bg-primary py-2.5 text-sm font-semibold text-on-accent disabled:opacity-50"
      >
        {copy.start}
      </button>

      {active && (
        <div className="mt-4 rounded-xl bg-surface-elevated p-3 text-sm">
          <div className="font-medium">
            {paramLabel} · {active.rangeFrom}→{active.rangeTo}
          </div>
          <div className="text-xs text-text-secondary">
            {active.referenceSegmentLabel} · {copy.runs(active.runs.length)} ·{" "}
            {statusLabel}
          </div>
          <div className="mt-2 flex flex-wrap gap-2">
            {Array.from(
              {
                length:
                  Math.floor((active.rangeTo - active.rangeFrom) / active.step) +
                  1,
              },
              (_, i) => active.rangeFrom + i * active.step
            ).map((v) => (
              <p key={v} className="rounded-lg bg-muted px-2 py-1 text-xs">
                {copy.variant(v)}
              </p>
            ))}
          </div>
          {allowDemoContent() && (
            <div className="mt-2 flex flex-wrap gap-2">
              {Array.from(
                {
                  length:
                    Math.floor(
                      (active.rangeTo - active.rangeFrom) / active.step
                    ) + 1,
                },
                (_, i) => active.rangeFrom + i * active.step
              ).map((v) => (
                <button
                  key={v}
                  type="button"
                  onClick={() => addDemoRuns(active.id, v)}
                  className="rounded-lg border border-dashed border-border px-2 py-1 text-xs text-text-secondary"
                >
                  {copy.demo(v)}
                </button>
              ))}
            </div>
          )}
          <button
            type="button"
            onClick={() => evaluateBracketing(active.id)}
            className="mt-3 w-full rounded-xl bg-accent py-2 text-sm font-semibold text-on-accent"
          >
            {copy.evaluate}
          </button>
          {active.resultSummary && (
            <p className="mt-2 text-xs text-text-secondary">
              {presentBracketingSummary(active.resultSummary, lang)}
              {active.provenBestValue !== undefined &&
                ` · ${copy.best(active.provenBestValue, active.unit)}`}
              {active.noProvenDifference && ` · ${copy.noDiff}`}
            </p>
          )}
        </div>
      )}
    </section>
  );
}
