"use client";

import { useCallback, useId, useMemo, useState, type ReactNode } from "react";
import {
  GRADE_COLORS,
  nearestSample,
  type GradeBand,
  type RideSample,
  type RideTelemetry,
} from "@/lib/ride/rideTelemetry";
import type { RideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import { ActivityGradeRibbon } from "@/components/ride/ActivitySparkline";

export function RideTelemetryCard({
  telemetry,
  copy,
  onHoverSample,
  map,
}: {
  telemetry: RideTelemetry;
  copy: RideTelemetryCopy;
  onHoverSample?: (sample: RideSample | null) => void;
  /** Karte sitzt auf derselben Fläche wie das Profil. */
  map?: ReactNode;
}) {
  const [hover, setHover] = useState<RideSample | null>(null);
  const chart = telemetry.chart;
  const hasElev = telemetry.channels.elev;

  const onLeave = useCallback(() => {
    setHover(null);
    onHoverSample?.(null);
  }, [onHoverSample]);

  const setSample = useCallback(
    (s: RideSample | null) => {
      setHover(s);
      onHoverSample?.(s);
    },
    [onHoverSample]
  );

  const slab = chart.length >= 2 || map;

  return (
    <section className="rounded-2xl border border-border bg-surface p-4 sm:p-5">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div>
          <h2 className="text-sm font-semibold">{copy.title}</h2>
          <p className="mt-1 max-w-xl text-[11px] leading-relaxed text-text-secondary">
            {hasElev ? copy.hint : copy.noElevation}
          </p>
        </div>
        {hasElev ? (
          <span className="rounded-full border border-border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
            {copy.gpsSource}
          </span>
        ) : null}
      </div>

      {slab ? (
        <div className="mt-4 overflow-hidden rounded-2xl border border-border">
          {map ? (
            <div className="relative h-56 w-full sm:h-72">{map}</div>
          ) : null}
          {hasElev ? (
            <ActivityGradeRibbon
              telemetry={telemetry}
              className="rounded-none"
            />
          ) : null}
          {chart.length >= 2 ? (
            <ElevationPlot
              telemetry={telemetry}
              copy={copy}
              hover={hover}
              onHover={setSample}
              onLeave={onLeave}
              embedded
            />
          ) : null}
        </div>
      ) : null}

      <HoverReadout hover={hover} copy={copy} />

      <TelemetryStats telemetry={telemetry} copy={copy} />

      {hasElev ? <GradeLegend copy={copy} /> : null}

      <SensorStrips
        telemetry={telemetry}
        copy={copy}
        hover={hover}
        onHover={setSample}
        onLeave={onLeave}
      />
    </section>
  );
}

function HoverReadout({
  hover,
  copy,
}: {
  hover: RideSample | null;
  copy: RideTelemetryCopy;
}) {
  if (!hover) {
    return (
      <p className="mt-2 text-[11px] text-text-secondary">{copy.hoverHere}</p>
    );
  }
  return (
    <p className="mt-2 text-xs tabular-nums text-text-secondary">
      {hover.distKm.toFixed(2)} {copy.km}
      {hover.elevM != null ? ` · ${Math.round(hover.elevM)} m` : ""}
      {hover.gradePct != null
        ? ` · ${hover.gradePct > 0 ? "+" : ""}${hover.gradePct.toFixed(1)} %`
        : ""}
      {hover.speedKmh != null ? ` · ${hover.speedKmh.toFixed(1)} km/h` : ""}
      {hover.hr != null ? ` · ${hover.hr} bpm` : ""}
      {hover.cad != null ? ` · ${hover.cad} rpm` : ""}
      {hover.power != null ? ` · ${hover.power} W` : ""}
    </p>
  );
}

function TelemetryStats({
  telemetry: t,
  copy,
}: {
  telemetry: RideTelemetry;
  copy: RideTelemetryCopy;
}) {
  const items: { label: string; value: string }[] = [];
  if (t.channels.elev) {
    items.push({ label: copy.climb, value: `${t.climbM} ${copy.hm}` });
    items.push({ label: copy.descent, value: `${t.descentM} ${copy.hm}` });
    if (t.maxGradePct != null) {
      items.push({
        label: copy.maxGrade,
        value: `${t.maxGradePct > 0 ? "+" : ""}${t.maxGradePct.toFixed(1)} %`,
      });
    }
  }
  if (t.maxSpeedKmh != null) {
    items.push({
      label: copy.maxSpeed,
      value: `${t.maxSpeedKmh.toFixed(1)} km/h`,
    });
  }
  if (t.avgHr != null) {
    items.push({ label: copy.hr, value: `${t.avgHr} bpm` });
  }
  if (t.avgCad != null) {
    items.push({ label: copy.cad, value: `${t.avgCad} rpm` });
  }
  if (t.avgPower != null) {
    items.push({ label: copy.power, value: `${t.avgPower} W` });
  }
  if (t.channels.impact) {
    items.push({ label: copy.impact, value: `${t.impactCount}` });
  }
  if (t.maxLean != null && t.channels.lean) {
    items.push({ label: copy.lean, value: `${t.maxLean.toFixed(0)}°` });
  }
  if (items.length === 0) return null;

  return (
    <dl className="mt-4 grid grid-cols-2 gap-2 sm:grid-cols-4">
      {items.map((it) => (
        <div
          key={it.label}
          className="rounded-xl border border-border bg-surface-elevated/60 px-3 py-2"
        >
          <dt className="text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
            {it.label}
          </dt>
          <dd className="mt-0.5 text-sm font-semibold tabular-nums">{it.value}</dd>
        </div>
      ))}
    </dl>
  );
}

function ElevationPlot({
  telemetry,
  copy,
  hover,
  onHover,
  onLeave,
  embedded = false,
}: {
  telemetry: RideTelemetry;
  copy: RideTelemetryCopy;
  hover: RideSample | null;
  onHover: (s: RideSample | null) => void;
  onLeave: () => void;
  embedded?: boolean;
}) {
  const fillId = `ride-elev-${useId().replace(/:/g, "")}`;
  const W = 640;
  const H = embedded ? 148 : 168;
  const padL = 40;
  const padR = 12;
  const padT = 14;
  const padB = 22;
  const innerW = W - padL - padR;
  const innerH = H - padT - padB;
  const pts = telemetry.chart;
  const elevs = pts.map((p) => p.elevM).filter((e): e is number => e != null);
  const minE = elevs.length ? Math.min(...elevs) - 8 : 0;
  const maxE = elevs.length ? Math.max(...elevs) + 8 : 100;
  const span = Math.max(maxE - minE, 12);
  const total = Math.max(telemetry.totalDistKm, 0.001);

  const xOf = (distKm: number) => padL + (distKm / total) * innerW;
  const yOf = (elev: number) => padT + (1 - (elev - minE) / span) * innerH;

  const area = useMemo(() => {
    const known = pts.filter((p) => p.elevM != null);
    if (known.length < 2) return "";
    const head = known
      .map((p, i) => {
        const x = xOf(p.distKm).toFixed(1);
        const y = yOf(p.elevM as number).toFixed(1);
        return `${i === 0 ? "M" : "L"}${x},${y}`;
      })
      .join(" ");
    const last = known[known.length - 1];
    const first = known[0];
    return `${head} L${xOf(last.distKm).toFixed(1)},${(padT + innerH).toFixed(1)} L${xOf(first.distKm).toFixed(1)},${(padT + innerH).toFixed(1)} Z`;
  }, [pts, minE, span, total]);

  const pick = (clientX: number, target: SVGSVGElement) => {
    const box = target.getBoundingClientRect();
    const rel = (clientX - box.left) / box.width;
    const distKm = Math.max(0, Math.min(1, rel)) * total;
    onHover(nearestSample(telemetry, distKm));
  };

  return (
    <div className={embedded ? "bg-[#16161c] px-2 pb-1 pt-1" : "mt-4"}>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className={
          embedded
            ? "w-full overflow-visible"
            : "w-full overflow-visible rounded-xl bg-[#16161c]"
        }
        role="img"
        aria-label={copy.title}
        onPointerLeave={onLeave}
        onPointerMove={(e) => pick(e.clientX, e.currentTarget)}
      >
        <defs>
          <linearGradient id={fillId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#FF6A00" stopOpacity="0.28" />
            <stop offset="100%" stopColor="#7A8B73" stopOpacity="0.06" />
          </linearGradient>
        </defs>
        {area ? <path d={area} fill={`url(#${fillId})`} /> : null}
        {pts.map((p, i) => {
          if (i === 0) return null;
          const prev = pts[i - 1];
          if (prev.elevM == null || p.elevM == null) {
            if (telemetry.totalDistKm > 0 && p.elevM == null) {
              return (
                <rect
                  key={`gap-${i}`}
                  x={xOf(prev.distKm)}
                  y={padT}
                  width={Math.max(1, xOf(p.distKm) - xOf(prev.distKm))}
                  height={innerH}
                  fill="#6B7280"
                  opacity="0.22"
                />
              );
            }
            return null;
          }
          return (
            <line
              key={`e-${i}`}
              x1={xOf(prev.distKm)}
              y1={yOf(prev.elevM)}
              x2={xOf(p.distKm)}
              y2={yOf(p.elevM)}
              stroke={GRADE_COLORS[p.band]}
              strokeWidth="2.6"
              strokeLinecap="round"
            />
          );
        })}
        {pts
          .filter((p) => p.impact && p.elevM != null)
          .map((p, i) => (
            <circle
              key={`imp-${i}`}
              cx={xOf(p.distKm)}
              cy={yOf(p.elevM as number)}
              r="3.2"
              fill="#FF6A00"
              stroke="#121215"
              strokeWidth="1"
            />
          ))}
        <text
          x={4}
          y={padT + 4}
          fill="#9CA3AF"
          fontSize="10"
          className="tabular-nums"
        >
          {Math.round(maxE)}
        </text>
        <text
          x={4}
          y={padT + innerH}
          fill="#9CA3AF"
          fontSize="10"
          className="tabular-nums"
        >
          {Math.round(minE)}
        </text>
        <text
          x={padL}
          y={H - 6}
          fill="#9CA3AF"
          fontSize="10"
          className="tabular-nums"
        >
          0 {copy.km}
        </text>
        <text
          x={W - padR}
          y={H - 6}
          fill="#9CA3AF"
          fontSize="10"
          textAnchor="end"
          className="tabular-nums"
        >
          {telemetry.totalDistKm.toFixed(1)} {copy.km}
        </text>
        {hover && hover.elevM != null ? (
          <>
            <line
              x1={xOf(hover.distKm)}
              y1={padT}
              x2={xOf(hover.distKm)}
              y2={padT + innerH}
              stroke="#F2F2F2"
              strokeOpacity="0.35"
              strokeDasharray="3 3"
            />
            <circle
              cx={xOf(hover.distKm)}
              cy={yOf(hover.elevM)}
              r="4.5"
              fill="#FF6A00"
              stroke="#F2F2F2"
              strokeWidth="1.4"
            />
          </>
        ) : null}
      </svg>
    </div>
  );
}

function GradeLegend({ copy }: { copy: RideTelemetryCopy }) {
  const rows: { band: GradeBand; label: string }[] = [
    { band: "steep_up", label: copy.steepUp },
    { band: "up", label: copy.up },
    { band: "roll", label: copy.roll },
    { band: "down", label: copy.down },
    { band: "steep_down", label: copy.steepDown },
  ];
  return (
    <ul className="mt-3 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-text-secondary">
      {rows.map((r) => (
        <li key={r.band} className="inline-flex items-center gap-1.5">
          <span
            className="h-2 w-2 rounded-full"
            style={{ background: GRADE_COLORS[r.band] }}
          />
          {r.label}
        </li>
      ))}
    </ul>
  );
}

function SensorStrips({
  telemetry,
  copy,
  hover,
  onHover,
  onLeave,
}: {
  telemetry: RideTelemetry;
  copy: RideTelemetryCopy;
  hover: RideSample | null;
  onHover: (s: RideSample | null) => void;
  onLeave: () => void;
}) {
  const strips: {
    key: "speed" | "hr" | "cad" | "power" | "lean";
    label: string;
    unit: string;
    values: (number | null)[];
    color: string;
  }[] = [];
  const pts = telemetry.chart;
  if (telemetry.channels.speed) {
    strips.push({
      key: "speed",
      label: copy.avgSpeed,
      unit: "km/h",
      values: pts.map((p) => p.speedKmh),
      color: "#E8A87C",
    });
  }
  if (telemetry.channels.hr) {
    strips.push({
      key: "hr",
      label: copy.hr,
      unit: "bpm",
      values: pts.map((p) => p.hr),
      color: "#EF4444",
    });
  }
  if (telemetry.channels.cad) {
    strips.push({
      key: "cad",
      label: copy.cad,
      unit: "rpm",
      values: pts.map((p) => p.cad),
      color: "#7A8B73",
    });
  }
  if (telemetry.channels.power) {
    strips.push({
      key: "power",
      label: copy.power,
      unit: "W",
      values: pts.map((p) => p.power),
      color: "#FF6A00",
    });
  }
  if (telemetry.channels.lean) {
    strips.push({
      key: "lean",
      label: copy.lean,
      unit: "°",
      values: pts.map((p) => (p.lean != null ? Math.abs(p.lean) : null)),
      color: "#5B8C9A",
    });
  }
  if (strips.length === 0) return null;

  const total = Math.max(telemetry.totalDistKm, 0.001);
  const pick = (clientX: number, el: SVGSVGElement) => {
    const box = el.getBoundingClientRect();
    const rel = (clientX - box.left) / box.width;
    onHover(nearestSample(telemetry, Math.max(0, Math.min(1, rel)) * total));
  };

  return (
    <div className="mt-4 space-y-3">
      {strips.map((s) => {
        const known = s.values.filter((v): v is number => v != null);
        const min = known.length ? Math.min(...known) : 0;
        const max = known.length ? Math.max(...known) : 1;
        const span = Math.max(max - min, 1);
        const W = 640;
        const H = 44;
        return (
          <div key={s.key}>
            <div className="mb-1 flex justify-between text-[10px] text-text-secondary">
              <span className="font-semibold uppercase tracking-wide">
                {s.label}
              </span>
              <span className="tabular-nums">
                {known.length
                  ? `${Math.round(min)}–${Math.round(max)} ${s.unit}`
                  : "—"}
              </span>
            </div>
            <svg
              viewBox={`0 0 ${W} ${H}`}
              className="w-full rounded-lg bg-[#16161c]"
              onPointerLeave={onLeave}
              onPointerMove={(e) => pick(e.clientX, e.currentTarget)}
            >
              {pts.map((p, i) => {
                if (i === 0) return null;
                const a = s.values[i - 1];
                const b = s.values[i];
                if (a == null || b == null) return null;
                const x1 = (pts[i - 1].distKm / total) * W;
                const x2 = (p.distKm / total) * W;
                const y1 = H - 4 - ((a - min) / span) * (H - 8);
                const y2 = H - 4 - ((b - min) / span) * (H - 8);
                return (
                  <line
                    key={`${s.key}-${i}`}
                    x1={x1}
                    y1={y1}
                    x2={x2}
                    y2={y2}
                    stroke={s.color}
                    strokeWidth="2"
                    strokeLinecap="round"
                  />
                );
              })}
              {hover ? (
                <line
                  x1={(hover.distKm / total) * W}
                  y1={2}
                  x2={(hover.distKm / total) * W}
                  y2={H - 2}
                  stroke="#F2F2F2"
                  strokeOpacity="0.28"
                />
              ) : null}
            </svg>
          </div>
        );
      })}
    </div>
  );
}
