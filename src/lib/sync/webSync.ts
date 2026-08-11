/**
 * Web-Sync: Payload, Apply, Bidirectional, Konflikt-Auflösung.
 */

import { useAppStore } from "@/store/useAppStore";
import {
  pushSync,
  syncBidirectional,
  SyncConflictError,
  type SyncPayload,
} from "@/lib/sync/client";
import {
  buildSyncPayload,
  remoteToApplyPatch,
  type AppSyncSlice,
} from "@/lib/sync/payload";

export type SyncConflictState = {
  remote: SyncPayload;
  remoteUpdatedAt?: string;
  localUpdatedAt?: string;
};

export type WebSyncResult =
  | {
      ok: true;
      direction: "pulled" | "pushed" | "noop";
      message: string;
    }
  | {
      ok: false;
      conflict: true;
      message: string;
      conflictState: SyncConflictState;
    }
  | {
      ok: false;
      conflict: false;
      message: string;
    };

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

function summarizePayload(p: SyncPayload | undefined | null): string {
  if (!p) return "leer";
  const n = (x: unknown) => (Array.isArray(x) ? x.length : 0);
  return `${n(p.bikes)} Bikes · ${n(p.rides)} Rides · ${n(p.savedRoutes)} Touren · ${n(p.routeCollections)} Sammlungen`;
}

export async function runWebSync(): Promise<WebSyncResult> {
  try {
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
        ? `Sync: Cloud übernommen (${summarizePayload(merged)}).`
        : direction === "pushed"
          ? `Sync: Dieses Gerät hochgeladen (${summarizePayload(merged)}).`
          : "Sync: bereits aktuell.";
    return { ok: true, direction, message };
  } catch (e) {
    if (e instanceof SyncConflictError && e.remote) {
      const local = buildSyncPayload(sliceFromAppStore());
      return {
        ok: false,
        conflict: true,
        message:
          "Konflikt: Cloud und dieses Gerät haben unterschiedliche Stände.",
        conflictState: {
          remote: e.remote,
          remoteUpdatedAt: e.remoteUpdatedAt,
          localUpdatedAt: local.updatedAt,
        },
      };
    }
    return {
      ok: false,
      conflict: false,
      message: e instanceof Error ? e.message : "Sync fehlgeschlagen",
    };
  }
}

/** Nutzer wählt: Cloud behalten oder lokales Gerät erzwingen. */
export async function resolveSyncConflict(
  choice: "keep_remote" | "keep_local",
  conflict: SyncConflictState
): Promise<WebSyncResult> {
  try {
    if (choice === "keep_remote") {
      applySyncPayloadToStore(conflict.remote);
      return {
        ok: true,
        direction: "pulled",
        message: `Konflikt gelöst: Cloud behalten (${summarizePayload(conflict.remote)}).`,
      };
    }
    const local = buildSyncPayload(sliceFromAppStore());
    const { updatedAt } = await pushSync(local, null, { force: true });
    return {
      ok: true,
      direction: "pushed",
      message: `Konflikt gelöst: Gerät erzwungen hochgeladen (${updatedAt.slice(0, 19)}).`,
    };
  } catch (e) {
    return {
      ok: false,
      conflict: false,
      message: e instanceof Error ? e.message : "Auflösung fehlgeschlagen",
    };
  }
}

export { summarizePayload };
