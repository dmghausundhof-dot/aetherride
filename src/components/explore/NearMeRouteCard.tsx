"use client";

import { useState } from "react";
import { Navigation, Play, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { useAppStore } from "@/store/useAppStore";
import { activeRouteFromEngine } from "@/lib/routing/activeRoute";
import type { ClientRouteResult } from "@/lib/routing/profiles";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";

/**
 * Route ab GPS oder manuellem Zentrum — Live-Engine.
 */
export function NearMeRouteCard({
  center,
  profile,
  defaultKm = 25,
}: {
  center: [number, number] | null;
  profile: RoutingProfile;
  defaultKm?: number;
}) {
  const router = useRouter();
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const [km, setKm] = useState(defaultKm);
  const [mode, setMode] = useState<"loop" | "point_to_point">("loop");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [preview, setPreview] = useState<ClientRouteResult | null>(null);

  const run = async (andStart: boolean) => {
    if (!center) {
      setMsg("Standort oder Kartenmitte fehlt");
      return;
    }
    setBusy(true);
    setMsg(null);
    try {
      const q = new URLSearchParams({
        lat: String(center[1]),
        lng: String(center[0]),
        profile,
        mode,
        distanceKm: String(km),
        label: mode === "loop" ? `Runde ${km} km` : `Tour ${km} km`,
      });
      const r = await fetch(`/api/tours/geometry?${q}`);
      const j = await r.json();
      if (!r.ok) throw new Error(j.error || `HTTP ${r.status}`);
      const result: ClientRouteResult = {
        distanceM: j.distanceM,
        durationS: j.durationS,
        geometry: j.geometry,
        engine: j.engine,
        profile: j.profile,
        steps: j.steps,
        warnings: j.warnings,
      };
      setPreview(result);
      const name =
        j.label ||
        (mode === "loop" ? `Runde ${km} km` : `Route ${km} km`);
      const distanceKm = Math.round((result.distanceM / 1000) * 10) / 10;
      const rawAscent =
        typeof j.elevationM === "number"
          ? j.elevationM
          : Math.round(result.distanceM * 0.02);
      const elev = sanitizeElevationM(rawAscent, distanceKm);
      saveRoute({
        id: j.tourId || `near-${Date.now()}`,
        name,
        distanceKm,
        elevationM: elev ?? 0,
        durationMin: Math.round(result.durationS / 60),
        savedAt: new Date().toISOString(),
        source: "engine",
        geometry: result.geometry,
        loop: mode === "loop",
      });
      setMsg(
        `${formatDistanceElevation(distanceKm, elev)} · ${result.engine} · gespeichert`
      );
      if (andStart) {
        setActiveRoute(activeRouteFromEngine(name, result));
        router.push("/ride");
      }
    } catch (e) {
      setMsg(e instanceof Error ? e.message : "Routing fehlgeschlagen");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-4">
      <div className="flex items-center gap-2">
        <Navigation className="h-4 w-4 text-accent" />
        <h3 className="text-sm font-semibold">Route ab hier</h3>
      </div>
      <p className="mt-1 text-[11px] text-text-secondary">
        Live-Routing vom GPS oder der Kartenmitte — speichern & in der App
        fahren.
      </p>
      {!center && (
        <p className="mt-2 text-xs text-warning">
          Standort freigeben oder Karte verschieben.
        </p>
      )}
      <div className="mt-3 flex flex-wrap gap-2">
        <select
          value={mode}
          onChange={(e) =>
            setMode(e.target.value as "loop" | "point_to_point")
          }
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
        >
          <option value="loop">Rundkurs</option>
          <option value="point_to_point">Strecke</option>
        </select>
        <label className="flex items-center gap-1 text-xs text-text-secondary">
          ~{km} km
          <input
            type="range"
            min={8}
            max={80}
            step={1}
            value={km}
            onChange={(e) => setKm(Number(e.target.value))}
            className="w-24"
          />
        </label>
      </div>
      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={busy || !center}
          onClick={() => void run(false)}
          className="flex flex-1 items-center justify-center gap-1 rounded-xl border border-border py-2 text-xs font-medium disabled:opacity-40"
        >
          {busy ? (
            <Loader2 className="h-3.5 w-3.5 animate-spin" />
          ) : null}
          Berechnen
        </button>
        <button
          type="button"
          disabled={busy || !center}
          onClick={() => void run(true)}
          className="flex flex-1 items-center justify-center gap-1 rounded-xl bg-accent py-2 text-xs font-semibold text-white disabled:opacity-40"
        >
          <Play className="h-3.5 w-3.5 fill-current" /> In App
        </button>
      </div>
      {msg && (
        <p className="mt-2 text-[11px] text-text-secondary">{msg}</p>
      )}
      {preview && (
        <p className="mt-1 text-[11px] tabular-nums text-accent">
          {(preview.distanceM / 1000).toFixed(1)} km ·{" "}
          {Math.round(preview.durationS / 60)} min · {preview.engine}
        </p>
      )}
    </div>
  );
}
