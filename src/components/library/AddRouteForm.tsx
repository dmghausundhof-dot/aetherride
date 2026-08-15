"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { simpleNamedRoute } from "@/lib/library/simpleAddRoute";

export function AddRouteForm({
  defaultStart,
  onSaved,
  compact = false,
}: {
  /** [lng, lat] Kartenmitte / GPS */
  defaultStart?: [number, number] | null;
  onSaved?: (name: string) => void;
  compact?: boolean;
}) {
  const saveRoute = useAppStore((s) => s.saveRoute);
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
    setMsg(`Gespeichert: ${entry.name}`);
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
              ? "inline-flex items-center gap-1.5 rounded-lg bg-accent px-2.5 py-1.5 text-xs font-semibold text-white"
              : "inline-flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-semibold text-white"
          }
        >
          <Plus className="h-3.5 w-3.5" /> Route hinzufügen
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
      <p className="text-sm font-semibold">Route hinzufügen</p>
      <p className="mt-1 text-[11px] text-text-secondary">
        Name + Start (Kartenmitte/GPS) — ohne erfundenen Track. GPX bleibt
        optional.
      </p>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Name der Route"
        className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        maxLength={80}
      />
      <p className="mt-1 text-[11px] text-text-secondary">
        {defaultStart
          ? `Start: ${defaultStart[1].toFixed(3)}°N, ${defaultStart[0].toFixed(3)}°E`
          : "Start: GPS, falls erlaubt — sonst ohne Pin."}
      </p>
      <div className="mt-2 flex flex-wrap gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void save()}
          className="rounded-lg bg-accent px-3 py-1.5 text-xs font-semibold text-white"
        >
          {busy ? "…" : "In Meine Touren"}
        </button>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="rounded-lg border border-border px-3 py-1.5 text-xs"
        >
          Abbrechen
        </button>
      </div>
    </div>
  );
}
