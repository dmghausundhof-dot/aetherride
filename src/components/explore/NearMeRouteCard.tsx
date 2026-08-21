"use client";

import { Loader2 } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { RoutingProfile } from "@/lib/routing/profiles";
import type { ClientRouteResult } from "@/lib/routing/profiles";
import { useAppStore } from "@/store/useAppStore";
import {
  activeRouteForWebRideBridge,
  savedRouteForWebRideHandoff,
} from "@/lib/routing/activeRoute";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";
import { isHonestLoop } from "@/lib/discover/loopHonesty";
import { useChromeLang } from "@/hooks/useChromeLang";
import { discoverCopy } from "@/lib/i18n/discoverCopy";
import { discoverUi } from "@/lib/i18n/discoverUi";
import { profileAllowsOsmRoundTrip } from "@/lib/routing/osmRoundTrip";

/**
 * Route ab GPS oder manuellem Zentrum — Live-Engine.
 * Rundkurs mode: reject engine results that are not closed (≤300 m).
 * Preview first — Mappe after Merken; „In App“ speichert vor der Bridge.
 */
export function NearMeRouteCard({
  center,
  profile,
  defaultKm = 25,
  routeMode: controlledMode,
  onRouteModeChange,
  onLoopPreview,
}: {
  center: [number, number] | null;
  profile: RoutingProfile;
  defaultKm?: number;
  routeMode?: "loop" | "point_to_point";
  onRouteModeChange?: (mode: "loop" | "point_to_point") => void;
  onLoopPreview?: (result: ClientRouteResult, label: string) => void;
}) {
  const router = useRouter();
  const lang = useChromeLang();
  const d = discoverUi(lang);
  const loopLabel = discoverCopy(lang).loop;
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const [km, setKm] = useState(defaultKm);
  const [uncontrolledMode, setUncontrolledMode] = useState<
    "loop" | "point_to_point"
  >("loop");
  const loopOk = profileAllowsOsmRoundTrip(profile);
  const mode = loopOk
    ? (controlledMode ?? uncontrolledMode)
    : "point_to_point";
  const setMode = (m: "loop" | "point_to_point") => {
    onRouteModeChange?.(m);
    if (controlledMode === undefined) setUncontrolledMode(m);
  };
  useEffect(() => {
    if (!loopOk && controlledMode === "loop") {
      onRouteModeChange?.("point_to_point");
    }
  }, [loopOk, controlledMode, onRouteModeChange]);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [preview, setPreview] = useState<ClientRouteResult | null>(null);
  const [previewMeta, setPreviewMeta] = useState<{
    name: string;
    distanceKm: number;
    elev: number | null;
    isLoop: boolean;
    tourId: string;
  } | null>(null);

  const run = async (andStart: boolean) => {
    if (!center) {
      setMsg(d.needCenter);
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
      const coords = (result.geometry?.coordinates ?? []) as [number, number][];
      if (
        mode === "loop" &&
        !isHonestLoop({ loopFlag: true, trackLngLat: coords })
      ) {
        setPreview(null);
        setPreviewMeta(null);
        setMsg(d.noHonestEngine);
        return;
      }
      setPreview(result);
      const name =
        j.label ||
        (mode === "loop" ? `Runde ${km} km` : `Route ${km} km`);
      const distanceKm = Math.round((result.distanceM / 1000) * 10) / 10;
      const elev =
        typeof j.elevationM === "number"
          ? sanitizeElevationM(j.elevationM, distanceKm)
          : null;
      const isLoop =
        mode === "loop" &&
        isHonestLoop({ loopFlag: true, trackLngLat: coords });
      setPreviewMeta({
        name,
        distanceKm,
        elev,
        isLoop,
        tourId: j.tourId || `near-${Date.now()}`,
      });
      setMsg(d.previewEngine(formatDistanceElevation(distanceKm, elev)));
      if (isLoop) {
        onLoopPreview?.(result, name);
      }
      if (andStart) {
        const entry = savedRouteForWebRideHandoff({
          id: j.tourId || `near-${Date.now()}`,
          name,
          distanceKm,
          elevationM: elev,
          durationMin: Math.round(result.durationS / 60),
          geometry: result.geometry,
          source: "engine",
          loop: isLoop,
        });
        if (!entry) {
          setMsg(d.routingFail);
          return;
        }
        saveRoute(entry);
        const active = activeRouteForWebRideBridge(entry);
        if (!active) {
          setMsg(d.routingFail);
          return;
        }
        setActiveRoute(active);
        router.push("/ride");
      }
    } catch (e) {
      setMsg(e instanceof Error ? e.message : d.routingFail);
    } finally {
      setBusy(false);
    }
  };

  const savePreview = () => {
    if (!preview || !previewMeta) return;
    saveRoute({
      id: previewMeta.tourId,
      name: previewMeta.name,
      distanceKm: previewMeta.distanceKm,
      elevationM: previewMeta.elev ?? 0,
      durationMin: Math.round(preview.durationS / 60),
      savedAt: new Date().toISOString(),
      source: "engine",
      geometry: preview.geometry,
      loop: previewMeta.isLoop,
    });
    setMsg(d.savedEngine(formatDistanceElevation(previewMeta.distanceKm, previewMeta.elev)));
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-4">
      <div className="flex items-center gap-2">
        <ChromeGlyph name="karte" size={16} />
        <h3 className="text-sm font-semibold">{d.fromHereTitle}</h3>
      </div>
      <p className="mt-1 text-[11px] text-text-secondary">
        {d.fromHereHint}
      </p>
      {!center && (
        <p className="mt-2 text-xs text-warning">
          {d.needCenter}
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
          {loopOk ? <option value="loop">{loopLabel}</option> : null}
          <option value="point_to_point">{d.stretch}</option>
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
          {d.compute}
        </button>
        <button
          type="button"
          disabled={busy || !center}
          onClick={() => void run(true)}
          className="flex flex-1 items-center justify-center gap-1 rounded-xl bg-accent py-2 text-xs font-semibold text-on-accent disabled:opacity-40"
        >
          <ChromeGlyph name="play" size={14} current /> {d.inApp}
        </button>
      </div>
      {preview && previewMeta ? (
        <button
          type="button"
          onClick={savePreview}
          className="mt-2 inline-flex w-full items-center justify-center gap-1.5 rounded-xl border border-chrome/40 py-2 text-xs font-medium text-chrome"
        >
          <ChromeGlyph name="merken" size={14} current />
          {d.savePreview}
        </button>
      ) : null}
      {msg && (
        <p className="mt-2 text-[11px] text-text-secondary">{msg}</p>
      )}
      {preview && (
        <p className="mt-1 text-[11px] tabular-nums text-accent">
          {(preview.distanceM / 1000).toFixed(1)} km ·{" "}
          {Math.round(preview.durationS / 60)} min
        </p>
      )}
    </div>
  );
}
