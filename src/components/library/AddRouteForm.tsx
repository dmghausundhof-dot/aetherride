"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { simpleNamedRoute } from "@/lib/library/simpleAddRoute";
import { useChromeLang } from "@/hooks/useChromeLang";
import { platzCopy } from "@/lib/i18n/platzCopy";

export function AddRouteForm({
  defaultStart,
  onSaved,
  onPickGpx,
  compact = false,
}: {
  /** [lng, lat] Kartenmitte / GPS */
  defaultStart?: [number, number] | null;
  onSaved?: (name: string) => void;
  onPickGpx?: () => void;
  compact?: boolean;
}) {
  const saveRoute = useAppStore((s) => s.saveRoute);
  const p = platzCopy(useChromeLang());
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setBusy(true);
    setMsg(null);
    let start = defaultStart ?? undefined;
    if (!start && typeof navigator !== "undefined" && navigator.geolocation) {
      start = await new Promise<[number, number] | undefined>((resolve) => {
        navigator.geolocation.getCurrentPosition(
          (pos) => resolve([pos.coords.longitude, pos.coords.latitude]),
          () => resolve(undefined),
          { timeout: 4000 }
        );
      });
    }
    const entry = simpleNamedRoute({
      name,
      start,
    });
    saveRoute(entry);
    setName("");
    setOpen(false);
    setBusy(false);
    setMsg(p.savedNamed(entry.name));
    onSaved?.(entry.name);
  };

  if (!open) {
    return (
      <div>
        <button
          type="button"
          onClick={() => setOpen(true)}
          className={
            compact
              ? "inline-flex items-center gap-1.5 rounded-xl bg-accent px-2.5 py-1.5 text-xs font-semibold text-on-accent"
              : "inline-flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-semibold text-on-accent"
          }
        >
          <Plus className="h-3.5 w-3.5" /> {p.addRoute}
        </button>
        {msg && (
          <p className="mt-2 text-xs text-text-secondary" role="status">
            {msg}
          </p>
        )}
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-border bg-surface p-3">
      <p className="text-sm font-semibold">{p.addRoute}</p>
      <p className="mt-1 text-[11px] text-text-secondary">{p.addRouteHint}</p>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder={p.routeName}
        className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        maxLength={80}
      />
      <p className="mt-1 text-[11px] text-text-secondary">
        {defaultStart
          ? p.startPin(defaultStart[1].toFixed(3), defaultStart[0].toFixed(3))
          : p.startGps}
      </p>
      <div className="mt-2 flex flex-wrap gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void save()}
          className="rounded-xl bg-accent px-3 py-1.5 text-xs font-semibold text-on-accent"
        >
          {busy ? "…" : p.intoMappe}
        </button>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="rounded-lg border border-border px-3 py-1.5 text-xs"
        >
          {p.cancel}
        </button>
        {onPickGpx ? (
          <button
            type="button"
            onClick={() => {
              setOpen(false);
              onPickGpx();
            }}
            className="text-xs font-medium text-text-secondary"
          >
            {p.importGpx}
          </button>
        ) : null}
      </div>
    </div>
  );
}
