"use client";

import { GRADE_COLORS, type RideTelemetry } from "@/lib/ride/rideTelemetry";
import { cn } from "@/lib/utils";

export function ActivitySparkline({
  telemetry,
  className,
}: {
  telemetry: RideTelemetry;
  className?: string;
}) {
  const pts = telemetry.chart.filter((s) => s.elevM != null);
  const w = 200;
  const h = 36;
  if (pts.length < 2 || telemetry.totalDistKm <= 0) {
    return (
      <svg
        viewBox={`0 0 ${w} ${h}`}
        className={className}
        aria-hidden
        preserveAspectRatio="none"
      />
    );
  }

  const elevs = pts.map((p) => p.elevM as number);
  const minE = Math.min(...elevs);
  const maxE = Math.max(...elevs);
  const span = Math.max(maxE - minE, 8);
  const xOf = (distKm: number) => (distKm / telemetry.totalDistKm) * w;
  const yOf = (elev: number) => h - 3 - ((elev - minE) / span) * (h - 6);
  const first = pts[0];
  const last = pts[pts.length - 1];
  const fill = `M${xOf(first.distKm).toFixed(1)},${h} ${pts
    .map((p) => `L${xOf(p.distKm).toFixed(1)},${yOf(p.elevM as number).toFixed(1)}`)
    .join(" ")} L${xOf(last.distKm).toFixed(1)},${h} Z`;

  return (
    <svg
      viewBox={`0 0 ${w} ${h}`}
      className={className}
      aria-hidden
      preserveAspectRatio="none"
    >
      <path d={fill} fill="#FF6A00" fillOpacity="0.14" />
      {pts.map((p, i) => {
        if (i === 0) return null;
        const prev = pts[i - 1];
        if (prev.elevM == null || p.elevM == null) return null;
        return (
          <line
            key={`${p.distKm}-${i}`}
            x1={xOf(prev.distKm)}
            y1={yOf(prev.elevM)}
            x2={xOf(p.distKm)}
            y2={yOf(p.elevM)}
            stroke={GRADE_COLORS[p.band]}
            strokeWidth="2.2"
            strokeLinecap="round"
          />
        );
      })}
    </svg>
  );
}

/** Hof, Liste, Rad: dieselbe Mini-Fläche — Profil + Neigungsband. */
export function RideTerrainPeek({
  telemetry,
  caption,
  className,
}: {
  telemetry: RideTelemetry;
  caption?: string;
  className?: string;
}) {
  if (!telemetry.channels.elev || telemetry.totalDistKm <= 0) return null;
  return (
    <div
      className={cn(
        "rounded-xl bg-[#16161c] px-2.5 pb-2 pt-2",
        className
      )}
    >
      {caption ? (
        <p className="mb-1 text-[10px] font-semibold tabular-nums text-text-secondary">
          {caption}
        </p>
      ) : null}
      <ActivitySparkline telemetry={telemetry} className="h-11 w-full" />
      <ActivityGradeRibbon telemetry={telemetry} className="mt-1.5" />
    </div>
  );
}

export function ActivityGradeRibbon({
  telemetry,
  className,
}: {
  telemetry: RideTelemetry;
  className?: string;
}) {
  if (!telemetry.channels.elev || telemetry.totalDistKm <= 0) return null;
  const pts = telemetry.chart;
  return (
    <div
      className={`flex h-1.5 overflow-hidden rounded-full bg-surface-elevated ${className ?? ""}`}
      aria-hidden
    >
      {pts.map((p, i) => {
        if (i === 0) return null;
        const prev = pts[i - 1];
        const width =
          ((p.distKm - prev.distKm) / telemetry.totalDistKm) * 100;
        if (width <= 0) return null;
        return (
          <span
            key={`${p.distKm}-r`}
            className="h-full"
            style={{
              width: `${width}%`,
              background: GRADE_COLORS[p.band],
            }}
          />
        );
      })}
    </div>
  );
}
