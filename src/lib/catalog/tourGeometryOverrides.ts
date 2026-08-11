/**
 * Optionale redaktionelle Tour-Linien (GeoJSON [lng,lat]).
 * Wenn gesetzt, wird Live-Routing für diese Tour übersprungen.
 *
 * Zum Kuratieren: GPX → Koordinaten extrahieren und hier eintragen,
 * oder Datei data/catalog/tour-geometry-overrides.json (optional geladen).
 */

export type GeometryOverride = {
  coordinates: [number, number][];
  distanceM?: number;
  durationS?: number;
  shape?: "loop" | "out_and_back" | "point_to_point";
  source?: string;
};

/** Eingebaute Overrides für Kern-Touren (vereinfachte, ehrliche Annäherungen) */
const BUILTIN: Record<string, GeometryOverride> = {
  // Heidelberg City — grober Ring (kuratiert, kein Fake-Singletrack)
  "r-heidelberg-city": {
    shape: "loop",
    source: "editorial-approx",
    distanceM: 14000,
    durationS: 50 * 60,
    coordinates: [
      [8.675, 49.41],
      [8.69, 49.415],
      [8.705, 49.412],
      [8.71, 49.402],
      [8.695, 49.398],
      [8.68, 49.4],
      [8.675, 49.41],
    ],
  },
  // Bodensee Südufer — Ost-West-Korridor
  "r-bodensee-road": {
    shape: "point_to_point",
    source: "editorial-approx",
    distanceM: 72000,
    durationS: 200 * 60,
    coordinates: [
      [9.05, 47.66],
      [9.12, 47.655],
      [9.2, 47.66],
      [9.28, 47.658],
      [9.36, 47.655],
    ],
  },
  // Freiburg City
  "r-freiburg-city": {
    shape: "loop",
    source: "editorial-approx",
    distanceM: 18500,
    durationS: 55 * 60,
    coordinates: [
      [7.84, 47.995],
      [7.855, 48.0],
      [7.87, 47.998],
      [7.865, 47.985],
      [7.845, 47.988],
      [7.84, 47.995],
    ],
  },
};

let fileOverrides: Record<string, GeometryOverride> | null = null;

/** Optional JSON file merge (server-only, best-effort). */
export function getTourGeometryOverride(
  tourId: string
): GeometryOverride | null {
  if (fileOverrides === null && typeof process !== "undefined") {
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const fs = require("fs") as typeof import("fs");
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const path = require("path") as typeof import("path");
      const p = path.join(
        process.cwd(),
        "data/catalog/tour-geometry-overrides.json"
      );
      if (fs.existsSync(p)) {
        fileOverrides = JSON.parse(fs.readFileSync(p, "utf8")) as Record<
          string,
          GeometryOverride
        >;
      } else {
        fileOverrides = {};
      }
    } catch {
      fileOverrides = {};
    }
  }
  return (
    (fileOverrides && fileOverrides[tourId]) || BUILTIN[tourId] || null
  );
}
