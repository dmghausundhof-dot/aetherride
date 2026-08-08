"use client";

import type { Bike, BikeCategory, ComponentSlot } from "@/types";
import { getActiveComponents } from "@/store/useAppStore";
import { slotLabel } from "@/lib/catalog/slots";
import { cn } from "@/lib/utils";

type HotspotStatus = "ok" | "missing" | "maintenance";

interface Hotspot {
  slot: ComponentSlot;
  cx: number;
  cy: number;
  status: HotspotStatus;
}

function statusColor(s: HotspotStatus): string {
  if (s === "ok") return "#22C55E";
  if (s === "maintenance") return "#EAB308";
  return "#6B7280";
}

/** Spec F-GAR-004: 8 Silhouetten — Hardtail, Fully-Trail, Fully-Enduro, DH, Gravel, Road, Urban, E-MTB */
function silhouetteKind(
  category: BikeCategory
):
  | "hardtail"
  | "trail"
  | "enduro"
  | "dh"
  | "gravel"
  | "road"
  | "urban"
  | "emtb"
  | "hiking" {
  switch (category) {
    case "mtb_trail":
      return "hardtail"; // Trail ohne Heckdämpfer-Slot → Hardtail-Schema; mit Shock → trail
    case "mtb_am":
      return "trail";
    case "mtb_enduro":
      return "enduro";
    case "dh":
      return "dh";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "urban":
    case "etrekking":
      return "urban";
    case "emtb":
      return "emtb";
    case "hiking":
      return "hiking";
    default:
      return "trail";
  }
}

function framePath(kind: ReturnType<typeof silhouetteKind>): string {
  switch (kind) {
    case "hardtail":
      return "M100 70 L175 55 L240 130 L115 130 Z";
    case "trail":
      return "M100 75 L170 55 L235 130 L110 130 Z";
    case "enduro":
      return "M95 80 L165 50 L230 135 L105 135 Z";
    case "dh":
      return "M90 85 L155 48 L225 140 L100 140 Z";
    case "gravel":
      return "M100 68 L165 68 L235 128 L100 128 Z";
    case "road":
      return "M95 65 L170 62 L240 125 L100 125 Z";
    case "urban":
      return "M105 75 L180 75 L245 130 L110 130 Z";
    case "emtb":
      return "M95 78 L168 52 L232 132 L108 132 Z";
    default:
      return "M100 75 L170 55 L235 130 L110 130 Z";
  }
}

function wheelRadius(kind: ReturnType<typeof silhouetteKind>): number {
  if (kind === "road" || kind === "gravel" || kind === "urban") return 32;
  if (kind === "dh") return 36;
  return 38;
}

/**
 * F-GAR-004 — schematisches SVG-Bike mit Hotspots (kein 3D).
 * Zustandsfarbe: gepflegt / Wartung fällig / Daten fehlen.
 */
