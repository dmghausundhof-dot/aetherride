"use client";

import { Loader2 } from "lucide-react";

export function AroundYouLoopCta({
  busy,
  applied,
  compact = false,
  message,
  cta,
  another,
  busyLabel,
  hint,
  stats,
  uncertain,
  reasons,
  onGenerate,
}: {
  busy: boolean;
  applied: boolean;
  compact?: boolean;
  km?: number | null;
  minutes?: number | null;
  message?: string | null;
  cta: string;
  another: string;
  busyLabel: string;
  hint: string;
  stats?: string;
  uncertain?: string;
  reasons?: string[];
  onGenerate: (next: boolean) => void;
}) {
  const label = busy ? busyLabel : applied ? another : cta;
  return (
    <div
      className={
        compact ? "mt-2 flex flex-col gap-1" : "mt-2 flex flex-col gap-1.5"
      }
    >
      <button
        type="button"
        disabled={busy}
        onClick={() => onGenerate(applied)}
        className={
          compact
            ? "inline-flex items-center justify-center gap-1.5 rounded-lg border border-chrome/40 px-3 py-1.5 text-xs font-medium text-chrome disabled:opacity-40"
            : "inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-chrome py-2.5 text-xs font-semibold text-on-accent disabled:opacity-40"
        }
      >
        {busy ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : null}
        {label}
      </button>
      {!compact && applied && stats ? (
        <p className="text-[11px] tabular-nums text-foreground">
          {stats}
          {uncertain ? ` · ${uncertain}` : ""}
        </p>
      ) : null}
      {!compact ? (
        <p className="text-[11px] text-text-secondary">{message ?? hint}</p>
      ) : message ? (
        <p className="text-[11px] text-text-secondary">{message}</p>
      ) : null}
      {compact && applied && stats ? (
        <p className="text-[11px] tabular-nums text-text-secondary">
          {stats}
          {uncertain ? ` · ${uncertain}` : ""}
        </p>
      ) : null}
      {!compact && applied && reasons && reasons.length === 3 ? (
        <ul className="mt-0.5 space-y-0.5 text-[11px] text-text-secondary">
          {reasons.map((r) => (
            <li key={r}>{r}</li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
