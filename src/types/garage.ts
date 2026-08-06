/**
 * AetherRide Garage Domain – Spec F-GAR / F-SET / DM-02…DM-07
 * Clientseitige Modelle für die Web-Implementierung der Spec-P0-Garage.
 */

export type BikeCategory =
  | "mtb_trail"
  | "mtb_am"
  | "mtb_enduro"
  | "dh"
  | "gravel"
  | "road"
  | "urban"
  | "emtb"
  | "etrekking"
  | "hiking";

/** Legacy-Alias aus älterem Demo-Code → Spec-Kategorie */
export type BikeType =
  | "all_mountain"
  | "enduro"
  | "gravel"
  | "road"
  | "e_mtb"
  | "e_gravel"
  | "hiking";

export type WheelSize = "27_5" | "29" | "700c" | "650b";

export type AttributeSource =
  | "oem"
  | "manufacturer_doc"
  | "editorial"
  | "user_input"
  | "community";

export type AttributeConfidence =
  | "oem"
  | "manufacturer_doc"
  | "editorial"
  | "community"
  | "user_input";

export type CompatibilityVerdict =
  | "COMPATIBLE"
  | "CONDITIONAL"
  | "INCOMPATIBLE"
  | "INSUFFICIENT_DATA";

export type RuleSeverity = "safety_critical" | "functional" | "fitment";

export type SetupCondition =
  | "dry"
  | "wet"
  | "mixed"
  | "bikepark"
  | "race"
  | "general";

export type MaintenancePerformer = "workshop" | "self";

export type BracketingParameter =
  | "fork.air_pressure_psi"
  | "fork.rebound"
  | "fork.lsc"
  | "fork.hsc"
  | "fork.sag_pct"
  | "shock.air_pressure_psi"
  | "shock.rebound"
  | "shock.lsc"
  | "shock.hsc"
  | "shock.sag_pct"
  | "tire.front_psi"
  | "tire.rear_psi";

/** Spec F-GAR-002 Pflicht-Slots (MTB/E-MTB + Gravel/Road-Erweiterungen) */
export type ComponentSlot =
  | "frame"
  | "fork"
  | "rear_shock"
  | "headset"
  | "stem"
  | "handlebar"
  | "grips"
  | "seatpost"
  | "saddle"
  | "front_hub"
  | "rear_hub"
  | "front_rim"
  | "rear_rim"
  | "tire_front"
  | "tire_rear"
  | "tire_insert_front"
  | "tire_insert_rear"
  | "cassette"
  | "chain"
  | "crankset"
  | "chainring"
  | "rear_derailleur"
  | "shifter"
  | "front_derailleur"
  | "bottom_bracket"
  | "brake_front"
  | "brake_rear"
  | "rotor_front"
  | "rotor_rear"
  | "brake_pads_front"
  | "brake_pads_rear"
  | "pedals"
  | "bar_tape"
  | "motor"
  | "battery"
  | "display"
  | "hiking_shoes"
  | "hiking_pack"
  | "hiking_poles";

export interface TypedAttribute {
  key: string;
  valueText?: string;
  valueNum?: number;
  valueEnum?: string;
  /** Explizit „nicht zutreffend“ vs. fehlend (Spec DM-04) */
  notApplicable?: boolean;
  source: AttributeSource;
  verifiedAt: string;
  unit?: string;
}

export interface AdjusterDef {
  key: string;
  label: string;
  unit: string;
  min?: number;
  max?: number;
  step?: number;
  totalClicks?: number;
  reference?: "from_closed" | "from_open";
  values?: number[];
}

export interface TorqueSpec {
  fastener: string;
  nm: number;
  sourceUrl: string;
  sourceLabel: string;
}

export interface ComponentModel {
  id: string;
  slot: ComponentSlot;
  manufacturer: string;
  model: string;
  variant?: string;
  modelYear?: number;
  weightG?: number;
  attributes: TypedAttribute[];
  adjusters: AdjusterDef[];
  torqueSpecs: TorqueSpec[];
  source: AttributeConfidence;
  sourceUrl: string;
  verifiedAt: string;
  verifiedBy: string;
  safetyCritical: boolean;
}

export interface CatalogBikeVariant {
  id: string;
  name: string;
  year: number;
  frameSizeOptions: string[];
  category: BikeCategory;
  travelFrontMm?: number;
  travelRearMm?: number;
  wheelSizeFront: WheelSize;
  wheelSizeRear: WheelSize;
  isEbike: boolean;
  weightKgApprox?: number;
  /** Slot → ComponentModel-ID der OEM-Ausstattung */
  oemComponents: Partial<Record<ComponentSlot, string>>;
  frameAttributes: TypedAttribute[];
  sourceUrl: string;
}

export interface CatalogManufacturer {
  id: string;
  name: string;
  bikes: CatalogBikeVariant[];
}

export interface BikeComponent {
  id: string;
  bikeId: string;
  slot: ComponentSlot;
  componentModelId?: string;
  freeText?: string;
  manufacturer?: string;
  model?: string;
  installedAt: string;
  removedAt?: string;
  serialNumber?: string;
  odometerKmAtInstall: number;
  hoursAtInstall: number;
  notes?: string;
  /** Nutzer-Overrides / freie Specs wenn kein Katalog */
  attributes: TypedAttribute[];
  currentSettings: Record<string, number | string>;
}

export interface SetupValue {
  bikeComponentId: string;
  slot: ComponentSlot;
  adjusterKey: string;
  /** SI wo sinnvoll; Klicks dimensionslos von geschlossen */
  valueNum: number;
  unit: string;
  outOfSpec: boolean;
}

