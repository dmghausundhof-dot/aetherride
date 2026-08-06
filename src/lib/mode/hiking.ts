/**
 * Spec 2.8 — Wanderprofil (P0)
 *
 * Enthalten: HIKING-Routing, TbT, Offline, Tracking, Höhenprofil, Ausrüstung.
 * Nicht enthalten: Fahrwerk, Bracketing, Kompatibilitäts-Engine.
 * MUSS: Bike-UI ausblenden, nicht leer anzeigen.
 */

export type AppMode = "bike" | "hiking";

export interface HikingGearItem {
  id: string;
  label: string;
  essential: boolean;
}

export const HIKING_GEAR_DEFAULT: HikingGearItem[] = [
  { id: "boots", label: "Wanderschuhe", essential: true },
  { id: "map", label: "Karte / Offline-Region", essential: true },
  { id: "water", label: "Wasser", essential: true },
  { id: "layers", label: "Wetterschutz", essential: true },
  { id: "firstaid", label: "Erste Hilfe", essential: true },
  { id: "poles", label: "Stöcke", essential: false },
  { id: "gps", label: "Powerbank", essential: false },
];

export function uiVisibilityForMode(mode: AppMode) {
  if (mode === "hiking") {
    return {
      garageBikeFeatures: false,
      bracketing: false,
      compatibility: false,
      suspensionMetrics: false,
      setupCoach: false,
      shopBikeParts: false,
      hikingGear: true,
      routingProfile: "HIKING" as const,
      sportType: "hiking" as const,
    };
  }
  return {
    garageBikeFeatures: true,
    bracketing: true,
    compatibility: true,
    suspensionMetrics: true,
    setupCoach: true,
    shopBikeParts: true,
    hikingGear: false,
    routingProfile: null,
    sportType: null,
  };
}
