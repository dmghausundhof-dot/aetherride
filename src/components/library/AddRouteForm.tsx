"use client";

import { useState } from "react";
import Link from "next/link";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useAppStore } from "@/store/useAppStore";
import { simpleNamedRoute } from "@/lib/library/simpleAddRoute";
import { mappeGoRideDiscoverHref } from "@/lib/tours/mappeList";
import { useChromeLang } from "@/hooks/useChromeLang";
import { platzCopy } from "@/lib/i18n/platzCopy";
import { catalogCopy } from "@/lib/i18n/catalogCopy";

export function AddRouteForm({
  defaultStart,
  startSource = null,
  onSaved,
  onPickGpx,
  compact = false,
  label,
  tone = "accent",
}: {
  /** [lng, lat] Kartenmitte / GPS */
  defaultStart?: [number, number] | null;
  startSource?: "gps" | "map" | null;
  onSaved?: (name: string) => void;
  onPickGpx?: () => void;
  compact?: boolean;
  label?: string;
  tone?: "accent" | "ghost";
}) {
  const saveRoute = useAppStore((s) => s.saveRoute);
  const lang = useChromeLang();
  const p = platzCopy(lang);
  const openPlanner = catalogCopy(lang).tour.openPlanner;
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const [planHref, setPlanHref] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setBusy(true);
    setMsg(null);
    setPlanHref(null);
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
    setPlanHref(mappeGoRideDiscoverHref(entry));
    onSaved?.(entry.name);
  };

  if (!open) {
    return (
      <div>
        <button
          type="button"
          onClick={() => setOpen(true)}
          className={
            tone === "ghost"
              ? "inline-flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold text-text-secondary"
              : compact
              ? "inline-flex items-center gap-1.5 rounded-xl bg-accent px-2.5 py-1.5 text-xs font-semibold text-on-accent"
              : "inline-flex items-center gap-1.5 rounded-xl bg-accent px-3 py-2 text-sm font-semibold text-on-accent"
          }
        >
          {tone === "ghost" ? null : <ChromeGlyph name="add" size={14} current />} {label ?? p.keepRoute}
        </button>
        {msg && (
          <p className="mt-2 text-xs text-text-secondary" role="status">
            {msg}
            {planHref ? (
              <>
                {" · "}
                <Link href={planHref} className="font-semibold text-accent">
                  {openPlanner}
                </Link>
              </>
            ) : null}
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
        {(() => {
          if (!defaultStart) return p.startNone;
          const coords = `${defaultStart[1].toFixed(3)}°N, ${defaultStart[0].toFixed(3)}°E`;
          if (startSource === "gps") return p.startFromGps(coords);
          if (startSource === "map") return p.startFromMap(coords);
          return p.startPin(defaultStart[1].toFixed(3), defaultStart[0].toFixed(3));
        })()}
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
