/**
 * Web-Sync-Helfer: Payload bauen, Remote anwenden, bidirektional.
 */

import { useAppStore } from "@/store/useAppStore";
import {
  syncBidirectional,
  type SyncPayload,
} from "@/lib/sync/client";
import {
  buildSyncPayload,
  remoteToApplyPatch,
  type AppSyncSlice,
} from "@/lib/sync/payload";

export function sliceFromAppStore(): AppSyncSlice {
  const s = useAppStore.getState();
  return {
    bikes: s.bikes,
    rides: s.rides,
    consents: s.consents,
    privacyZones: s.privacyZones,
    familyRiders: s.familyRiders,
    activeFamilyRiderId: s.activeFamilyRiderId,
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
    onboardingDone: s.onboardingDone,
    recommendations: s.recommendations,
  };
}

export function applySyncPayloadToStore(remote: SyncPayload) {
  const patch = remoteToApplyPatch(remote);
  useAppStore.setState((s) => ({
    ...s,
    ...(patch as Partial<typeof s>),
  }));
  if (patch.subscriptionTier === "pro" || patch.subscriptionTier === "free") {
    useAppStore.getState().setSubscriptionTier(patch.subscriptionTier);
  }
}

export async function runWebSync(): Promise<{
  direction: "pulled" | "pushed" | "noop";
  message: string;
}> {
  const local = buildSyncPayload(sliceFromAppStore());
  const { merged, direction } = await syncBidirectional(local);
  if (direction === "pulled") {
    applySyncPayloadToStore(merged);
  }
  if (direction === "pushed" && merged.subscriptionTier === "pro") {
    useAppStore.getState().setSubscriptionTier("pro");
  }
  const message =
    direction === "pulled"
      ? "Sync: Remote übernommen (LWW)."
      : direction === "pushed"
        ? "Sync: Lokal hochgeladen."
        : "Sync: bereits aktuell.";
  return { direction, message };
}
