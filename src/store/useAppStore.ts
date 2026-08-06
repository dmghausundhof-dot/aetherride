"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";
import { findCatalogBike } from "@/lib/catalog/bikes";
import { getComponentModel } from "@/lib/catalog/components";
import {
  bikeTypeToCategory,
  categoryToBikeType,
  requiredSlotsForCategory,
} from "@/lib/catalog/slots";
import {
  buildDefaultIntervals,
  evaluateIntervalDue,
} from "@/lib/maintenance/intervals";
import { evaluateBracketingSeries } from "@/lib/setup/bracketing";
import {
  buildSetupValuesFromBike,
  createImmutableSetup,
  recommendedSagPct,
} from "@/lib/setup/ranges";
import { templatesForCategory } from "@/lib/setup/templates";
import {
  calibrateFromRide,
  defaultCalibration,
  type RangeCalibration,
} from "@/lib/ebike/range";
import { buildEstimatedAssistLog } from "@/lib/ebike/assistLog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import {
  DEFAULT_CONSENTS,
  DEFAULT_PRIVACY_ZONES,
  type ConsentPurpose,
  type ConsentState,
  type PrivacyZone,
} from "@/lib/privacy/consents";
import {
  createFamilyRider,
  type FamilyRider,
} from "@/lib/garage/family";
import type { CommerceMode } from "@/lib/shop/marketplace";
import {
  buildPostRideAnalysis,
  recommendationToSetupOverrides,
} from "@/lib/ai/setupRecommendation";
import {
  createEmptyCalibration,
  isCalibrationValid,
  type BikeCalibration,
} from "@/lib/sensor/calibration";
import {
  continueWithoutAccount,
  loadSession,
  requestAccountDeletion,
  signInLocal,
  signOut,
  type AccountDeletionRequest,
  type AuthProvider,
  type AuthSession,
} from "@/lib/auth/session";
import { appendOp, flushOpsLog } from "@/lib/sync/opsLog";
import type { AppMode } from "@/lib/mode/hiking";
import type {
  Bike,
  BikeCategory,
  BikeComponent,
  BikeType,
  BracketingParameter,
  BracketingRun,
  BracketingSeries,
  ComponentSlot,
  MaintenanceInterval,
  MaintenanceLogEntry,
  Recommendation,
  Ride,
  RideFeedback,
  RiderProfile,
  SensorMetrics,
  Setup,
  SetupCondition,
  WheelSize,
} from "@/types";

export type SubscriptionTier = "free" | "pro";

interface AppState {
  bikes: Bike[];
  rides: Ride[];
  riderProfile: RiderProfile;
  recommendations: Recommendation[];
  activeBikeId: string | null;
  isRiding: boolean;
  currentRide: Partial<Ride> | null;
  liveMetrics: SensorMetrics | null;
  boschConnected: boolean;
  boschLive: {
    speed: number;
    soc: number;
    riderPower: number;
    cadence: number;
    odometer: number;
  } | null;
  maintenanceLogs: MaintenanceLogEntry[];
  maintenanceIntervals: MaintenanceInterval[];
  bracketingSeries: BracketingSeries[];
  rideFeedbacks: RideFeedback[];
  storageVersion: number;
  subscriptionTier: SubscriptionTier;
  rangeCalibration: RangeCalibration | null;
  profileExplanations: Record<string, string>;
  consents: ConsentState[];
  privacyZones: PrivacyZone[];
  familyRiders: FamilyRider[];
  activeFamilyRiderId: string | null;
  commerceMode: CommerceMode;
  /** F-SEN-002 Kalibrierung je Bike */
  bikeCalibrations: Record<string, BikeCalibration>;
  /** Spec 2.8 */
  appMode: AppMode;
  onboardingCompleted: boolean;
  authSession: AuthSession;
  accountDeletion: AccountDeletionRequest | null;

  setActiveBike: (id: string) => void;
  addBikeFromCatalog: (input: {
    catalogBikeId: string;
    frameSize: string;
    name?: string;
  }) => string;
  addBikeBasic: (input: {
    name: string;
    category: BikeCategory;
    travelFrontMm?: number;
    travelRearMm?: number;
    wheelSizeFront?: WheelSize;
    wheelSizeRear?: WheelSize;
    frameSize?: string;
    year?: number;
  }) => string;
  addBikeFromImport: (input: { name: string; note?: string }) => string;
  updateBike: (id: string, data: Partial<Bike>) => void;

  installComponent: (input: {
    bikeId: string;
    slot: ComponentSlot;
    componentModelId?: string;
    freeText?: string;
    manufacturer?: string;
    model?: string;
  }) => string;
  removeComponent: (bikeId: string, componentId: string) => void;
  moveComponent: (componentId: string, fromBikeId: string, toBikeId: string) => void;
  updateComponentSettings: (
    bikeId: string,
    componentId: string,
    settings: Record<string, number | string>
  ) => void;

  createSetupVersion: (input: {
    bikeId: string;
    label: string;
    conditions: SetupCondition;
    description?: string;
    valueOverrides?: Record<string, number>;
  }) => string;
  setCurrentSetup: (bikeId: string, setupId: string) => void;

  addMaintenanceLog: (
    entry: Omit<MaintenanceLogEntry, "id">
  ) => void;
  markIntervalDone: (intervalId: string) => void;
  overrideInterval: (
    intervalId: string,
    patch: Partial<
      Pick<
        MaintenanceInterval,
        "intervalKm" | "intervalHours" | "intervalDays" | "label"
      >
    >
  ) => void;

  startBracketing: (input: {
    bikeId: string;
    parameter: BracketingParameter;
    rangeFrom: number;
    rangeTo: number;
    step: number;
    referenceSegmentLabel: string;
  }) => string;
  addBracketingRun: (
    seriesId: string,
    run: Omit<BracketingRun, "id" | "createdAt">
  ) => void;
  evaluateBracketing: (seriesId: string) => void;

