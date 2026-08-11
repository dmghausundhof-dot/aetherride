"use client";

import type { Bike, ComponentSlot } from "@/types";
import { getActiveComponents } from "@/store/useAppStore";
import { slotLabel } from "@/lib/catalog/slots";
import { cn } from "@/lib/utils";
import {
  SCHEMA_ASSET_PATH,
  SCHEMA_DOT_R,
  SCHEMA_HIT_R_MIN,
  SCHEMA_HOTSPOTS,
  SCHEMA_LAYERS,
  SCHEMA_VIEWBOX,
  SCHEMA_VIEWBOX_H,
  SCHEMA_VIEWBOX_W,
  STATUS_COLORS,
  type HotspotStatus,
  type SchemaLayer,
} from "@/lib/garage/schema/anchors";
import {
  HIKING_ANCHORS,
  planBikeSchema,
} from "@/lib/garage/schema/mapper";

interface Hotspot {
  slot: ComponentSlot;
  cx: number;
  cy: number;
  hitR: number;
  status: HotspotStatus;
  label: string;
}

function statusLabelDe(s: HotspotStatus): string {
  if (s === "ok") return "gepflegt";
  if (s === "maintenance") return "Wartung fällig";
  return "Daten fehlen";
}

function LayerShape({ layer }: { layer: SchemaLayer }) {
  if (layer.type === "line") {
    return (
      <line
        x1={layer.x1}
        y1={layer.y1}
        x2={layer.x2}
        y2={layer.y2}
        stroke={layer.stroke}
        strokeWidth={layer.strokeWidth}
        strokeLinecap="round"
      />
    );
  }
  return (
    <rect
      x={layer.x}
      y={layer.y}
      width={layer.width}
      height={layer.height}
      rx={layer.rx}
      fill={layer.fill}
      opacity={0.92}
    />
  );
}

/**
 * G-SCH-04 — diamond-frame bike schema with maintenance hotspots.
 * Assets: public/garage/silhouettes/{road,gravel,mtb,city}.svg
 * Replaces stick-polygon F-GAR-004 silhouette.
 */
export function BikeSchema({
  bike,
  maintenanceSlots = [],
  onSelectSlot,
  selectedSlot,
}: {
  bike: Bike;
  maintenanceSlots?: ComponentSlot[];
  onSelectSlot?: (slot: ComponentSlot) => void;
  selectedSlot?: ComponentSlot | null;
}) {
  const active = getActiveComponents(bike);
  const filled = new Set(active.map((c) => c.slot));
  const maint = new Set(maintenanceSlots);

  const hasRearShock =
    filled.has("rear_shock") ||
    (["mtb_am", "mtb_enduro", "dh", "emtb"] as const).includes(
      bike.category as "mtb_am" | "mtb_enduro" | "dh" | "emtb"
    );

  const plan = planBikeSchema({
    category: bike.category,
    isEbike: bike.isEbike,
    hasRearShock,
  });

  const anchors =
    plan.template != null
      ? SCHEMA_HOTSPOTS[plan.template]
      : HIKING_ANCHORS;

  const layers =
    plan.template != null ? SCHEMA_LAYERS[plan.template] : {};

  const hotspots: Hotspot[] = plan.hotspotSlots
    .map((slot) => {
      const a = anchors[slot];
      if (!a) return null;
      const status: HotspotStatus = !filled.has(slot)
        ? "missing"
        : maint.has(slot)
          ? "maintenance"
          : "ok";
      return {
        slot,
        cx: a.cx,
        cy: a.cy,
        hitR: Math.max(a.hitR, SCHEMA_HIT_R_MIN),
        status,
        label: a.label_de || slotLabel(slot),
      };
    })
    .filter((h): h is Hotspot => h != null);

  const title = plan.template
    ? `${bike.name} Schema`
    : `${bike.name} Ausrüstung`;

  return (
    <div className="rounded-2xl border border-border bg-surface p-3">
      <svg
        viewBox={SCHEMA_VIEWBOX}
        className="h-auto w-full"
        role="img"
        aria-label={title}
      >
        <title>{title}</title>
        {plan.template ? (
          <image
            href={SCHEMA_ASSET_PATH[plan.template]}
            x={0}
            y={0}
            width={SCHEMA_VIEWBOX_W}
            height={SCHEMA_VIEWBOX_H}
            preserveAspectRatio="xMidYMid meet"
          />
        ) : (
          <>
            <rect
              width={SCHEMA_VIEWBOX_W}
              height={SCHEMA_VIEWBOX_H}
              fill="#0A1210"
              rx="12"
            />
            <text
              x={500}
              y={80}
              textAnchor="middle"
              fill="#A8B5AE"
              fontSize="28"
              fontFamily="system-ui,sans-serif"
            >
              Wander-Ausrüstung
            </text>
          </>
        )}

        {/* Optional layers: shock (fully), motor/battery (eBike) */}
        {plan.showShock && layers.rear_shock && (
          <LayerShape layer={layers.rear_shock} />
        )}
        {plan.showEbike && layers.motor && (
          <LayerShape layer={layers.motor} />
        )}
        {plan.showEbike && layers.battery && (
          <LayerShape layer={layers.battery} />
        )}

        {hotspots.map((h) => {
          const selected = selectedSlot === h.slot;
          return (
            <g
              key={h.slot}
              className="cursor-pointer"
              role="button"
              tabIndex={0}
              aria-label={`${h.label} — ${statusLabelDe(h.status)}`}
              onClick={() => onSelectSlot?.(h.slot)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onSelectSlot?.(h.slot);
                }
              }}
            >
              {/* Invisible hit target ≥44pt */}
              <circle
                cx={h.cx}
                cy={h.cy}
                r={h.hitR}
                fill="transparent"
                stroke="none"
              />
              {selected && (
                <circle
                  cx={h.cx}
                  cy={h.cy}
                  r={h.hitR}
                  fill="none"
                  stroke="#FF6B35"
                  strokeWidth="3"
                  opacity="0.9"
                />
              )}
              <circle
                cx={h.cx}
                cy={h.cy}
                r={SCHEMA_DOT_R}
                fill={STATUS_COLORS[h.status]}
                stroke="#0A1210"
                strokeWidth="2"
                pointerEvents="none"
              />
              <title>
                {h.label} — {statusLabelDe(h.status)}
              </title>
            </g>
          );
        })}
      </svg>
      <div className="mt-2 flex flex-wrap gap-3 text-[10px] text-text-secondary">
        <Legend color={STATUS_COLORS.ok} label="gepflegt" />
        <Legend color={STATUS_COLORS.maintenance} label="Wartung" />
        <Legend color={STATUS_COLORS.missing} label="fehlt" />
      </div>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1">
      <span
        className={cn("inline-block h-2.5 w-2.5 rounded-full")}
        style={{ background: color }}
      />
      {label}
    </span>
  );
}

/** @deprecated Use BikeSchema — kept as alias for existing imports */
export { BikeSchema as BikeSilhouette };