export function BikeSilhouette({
  bike,
  maintenanceSlots = [],
  onSelectSlot,
}: {
  bike: Bike;
  maintenanceSlots?: ComponentSlot[];
  onSelectSlot?: (slot: ComponentSlot) => void;
}) {
  const active = getActiveComponents(bike);
  const filled = new Set(active.map((c) => c.slot));
  const maint = new Set(maintenanceSlots);
  const kind = silhouetteKind(bike.category);
  // Hardtail vs Fully-Trail: wenn Heckdämpfer verbaut/erwartet → trail-Zeichnung
  const hasRearShock =
    filled.has("rear_shock") ||
    ["mtb_am", "mtb_enduro", "dh", "emtb"].includes(bike.category);
  const drawKind =
    kind === "hardtail" && hasRearShock ? "trail" : kind;

  const spots: { slot: ComponentSlot; cx: number; cy: number }[] =
    drawKind === "hiking"
      ? [
          { slot: "hiking_shoes", cx: 80, cy: 140 },
          { slot: "hiking_pack", cx: 160, cy: 70 },
          { slot: "hiking_poles", cx: 240, cy: 100 },
        ]
      : [
          { slot: "fork", cx: 70, cy: drawKind === "dh" ? 100 : 95 },
          { slot: "tire_front", cx: 55, cy: 145 },
          { slot: "handlebar", cx: 95, cy: drawKind === "road" ? 50 : 55 },
          { slot: "stem", cx: 105, cy: 70 },
          { slot: "frame", cx: 160, cy: 100 },
          { slot: "seatpost", cx: 195, cy: 55 },
          { slot: "saddle", cx: 200, cy: 40 },
          { slot: "rear_shock", cx: 175, cy: 85 },
          { slot: "tire_rear", cx: 250, cy: 145 },
          { slot: "cassette", cx: 255, cy: 130 },
          { slot: "brake_front", cx: 60, cy: 120 },
          { slot: "chain", cx: 200, cy: 135 },
          { slot: "motor", cx: 150, cy: 125 },
          { slot: "battery", cx: 155, cy: 105 },
        ];

  const hotspots: Hotspot[] = spots
    .filter((s) => {
      if (s.slot === "motor" || s.slot === "battery") {
        return bike.isEbike || drawKind === "emtb";
      }
      if (s.slot === "rear_shock") {
        return hasRearShock && !["road", "gravel", "urban", "hiking"].includes(bike.category);
      }
      return true;
    })
    .map((s) => ({
      ...s,
      status: !filled.has(s.slot)
        ? "missing"
        : maint.has(s.slot)
          ? "maintenance"
          : "ok",
    }));

  const r = wheelRadius(drawKind);

  return (
    <div className="rounded-2xl border border-border bg-surface p-3">
      <div className="mb-1 flex items-center justify-between text-[10px] text-text-secondary">
        <span>Schema · {drawKind}</span>
        <span>Hotspots</span>
      </div>
      <svg viewBox="0 0 320 200" className="h-auto w-full" role="img">
        <title>{bike.name} Schema ({drawKind})</title>
        <defs>
          <linearGradient id="groundGrad" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="#243830" stopOpacity="0.3" />
            <stop offset="50%" stopColor="#243830" />
            <stop offset="100%" stopColor="#243830" stopOpacity="0.3" />
          </linearGradient>
        </defs>
        <line
          x1="20"
          y1="170"
          x2="300"
          y2="170"
          stroke="url(#groundGrad)"
          strokeWidth="2"
        />
        <circle
          cx="60"
          cy="145"
          r={r}
          fill="none"
          stroke="#A8B5AE"
          strokeWidth="3"
        />
        <circle
          cx="250"
          cy="145"
          r={r}
          fill="none"
          stroke="#A8B5AE"
          strokeWidth="3"
        />
        {/* Speichen-Andeutung */}
        {[0, 60, 120].map((deg) => (
          <g key={deg}>
            <line
              x1="60"
              y1="145"
              x2={60 + Math.cos((deg * Math.PI) / 180) * (r - 4)}
              y2={145 + Math.sin((deg * Math.PI) / 180) * (r - 4)}
              stroke="#243830"
              strokeWidth="1"
            />
            <line
              x1="250"
              y1="145"
              x2={250 + Math.cos((deg * Math.PI) / 180) * (r - 4)}
              y2={145 + Math.sin((deg * Math.PI) / 180) * (r - 4)}
              stroke="#243830"
              strokeWidth="1"
            />
          </g>
        ))}
        <path
          d={framePath(drawKind)}
          fill="none"
          stroke="#1A5C45"
          strokeWidth={drawKind === "dh" ? 5 : 4}
          strokeLinejoin="round"
        />
        <path
          d={
            drawKind === "dh"
              ? "M90 85 L55 150"
              : "M95 70 L60 145"
          }
          fill="none"
          stroke="#FF6B35"
          strokeWidth={drawKind === "dh" ? 4 : 3}
        />
        <path
          d="M170 55 L250 145 M110 130 L250 145"
          fill="none"
          stroke="#1A5C45"
          strokeWidth="3"
        />
        {hasRearShock && drawKind !== "hardtail" && (
          <line
            x1="165"
            y1="70"
            x2="195"
            y2="100"
            stroke="#FF6B35"
            strokeWidth="3"
            strokeLinecap="round"
          />
        )}
        <line
          x1={drawKind === "road" ? 75 : 80}
          y1={drawKind === "road" ? 48 : 55}
          x2={drawKind === "road" ? 120 : 115}
          y2={drawKind === "road" ? 52 : 55}
          stroke="#F0F5F2"
          strokeWidth="3"
        />
        <ellipse cx="200" cy="40" rx="18" ry="6" fill="#F0F5F2" />
        {(bike.isEbike || drawKind === "emtb") && (
          <>
            <rect
              x="135"
              y="115"
              width="36"
              height="20"
              rx="4"
              fill="#FF6B35"
              opacity="0.9"
            />
            <rect
              x="145"
              y="95"
              width="28"
              height="14"
              rx="3"
              fill="#1A5C45"
              opacity="0.85"
            />
          </>
        )}

        {hotspots.map((h) => (
          <g
            key={h.slot}
            className="cursor-pointer"
            onClick={() => onSelectSlot?.(h.slot)}
          >
            <circle
              cx={h.cx}
              cy={h.cy}
              r="9"
              fill={statusColor(h.status)}
              stroke="#0A1210"
              strokeWidth="2"
            />
            <title>
              {slotLabel(h.slot)} —{" "}
              {h.status === "ok"
                ? "gepflegt"
                : h.status === "maintenance"
                  ? "Wartung fällig"
                  : "Daten fehlen"}
            </title>
          </g>
        ))}
      </svg>
      <div className="mt-2 flex flex-wrap gap-3 text-[10px] text-text-secondary">
        <Legend color="#22C55E" label="gepflegt" />
        <Legend color="#EAB308" label="Wartung" />
        <Legend color="#6B7280" label="fehlt" />
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