  submitRideFeedback: (feedback: Omit<RideFeedback, "createdAt">) => void;
  updateRiderProfile: (patch: Partial<RiderProfile>) => void;
  setSubscriptionTier: (tier: SubscriptionTier) => void;
  applySetupTemplate: (bikeId: string, templateId: string) => string;
  canUseProFeature: (feature: "multi_bike" | "bracketing" | "range" | "offline") => boolean;
  setConsent: (purpose: ConsentPurpose, granted: boolean) => void;
  addPrivacyZone: (zone: Omit<PrivacyZone, "id">) => void;
  removePrivacyZone: (id: string) => void;
  addFamilyRider: (name: string, weightKg: number) => string;
  setActiveFamilyRider: (id: string | null) => void;
  assignSetupToRider: (riderId: string, setupId: string) => void;
  setCommerceMode: (mode: CommerceMode) => void;
  setAppMode: (mode: AppMode) => void;
  setOnboardingCompleted: (done: boolean) => void;
  setBikeCalibration: (bikeId: string, cal: BikeCalibration) => void;
  getBikeCalibration: (bikeId: string) => BikeCalibration | null;
  signIn: (provider: AuthProvider, email?: string) => void;
  signOutUser: () => void;
  continueLocal: () => void;
  requestDeleteAccount: () => AccountDeletionRequest | null;
  syncNow: () => Promise<{ flushed: number; skipped: boolean; reason?: string }>;

  startRide: (bikeId: string, sportType: BikeType) => void;
  updateLiveMetrics: (metrics: Partial<SensorMetrics>) => void;
  updateBoschLive: (data: Partial<AppState["boschLive"]>) => void;
  endRide: () => Ride | null;
  addRecommendation: (rec: Omit<Recommendation, "id" | "status">) => void;
  dismissRecommendation: (id: string) => void;
  acceptRecommendation: (id: string) => void;
  regenerateSetupRecommendation: (rideId: string) => void;
  seedDemoData: () => void;

  /** @deprecated use createSetupVersion */
  addSetup: (
    bikeId: string,
    setup: {
      name: string;
      description?: string;
      settingsSnapshot: Record<string, string | number>;
      isActive: boolean;
    }
  ) => void;
  /** @deprecated use setCurrentSetup */
  setActiveSetup: (bikeId: string, setupId: string) => void;
  /** @deprecated use installComponent */
  addComponent: (
    bikeId: string,
    component: {
      category: string;
      manufacturer: string;
      model: string;
      specs: Record<string, string | number | boolean>;
      currentSettings: Record<string, string | number>;
    }
  ) => void;
  /** @deprecated use addBikeBasic */
  addBike: (
    bike: Omit<Bike, "id" | "createdAt" | "updatedAt" | "components" | "setups" | "category" | "isActive" | "isEbike" | "totalOdometerKm" | "totalHours"> & {
      type: BikeType;
      isDefault?: boolean;
    }
  ) => string;
}

const STORAGE_VERSION = 6;

const PROFILE_EXPLANATIONS: Record<string, string> = {
  style:
    "Abgeleitet aus Impact-Häufigkeit und Flow-Scores deiner Rides — jederzeit korrigierbar.",
  skillLevel:
    "Selbsteinschätzung 1–5; beeinflusst Routenvorschläge und Reichweiten-P_fahrer.",
  preferTechnical:
    "Gewichtet Routen mit höherem mtb:scale und rootigem Untergrund stärker.",
  preferFlow:
    "Bevorzugt flowige Trails und kompakte Oberflächen in Discover.",
  preferSteep: "Hebt Routen mit mehr Höhenmetern und steileren Rampen an.",
  eBikeAssistPreference:
    "Nur Logging/Prognose-Kontext — keine Motorsteuerung (F-EBK-000).",
  riderWeightKg:
    "Für SAG-Vorlagen und Reichweitenphysik (Art. 9 DSGVO: lokal, korrigierbar).",
  avgRideDurationMin: "Aus abgeschlossenen Rides gemittelt — manuell überschreibbar.",
  weeklyDistanceKm: "Rollierende Wochenkilometer — manuell überschreibbar.",
  terrainShare:
    "Verteilung über mtb:scale / Oberfläche aus Historie — korrigierbar (F-AI-002).",
  styleIndicators:
    "Bremsintensität, Querbeschleunigung, Impacts, Sprünge — erklärbar, kein Embedding.",
};

const defaultProfile: RiderProfile = {
  style: "flow",
  skillLevel: 3,
  preferences: {
    preferSteep: false,
    preferTechnical: true,
    preferFlow: true,
    eBikeAssistPreference: "sport",
  },
  terrainShare: {
    s0s1: 35,
    s2: 40,
    s3plus: 15,
    gravelRoad: 10,
  },
  styleIndicators: {
    brakeIntensityBeforeCorners: 45,
    timeOver04gLateralPct: 12,
    impactsPerHour: 8,
    jumpsPerRide: 2,
  },
  fitnessIndicators: {
    avgRideDurationMin: 90,
    weeklyDistanceKm: 45,
  },
  riderWeightKg: 78,
};

function emptyBikeBase(
  partial: Omit<
    Bike,
    "id" | "createdAt" | "updatedAt" | "components" | "setups" | "isActive"
  > & { id?: string }
): Bike {
  const id = partial.id ?? uuidv4();
  const now = new Date().toISOString();
  return {
    ...partial,
    id,
    isActive: false,
    createdAt: now,
    updatedAt: now,
    components: [],
    setups: [],
  };
}

function installFromModel(
  bikeId: string,
  slot: ComponentSlot,
  modelId: string,
  odo: number,
  hours: number
): BikeComponent {
  const model = getComponentModel(modelId)!;
  const settings: Record<string, number | string> = {};
  for (const adj of model.adjusters) {
    if (adj.key === "sag_pct") continue;
    if (adj.min !== undefined && adj.max !== undefined) {
      settings[adj.key] = Math.round((adj.min + adj.max) / 2);
    } else if (adj.totalClicks) {
      settings[adj.key] = Math.round(adj.totalClicks / 2);
    }
  }
  return {
    id: uuidv4(),
    bikeId,
    slot,
    componentModelId: modelId,
    manufacturer: model.manufacturer,
    model: [model.model, model.variant].filter(Boolean).join(" "),
    installedAt: new Date().toISOString(),
    odometerKmAtInstall: odo,
    hoursAtInstall: hours,
    attributes: [],
    currentSettings: settings,
  };
}

function ensureSingleActive(bikes: Bike[], activeId: string): Bike[] {
  return bikes.map((b) => ({ ...b, isActive: b.id === activeId }));
}

