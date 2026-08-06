"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";
import type {
  Bike,
  Component,
  Setup,
  Ride,
  RiderProfile,
  Product,
  Recommendation,
  BikeType,
  ComponentCategory,
  SensorMetrics,
} from "@/types";

interface AppState {
  // Data
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

  // Actions
  setActiveBike: (id: string) => void;
  addBike: (bike: Omit<Bike, "id" | "createdAt" | "updatedAt" | "components" | "setups">) => string;
  updateBike: (id: string, data: Partial<Bike>) => void;
  addComponent: (bikeId: string, component: Omit<Component, "id" | "bikeId">) => void;
  updateComponent: (bikeId: string, componentId: string, data: Partial<Component>) => void;
  addSetup: (bikeId: string, setup: Omit<Setup, "id" | "bikeId" | "createdAt">) => void;
  setActiveSetup: (bikeId: string, setupId: string) => void;
  startRide: (bikeId: string, sportType: BikeType) => void;
  updateLiveMetrics: (metrics: Partial<SensorMetrics>) => void;
  updateBoschLive: (data: Partial<AppState["boschLive"]>) => void;
  endRide: () => Ride | null;
  addRecommendation: (rec: Omit<Recommendation, "id" | "status">) => void;
  dismissRecommendation: (id: string) => void;
  acceptRecommendation: (id: string) => void;
  seedDemoData: () => void;
}

