"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { ClipboardCheck, Download, ShieldAlert } from "lucide-react";
import { downloadText } from "@/lib/export/gpx";
import {
  GATE_WORKBENCH,
  assertMasterFlagsStillFalse,
  gateReadiness,
  getClosureItem,
  renderHumanGateWorkbenchMarkdown,
  resolvePackContent,
  setClosureItem,
  workbenchSummaryDe,
} from "@/lib/legal/humanGateWorkbench";
import type { HumanSignGateId } from "@/lib/legal/gateSignoffPrep";

export default function HumanGatesWorkbenchPage() {
  const [tick, setTick] = useState(0);
  const summary = useMemo(() => workbenchSummaryDe(), [tick]);
  const flagsStillFalse = assertMasterFlagsStillFalse();

  return (
    <div className="flex flex-col gap-5 p-4 pt-6 pb-24">
      <header>
        <h1 className="text-2xl font-bold">Human Gates</h1>
        <p className="text-sm text-text-secondary">
          Closure-Arbeitsraum · Checklisten lokal · Flags nur im Code
        </p>
      </header>

      <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
        <h2 className="mb-1 flex items-center gap-2 font-semibold">
          <ShieldAlert className="h-4 w-4" /> Human must sign
        </h2>
        <p className="mb-2 text-xs text-text-secondary">{summary}</p>
        <p className="mb-3 text-[11px] text-warning">
          Checkboxen schreiben nur localStorage. Master-Flags (
          {flagsStillFalse ? "alle false ✓" : "ACHTUNG: Flag true!"}) werden hier
          niemals gesetzt.
        </p>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadText(
                "aetherride-human-gate-workbench.md",
                renderHumanGateWorkbenchMarkdown(),
                "text/markdown;charset=utf-8"
              )
            }
            className="inline-flex items-center gap-1.5 rounded-lg bg-accent px-3 py-1.5 text-xs font-medium text-white"
          >
            <Download className="h-3.5 w-3.5" /> Workbench (.md)
          </button>
          <Link
            href="/privacy"
            className="rounded-lg border border-border px-3 py-1.5 text-xs"
          >
            Privacy · Pack-Exports
          </Link>
        </div>
      </section>

      {GATE_WORKBENCH.map((gate) => {
        const readiness = gateReadiness(gate.gateId);
        return (
          <GateCard
            key={gate.gateId}
            gateId={gate.gateId}
            flagName={gate.flagName}
            flagValue={gate.flagValue}
            modulePath={gate.modulePath}
            ownerRoleDe={gate.ownerRoleDe}
            items={gate.items}
            packDownloads={gate.packDownloads}
            readiness={readiness}
            onToggle={() => setTick((n) => n + 1)}
          />
        );
      })}

      <p className="text-center text-xs text-text-secondary">
        <Link href="/profile" className="text-accent">
          Profil
        </Link>
        {" · "}
        <Link href="/privacy" className="text-accent">
          Daten & Privatsphäre
        </Link>
      </p>
    </div>
  );
}

function GateCard({
  gateId,
  flagName,
  flagValue,
  modulePath,
  ownerRoleDe,
  items,
  packDownloads,
  readiness,
  onToggle,
}: {
  gateId: HumanSignGateId;
  flagName: string;
  flagValue: boolean;
  modulePath: string;
  ownerRoleDe: string;
  items: { id: string; labelDe: string }[];
  packDownloads: { filename: string; kind: string }[];
  readiness: { done: number; total: number; pct: number; allDone: boolean };
  onToggle: () => void;
}) {
  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <div className="mb-2 flex flex-wrap items-baseline justify-between gap-2">
        <h3 className="flex items-center gap-2 font-semibold">
          <ClipboardCheck className="h-4 w-4 text-accent" />
          {gateId}
        </h3>
        <span className="text-[11px] text-text-secondary">
          lokal {readiness.done}/{readiness.total} ({readiness.pct}%)
        </span>
      </div>
      <p className="mb-1 text-xs text-text-secondary">{ownerRoleDe}</p>
      <p className="mb-3 font-mono text-[11px] text-text-secondary">
        {flagName} = {String(flagValue)}
        <br />
        {modulePath}
      </p>

      <ul className="mb-3 space-y-2">
        {items.map((item) => {
          const checked = getClosureItem(gateId, item.id);
          return (
            <li key={item.id}>
              <label className="flex cursor-pointer items-start gap-2 text-sm">
                <input
                  type="checkbox"
                  className="mt-1"
                  checked={checked}
                  onChange={(e) => {
                    setClosureItem(gateId, item.id, e.target.checked);
                    onToggle();
                  }}
                />
                <span>
                  {item.labelDe}
                  {item.id === "ready_for_code_flag" && (
                    <span className="mt-0.5 block text-[11px] text-warning">
                      Nur nach echter Freigabe — Flag danach manuell im Code.
                    </span>
                  )}
                </span>
              </label>
            </li>
          );
        })}
      </ul>

      <div className="flex flex-wrap gap-2">
        {packDownloads.map((pack) => (
          <button
            key={pack.kind}
            type="button"
            onClick={() => {
              const body = resolvePackContent(pack.kind);
              if (!body) return;
              downloadText(
                pack.filename,
                body,
                pack.filename.endsWith(".txt")
                  ? "text/plain;charset=utf-8"
                  : "text/markdown;charset=utf-8"
              );
            }}
            className="inline-flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-[11px]"
          >
            <Download className="h-3 w-3" /> {pack.filename}
          </button>
        ))}
      </div>
    </section>
  );
}
