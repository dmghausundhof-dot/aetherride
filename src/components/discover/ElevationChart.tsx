"use client";

import { useRef } from "react";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";
import { useChromeLang } from "@/hooks/useChromeLang";
import { discoverUi } from "@/lib/i18n/discoverUi";

export function ElevationChart({
  elev,
  compact = false,
  onHoverKm,
  hoverKm,
  onPickKm,
}: {
  elev: ElevationProfile;
  compact?: boolean;
  onHoverKm?: (km: number | null) => void;
  hoverKm?: number | null;
  /** Finger-up with little movement — not a scrub pan. */
  onPickKm?: (km: number) => void;
}) {
  const d = discoverUi(useChromeLang());
  const downRef = useRef<{ x: number; y: number } | null>(null);
  const draggedRef = useRef(false);
  const elevs = elev.points
    .map((p) => p.elevM)
    .filter((e): e is number => e != null);
  const minE = elevs.length ? Math.min(...elevs) - 20 : 700;
  const maxE = elevs.length ? Math.max(...elevs) + 20 : 1100;
  const span = Math.max(maxE - minE, 1);
  const climbDisplay = sanitizeElevationM(
    elev.totalClimbM,
    elev.totalDistKm
  );

  const padL = 40;
  const padR = 10;
  const padT = 14;
  const padB = 20;
  const chartW = 400 - padL - padR;
  const chartH = 128 - padT - padB;
  const xAt = (distKm: number) =>
    padL + (distKm / Math.max(elev.totalDistKm, 0.001)) * chartW;
  const yAt = (elevM: number) =>
    padT + (1 - (elevM - minE) / span) * chartH;

  const kmAt = (clientX: number, target: SVGSVGElement) => {
    if (elev.totalDistKm <= 0) return null;
    const rect = target.getBoundingClientRect();
    const x = ((clientX - rect.left) / rect.width) * 400;
    const t = Math.max(0, Math.min(1, (x - padL) / chartW));
    return t * elev.totalDistKm;
  };

  return (
    <div className={`flex flex-col ${compact ? "gap-1.5" : "gap-3"}`}>
      {compact ? null : (
      <p className="text-xs text-text-secondary">
        {formatDistanceElevation(
          Math.round(elev.totalDistKm * 10) / 10,
          climbDisplay
        )}
        {elev.gapKm > 0
          ? d.gapElev(elev.gapKm.toFixed(1))
          : ""}
      </p>
      )}
      <svg
        viewBox="0 0 400 128"
        className={`w-full touch-none rounded-xl bg-surface ${
          onPickKm ? "cursor-pointer" : ""
        }`}
        onPointerDown={(e) => {
          downRef.current = { x: e.clientX, y: e.clientY };
          draggedRef.current = false;
        }}
        onPointerMove={(e) => {
          const down = downRef.current;
          if (down) {
            const dx = e.clientX - down.x;
            const dy = e.clientY - down.y;
            if (dx * dx + dy * dy > 100) draggedRef.current = true;
          }
          if (!onHoverKm) return;
          onHoverKm(kmAt(e.clientX, e.currentTarget));
        }}
        onPointerUp={(e) => {
          if (onPickKm && downRef.current && !draggedRef.current) {
            const km = kmAt(e.clientX, e.currentTarget);
            if (km != null) onPickKm(km);
          }
          downRef.current = null;
        }}
        onPointerLeave={() => onHoverKm?.(null)}
        onPointerCancel={() => {
          downRef.current = null;
        }}
      >
        <text x="4" y="12" fontSize="11" fontWeight="700" fill="currentColor" className="fill-text-secondary">
          {Math.round(maxE)} m
        </text>
        <text x="4" y={padT + chartH} fontSize="11" fontWeight="700" fill="currentColor" className="fill-text-secondary">
          {Math.round(minE)} m
        </text>
        <text x={padL} y="124" fontSize="11" fontWeight="700" fill="currentColor" className="fill-text-secondary">
          0 km
        </text>
        <text
          x="396"
          y="124"
          fontSize="11"
          fontWeight="700"
          textAnchor="end"
          fill="currentColor"
          className="fill-text-secondary"
        >
          {elev.totalDistKm.toFixed(elev.totalDistKm < 10 ? 1 : 0)} km
        </text>
        {elev.points.map((p, i) => {
          if (p.elevM == null || i === 0 || elev.totalDistKm <= 0) return null;
          const prev = elev.points[i - 1];
          if (prev.elevM == null) return null;
          const steep = (p.gradePct ?? 0) > 8;
          return (
            <line
              key={i}
              x1={xAt(prev.distKm)}
              y1={yAt(prev.elevM)}
              x2={xAt(p.distKm)}
              y2={yAt(p.elevM)}
              stroke={steep ? "#FF6A00" : "#7A8B73"}
              strokeWidth="2"
            />
          );
        })}
        {hoverKm != null && elev.totalDistKm > 0 ? (
          <line
            x1={xAt(hoverKm)}
            y1={padT}
            x2={xAt(hoverKm)}
            y2={padT + chartH}
            stroke="#1F1F1F"
            strokeWidth="1.4"
            opacity="0.55"
          />
        ) : null}
        {elev.points
          .filter((p) => p.elevM == null)
          .map((p) => (
            <rect
              key={`gap-${p.distKm}`}
              x={xAt(p.distKm) - 3}
              y={padT}
              width={6}
              height={chartH}
              fill="#6B7280"
              opacity="0.35"
            />
          ))}
      </svg>
      {compact ? null : (
      <div className="text-[11px] text-text-secondary">
        <p className="font-medium text-foreground">{d.surfaceTitle}</p>
        {elev.surfaceBands.slice(0, 6).map((b) => (
          <span key={`${b.fromKm}-${b.surface}`} className="mr-2">
            {b.fromKm.toFixed(1)}–{b.toKm.toFixed(1)} km: {b.surface ?? "—"}
          </span>
        ))}
        <p className="mt-2 font-medium text-foreground">{d.difficultyTitle}</p>
        {elev.scaleBands.slice(0, 6).map((b) => (
          <span key={`${b.fromKm}-s`} className="mr-2">
            {b.fromKm.toFixed(1)}: {b.scale ?? "—"}
          </span>
        ))}
      </div>
      )}
    </div>
  );
}
