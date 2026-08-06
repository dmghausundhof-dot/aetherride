"use client";

import {
  G0_DECISION,
  G0_NON_GOALS,
  G0_SPRINT0_PLAN,
  NATIVE_MODULE_MATRIX,
  g0StatusBadge,
  g0StatusShort,
  evaluateG0GoNoGo,
  isG0Closed,
} from "@/lib/platform/g0TeamSetup";

export function G0StatusPanel({ compact = false }: { compact?: boolean }) {
  const closed = isG0Closed();
  const go = evaluateG0GoNoGo();

  if (compact) {
    return (
      <p
        className={`rounded-lg px-2 py-1.5 text-[11px] ${
          closed
            ? "border border-success/30 bg-success/10"
            : "border border-warning/30 bg-warning/10"
        }`}
      >
        {g0StatusBadge()}: {g0StatusShort()}
      </p>
    );
  }

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="font-semibold">Gate G-0 · Team-Setup</h3>
      <p className="mt-1 text-[11px] text-text-secondary">
        Spec §5.1 / §9.2 · vor Sprint 1 · {g0StatusBadge()}
      </p>
      <p
        className={`mt-2 rounded-lg px-2 py-1.5 text-xs ${
          closed
            ? "border border-success/30 bg-success/10"
            : "border border-warning/30 bg-warning/10"
        }`}
      >
        {g0StatusShort()}
      </p>
      <p className="mt-2 text-xs text-text-secondary">
        Go/No-Go (aktuell): <span className="font-medium">{go.result}</span>
      </p>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {go.reasons.map((r) => (
          <li key={r}>{r}</li>
        ))}
      </ul>

      <h4 className="mt-3 text-xs font-semibold">Checkliste</h4>
      <ul className="mt-1 space-y-1 text-[11px] text-text-secondary">
        {G0_DECISION.checklist.map((c) => (
          <li key={c.id}>
            {c.done ? "✓" : "○"} {c.label}
          </li>
        ))}
      </ul>

      <h4 className="mt-3 text-xs font-semibold">Native-Module-Matrix</h4>
      <div className="mt-1 overflow-x-auto">
        <table className="w-full text-left text-[10px] text-text-secondary">
          <thead>
            <tr className="border-b border-border">
              <th className="py-1 pr-2">Modul</th>
              <th className="py-1 pr-2">Web</th>
              <th className="py-1">Owner</th>
            </tr>
          </thead>
          <tbody>
            {NATIVE_MODULE_MATRIX.map((row) => (
              <tr key={row.id} className="border-b border-border/50">
                <td className="py-1 pr-2 font-medium text-foreground">
                  {row.specModule}
                </td>
                <td className="py-1 pr-2">{row.webDemo}</td>
                <td className="py-1">{row.ownerRole}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h4 className="mt-3 text-xs font-semibold">Sprint-0 (ohne Fake-Flutter)</h4>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {G0_SPRINT0_PLAN.map((p) => (
          <li key={p}>{p}</li>
        ))}
      </ul>
      <h4 className="mt-3 text-xs font-semibold">Non-Goals</h4>
      <ul className="mt-1 list-inside list-disc text-[11px] text-text-secondary">
        {G0_NON_GOALS.map((p) => (
          <li key={p}>{p}</li>
        ))}
      </ul>
    </section>
  );
}
