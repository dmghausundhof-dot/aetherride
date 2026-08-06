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
  riderProfile?: unknown;
  subscriptionTier?: SubscriptionTier;
  commerceMode?: unknown;
  activeBikeId?: string | null;
  updatedAt?: string;
};

export async function pullSync(): Promise<SyncPayload | null> {
  const res = await fetch("/api/sync", { method: "GET" });
  if (res.status === 401) return null;
  if (!res.ok) throw new Error(`Sync pull failed: ${res.status}`);
  const data = await res.json();
  return (data.payload as SyncPayload) ?? null;
}

export async function pushSync(payload: SyncPayload): Promise<void> {
  const res = await fetch("/api/sync", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ payload }),
  });
  if (!res.ok) throw new Error(`Sync push failed: ${res.status}`);
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
