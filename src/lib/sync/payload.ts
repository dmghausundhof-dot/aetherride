/**
 * Zentrale Sync-Payload: Garage, Library, Activities, Collections, Feedback.
 * LWW Snapshot — kompatibel mit /api/sync + mobile.
 */

import type { SyncPayload } from "@/lib/sync/client";
import type { SubscriptionTier } from "@/store/useAppStore";

/** Snapshot aus App-Store-Slice (kein Zustand-Import zirkulär) */
export type AppSyncSlice = {
  bikes: unknown;
  rides: unknown;
  consents: unknown;
  privacyZones: unknown;
  familyRiders: unknown;
  activeFamilyRiderId: string | null;
  ownSetupByBikeId?: Record<string, string>;
  riderProfile: unknown;
  subscriptionTier: SubscriptionTier;
  commerceMode: unknown;
  rangeCalibration: unknown;
  savedRoutes: unknown;
  routeCollections: unknown;
  maintenanceLogs: unknown;
  maintenanceIntervals: unknown;
  rideFeedbacks: unknown;
  activeBikeId: string | null;
  preferredSport: unknown;
  preferredSports?: unknown;
  onboardingDone: boolean;
  recommendations?: unknown;
};

export const SYNC_PAYLOAD_VERSION = 2;

export function buildSyncPayload(s: AppSyncSlice): SyncPayload {
  return {
    payloadVersion: SYNC_PAYLOAD_VERSION,
    bikes: s.bikes,
    rides: s.rides,
    consents: s.consents,
    privacyZones: s.privacyZones,
    familyRiders: s.familyRiders,
    activeFamilyRiderId: s.activeFamilyRiderId,
    ownSetupByBikeId: s.ownSetupByBikeId,
    riderProfile: s.riderProfile,
    subscriptionTier: s.subscriptionTier,
    commerceMode: s.commerceMode,
    rangeCalibration: s.rangeCalibration,
    savedRoutes: s.savedRoutes,
    routeCollections: s.routeCollections,
    maintenanceLogs: s.maintenanceLogs,
    maintenanceIntervals: s.maintenanceIntervals,
    rideFeedbacks: s.rideFeedbacks,
    activeBikeId: s.activeBikeId,
    preferredSport: s.preferredSport,
    preferredSports: s.preferredSports,
    onboardingDone: s.onboardingDone,
    recommendations: s.recommendations,
    updatedAt: new Date().toISOString(),
  };
}

/** Felder, die beim Pull auf den Store gemappt werden */
export type RemoteApplyPatch = {
  bikes?: unknown;
  rides?: unknown;
  consents?: unknown;
  privacyZones?: unknown;
  familyRiders?: unknown;
  activeFamilyRiderId?: string | null;
  ownSetupByBikeId?: Record<string, string> | null;
  riderProfile?: unknown;
  subscriptionTier?: SubscriptionTier;
  commerceMode?: unknown;
  rangeCalibration?: unknown;
  savedRoutes?: unknown;
  routeCollections?: unknown;
  maintenanceLogs?: unknown;
  maintenanceIntervals?: unknown;
  rideFeedbacks?: unknown;
  activeBikeId?: string | null;
  preferredSport?: unknown;
  preferredSports?: unknown;
  onboardingDone?: boolean;
  recommendations?: unknown;
};

export function remoteToApplyPatch(remote: SyncPayload): RemoteApplyPatch {
  const patch: RemoteApplyPatch = {};
  if (Array.isArray(remote.bikes)) patch.bikes = remote.bikes;
  if (Array.isArray(remote.rides)) patch.rides = remote.rides;
  if (Array.isArray(remote.consents)) patch.consents = remote.consents;
  if (Array.isArray(remote.privacyZones))
    patch.privacyZones = remote.privacyZones;
  if (Array.isArray(remote.familyRiders))
    patch.familyRiders = remote.familyRiders;
  if (remote.activeFamilyRiderId !== undefined)
    patch.activeFamilyRiderId = remote.activeFamilyRiderId ?? null;
  if (remote.ownSetupByBikeId && typeof remote.ownSetupByBikeId === "object")
    patch.ownSetupByBikeId = remote.ownSetupByBikeId;
  if (remote.riderProfile && typeof remote.riderProfile === "object")
    patch.riderProfile = remote.riderProfile;
  if (remote.subscriptionTier === "pro" || remote.subscriptionTier === "free")
    patch.subscriptionTier = remote.subscriptionTier;
  if (
    remote.commerceMode === "affiliate" ||
    remote.commerceMode === "marketplace"
  )
    patch.commerceMode = remote.commerceMode;
  if (remote.rangeCalibration && typeof remote.rangeCalibration === "object")
    patch.rangeCalibration = remote.rangeCalibration;
  if (Array.isArray(remote.savedRoutes)) patch.savedRoutes = remote.savedRoutes;
  if (Array.isArray(remote.routeCollections))
    patch.routeCollections = remote.routeCollections;
  if (Array.isArray(remote.maintenanceLogs))
    patch.maintenanceLogs = remote.maintenanceLogs;
  if (Array.isArray(remote.maintenanceIntervals))
    patch.maintenanceIntervals = remote.maintenanceIntervals;
  if (Array.isArray(remote.rideFeedbacks))
    patch.rideFeedbacks = remote.rideFeedbacks;
  if (remote.activeBikeId !== undefined)
    patch.activeBikeId = remote.activeBikeId ?? null;
  if (remote.preferredSport !== undefined)
    patch.preferredSport = remote.preferredSport;
  if (remote.preferredSports !== undefined)
    patch.preferredSports = remote.preferredSports;
  if (typeof remote.onboardingDone === "boolean")
    patch.onboardingDone = remote.onboardingDone;
  if (Array.isArray(remote.recommendations))
    patch.recommendations = remote.recommendations;
  return patch;
}