function componentUsageKm(bike: Bike, comp: BikeComponent, rides: Ride[]): number {
  const start = new Date(comp.installedAt).getTime();
  const end = comp.removedAt ? new Date(comp.removedAt).getTime() : Date.now();
  return rides
    .filter((r) => r.bikeId === bike.id)
    .filter((r) => {
      const t = new Date(r.startTime).getTime();
      return t >= start && t <= end;
    })
    .reduce((s, r) => s + r.distanceM / 1000, 0);
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      bikes: [],
      rides: [],
      riderProfile: defaultProfile,
      recommendations: [],
      activeBikeId: null,
      isRiding: false,
      currentRide: null,
      liveMetrics: null,
      boschConnected: false,
      boschLive: null,
      maintenanceLogs: [],
      maintenanceIntervals: [],
      bracketingSeries: [],
      rideFeedbacks: [],
      storageVersion: STORAGE_VERSION,
      subscriptionTier: "free",
      rangeCalibration: null,
      profileExplanations: PROFILE_EXPLANATIONS,
      consents: DEFAULT_CONSENTS,
      privacyZones: DEFAULT_PRIVACY_ZONES,
      familyRiders: [],
      activeFamilyRiderId: null,
      commerceMode: "affiliate",
      bikeCalibrations: {},
      appMode: "bike",
      onboardingCompleted: false,
      authSession: { user: null, syncEnabled: false },
      accountDeletion: null,

      setActiveBike: (id) =>
        set((s) => ({
          activeBikeId: id,
          bikes: ensureSingleActive(s.bikes, id),
        })),

      setAppMode: (mode) => set({ appMode: mode }),
      setOnboardingCompleted: (done) => set({ onboardingCompleted: done }),

      setBikeCalibration: (bikeId, cal) =>
        set((s) => ({
          bikeCalibrations: { ...s.bikeCalibrations, [bikeId]: cal },
        })),

      getBikeCalibration: (bikeId) => get().bikeCalibrations[bikeId] ?? null,

      signIn: (provider, email) => {
        const session = signInLocal({ provider, email });
        set({ authSession: session });
        appendOp({
          entity: "profile",
          entityId: session.user?.id ?? "anon",
          op: "create",
          payload: { provider },
        });
      },

      signOutUser: () => set({ authSession: signOut() }),

      continueLocal: () => set({ authSession: continueWithoutAccount() }),

      requestDeleteAccount: () => {
        const user = get().authSession.user;
        if (!user || user.provider === "local_anonymous") return null;
        const req = requestAccountDeletion(user);
        set({ accountDeletion: req });
        appendOp({
          entity: "profile",
          entityId: user.id,
          op: "delete",
          payload: req,
        });
        return req;
      },

      syncNow: async () => {
        const result = await flushOpsLog(get().authSession.syncEnabled);
        return result;
      },

      updateRiderProfile: (patch) =>
        set((s) => ({
          riderProfile: {
            ...s.riderProfile,
            ...patch,
            preferences: {
              ...s.riderProfile.preferences,
              ...(patch.preferences ?? {}),
            },
            fitnessIndicators: {
              ...s.riderProfile.fitnessIndicators,
              ...(patch.fitnessIndicators ?? {}),
            },
          },
        })),

      setSubscriptionTier: (tier) => set({ subscriptionTier: tier }),

      canUseProFeature: (feature) => {
        const tier = get().subscriptionTier;
        if (tier === "pro") return true;
        return false;
      },

      setConsent: (purpose, granted) =>
        set((s) => ({
          consents: s.consents.map((c) =>
            c.purpose === purpose
              ? {
                  ...c,
                  granted,
                  updatedAt: new Date().toISOString(),
                }
              : c
          ),
        })),

      addPrivacyZone: (zone) =>
        set((s) => ({
          privacyZones: [
            ...s.privacyZones,
            { ...zone, id: uuidv4() },
          ],
        })),

      removePrivacyZone: (id) =>
        set((s) => ({
          privacyZones: s.privacyZones.filter((z) => z.id !== id),
        })),

      addFamilyRider: (name, weightKg) => {
        const rider = createFamilyRider(name, weightKg);
        set((s) => ({
          familyRiders: [...s.familyRiders, rider],
          activeFamilyRiderId: s.activeFamilyRiderId ?? rider.id,
        }));
        return rider.id;
      },

      setActiveFamilyRider: (id) => set({ activeFamilyRiderId: id }),

      assignSetupToRider: (riderId, setupId) =>
        set((s) => ({
          familyRiders: s.familyRiders.map((r) =>
            r.id === riderId
              ? {
                  ...r,
                  setupIds: r.setupIds.includes(setupId)
                    ? r.setupIds
                    : [...r.setupIds, setupId],
                }
              : r
          ),
        })),

      setCommerceMode: (mode) => set({ commerceMode: mode }),

      applySetupTemplate: (bikeId, templateId) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        if (!bike) return "";
        const tpl = templatesForCategory(bike.category).find(
          (t) => t.id === templateId
        );
        if (!tpl) return "";
        const weight = get().riderProfile.riderWeightKg ?? 78;
        const overrides = tpl.resolve(weight, bike.category);
        return get().createSetupVersion({
          bikeId,
          label: `${tpl.label} (Vorlage)`,
          conditions: tpl.conditions,
          description: `${tpl.disclaimer} Quelle: ${tpl.sourceLabel}`,
          valueOverrides: overrides,
        });
      },

      addBikeFromCatalog: ({ catalogBikeId, frameSize, name }) => {
        if (
          get().subscriptionTier === "free" &&
          get().bikes.length >= 1
        ) {
          throw new Error(
            "Free-Tier: nur 1 Bike. Für Multi-Bike Pro freischalten (Spec 1.4)."
          );
        }
        const found = findCatalogBike(catalogBikeId);
        if (!found) throw new Error("Katalog-Bike nicht gefunden");
        const { bike: cat, manufacturer } = found;
        const id = uuidv4();
        const type = categoryToBikeType(cat.category);
        let bike = emptyBikeBase({
          id,
          name: name || `${manufacturer.name} ${cat.name}`,
          category: cat.category,
          type,
          catalogBikeId: cat.id,
          year: cat.year,
          frameSize,
          travelFrontMm: cat.travelFrontMm,
          travelRearMm: cat.travelRearMm,
          wheelSizeFront: cat.wheelSizeFront,
          wheelSizeRear: cat.wheelSizeRear,
          weightKg: cat.weightKgApprox,
          isEbike: cat.isEbike,
          totalOdometerKm: 0,
          totalHours: 0,
        });

        const components: BikeComponent[] = [];
        for (const [slot, modelId] of Object.entries(cat.oemComponents)) {
          if (!modelId) continue;
          const c = installFromModel(
            id,
            slot as ComponentSlot,
            modelId,
            0,
            0
          );
          // SAG-Defaults nach Kategorie
          if (slot === "fork") {
            c.currentSettings.sag_pct = recommendedSagPct(
              cat.category,
              "fork"
            ).target;
            c.currentSettings.air_pressure_psi = 75;
            c.currentSettings.rebound = 8;
            c.currentSettings.lsc = 6;
            c.currentSettings.hsc = 4;
          }
          if (slot === "rear_shock") {
            c.currentSettings.sag_pct = recommendedSagPct(
              cat.category,
              "shock"
            ).target;
            c.currentSettings.air_pressure_psi = 180;
            c.currentSettings.rebound = 10;
            c.currentSettings.lsc = 5;
            c.currentSettings.hsc = 3;
          }
          if (slot === "tire_front") c.currentSettings.pressure_psi = 22;
          if (slot === "tire_rear") c.currentSettings.pressure_psi = 24;
          components.push(c);
        }
        bike = { ...bike, components };

        const setup = createImmutableSetup({
          id: uuidv4(),
          bike,
          label: "OEM Basis-Setup",
          conditions: "general",
          description: "Aus Katalog-Vorbefüllung",
          riderWeightKg: get().riderProfile.riderWeightKg,
          createdBy: "catalog",
        });
        bike = { ...bike, setups: [setup] };

        const intervals = buildDefaultIntervals(bike, () => uuidv4());

        set((s) => {
          const bikes = ensureSingleActive([...s.bikes, bike], id);
          return {
            bikes,
            activeBikeId: id,
            maintenanceIntervals: [...s.maintenanceIntervals, ...intervals],
          };
        });
        return id;
      },

      addBikeBasic: (input) => {
        if (
          get().subscriptionTier === "free" &&
          get().bikes.length >= 1
        ) {
          throw new Error(
            "Free-Tier: nur 1 Bike. Für Multi-Bike Pro freischalten (Spec 1.4)."
          );
        }
        const id = uuidv4();
        const type = categoryToBikeType(input.category);
        const bike = emptyBikeBase({
          id,
          name: input.name,
          category: input.category,
          type,
          year: input.year,
          frameSize: input.frameSize,
          travelFrontMm: input.travelFrontMm,
          travelRearMm: input.travelRearMm,
          wheelSizeFront: input.wheelSizeFront,
          wheelSizeRear: input.wheelSizeRear,
          isEbike: input.category === "emtb" || input.category === "etrekking",
          totalOdometerKm: 0,
          totalHours: 0,
        });
        set((s) => ({
          bikes: ensureSingleActive([...s.bikes, bike], id),
          activeBikeId: id,
        }));
        return id;
      },

      addBikeFromImport: ({ name, note }) => {
        const id = get().addBikeBasic({
          name: name || "Import-Bike",
          category: "mtb_am",
        });
        if (note) {
          get().updateBike(id, {
            // store note in color field fallback? use update with description via name suffix
          });
          get().addMaintenanceLog({
            bikeId: id,
            date: new Date().toISOString().slice(0, 10),
            activity: "GPX/FIT-Import: Platzhalter-Bike angelegt",
            performer: "self",
            notes: note,
          });
        }
        return id;
      },

      updateBike: (id, data) =>
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === id
              ? { ...b, ...data, updatedAt: new Date().toISOString() }
              : b
          ),
        })),

      installComponent: ({
        bikeId,
        slot,
        componentModelId,
        freeText,
        manufacturer,
        model,
      }) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        if (!bike) return "";
        const now = new Date().toISOString();
        // Historie: bestehende aktive Komponente im Slot beenden
        const closed = bike.components.map((c) =>
          c.slot === slot && !c.removedAt ? { ...c, removedAt: now } : c
        );
        const modelObj = componentModelId
          ? getComponentModel(componentModelId)
          : undefined;
        const comp: BikeComponent = {
          id: uuidv4(),
          bikeId,
          slot,
          componentModelId,
          freeText: componentModelId ? undefined : freeText,
          manufacturer: manufacturer ?? modelObj?.manufacturer,
          model:
            model ??
            (modelObj
              ? [modelObj.model, modelObj.variant].filter(Boolean).join(" ")
              : freeText),
          installedAt: now,
          odometerKmAtInstall: bike.totalOdometerKm,
          hoursAtInstall: bike.totalHours,
          attributes: [],
          currentSettings: {},
        };
        if (modelObj) {
          for (const adj of modelObj.adjusters) {
            if (adj.min !== undefined && adj.max !== undefined) {
              comp.currentSettings[adj.key] = Math.round((adj.min + adj.max) / 2);
            }
          }
        }
        const components = [...closed, comp];
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? { ...b, components, updatedAt: now }
              : b
          ),
        }));
        // Intervalle für Slot ergänzen falls nötig
        const updated = get().bikes.find((b) => b.id === bikeId)!;
        const existing = get().maintenanceIntervals.filter(
          (i) => i.bikeId === bikeId && i.slot === slot
        );
        if (existing.length === 0) {
          const neu = buildDefaultIntervals(updated, () => uuidv4()).filter(
            (i) => i.slot === slot
          );
          set((s) => ({
            maintenanceIntervals: [...s.maintenanceIntervals, ...neu],
          }));
        }
        return comp.id;
      },

      removeComponent: (bikeId, componentId) => {
        const now = new Date().toISOString();
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  components: b.components.map((c) =>
                    c.id === componentId ? { ...c, removedAt: now } : c
                  ),
                  updatedAt: now,
                }
              : b
          ),
        }));
      },

      moveComponent: (componentId, fromBikeId, toBikeId) => {
        const from = get().bikes.find((b) => b.id === fromBikeId);
        const to = get().bikes.find((b) => b.id === toBikeId);
        if (!from || !to) return;
        const comp = from.components.find((c) => c.id === componentId);
        if (!comp || comp.removedAt) return;
        const now = new Date().toISOString();
        const usageKm = componentUsageKm(from, comp, get().rides);
        const moved: BikeComponent = {
          ...comp,
          id: uuidv4(),
          bikeId: toBikeId,
          installedAt: now,
          removedAt: undefined,
          odometerKmAtInstall: to.totalOdometerKm,
          hoursAtInstall: to.totalHours,
          notes: [
            comp.notes,
            `Verschoben von ${from.name} (Laufleistung bis Transfer ≈ ${usageKm.toFixed(0)} km)`,
          ]
            .filter(Boolean)
            .join(" · "),
        };
        set((s) => ({
          bikes: s.bikes.map((b) => {
            if (b.id === fromBikeId) {
              return {
                ...b,
                components: b.components.map((c) =>
                  c.id === componentId ? { ...c, removedAt: now } : c
                ),
                updatedAt: now,
              };
            }
            if (b.id === toBikeId) {
              const closed = b.components.map((c) =>
                c.slot === comp.slot && !c.removedAt
                  ? { ...c, removedAt: now }
                  : c
              );
              return {
                ...b,
                components: [...closed, moved],
                updatedAt: now,
              };
            }
            return b;
          }),
        }));
      },

      updateComponentSettings: (bikeId, componentId, settings) =>
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  components: b.components.map((c) =>
                    c.id === componentId
                      ? {
                          ...c,
                          currentSettings: { ...c.currentSettings, ...settings },
                        }
                      : c
                  ),
                  updatedAt: new Date().toISOString(),
                }
              : b
          ),
        })),

      createSetupVersion: ({
        bikeId,
        label,
        conditions,
        description,
        valueOverrides,
      }) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        if (!bike) return "";
        const values = buildSetupValuesFromBike(bike, valueOverrides);
        const setup = createImmutableSetup({
          id: uuidv4(),
          bike,
          label,
          conditions,
          description,
          riderWeightKg: get().riderProfile.riderWeightKg,
          values,
          createdBy: "user",
        });
        // Sync currentSettings from new setup values (mutable live state on components)
        const settingsByComp = new Map<string, Record<string, number>>();
        for (const v of values) {
          const cur = settingsByComp.get(v.bikeComponentId) ?? {};
          cur[v.adjusterKey] = v.valueNum;
          settingsByComp.set(v.bikeComponentId, cur);
        }
        set((s) => ({
          bikes: s.bikes.map((b) => {
            if (b.id !== bikeId) return b;
            return {
              ...b,
              components: b.components.map((c) => {
                const patch = settingsByComp.get(c.id);
                return patch
                  ? { ...c, currentSettings: { ...c.currentSettings, ...patch } }
                  : c;
              }),
              setups: [
                ...b.setups.map((su) => ({ ...su, isCurrent: false })),
                setup,
              ],
              updatedAt: new Date().toISOString(),
            };
          }),
        }));
        return setup.id;
      },

      setCurrentSetup: (bikeId, setupId) =>
        set((s) => ({
          bikes: s.bikes.map((b) => {
            if (b.id !== bikeId) return b;
            const setup = b.setups.find((su) => su.id === setupId);
            if (!setup) return b;
            // Apply immutable snapshot values to live component settings
            const byComp = new Map<string, Record<string, number>>();
            for (const v of setup.values) {
              const cur = byComp.get(v.bikeComponentId) ?? {};
              cur[v.adjusterKey] = v.valueNum;
              byComp.set(v.bikeComponentId, cur);
            }
            return {
              ...b,
              setups: b.setups.map((su) => ({
                ...su,
                isCurrent: su.id === setupId,
              })),
              components: b.components.map((c) => {
                const patch = byComp.get(c.id);
                return patch
                  ? { ...c, currentSettings: { ...c.currentSettings, ...patch } }
                  : c;
              }),
            };
          }),
        })),

      addMaintenanceLog: (entry) => {
        const id = uuidv4();
        set((s) => ({
          maintenanceLogs: [{ ...entry, id }, ...s.maintenanceLogs],
        }));
      },

      markIntervalDone: (intervalId) => {
        const bikeId = get().maintenanceIntervals.find(
          (i) => i.id === intervalId
        )?.bikeId;
        const bike = get().bikes.find((b) => b.id === bikeId);
        if (!bike) return;
        const now = new Date().toISOString();
        set((s) => ({
          maintenanceIntervals: s.maintenanceIntervals.map((i) =>
            i.id === intervalId
              ? {
                  ...i,
                  lastDoneAt: now,
                  lastDoneOdometerKm: bike.totalOdometerKm,
                  lastDoneHours: bike.totalHours,
                }
              : i
          ),
        }));
        const interval = get().maintenanceIntervals.find(
          (i) => i.id === intervalId
        );
        if (interval) {
          get().addMaintenanceLog({
            bikeId: bike.id,
            bikeComponentId: interval.bikeComponentId,
            slot: interval.slot,
            date: now.slice(0, 10),
            activity: interval.label,
            performer: "self",
            odometerKm: bike.totalOdometerKm,
            hours: bike.totalHours,
          });
        }
      },

      overrideInterval: (intervalId, patch) =>
        set((s) => ({
          maintenanceIntervals: s.maintenanceIntervals.map((i) =>
            i.id === intervalId
              ? { ...i, ...patch, overriddenByUser: true }
              : i
          ),
        })),

      startBracketing: ({
        bikeId,
        parameter,
        rangeFrom,
        rangeTo,
        step,
        referenceSegmentLabel,
      }) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        const setup = bike?.setups.find((s) => s.isCurrent);
        if (!bike || !setup) return "";
        // Nur ein Parameter – Validierung
        if (rangeFrom === rangeTo) return "";
        const id = uuidv4();
        const unit = parameter.includes("psi")
          ? "psi"
          : parameter.includes("sag")
            ? "%"
            : "clicks";
        const series: BracketingSeries = {
          id,
          bikeId,
          setupId: setup.id,
          parameter,
          unit,
          rangeFrom,
          rangeTo,
          step,
          referenceSegmentLabel,
          status: "open",
          runs: [],
          createdAt: new Date().toISOString(),
        };
        set((s) => ({
          bracketingSeries: [series, ...s.bracketingSeries],
        }));
        return id;
      },

      addBracketingRun: (seriesId, run) => {
        set((s) => ({
          bracketingSeries: s.bracketingSeries.map((series) => {
            if (series.id !== seriesId) return series;
            const full: BracketingRun = {
              ...run,
              id: uuidv4(),
              createdAt: new Date().toISOString(),
            };
            return { ...series, runs: [...series.runs, full] };
          }),
        }));
      },

      evaluateBracketing: (seriesId) => {
        const series = get().bracketingSeries.find((s) => s.id === seriesId);
        if (!series) return;
        const result = evaluateBracketingSeries(series);
        set((s) => ({
          bracketingSeries: s.bracketingSeries.map((ser) =>
            ser.id === seriesId
              ? {
                  ...ser,
                  status: result.ready ? "evaluated" : "ready_to_evaluate",
                  resultSummary: result.summary,
                  provenBestValue: result.provenBestValue,
                  noProvenDifference: result.noProvenDifference,
                }
              : ser
          ),
        }));
      },

      submitRideFeedback: (feedback) =>
        set((s) => ({
          rideFeedbacks: [
            { ...feedback, createdAt: new Date().toISOString() },
            ...s.rideFeedbacks,
          ],
        })),

      startRide: (bikeId, sportType) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        const activeSetup = bike?.setups.find((s) => s.isCurrent);
        set({
          isRiding: true,
          currentRide: {
            id: uuidv4(),
            bikeId,
            setupId: activeSetup?.id,
            sportType,
            startTime: new Date().toISOString(),
            distanceM: 0,
            elevationGainM: 0,
            durationSec: 0,
            summaryMetrics: {
              gForcePeak: 0,
              gForceRms: 0,
              leanAngleMax: 0,
              impactCount: 0,
              flowScore: 70,
            },
          },
          liveMetrics: {
            gForcePeak: 0,
            gForceRms: 0,
            leanAngleMax: 0,
            impactCount: 0,
            flowScore: 75,
          },
        });
      },

      updateLiveMetrics: (metrics) =>
        set((s) => ({
          liveMetrics: s.liveMetrics ? { ...s.liveMetrics, ...metrics } : null,
          currentRide: s.currentRide
            ? {
                ...s.currentRide,
                summaryMetrics: {
                  ...(s.currentRide.summaryMetrics as SensorMetrics),
                  ...metrics,
                },
              }
            : null,
        })),

      updateBoschLive: (data) =>
        set((s) => ({
          boschLive: s.boschLive ? { ...s.boschLive, ...data } : null,
        })),

      endRide: () => {
        const { currentRide, liveMetrics, boschLive } = get();
        if (!currentRide || !currentRide.id) return null;

        const endTime = new Date().toISOString();
        const start = new Date(currentRide.startTime!).getTime();
        const durationSec = Math.round((Date.now() - start) / 1000);

        const ride: Ride = {
          id: currentRide.id,
          bikeId: currentRide.bikeId!,
          setupId: currentRide.setupId,
          sportType: currentRide.sportType!,
          startTime: currentRide.startTime!,
          endTime,
          distanceM: currentRide.distanceM || Math.round(durationSec * 4.2),
          elevationGainM:
            currentRide.elevationGainM || Math.round(durationSec * 0.8),
          durationSec,
          summaryMetrics: liveMetrics || currentRide.summaryMetrics!,
          motorData: boschLive
            ? {
                avgSoc: boschLive.soc,
                minSoc: Math.max(0, boschLive.soc - 15),
                avgRiderPower: boschLive.riderPower,
                avgCadence: boschLive.cadence,
                totalOdometer: boschLive.odometer,
              }
            : undefined,
        };

        const bikeBefore = get().bikes.find((b) => b.id === ride.bikeId);
        if (bikeBefore?.isEbike) {
          ride.assistSummary = buildEstimatedAssistLog({
            durationSec: ride.durationSec,
            distanceM: ride.distanceM,
            elevationGainM: ride.elevationGainM,
            avgRiderPower: boschLive?.riderPower,
            avgSpeedKmh: boschLive?.speed,
            preferredMode:
              get().riderProfile.preferences.eBikeAssistPreference,
          });
        }

        // P1: Reichweiten-Selbstkalibrierung aus SOC-Delta
        if (bikeBefore?.isEbike && boschLive) {
          const prevCal =
            get().rangeCalibration ??
            defaultCalibration(bikeBefore, get().riderProfile);
          const whCap = 800;
          const usedWh = Math.max(5, whCap * 0.12);
          set({
            rangeCalibration: calibrateFromRide(prevCal, ride, usedWh),
          });
        }

        set((s) => ({
          rides: [ride, ...s.rides],
          isRiding: false,
          currentRide: null,
          liveMetrics: null,
          bikes: s.bikes.map((b) =>
            b.id === ride.bikeId
              ? {
                  ...b,
                  totalOdometerKm:
                    b.totalOdometerKm + ride.distanceM / 1000,
                  totalHours: b.totalHours + ride.durationSec / 3600,
                  updatedAt: endTime,
                }
              : b
          ),
        }));

        // F-SHP-002: anlassbezogene Produktempfehlungen (nur mit Consent)
        const productConsent = get().consents.find(
          (c) => c.purpose === "product_recommendations"
        )?.granted;
        if (productConsent && bikeBefore) {
          const setup = bikeBefore.setups.find((s) => s.isCurrent);
          const precs = allProductRecommendations({
            bike: bikeBefore,
            rides: [ride, ...get().rides],
            setup,
          });
          for (const pr of precs.slice(0, 2)) {
            get().addRecommendation({
              type: "product",
              title: pr.title,
              content: `${pr.product.name} · ${pr.product.priceEur} € · ${pr.product.merchantName}`,
              reasoning: `Auslöser: ${pr.triggeringDataPoint}. ${pr.reason}`,
              score: pr.confidence === "high" ? 0.85 : 0.65,
              relatedBikeId: bikeBefore.id,
              relatedRideId: ride.id,
            });
          }
        }
        // Wartungshinweise als Recommendations
        const bike = get().bikes.find((b) => b.id === ride.bikeId);
        if (bike) {
          for (const interval of get().maintenanceIntervals.filter(
            (i) => i.bikeId === bike.id
          )) {
            const due = evaluateIntervalDue(
              interval,
              bike.totalOdometerKm,
              bike.totalHours
            );
            if (due.status === "overdue" || due.status === "due_soon") {
              get().addRecommendation({
                type: "maintenance",
                title: due.status === "overdue" ? "Wartung überfällig" : "Wartung bald fällig",
                content: interval.label,
                reasoning: `Fortschritt ${due.progressPct}% · verbleibend ${due.remainingLabel}. Quelle: ${interval.sourceLabel}`,
                score: due.status === "overdue" ? 0.95 : 0.7,
                relatedBikeId: bike.id,
                relatedRideId: ride.id,
              });
            }
          }

          // F-AI-003: genau eine Setup-Empfehlung (deterministisch)
          if (get().appMode !== "hiking") {
            const feedback = get().rideFeedbacks.find(
              (f) => f.rideId === ride.id
            );
            const cal =
              get().bikeCalibrations[bike.id] ??
              createEmptyCalibration(bike.id);
            // Demo-Kalibrierung mit ζ falls leer — damit Engine testbar bleibt
            const calWithDemo =
              cal.suspension?.zeta != null
                ? cal
                : {
                    ...cal,
                    mountMode: "HANDLEBAR" as const,
                    mountConfirmed: true,
                    suspension: {
                      zeta: 0.21,
                      fdHz: 2.4,
                      fnHz: 2.5,
                      cv: 0.08,
                      accepted: true,
                      scopeNote: "Demo-ζ für Post-Ride-Engine",
                    },
                    sagFrontMm: cal.sagFrontMm ?? 40,
                    travelFrontMm: bike.travelFrontMm ?? 160,
                    calibratedAt: new Date().toISOString(),
                    quaternion: cal.quaternion ?? {
                      gDev: [0, 0, 1],
                      gBike: [0, 0, -1],
                      yawFromGnssPending: true as const,
                    },
                  };
            const analysis = buildPostRideAnalysis({
              bike,
              ride,
              feedback,
              calibration: calWithDemo,
            });
            if (analysis.recommendation) {
              const card = analysis.recommendation;
              get().addRecommendation({
                type: "setup",
                title: card.title,
                content: `${card.why}\n\nErwartete Wirkung: ${card.expectedEffect}`,
                reasoning: `${card.limits} · Konfidenz: ${card.confidence}${
                  card.observationOnly ? " · nur Beobachtung" : ""
                }\nBelege: ${(card.evidence ?? []).join("; ")}`,
                score:
                  card.confidence === "high"
                    ? 0.9
                    : card.confidence === "medium"
                      ? 0.7
                      : 0.4,
                relatedBikeId: bike.id,
                relatedRideId: ride.id,
                evidence: card.evidence,
                expectedEffect: card.expectedEffect,
                limits: card.limits,
                confidence: card.confidence,
                ruleId: card.ruleId,
                observationOnly: card.observationOnly,
                setupApply: card.apply,
                workshopLine: card.workshopLine,
                coachLine: card.coachLine,
              });
            }
          }
        }

        appendOp({
          entity: "ride",
          entityId: ride.id,
          op: "create",
          payload: { distanceM: ride.distanceM, durationSec: ride.durationSec },
        });

        return ride;
      },

      addRecommendation: (rec) =>
        set((s) => ({
          recommendations: [
            { ...rec, id: uuidv4(), status: "shown" },
            ...s.recommendations,
          ],
        })),

      dismissRecommendation: (id) =>
        set((s) => ({
          recommendations: s.recommendations.map((r) =>
            r.id === id ? { ...r, status: "dismissed" } : r
          ),
        })),

      acceptRecommendation: (id) => {
        const rec = get().recommendations.find((r) => r.id === id);
        set((s) => ({
          recommendations: s.recommendations.map((r) =>
            r.id === id ? { ...r, status: "accepted" } : r
          ),
        }));
        // F-AI-003: Übernehmen erzeugt immutable Setup-Version
        if (
          rec?.type === "setup" &&
          rec.relatedBikeId &&
          rec.setupApply &&
          Object.keys(rec.setupApply).length > 0 &&
          !rec.observationOnly
        ) {
          get().createSetupVersion({
            bikeId: rec.relatedBikeId,
            label: `Empfehlung ${rec.ruleId ?? ""}`.trim(),
            conditions: "general",
            description: rec.title,
            valueOverrides: recommendationToSetupOverrides({
              ruleId: rec.ruleId ?? "SR",
              title: rec.title,
              why: rec.reasoning,
              expectedEffect: rec.expectedEffect ?? "",
              limits: rec.limits ?? "",
              confidence: rec.confidence ?? "medium",
              apply: rec.setupApply,
              evidence: rec.evidence ?? [],
              observationOnly: false,
            }),
          });
          appendOp({
            entity: "setup",
            entityId: rec.relatedBikeId,
            op: "create",
            payload: rec.setupApply,
          });
        }
      },

      regenerateSetupRecommendation: (rideId) => {
        const ride = get().rides.find((r) => r.id === rideId);
        const bike = ride
          ? get().bikes.find((b) => b.id === ride.bikeId)
          : null;
        if (!ride || !bike) return;
        const feedback = get().rideFeedbacks.find((f) => f.rideId === ride.id);
        const cal =
          get().bikeCalibrations[bike.id] ?? createEmptyCalibration(bike.id);
        const analysis = buildPostRideAnalysis({
          bike,
          ride,
          feedback,
          calibration: cal,
        });
        // alte Setup-Empfehlung für diesen Ride entfernen/ersetzen
        set((s) => ({
          recommendations: s.recommendations.filter(
            (r) => !(r.relatedRideId === rideId && r.type === "setup")
          ),
        }));
        if (analysis.recommendation) {
          const card = analysis.recommendation;
          get().addRecommendation({
            type: "setup",
            title: card.title,
            content: `${card.why}\n\nErwartete Wirkung: ${card.expectedEffect}`,
            reasoning: `${card.limits} · Konfidenz: ${card.confidence}${
              card.observationOnly ? " · nur Beobachtung" : ""
            }`,
            score:
              card.confidence === "high"
                ? 0.9
                : card.confidence === "medium"
                  ? 0.7
                  : 0.4,
            relatedBikeId: bike.id,
            relatedRideId: ride.id,
            evidence: card.evidence,
            expectedEffect: card.expectedEffect,
            limits: card.limits,
            confidence: card.confidence,
            ruleId: card.ruleId,
            observationOnly: card.observationOnly,
            setupApply: card.apply,
            workshopLine: card.workshopLine,
            coachLine: card.coachLine,
          });
        }
      },

      // Legacy wrappers
      addBike: (bikeData) => {
        return get().addBikeBasic({
          name: bikeData.name,
          category: bikeTypeToCategory(bikeData.type),
          year: bikeData.year,
          frameSize: bikeData.frameSize,
          travelFrontMm: undefined,
          wheelSizeFront: "29",
          wheelSizeRear: "29",
        });
      },

      addComponent: (bikeId, component) => {
        const slotMap: Record<string, ComponentSlot> = {
          fork: "fork",
          shock: "rear_shock",
          tire_front: "tire_front",
          tire_rear: "tire_rear",
          motor: "motor",
          battery: "battery",
          display: "display",
          saddle: "saddle",
        };
        const slot = slotMap[component.category] ?? "frame";
        get().installComponent({
          bikeId,
          slot,
          freeText: `${component.manufacturer} ${component.model}`,
          manufacturer: component.manufacturer,
          model: component.model,
        });
      },

      addSetup: (bikeId, setup) => {
        get().createSetupVersion({
          bikeId,
          label: setup.name,
          conditions: "general",
          description: setup.description,
          valueOverrides: Object.fromEntries(
            Object.entries(setup.settingsSnapshot).map(([k, v]) => [
              k.includes(".") ? k : `fork.${k}`,
              Number(v),
            ])
          ),
        });
      },

      setActiveSetup: (bikeId, setupId) => get().setCurrentSetup(bikeId, setupId),

      seedDemoData: () => {
        const existing = get().bikes;
        if (existing.length > 0) return;
        // Demo: Pro, damit Multi-Bike-Seed Spec 1.4 nicht blockiert
        set({ subscriptionTier: "pro" });
        get().addBikeFromCatalog({
          catalogBikeId: "cat-transition-spire-2024",
          frameSize: "L",
        });
        get().addBikeFromCatalog({
          catalogBikeId: "cat-specialized-diverge-2023",
          frameSize: "54",
        });
        get().createSetupVersion({
          bikeId: get().bikes[0].id,
          label: "Wet Roots",
          conditions: "wet",
          description: "Nasse, rutschige Bedingungen",
          valueOverrides: {
            "fork.sag_pct": 30,
            "fork.rebound": 10,
            "rear_shock.sag_pct": 32,
            "rear_shock.rebound": 12,
            "tire_front.pressure_psi": 20,
            "tire_rear.pressure_psi": 22,
          },
        });
        // restore dry as current
        const dry = get().bikes[0]?.setups.find((s) =>
          s.label.includes("OEM")
        );
        if (dry) get().setCurrentSetup(get().bikes[0].id, dry.id);

        set({
          boschConnected: true,
          boschLive: {
            speed: 0,
            soc: 87,
            riderPower: 0,
            cadence: 0,
            odometer: 1247,
          },
        });
      },
    }),
    {
      name: "aetherride-storage",
      version: STORAGE_VERSION,
      migrate: (persisted, fromVersion) => {
        const base = (persisted as Partial<AppState>) ?? {};
        const profile = {
          ...defaultProfile,
          ...base.riderProfile,
          preferences: {
            ...defaultProfile.preferences,
            ...base.riderProfile?.preferences,
          },
          terrainShare: {
            ...defaultProfile.terrainShare!,
            ...base.riderProfile?.terrainShare,
          },
          styleIndicators: {
            ...defaultProfile.styleIndicators!,
            ...base.riderProfile?.styleIndicators,
          },
          fitnessIndicators: {
            ...defaultProfile.fitnessIndicators,
            ...base.riderProfile?.fitnessIndicators,
          },
        };
        return {
          ...base,
          riderProfile: profile,
          subscriptionTier: base.subscriptionTier ?? "free",
          rangeCalibration: base.rangeCalibration ?? null,
          profileExplanations: PROFILE_EXPLANATIONS,
          consents: base.consents?.length ? base.consents : DEFAULT_CONSENTS,
          privacyZones: base.privacyZones?.length
            ? base.privacyZones
            : DEFAULT_PRIVACY_ZONES,
          familyRiders: base.familyRiders ?? [],
          activeFamilyRiderId: base.activeFamilyRiderId ?? null,
          commerceMode: base.commerceMode ?? "affiliate",
          bikeCalibrations: base.bikeCalibrations ?? {},
          appMode: base.appMode ?? "bike",
          onboardingCompleted: base.onboardingCompleted ?? false,
          authSession: base.authSession ?? loadSession(),
          accountDeletion: base.accountDeletion ?? null,
          storageVersion: STORAGE_VERSION,
        } as AppState;
      },
      partialize: (s) => ({
        bikes: s.bikes,
        rides: s.rides,
        riderProfile: s.riderProfile,
        recommendations: s.recommendations,
        activeBikeId: s.activeBikeId,
        boschConnected: s.boschConnected,
        maintenanceLogs: s.maintenanceLogs,
        maintenanceIntervals: s.maintenanceIntervals,
        bracketingSeries: s.bracketingSeries,
        rideFeedbacks: s.rideFeedbacks,
        storageVersion: s.storageVersion,
        subscriptionTier: s.subscriptionTier,
        rangeCalibration: s.rangeCalibration,
        consents: s.consents,
        privacyZones: s.privacyZones,
        familyRiders: s.familyRiders,
        activeFamilyRiderId: s.activeFamilyRiderId,
        commerceMode: s.commerceMode,
        bikeCalibrations: s.bikeCalibrations,
        appMode: s.appMode,
        onboardingCompleted: s.onboardingCompleted,
        authSession: s.authSession,
        accountDeletion: s.accountDeletion,
      }),
    }
  )
);

