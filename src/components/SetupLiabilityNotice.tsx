"use client";

import {
  SETUP_LIABILITY,
  a08StatusBadge,
  isA08Closed,
} from "@/lib/legal/setupLiability";

export function SetupLiabilityNotice({
  variant = "short",
}: {
  variant?: "short" | "long" | "template";
}) {
  const closed = isA08Closed();
  const text =
    variant === "long"
      ? SETUP_LIABILITY.longDe
      : variant === "template"
        ? SETUP_LIABILITY.templateNoteDe
        : SETUP_LIABILITY.shortDe;

  return (
    <aside
      className={`rounded-lg px-2 py-1.5 text-[11px] ${
        closed
          ? "border border-border bg-surface-elevated text-text-secondary"
          : "border border-warning/30 bg-warning/10 text-text-secondary"
      }`}
      role="note"
      aria-label="Setup-Haftungshinweis"
    >
      <p className="mb-0.5 font-medium text-foreground">{a08StatusBadge()}</p>
      <p>{text}</p>
      {variant !== "template" && (
        <p className="mt-1">{SETUP_LIABILITY.workshopSafetyDe}</p>
      )}
    </aside>
  );
}
