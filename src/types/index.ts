// AetherRide Core Data Models – re-export Garage-Domain + Ride/Shop

export type {
  Bike,
  BikeCategory,
  BikeComponent,
  BikeType,
  BracketingParameter,
  BracketingRun,
  BracketingSeries,
  CatalogBikeVariant,
  CatalogManufacturer,
  FrameSizeGeometry,
  CompatibilityResult,
  CompatibilityVerdict,
  ComponentModel,
  ComponentSlot,
  MaintenanceInterval,
  MaintenanceLogEntry,
  RideFeedback,
  Setup,
  SetupCondition,
  SetupValue,
  TypedAttribute,
  WheelSize,
} from "./garage";

export { SLOT_GROUPS } from "./garage";

/** Legacy category alias used by older demo components */
export type ComponentCategory =
  | "fork"
  | "shock"
  | "tire_front"
  | "tire_rear"
  | "wheelset"
  | "drivetrain"
  | "brakes"
  | "cockpit"
  | "saddle"
  | "motor"
  | "battery"
  | "display"
  | "other";

export interface SensorMetrics {
  gForcePeak: number;
  gForceRms: number;
  leanAngleMax: number;
  impactCount: number;
  flowScore: number;
  estimatedTravelUsagePct?: number;
  avgCadence?: number;
  maxSpeed?: number;
}

export interface Ride {
  id: string;
  /** Leer = Freeride ohne Garage-Bike */
  bikeId?: string;
  setupId?: string;
  sportType: import("./garage").BikeType;
  startTime: string;
  endTime?: string;
  distanceM: number;
  elevationGainM: number;
  durationSec: number;
  track?: { lat: number; lng: number; elev?: number; time: number }[];
  summaryMetrics: SensorMetrics;
  motorData?: {
    avgSoc: number;
    minSoc: number;
    avgRiderPower: number;
    avgCadence: number;
    totalOdometer: number;
  };
  /** Assist-Log (Schätzung/manuell/OEM) */
  assistSummary?: import("@/lib/ebike/assistLog").AssistRideSummary;
  notes?: string;
}

export interface RiderProfile {
  style: "aggressive" | "flow" | "efficient" | "explorative";
  skillLevel: 1 | 2 | 3 | 4 | 5;
  preferences: {
    preferSteep: boolean;
    preferTechnical: boolean;
    preferFlow: boolean;
    eBikeAssistPreference: "eco" | "tour" | "sport" | "turbo";
  };
  /** F-AI-002: erklärbare Terrainverteilung (Summe ≈ 100) */
  terrainShare?: {
    s0s1: number;
    s2: number;
    s3plus: number;
    gravelRoad: number;
  };
  /** Fahrstil-Indikatoren — korrigierbar, nicht Blackbox-Embedding */
  styleIndicators?: {
    brakeIntensityBeforeCorners: number; // 0–100
    timeOver04gLateralPct: number;
    impactsPerHour: number;
    jumpsPerRide: number;
  };
  fitnessIndicators: {
    avgRideDurationMin: number;
    weeklyDistanceKm: number;
  };
  riderWeightKg?: number;
}

export interface Product {
  id: string;
  name: string;
  category: string;
  manufacturer: string;
  price: number;
  imageUrl?: string;
  compatibilityTags: string[];
  description: string;
  componentModelId?: string;
}

export interface Recommendation {
  id: string;
  type: "setup" | "route" | "product" | "technique" | "maintenance";
  title: string;
  content: string;
  reasoning: string;
  score: number;
  relatedBikeId?: string;
  relatedRideId?: string;
  /** Shop-Produkt für Deep-Link (type === "product") */
  relatedProductId?: string;
  /** F-AI-003 strukturierte Setup-Felder — kein Text-Parsing nötig */
  setupDetail?: {
    expectedEffect: string;
    limits: string;
    confidence: "low" | "medium" | "high";
  };
  status: "shown" | "accepted" | "dismissed";
}

export type TabId = "home" | "garage" | "ride" | "discover" | "shop";
