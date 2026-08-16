"use client";

import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import type { Bike, BracketingParameter } from "@/types";
import { allowDemoContent } from "@/lib/config/allowDemoContent";

const PARAMS: { id: BracketingParameter; label: string }[] = [
  { id: "fork.rebound", label: "Gabel Zugstufe" },
  { id: "fork.lsc", label: "Gabel LSC" },
  { id: "fork.sag_pct", label: "Gabel SAG %" },
  { id: "fork.air_pressure_psi", label: "Gabel Luftdruck" },
  { id: "shock.rebound", label: "Dämpfer Zugstufe" },
  { id: "shock.sag_pct", label: "Dämpfer SAG %" },
  { id: "tire.front_psi", label: "Reifen vorn psi" },
  { id: "tire.rear_psi", label: "Reifen hinten psi" },
];

export function BracketingPanel({ bike }: { bike: Bike }) {
  const bracketingSeries = useAppStore((s) => s.bracketingSeries);
  const seriesList = bracketingSeries.filter((x) => x.bikeId === bike.id);
  const startBracketing = useAppStore((s) => s.startBracketing);
  const addBracketingRun = useAppStore((s) => s.addBracketingRun);
  const evaluateBracketing = useAppStore((s) => s.evaluateBracketing);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const pro = canUseProFeature("bracketing");

  const [parameter, setParameter] = useState<BracketingParameter>("fork.rebound");
  const [from, setFrom] = useState(6);
  const [to, setTo] = useState(10);
  const [step, setStep] = useState(2);
  const [segment, setSegment] = useState("Heimtrail Abfahrt");

  const active = seriesList[0];
  const paramLabel =
    PARAMS.find((p) => p.id === active?.parameter)?.label ?? active?.parameter;

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
      <h3 className="mb-1 font-semibold">Zwei Varianten testen</h3>
      <p className="mb-3 text-xs text-text-secondary">
        Nur eine Einstellung pro Vergleich. Nach ein paar vergleichbaren Fahrten
        siehst du, welche Variante sich besser anfühlt.
      </p>
      {!pro && (
        <div className="mb-3 rounded-xl border border-warning/40 bg-warning/10 px-3 py-2 text-xs text-warning">
          Vergleichen ist Pro. Unter Profil freischalten.
        </div>
      )}

      <div className="grid grid-cols-2 gap-2 text-sm">
        <label className="col-span-2">
          Was vergleichen?
          <select
            value={parameter}
            disabled={!pro}
            onChange={(e) =>
              setParameter(e.target.value as BracketingParameter)
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 disabled:opacity-50"
          >
            {PARAMS.map((p) => (
              <option key={p.id} value={p.id}>
                {p.label}
              </option>
            ))}
          </select>
        </label>
        <label>
          Von
          <input
            type="number"
            value={from}
            onChange={(e) => setFrom(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Bis
          <input
            type="number"
            value={to}
            onChange={(e) => setTo(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Schrittweite
          <input
            type="number"
            value={step}
            onChange={(e) => setStep(Number(e.target.value))}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label>
          Vergleichsstrecke
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
        Vergleich starten
      </button>

      {active && (
        <div className="mt-4 rounded-xl bg-surface-elevated p-3 text-sm">
          <div className="font-medium">
            {paramLabel} · {active.rangeFrom}→{active.rangeTo}
          </div>
          <div className="text-xs text-text-secondary">
            {active.referenceSegmentLabel} · {active.runs.length} Durchgänge ·{" "}
            {active.status === "open"
              ? "läuft"
              : active.status === "evaluated"
                ? "fertig"
                : "bereit"}
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
                Variante {v}
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
                  Demo: +2 Fahrten @ {v}
                </button>
              ))}
            </div>
          )}
          <button
            type="button"
            onClick={() => evaluateBracketing(active.id)}
            className="mt-3 w-full rounded-xl bg-accent py-2 text-sm font-semibold text-on-accent"
          >
            Auswerten
          </button>
          {active.resultSummary && (
            <p className="mt-2 text-xs text-text-secondary">
              {active.resultSummary}
              {active.provenBestValue !== undefined &&
                ` · Beste: ${active.provenBestValue} ${active.unit}`}
              {active.noProvenDifference && " · kein klarer Unterschied"}
            </p>
          )}
        </div>
      )}
    </section>
  );
}
