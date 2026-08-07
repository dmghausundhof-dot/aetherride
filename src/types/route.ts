import type { NavStep } from "@/lib/routing/navSteps";

/** Aktive Navigationsroute — Bridge Discover/Home → Ride */

export interface ActiveRoute {
  id: string;
  name: string;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  mtbScale?: string;
  surface?: string;
  /** Genau drei Gründe, wenn aus Vorschlag */
  reasons?: [string, string, string];
  /** LineString [lng, lat] — Demo oder Engine */
  geometry: GeoJSON.LineString | null;
  /** F-NAV-003 Engine- oder Demo-Steps */
  steps?: NavStep[];
  source: "suggestion" | "engine" | "import";
  setAt: string;
}

/** Vom Nutzer gespeicherte Tour (Discover Library) */
export interface SavedRoute {
  id: string;
  name: string;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  mtbScale?: string;
  surface?: string;
  loop?: boolean;
  reasons?: [string, string, string];
  matchScore?: number;
  savedAt: string;
  source: "suggestion" | "engine" | "import";
  /** Persistierte Geometrie (Engine / Hybrid / Demo) */
  geometry?: GeoJSON.LineString | null;
  /** Optionale Waypoints für erneutes Planen */
  waypoints?: { role: "start" | "via" | "end"; lngLat: [number, number]; label?: string }[];
  /** Hybrid-/Trail-Segmente für Map-Layer nach Reload */
  layers?: {
    approach?: GeoJSON.LineString;
    tour?: GeoJSON.LineString;
    trail?: GeoJSON.LineString;
  };
}

export type RideLiveLayer = "map" | "data" | "suspension";

export type MountCheck = "unknown" | "mounted" | "handheld";

export interface NavCue {
  id: string;
  /** Distanz vom Track-Start bis zum Manöver (m) */
  distanceAlongM: number;
  instruction: string;
  bearingDeg: number;
}
