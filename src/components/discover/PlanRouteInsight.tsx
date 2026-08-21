"use client";

import { useEffect, useState } from "react";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";
import { surfaceMixShares } from "@/lib/routing/elevationProfile";
import { ElevationChart } from "@/components/discover/ElevationChart";
import { SurfaceMixBar } from "@/components/discover/SurfaceMixBar";
import { osmSurfaceLabel } from "@/lib/routing/osmSurfaceLabel";
import type { discoverUi } from "@/lib/i18n/discoverUi";

type Copy = ReturnType<typeof discoverUi>;

export function PlanRouteInsight({
  geometry,
  distanceM,
  durationS,
  elevationSummary,
  looped,
  copy,
  onHoverKm,
  hoverKm,
  onPickKm,
  onProfile,
  adapting,
}: {
  geometry: GeoJSON.LineString | null | undefined;
  distanceM?: number;
  durationS?: number;
  elevationSummary?: string | null;
  looped?: boolean;
  copy: Copy;
  onHoverKm?: (km: number | null) => void;
  hoverKm?: number | null;
  onPickKm?: (km: number) => void;
  onProfile?: (elev: ElevationProfile | null) => void;
  adapting?: boolean;
}) {
  const [elev, setElev] = useState<ElevationProfile | null>(null);

  useEffect(() => {
    const coords = geometry?.coordinates;
    if (!coords || coords.length < 2) {
      setElev(null);
      return;
    }
    const key = `${coords.length}:${coords[0]?.join(",")}:${coords[coords.length - 1]?.join(",")}`;
    let cancelled = false;
    const track = coords.map(([lng, lat]) => ({ lat, lng }));
    void fetch("/api/elevation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ track }),
    })
      .then(async (r) => {
        if (!r.ok || cancelled) return;
        const j = (await r.json()) as ElevationProfile;
        if (!cancelled && j?.points?.length >= 2) setElev(j);
        else if (!cancelled) setElev(null);
      })
      .catch(() => {
        if (!cancelled) setElev(null);
      });
    return () => {
      cancelled = true;
      void key;
    };
  }, [geometry]);

  useEffect(() => {
    onProfile?.(elev);
  }, [elev, onProfile]);

  if (!distanceM) return null;
  const km = (distanceM / 1000).toFixed(distanceM < 10_000 ? 1 : 0);
  const min = durationS != null ? Math.round(durationS / 60) : null;
  const mix = elev ? surfaceMixShares(elev.surfaceBands) : [];
  const labels = {
    asphalt: copy.surfaceAsphalt,
    gravel: copy.surfaceSchotter,
    trail: copy.surfaceNatur,
  };
  const climb =
    elev && Number.isFinite(elev.totalClimbM) && elev.totalClimbM > 0
      ? `↑ ${Math.round(elev.totalClimbM)} m`
      : "—";
  const surface = mix[0]
    ? `${osmSurfaceLabel(mix[0].key, labels)} ${Math.round(mix[0].share * 100)}%`
    : elevationSummary?.trim() || "—";

  return (
    <div className="flex flex-col gap-2">
      {looped ? (
        <p className="text-[11px] font-bold text-chrome">{copy.loopClosed}</p>
      ) : null}
      {adapting ? (
        <p className="text-[11px] font-semibold text-text-secondary">
          {copy.routingAdapts}
        </p>
      ) : null}
      <div
        className={`overflow-hidden rounded-2xl border border-border bg-surface ${
          adapting ? "opacity-45" : ""
        }`}
      >
        <div className="grid grid-cols-2">
          <Stat label={copy.statDuration} value={min != null ? `${min} min` : "—"} />
          <Stat label={copy.statLength} value={`${km} km`} borderLeft />
        </div>
        <div className="grid grid-cols-2 border-t border-border">
          <Stat label={copy.statAscent} value={climb} />
          <Stat label={copy.statSurface} value={surface} borderLeft />
        </div>
      </div>
      {elev ? (
        <>
          <SurfaceMixBar
            bands={elev.surfaceBands}
            asphalt={copy.surfaceAsphalt}
            gravel={copy.surfaceSchotter}
            trail={copy.surfaceNatur}
          />
          <p className="text-[11px] font-semibold text-text-secondary">
            {copy.elevTitle}
          </p>
          <ElevationChart
            elev={elev}
            compact
            onHoverKm={onHoverKm}
            hoverKm={hoverKm}
            onPickKm={adapting ? undefined : onPickKm}
          />
        </>
      ) : null}
    </div>
  );
}

function Stat({
  label,
  value,
  borderLeft,
}: {
  label: string;
  value: string;
  borderLeft?: boolean;
}) {
  return (
    <div
      className={`px-3 py-2.5 text-left ${borderLeft ? "border-l border-border" : ""}`}
    >
      <div className="text-[11px] font-semibold text-text-secondary">{label}</div>
      <div className="text-[17px] font-extrabold tabular-nums leading-tight">
        {value}
      </div>
    </div>
  );
}