const defaultProfile: RiderProfile = {
  style: "flow",
  skillLevel: 3,
  preferences: {
    preferSteep: false,
    preferTechnical: true,
    preferFlow: true,
    eBikeAssistPreference: "sport",
  },
  fitnessIndicators: {
    avgRideDurationMin: 90,
    weeklyDistanceKm: 45,
  },
};

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

      setActiveBike: (id) => set({ activeBikeId: id }),

      addBike: (bikeData) => {
        const id = uuidv4();
        const now = new Date().toISOString();
        const bike: Bike = {
          ...bikeData,
          id,
          createdAt: now,
          updatedAt: now,
          components: [],
          setups: [],
        };
        set((s) => ({
          bikes: [...s.bikes, bike],
          activeBikeId: s.activeBikeId ?? id,
        }));
        return id;
      },

      updateBike: (id, data) =>
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === id ? { ...b, ...data, updatedAt: new Date().toISOString() } : b
          ),
        })),

      addComponent: (bikeId, component) => {
        const id = uuidv4();
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  components: [...b.components, { ...component, id, bikeId }],
                  updatedAt: new Date().toISOString(),
                }
              : b
          ),
        }));
      },

      updateComponent: (bikeId, componentId, data) =>
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  components: b.components.map((c) =>
                    c.id === componentId ? { ...c, ...data } : c
                  ),
                  updatedAt: new Date().toISOString(),
                }
              : b
          ),
        })),

      addSetup: (bikeId, setup) => {
        const id = uuidv4();
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  setups: [
                    ...b.setups.map((su) => ({ ...su, isActive: false })),
                    {
                      ...setup,
                      id,
                      bikeId,
                      createdAt: new Date().toISOString(),
                    },
                  ],
                  updatedAt: new Date().toISOString(),
                }
              : b
          ),
        }));
      },

      setActiveSetup: (bikeId, setupId) =>
        set((s) => ({
          bikes: s.bikes.map((b) =>
            b.id === bikeId
              ? {
                  ...b,
                  setups: b.setups.map((su) => ({
                    ...su,
                    isActive: su.id === setupId,
                  })),
                }
              : b
          ),
        })),

      startRide: (bikeId, sportType) => {
        const bike = get().bikes.find((b) => b.id === bikeId);
        const activeSetup = bike?.setups.find((s) => s.isActive);
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
          distanceM: currentRide.distanceM || Math.round(durationSec * 4.2), // mock ~15km/h
          elevationGainM: currentRide.elevationGainM || Math.round(durationSec * 0.8),
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

        set((s) => ({
          rides: [ride, ...s.rides],
          isRiding: false,
          currentRide: null,
          liveMetrics: null,
        }));

        // Generate recommendation
        const flow = ride.summaryMetrics.flowScore;
        const impacts = ride.summaryMetrics.impactCount;
        let title = "Setup-Empfehlung";
        let content = "Dein aktuelles Setup passt gut.";
        let reasoning = "Basierend auf Flow-Score und Impact-Count.";

        if (impacts > 12 && flow < 65) {
          content = "Rebound +2 Clicks empfohlen. Impacts wirken zu hart.";
          reasoning = `Impact-Count ${impacts} bei Flow-Score ${flow}. Historie zeigt bessere Werte bei höherem Rebound.`;
        } else if (flow > 85) {
          content = "Super Flow! Aktuelles Setup beibehalten.";
          reasoning = `Flow-Score ${flow} – einer deiner besten Werte.`;
        }

        get().addRecommendation({
          type: "setup",
          title,
          content,
          reasoning,
          score: 0.85,
          relatedBikeId: ride.bikeId,
          relatedRideId: ride.id,
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

      acceptRecommendation: (id) =>
        set((s) => ({
          recommendations: s.recommendations.map((r) =>
            r.id === id ? { ...r, status: "accepted" } : r
          ),
        })),

      seedDemoData: () => {
        const existing = get().bikes;
        if (existing.length > 0) return;

        const bikeId = get().addBike({
          name: "Transition Spire",
          type: "enduro",
          year: 2024,
          frameSize: "L",
          weightKg: 15.8,
          color: "Sage Green",
          isDefault: true,
        });

        get().addComponent(bikeId, {
          category: "fork",
          manufacturer: "Fox",
          model: "36 Factory Grip2 170mm",
          specs: { travelMm: 170, stanchion: 36, offset: 44 },
          currentSettings: { sagPct: 28, rebound: 8, compressionHsc: 4, compressionLsc: 6 },
        });

        get().addComponent(bikeId, {
          category: "shock",
          manufacturer: "Fox",
          model: "Float X2 Factory 205x65",
          specs: { travelMm: 65, eyeToEye: 205 },
          currentSettings: { sagPct: 30, rebound: 10, compressionHsc: 3, compressionLsc: 5 },
        });

        get().addComponent(bikeId, {
          category: "tire_front",
          manufacturer: "Maxxis",
          model: "Assegai 29x2.5 WT",
          specs: { width: 2.5, compound: "MaxxGrip", casing: "DD" },
          currentSettings: { pressurePsi: 22 },
        });

        get().addComponent(bikeId, {
          category: "tire_rear",
          manufacturer: "Maxxis",
          model: "Minion DHR II 29x2.4 WT",
          specs: { width: 2.4, compound: "MaxxTerra", casing: "DD" },
          currentSettings: { pressurePsi: 24 },
        });

        get().addComponent(bikeId, {
          category: "motor",
          manufacturer: "Bosch",
          model: "Performance Line CX Gen5",
          specs: { maxTorqueNm: 85, system: "Smart System" },
          currentSettings: { assistMode: "eMTB" },
        });

        get().addComponent(bikeId, {
          category: "battery",
          manufacturer: "Bosch",
          model: "PowerTube 800",
          specs: { capacityWh: 800 },
          currentSettings: {},
        });

        get().addSetup(bikeId, {
          name: "Enduro Dry Trails",
          description: "Für trockene, rootige Trails",
          settingsSnapshot: {
            forkSag: 28,
            forkRebound: 8,
            shockSag: 30,
            shockRebound: 10,
            frontPsi: 22,
            rearPsi: 24,
          },
          isActive: true,
        });

        get().addSetup(bikeId, {
          name: "Wet Roots",
          description: "Nasse, rutschige Bedingungen",
          settingsSnapshot: {
            forkSag: 30,
            forkRebound: 10,
            shockSag: 32,
            shockRebound: 12,
            frontPsi: 20,
            rearPsi: 22,
          },
          isActive: false,
        });

        // Second bike
        const gravelId = get().addBike({
          name: "Specialized Diverge",
          type: "gravel",
          year: 2023,
          frameSize: "54",
          weightKg: 9.2,
          color: "Carbon",
          isDefault: false,
        });

        get().addComponent(gravelId, {
          category: "tire_front",
          manufacturer: "Pathfinder",
          model: "Pro 700x42",
          specs: { width: 42 },
          currentSettings: { pressurePsi: 38 },
        });

        set({ boschConnected: true, boschLive: { speed: 0, soc: 87, riderPower: 0, cadence: 0, odometer: 1247 } });
      },
    }),
    {
      name: "aetherride-storage",
      partialize: (s) => ({
        bikes: s.bikes,
        rides: s.rides,
        riderProfile: s.riderProfile,
        recommendations: s.recommendations,
        activeBikeId: s.activeBikeId,
        boschConnected: s.boschConnected,
      }),
    }
  )
);
