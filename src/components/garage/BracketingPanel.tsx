"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import {
  BRACKETING_PARAMS,
  bracketingUnit,
} from "@/lib/setup/bracketingKeys";
import type { Bike, BracketingParameter } from "@/types";

export function BracketingPanel({ bike }: { bike: Bike }) {
  const seriesList = useAppStore((s) =>
    s.bracketingSeries.filter((x) => x.bikeId === bike.id)
  );
  const startBracketing = useAppStore((s) => s.startBracketing);
  const addBracketingRun = useAppStore((s) => s.addBracketingRun);
  const evaluateBracketing = useAppStore((s) => s.evaluateBracketing);
  const applyBracketingBest = useAppStore((s) => s.applyBracketingBest);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const pro = canUseProFeature("bracketing");

  const [parameter, setParameter] =
    useState<BracketingParameter>("fork.rebound");
  const [from, setFrom] = useState(6);
  const [to, setTo] = useState(10);
  const [step, setStep] = useState(2);
  const [segment, setSegment] = useState("Heimtrail Abfahrt");
  const [appliedMsg, setAppliedMsg] = useState<string | null>(null);

  const active = seriesList[0];
  const unit = bracketingUnit(parameter);

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
    setAppliedMsg(null);
  };

  const addDemoRuns = (seriesId: string, value: number) => {
    // Zwei Durchgänge pro Config – mit realistischer Streuung
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

  const takeBest = () => {
    if (!active) return;
    const id = applyBracketingBest(active.id);
    setAppliedMsg(
      id
        ? "Beste Werte als neue Setup-Version übernommen."
        : "Kein belegbarer Bestwert — nichts übernommen."
    );
  };

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="mb-1 font-semibold">Bracketing</h3>
      <p className="mb-3 text-xs text-text-secondary">
        Nur ein Parameter pro Serie. Keys = slot.adjuster (wie Setup). Effekt
        gilt erst bei |Δ| &gt; 1,5× gepoolter SD und n≥2 (F-SET-003).
      </p>
      {!pro && (
        <div className="mb-3 rounded-xl border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
          Bracketing ist Pro (Spec 1.4). Unter Profil freischalten — Demo-Daten
          starten mit Pro.
        </div>
      )}

      <div className="grid grid-cols-2 gap-2 text-sm">
        <label className="col-span-2">
          Parameter
          <select
            value={parameter}
            disabled={!pro}
            onChange={(e) =>
              setParameter(e.target.value as BracketingParameter)
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 disabled:opacity-50"
          >
            {BRACKETING_PARAMS.map((p) => (
              <option key={p.id} value={p.id}>
                {p.label} ({p.unit})
              </option>
            ))}
          </select>
        </label>
        <label>
          Von ({unit})
          <input
            type="number"
            value={from}
            onChange={(e) => setFrom(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Bis ({unit})
          <input
            type="number"
            value={to}
            onChange={(e) => setTo(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Schritt
          <input
            type="number"
            value={step}
            onChange={(e) => setStep(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Segment
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
        className="mt-3 w-full rounded-xl bg-primary py-2.5 text-sm font-semibold text-white"
      >
        Serie starten
      </button>

      {active && (
        <div className="mt-4 rounded-xl bg-surface-elevated p-3 text-sm">
          <div className="font-medium">
            {active.parameter} · {active.rangeFrom}→{active.rangeTo} /{" "}
            {active.step}
          </div>
          <div className="text-xs text-text-secondary">
            {active.referenceSegmentLabel} · {active.runs.length} Runs ·{" "}
            {active.status}
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
              <button
                key={v}
                type="button"
                onClick={() => addDemoRuns(active.id, v)}
                className="rounded-lg bg-muted px-2 py-1 text-xs"
              >
                +2 Runs @ {v}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={() => evaluateBracketing(active.id)}
            className="mt-3 w-full rounded-xl bg-accent py-2 text-sm font-semibold text-white"
          >
            Auswerten
          </button>
          {active.resultSummary && (
            <p className="mt-2 text-xs text-text-secondary">
              {active.resultSummary}
              {active.provenBestValue !== undefined &&
                ` · Beste: ${active.provenBestValue} ${active.unit}`}
              {active.noProvenDifference && " · kein belegbarer Unterschied"}
            </p>
          )}
          {active.provenBestValue !== undefined &&
            !active.noProvenDifference && (
              <button
                type="button"
                onClick={takeBest}
                className="mt-2 w-full rounded-xl border border-accent py-2 text-sm font-semibold text-accent"
              >
                Beste übernehmen
              </button>
            )}
          {appliedMsg && (
            <p className="mt-2 text-xs text-text-secondary">{appliedMsg}</p>
          )}
        </div>
      )}
    </section>
  );
}
