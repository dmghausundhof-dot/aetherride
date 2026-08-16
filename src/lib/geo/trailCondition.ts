/**
 * Trailforks Condition Layer — Attribution + Deep-Links (kein Geometry-Mirror).
 * Status-Proxy: Open-Meteo trailHint bleibt am Hof — nicht als
 * Trailforks-„Zustand“ auf jeden Pin.
 */

import {
  TRAILFORKS_ATTRIBUTION,
  trailforksMode,
  trailforksRegionUrl,
  trailforksTrailUrl,
} from "@/lib/geo/trailforks";
import { allowDemoContent } from "@/lib/config/allowDemoContent";

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
    id: "tf-freiburg",
    name: "Freiburg / Schauinsland",
    center: [7.9, 47.95],
    difficulty: "S1–S2",
    regionId: "freiburg",
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
  {
    id: "tf-kitz",
    name: "Kitzbühel / Kirchberg",
    center: [12.39, 47.45],
    difficulty: "S1–S2",
    regionId: "kitzbuehel",
  },
  {
    id: "tf-tegernsee",
    name: "Tegernsee Trails",
    center: [11.76, 47.71],
    difficulty: "S1–S2",
    regionId: "tegernsee",
  },
  {
    id: "tf-bodensee",
    name: "Bodensee / Überlingen",
    center: [9.18, 47.72],
    difficulty: "S0–S1",
    regionId: "bodensee",
  },
  {
    id: "tf-stuttgart",
    name: "Stuttgart Umland",
    center: [9.16, 48.76],
    difficulty: "S0–S1",
    regionId: "stuttgart",
  },
  {
    id: "tf-vosges",
    name: "Vosges / Ballon d'Alsace",
    center: [6.84, 47.82],
    difficulty: "S1–S2",
    regionId: "vosges",
  },
  {
    id: "tf-morzine",
    name: "Morzine / Portes du Soleil",
    center: [6.71, 46.18],
    difficulty: "S2–S3",
    regionId: "morzine",
  },
  {
    id: "tf-annecy",
    name: "Annecy / Semnoz",
    center: [6.13, 45.9],
    difficulty: "S1–S2",
    regionId: "annecy",
  },
  {
    id: "tf-provence",
    name: "Luberon / Provence",
    center: [5.23, 43.84],
    difficulty: "S0–S1",
    regionId: "luberon",
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

export function buildTrailforksPins(
  _trailHint?: string | null,
  near?: { lat: number; lon: number } | null
): {
  mode: typeof trailforksMode;
  pins: TrailforksPin[];
  disclaimer: string;
} {
  if (!allowDemoContent()) {
    return {
      mode: trailforksMode,
      pins: [],
      disclaimer:
        trailforksMode === "enabled"
          ? "Trailforks-Zustand aktiv (Partnerschaft)."
          : "Keine Beispiel-Pins — Trailforks-Partnerschaft ausstehend.",
    };
  }
  let pins: TrailforksPin[] = SEED_PINS.map((p) => ({
    ...p,
    // Wetter bleibt am Hof. Pins: Name + Deep-Link, kein Fake-nass/trocken.
    condition: "unknown" as const,
    conditionLabel: "",
    conditionSource: "trailforks" as const,
    openUrl: p.trailId
      ? trailforksTrailUrl(p.trailId)
      : trailforksRegionUrl(p.regionId),
    attribution: TRAILFORKS_ATTRIBUTION,
  }));

  if (near && Number.isFinite(near.lat) && Number.isFinite(near.lon)) {
    pins = [...pins].sort((a, b) => {
      const da =
        (a.center[0] - near.lon) ** 2 + (a.center[1] - near.lat) ** 2;
      const db =
        (b.center[0] - near.lon) ** 2 + (b.center[1] - near.lat) ** 2;
      return da - db;
    });
  }

  const disclaimer =
    trailforksMode === "attribution_only"
      ? "Beispiel-Regionen mit Link zu Trailforks — kein Live-Zustand in FlowLine."
      : trailforksMode === "enabled"
        ? "Trailforks-Zustand aktiv (Partnerschaft)."
        : "Trailforks-Partnerschaft ausstehend. Wetter nur am Hof, nicht als Trail-Zustand.";

  return { mode: trailforksMode, pins, disclaimer };
}
