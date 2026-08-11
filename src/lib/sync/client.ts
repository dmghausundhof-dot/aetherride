import {
  createClient as createBrowserClient,
  isSupabaseConfigured,
} from "@/lib/supabase/client";
import type { SubscriptionTier } from "@/store/useAppStore";

export type SyncPayload = {
  bikes?: unknown;
  rides?: unknown;
  setups?: unknown;
  consents?: unknown;
  privacyZones?: unknown;
  familyRiders?: unknown;
  activeFamilyRiderId?: string | null;
  riderProfile?: unknown;
  subscriptionTier?: SubscriptionTier;
  commerceMode?: unknown;
  rangeCalibration?: unknown;
  savedRoutes?: unknown;
  routeCollections?: unknown;
  freeTierExtraBike?: boolean;
  maintenanceLogs?: unknown;
  maintenanceIntervals?: unknown;
  rideFeedbacks?: unknown;
  recommendations?: unknown;
  wishlistIds?: unknown;
  bikePhotos?: unknown;
  activeBikeId?: string | null;
  preferredSport?: unknown;
  onboardingDone?: boolean;
  updatedAt?: string;
  payloadVersion?: number;
};

export type PullResult = {
  payload: SyncPayload | null;
  updatedAt: string | null;
};

export class SyncConflictError extends Error {
  remote?: SyncPayload;
  remoteUpdatedAt?: string;

  constructor(
    message: string,
    remote?: SyncPayload,
    remoteUpdatedAt?: string
  ) {
    super(message);
    this.name = "SyncConflictError";
    this.remote = remote;
    this.remoteUpdatedAt = remoteUpdatedAt;
  }
}

export async function pullSync(): Promise<PullResult> {
  const res = await fetch("/api/sync", { method: "GET" });
  if (res.status === 401) return { payload: null, updatedAt: null };
  if (!res.ok) throw new Error(`Sync pull failed: ${res.status}`);
  const data = await res.json();
  return {
    payload: (data.payload as SyncPayload) ?? null,
    updatedAt: data.updatedAt ?? data.payload?.updatedAt ?? null,
  };
}

export async function pushSync(
  payload: SyncPayload,
  clientUpdatedAt?: string | null,
  opts?: { force?: boolean }
): Promise<{ updatedAt: string }> {
  const stamp = new Date().toISOString();
  const bodyPayload = opts?.force
    ? { ...payload, updatedAt: stamp }
    : payload;
  // force: clientUpdatedAt = now → Server akzeptiert (remoteMs > clientMs schlägt fehl)
  const clientAt = opts?.force
    ? stamp
    : (clientUpdatedAt ?? payload.updatedAt ?? null);

  const res = await fetch("/api/sync", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      payload: bodyPayload,
      clientUpdatedAt: clientAt,
    }),
  });
  const data = await res.json().catch(() => ({}));
  if (res.status === 409) {
    throw new SyncConflictError(
      "sync_conflict",
      data.payload as SyncPayload | undefined,
      data.remoteUpdatedAt as string | undefined
    );
  }
  if (!res.ok) throw new Error(data.error || `Sync push failed: ${res.status}`);
  return { updatedAt: data.updatedAt || stamp };
}

export async function syncBidirectional(local: SyncPayload): Promise<{
  merged: SyncPayload;
  direction: "pulled" | "pushed" | "noop";
}> {
  const remote = await pullSync();
  const localAt = local.updatedAt
    ? new Date(local.updatedAt).getTime()
    : 0;
  const remoteAt = remote.updatedAt
    ? new Date(remote.updatedAt).getTime()
    : 0;

  if (!remote.payload) {
    const { updatedAt } = await pushSync({
      ...local,
      updatedAt: new Date().toISOString(),
    });
    return {
      merged: { ...local, updatedAt },
      direction: "pushed",
    };
  }

  if (remoteAt > localAt) {
    return {
      merged: {
        ...remote.payload,
        updatedAt: remote.updatedAt ?? remote.payload.updatedAt,
      },
      direction: "pulled",
    };
  }

  if (localAt > remoteAt) {
    try {
      const { updatedAt } = await pushSync(local, remote.updatedAt);
      return {
        merged: { ...local, updatedAt },
        direction: "pushed",
      };
    } catch (e) {
      if (e instanceof SyncConflictError) throw e;
      throw e;
    }
  }

  return {
    merged: local.updatedAt
      ? local
      : { ...local, updatedAt: remote.updatedAt ?? undefined },
    direction: "noop",
  };
}

export async function fetchProfileTier(): Promise<{
  tier: SubscriptionTier;
  status: string;
  email: string | null;
} | null> {
  if (!isSupabaseConfigured()) return null;
  const supabase = createBrowserClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  const { data } = await supabase
    .from("profiles")
    .select("subscription_tier, subscription_status")
    .eq("id", user.id)
    .maybeSingle();
  return {
    tier: (data?.subscription_tier as SubscriptionTier) || "free",
    status: data?.subscription_status || "inactive",
    email: user.email ?? null,
  };
}
