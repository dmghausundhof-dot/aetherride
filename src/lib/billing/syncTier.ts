import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Keep Mobile LWW (`/api/sync` → sync_snapshots.payload.subscriptionTier)
 * aligned with profiles.subscription_tier after Stripe/Play billing events.
 */
export async function upsertSubscriptionTierInSyncSnapshot(
  admin: SupabaseClient,
  userId: string,
  tier: "free" | "pro",
  extra?: Record<string, unknown>
): Promise<void> {
  const now = new Date().toISOString();
  const { data: snap } = await admin
    .from("sync_snapshots")
    .select("payload")
    .eq("user_id", userId)
    .maybeSingle();
  const payload =
    snap?.payload && typeof snap.payload === "object"
      ? { ...(snap.payload as Record<string, unknown>) }
      : {};
  payload.subscriptionTier = tier;
  payload.updatedAt = now;
  if (extra) {
    Object.assign(payload, extra);
  }
  await admin.from("sync_snapshots").upsert(
    {
      user_id: userId,
      payload,
      updated_at: now,
    },
    { onConflict: "user_id" }
  );
}
