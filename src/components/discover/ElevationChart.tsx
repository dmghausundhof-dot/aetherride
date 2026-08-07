"use client";

import type { ElevationProfile } from "@/lib/routing/elevationProfile";

export function ElevationChart({ elev }: { elev: ElevationProfile }) {
  const elevs = elev.points
    .map((p) => p.elevM)
    .filter((e): e is number => e != null);
  const minE = elevs.length ? Math.min(...elevs) - 20 : 700;
  const maxE = elevs.length ? Math.max(...elevs) + 20 : 1100;
  const span = Math.max(maxE - minE, 1);

  return (
    <div className="flex flex-col gap-3">
      <p className="text-xs text-text-secondary">
        {elev.totalDistKm.toFixed(1)} km · {elev.totalClimbM} hm
        {elev.gapKm > 0
          ? ` · ${elev.gapKm.toFixed(1)} km ohne Höhendaten`
          : ""}
      </p>
      <svg viewBox="0 0 400 120" className="w-full rounded-xl bg-surface">
        {elev.points.map((p, i) => {
          if (p.elevM == null || i === 0 || elev.totalDistKm <= 0) return null;
          const prev = elev.points[i - 1];
          if (prev.elevM == null) return null;
          const x1 = (prev.distKm / elev.totalDistKm) * 380 + 10;
          const x2 = (p.distKm / elev.totalDistKm) * 380 + 10;
          const y1 = 100 - ((prev.elevM - minE) / span) * 80;
          const y2 = 100 - ((p.elevM - minE) / span) * 80;
          const steep = (p.gradePct ?? 0) > 8;
          return (
            <line
              key={i}
              x1={x1}
              y1={y1}
              x2={x2}
              y2={y2}
              stroke={steep ? "#FF6B35" : "#1A5C45"}
              strokeWidth="2"
            />
          );
        })}
        {elev.points
          .filter((p) => p.elevM == null)
          .map((p) => (
            <rect
              key={`gap-${p.distKm}`}
              x={(p.distKm / elev.totalDistKm) * 380 + 8}
              y={20}
              width={6}
              height={80}
              fill="#6B7280"
              opacity="0.35"
            />
          ))}
      </svg>
      <div className="text-[11px] text-text-secondary">
        <p className="font-medium text-foreground">Oberfläche</p>
        {elev.surfaceBands.slice(0, 6).map((b) => (
          <span key={`${b.fromKm}-${b.surface}`} className="mr-2">
            {b.fromKm.toFixed(1)}–{b.toKm.toFixed(1)} km: {b.surface ?? "—"}
          </span>
        ))}
        <p className="mt-2 font-medium text-foreground">Schwierigkeit</p>
        {elev.scaleBands.slice(0, 6).map((b) => (
          <span key={`${b.fromKm}-s`} className="mr-2">
            {b.fromKm.toFixed(1)}: {b.scale ?? "—"}
          </span>
        ))}
      </div>
    </div>
  );
}
