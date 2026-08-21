/**
 * Honest A–B variants: same profile + overlay, different Valhalla costing.
 * GraphHopper/ORS have no matching delta — UI greys the chips.
 */

import type { ValhallaCosting } from "@/lib/routing/profiles";

export const ROUTE_VARIANTS = ["planned", "flatter", "unpaved"] as const;
export type RouteVariant = (typeof ROUTE_VARIANTS)[number];

export const VARIANT_VALHALLA_ONLY =
  "Weniger hm und mehr Schotter nur mit Live-Strecke — du siehst die geplante Linie.";

const FLATTER_HILLS = 0.45;
const UNPAVED_AVOID = 0.4;
const UNPAVED_ROADS = 0.55;

export function parseRouteVariant(raw: unknown): RouteVariant {
  const v = String(raw ?? "")
    .trim()
    .toLowerCase();
  if (v === "flatter" || v === "unpaved" || v === "planned") return v;
  return "planned";
}

function clamp01(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

/** Clone costing. Does not touch maxMtbScale / trailFitsBikeCategory. */
export function applyRouteVariant(
  costing: ValhallaCosting,
  variant: RouteVariant
): ValhallaCosting {
  if (variant === "planned") return costing;
  const bike = costing.costing_options.bicycle;
  if (costing.costing === "bicycle" && bike) {
    const next = { ...bike };
    if (variant === "flatter") {
      next.use_hills = clamp01(bike.use_hills * FLATTER_HILLS);
    } else {
      next.avoid_bad_surfaces = clamp01(bike.avoid_bad_surfaces * UNPAVED_AVOID);
      next.use_roads = clamp01(bike.use_roads * UNPAVED_ROADS);
    }
    return { costing: "bicycle", costing_options: { bicycle: next } };
  }
  const ped = costing.costing_options.pedestrian;
  if (costing.costing === "pedestrian" && ped && variant === "flatter") {
    return {
      costing: "pedestrian",
      costing_options: {
        pedestrian: {
          ...ped,
          use_hills: clamp01(ped.use_hills * FLATTER_HILLS),
        },
      },
    };
  }
  return costing;
}

export function variantNeedsValhalla(variant: RouteVariant): boolean {
  return variant !== "planned";
}
