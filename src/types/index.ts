// AetherRide Core Data Models

export type BikeType =
  | "all_mountain"
  | "enduro"
  | "gravel"
  | "road"
  | "e_mtb"
  | "e_gravel"
  | "hiking";

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

export interface Component {
  id: string;
  bikeId: string;
  category: ComponentCategory;
  manufacturer: string;
  model: string;
  specs: Record<string, string | number | boolean>;
  serialNumber?: string;
  purchaseDate?: string;
  notes?: string;
  currentSettings: Record<string, string | number>;
}

export interface Setup {
  id: string;
  bikeId: string;
  name: string;
  description?: string;
  settingsSnapshot: Record<string, string | number>;
  createdAt: string;
  linkedRideId?: string;
  isActive: boolean;
}

export interface Bike {
  id: string;
  name: string;
  type: BikeType;
  year?: number;
  frameSize?: string;
  weightKg?: number;
  color?: string;
  isDefault: boolean;
  createdAt: string;
  updatedAt: string;
  components: Component[];
  setups: Setup[];
}

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
  bikeId: string;
  setupId?: string;
  sportType: BikeType;
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
  fitnessIndicators: {
    avgRideDurationMin: number;
    weeklyDistanceKm: number;
  };
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
}

export interface Recommendation {
  id: string;
  type: "setup" | "route" | "product" | "technique";
  title: string;
  content: string;
  reasoning: string;
  score: number;
  relatedBikeId?: string;
  relatedRideId?: string;
  status: "shown" | "accepted" | "dismissed";
}

export type TabId = "home" | "garage" | "ride" | "discover" | "shop";