export interface Setup {
  id: string;
  bikeId: string;
  version: number;
  parentSetupId?: string;
  label: string;
  conditions: SetupCondition;
  description?: string;
  riderWeightKg?: number;
  gearWeightKg?: number;
  values: SetupValue[];
  createdAt: string;
  createdBy: "user" | "template" | "recommendation" | "catalog";
  isCurrent: boolean;
  linkedRideId?: string;
}

export interface Bike {
  id: string;
  name: string;
  category: BikeCategory;
  /** Legacy-Kompatibilität für bestehende Screens */
  type: BikeType;
  catalogBikeId?: string;
  year?: number;
  frameSize?: string;
  travelFrontMm?: number;
  travelRearMm?: number;
  wheelSizeFront?: WheelSize;
  wheelSizeRear?: WheelSize;
  weightKg?: number;
  color?: string;
  isActive: boolean;
  isEbike: boolean;
  createdAt: string;
  updatedAt: string;
  components: BikeComponent[];
  setups: Setup[];
  totalOdometerKm: number;
  totalHours: number;
}

export interface MaintenanceLogEntry {
  id: string;
  bikeId: string;
  bikeComponentId?: string;
  slot?: ComponentSlot;
  date: string;
  activity: string;
  costEur?: number;
  performer: MaintenancePerformer;
  notes?: string;
  odometerKm?: number;
  hours?: number;
}

export interface MaintenanceInterval {
  id: string;
  bikeId: string;
  slot: ComponentSlot;
  bikeComponentId?: string;
  label: string;
  intervalKm?: number;
  intervalHours?: number;
  intervalDays?: number;
  lastDoneAt?: string;
  lastDoneOdometerKm?: number;
  lastDoneHours?: number;
  sourceLabel: string;
  sourceUrl?: string;
  overriddenByUser: boolean;
}

export interface EvidenceItem {
  ruleCode: string;
  attributeKey: string;
  valueA?: string | number;
  valueB?: string | number;
  sourceA?: AttributeSource;
  sourceB?: AttributeSource;
  verifiedAtA?: string;
  verifiedAtB?: string;
  note?: string;
}

export interface CompatibilityResult {
  verdict: CompatibilityVerdict;
  ruleCode: string;
  title: string;
  severity: RuleSeverity;
  conditionText?: string;
  explainDe: string;
  missingAttributes: { key: string; howToObtain: string }[];
  evidence: EvidenceItem[];
  safetyWorkshopHint?: string;
  torqueSpecs: TorqueSpec[];
  sourceUrl?: string;
}

export interface BracketingRun {
  id: string;
  configValue: number;
  runIndex: number;
  segmentTimeSec: number;
  flowScore: number;
  impactHardness: number;
  subjectiveRating: number;
  matchQuality: number;
  createdAt: string;
}

export interface BracketingSeries {
  id: string;
  bikeId: string;
  setupId: string;
  parameter: BracketingParameter;
  unit: string;
  rangeFrom: number;
  rangeTo: number;
  step: number;
  referenceSegmentLabel: string;
  status: "open" | "ready_to_evaluate" | "evaluated";
  runs: BracketingRun[];
  createdAt: string;
  resultSummary?: string;
  provenBestValue?: number;
  noProvenDifference?: boolean;
}

export interface RideFeedback {
  rideId: string;
  overallFeel: 1 | 2 | 3 | 4 | 5;
  /**
   * Foren-nah DACH Enduro (eMTB-News / BIKE-Sprache).
   * Legacy too_soft|too_firm bleiben für Migration lesbar.
   */
  frontFeel?:
    | "packt_nicht"
    | "taucht"
    | "ok"
    | "rupft"
    | "toppt_aus"
    | "zu_straff"
    | "too_soft"
    | "too_firm";
  brakeDive?: "taucht" | "neutral" | "steht" | "dives" | "harsh";
  smallBump?: "rupft" | "ok" | "schmiert" | "tot" | "harsh" | "vague";
  skipped: boolean;
  createdAt: string;
}

/** Gruppen für UI */
export const SLOT_GROUPS: { id: string; label: string; slots: ComponentSlot[] }[] = [
  {
    id: "frame_suspension",
    label: "Rahmen & Fahrwerk",
    slots: ["frame", "fork", "rear_shock", "headset"],
  },
  {
    id: "cockpit",
    label: "Cockpit",
    slots: ["stem", "handlebar", "grips", "bar_tape", "seatpost", "saddle"],
  },
  {
    id: "wheels",
    label: "Laufräder & Reifen",
    slots: [
      "front_hub",
      "rear_hub",
      "front_rim",
      "rear_rim",
      "tire_front",
      "tire_rear",
      "tire_insert_front",
      "tire_insert_rear",
    ],
  },
  {
    id: "drivetrain",
    label: "Antrieb",
    slots: [
      "bottom_bracket",
      "crankset",
      "chainring",
      "cassette",
      "chain",
      "rear_derailleur",
      "shifter",
      "front_derailleur",
      "pedals",
    ],
  },
  {
    id: "brakes",
    label: "Bremsen",
    slots: [
      "brake_front",
      "brake_rear",
      "rotor_front",
      "rotor_rear",
      "brake_pads_front",
      "brake_pads_rear",
    ],
  },
  {
    id: "ebike",
    label: "E-Bike",
    slots: ["motor", "battery", "display"],
  },
  {
    id: "hiking",
    label: "Wander-Ausrüstung",
    slots: ["hiking_shoes", "hiking_pack", "hiking_poles"],
  },
];
