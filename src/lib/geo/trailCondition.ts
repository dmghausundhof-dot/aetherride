/**
 * Trailforks Condition Layer — Attribution + Deep-Links (kein Geometry-Mirror).
 * Status-Proxy: Open-Meteo trailHint bis Partnership.
 */

import {
  TRAILFORKS_ATTRIBUTION,
  trailforksMode,
  trailforksRegionUrl,
  trailforksTrailUrl,
} from "@/lib/geo/trailforks";

export type TrailCondition =
  | "unknown"
  | "dry_likely"
  | "damp_possible"
  | "wet_likely"
  | "closed";

export interface TrailforksPin {
  id: string;
  name: string;
  /** [lng, lat] */
  center: [number, number];
  difficulty?: string;
  regionId: string | number;
  trailId?: string | number;
  condition: TrailCondition;
  conditionLabel: string;
  conditionSource: "weather_proxy" | "trailforks" | "manual";
  openUrl: string;
  attribution: string;
}

const SEED_PINS: Omit<
  TrailforksPin,
  "condition" | "conditionLabel" | "conditionSource" | "openUrl" | "attribution"
>[] = [
  {
    id: "tf-kaltenbronn",
    name: "Kaltenbronn Trails",
    center: [8.425, 48.642],
    difficulty: "S1–S2",
    regionId: "schwarzwald",
    trailId: undefined,
  },
  {
    id: "tf-alpbach",
    name: "Alpbachtal Bikepark Area",
    center: [11.944, 47.399],
    difficulty: "S2–S3",
    regionId: "alpbachtal",
  },
  {
    id: "tf-soell",
    name: "Söll Flow Trails",
    center: [12.192, 47.505],
    difficulty: "S1",
    regionId: "wilder-kaiser",
  },
];

export function conditionFromTrailHint(
  hint?: string | null
): { condition: TrailCondition; label: string } {
  if (hint === "wet_likely")
    return { condition: "wet_likely", label: "eher nass (Wetter-Proxy)" };
  if (hint === "damp_possible")
    return { condition: "damp_possible", label: "feucht möglich (Wetter-Proxy)" };
  if (hint === "dry_likely")
    return { condition: "dry_likely", label: "eher trocken (Wetter-Proxy)" };
  return { condition: "unknown", label: "Zustand unbekannt" };
}

export function buildTrailforksPins(trailHint?: string | null): {
  mode: typeof trailforksMode;
  pins: TrailforksPin[];
  disclaimer: string;
} {
  const { condition, label } = conditionFromTrailHint(trailHint);
  const pins: TrailforksPin[] = SEED_PINS.map((p) => ({
    ...p,
    condition,
    conditionLabel: label,
    conditionSource: "weather_proxy",
    openUrl: p.trailId
      ? trailforksTrailUrl(p.trailId)
      : trailforksRegionUrl(p.regionId),
    attribution: TRAILFORKS_ATTRIBUTION,
  }));

  const disclaimer =
    trailforksMode === "attribution_only"
      ? "Trailforks nur als Deep-Link + Attribution — kein Status-/Geometrie-Mirror ohne Partnerschaft."
      : trailforksMode === "enabled"
        ? "Trailforks Condition Layer aktiv (Partnerschaft)."
        : "Trailforks-Partnerschaft ausstehend — Wetter-Proxy als Status-Hinweis.";

  return { mode: trailforksMode, pins, disclaimer };
}
