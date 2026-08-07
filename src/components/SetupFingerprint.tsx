"use client";

import type { Setup } from "@/types";

/** Kompakter Setup-Fingerprint (Sag / Rebound / Druck) für Home. */
export function SetupFingerprint({ setup }: { setup: Setup }) {
  const sag = setup.values.find((v) => /sag/i.test(v.adjusterKey));
  const rebound = setup.values.find(
    (v) => v.slot === "fork" && /rebound/i.test(v.adjusterKey)
  );
  const psi = setup.values.find(
    (v) => v.slot === "tire_front" && /pressure|psi/i.test(v.adjusterKey)
  );

  const chips = [
    sag ? { label: "Sag", value: `${sag.valueNum}${sag.unit || "%"}` } : null,
    rebound
      ? { label: "Zug", value: `${rebound.valueNum}` }
      : null,
    psi ? { label: "psi V", value: `${psi.valueNum}` } : null,
  ].filter(Boolean) as { label: string; value: string }[];

  if (chips.length === 0) {
    return (
      <p className="text-xs text-text-secondary">
        Setup „{setup.label}“ · {setup.conditions}
      </p>
    );
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {chips.map((c) => (
        <div
          key={c.label}
          className="rounded-lg bg-surface-elevated px-2 py-1 text-center"
        >
          <div className="tabular-nums text-sm font-semibold">{c.value}</div>
          <div className="text-[10px] text-text-secondary">{c.label}</div>
        </div>
      ))}
      <span className="text-xs text-text-secondary">
        {setup.conditions}
      </span>
    </div>
  );
}