/** Garage-Fortschritt: nächste fehlende P0-Aufgabe */
export function nextGarageTask(
  bike: Bike,
  calibration?: BikeCalibration | null
): string | null {
  const missing = getMissingSlots(bike);
  if (missing.length) {
    return `Komponente ergänzen: ${missing[0]}`;
  }
  if (!bike.setups.some((s) => s.isCurrent) && bike.setups.length === 0) {
    return "Erstes Setup anlegen";
  }
  if (
    !calibration?.mountConfirmed ||
    (calibration.mountMode !== "HANDLEBAR" && calibration.mountMode !== "STEM")
  ) {
    return "Halterung bestätigen + 45 s kalibrieren (F-SEN-002)";
  }
  if (!isCalibrationValid(calibration)) {
    return "Kalibrierung abschließen (Ausrichtung, Bounce, SAG)";
  }
  return null;
}

export function getActiveComponents(bike: Bike): BikeComponent[] {
  return bike.components.filter((c) => !c.removedAt);
}

export function getMissingSlots(bike: Bike): ComponentSlot[] {
  const required = requiredSlotsForCategory(bike.category);
  const filled = new Set(getActiveComponents(bike).map((c) => c.slot));
  return required.filter((s) => !filled.has(s));
}

export function bikeCompletenessPct(bike: Bike): number {
  const required = requiredSlotsForCategory(bike.category);
  if (required.length === 0) return 100;
  const filled = required.length - getMissingSlots(bike).length;
  return Math.round((filled / required.length) * 100);
}
