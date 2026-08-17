import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { upsertSubscriptionTierInSyncSnapshot } from "@/lib/billing/syncTier";
import { verifyPlayPurchaseWithGoogle } from "@/lib/billing/googlePlayVerify";
import { COMMERCE_CLOSED, isCommerceOpen } from "@/lib/config/appStage";

/**
 * Play Billing verify (2B + 2A):
 * - Always writes profiles.subscription_tier AND sync_snapshots.payload.subscriptionTier.
 * - PLAY_VERIFY_STUB=1 → trusted-token MVP (non-empty purchaseToken).
 * - Else if GOOGLE_PLAY_SERVICE_ACCOUNT_JSON → Android Publisher API (2A).
 * - Else → trusted-token MVP (documented until credentials exist).
 *
 * Ops: create Play product `aetherride_pro_monthly` (see mobile/README Billing).
 */
export async function POST(req: Request) {
  if (!isCommerceOpen()) {
    return NextResponse.json(COMMERCE_CLOSED, { status: 403 });
  }
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const body = await req.json();
    const purchaseToken =
      typeof body?.purchaseToken === "string" ? body.purchaseToken.trim() : "";
    const productId =
      typeof body?.productId === "string" && body.productId
        ? body.productId
        : "aetherride_pro_monthly";
    const packageName =
      typeof body?.packageName === "string" && body.packageName
        ? body.packageName
        : "com.aetherride.aetherride_mobile";

    if (!purchaseToken) {
      return NextResponse.json(
        { error: "purchaseToken required" },
        { status: 400 }
      );
    }

    const creds = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON?.trim() ?? "";
    const forceStub = process.env.PLAY_VERIFY_STUB === "1";
    let mode: "trusted_token_mvp" | "google_api" = "trusted_token_mvp";

    if (creds && !forceStub) {
      const verified = await verifyPlayPurchaseWithGoogle({
        packageName,
        productId,
        purchaseToken,
        serviceAccountJson: creds,
      });
      if (!verified.ok) {
        return NextResponse.json(
          {
            error: "play_purchase_invalid",
            detail: verified.error,
          },
          { status: 402 }
        );
      }
      mode = "google_api";
    }

    const admin = createAdminClient();
    const now = new Date().toISOString();

    const { error: profileErr } = await admin
      .from("profiles")
      .update({
        subscription_tier: "pro",
        subscription_status: "active",
        updated_at: now,
      })
      .eq("id", user.id);

    await upsertSubscriptionTierInSyncSnapshot(admin, user.id, "pro", {
      playPurchase: {
        productId,
        packageName,
        verifiedAt: now,
        tokenLen: purchaseToken.length,
        mode,
      },
    });

    if (profileErr) {
      return NextResponse.json({
        ok: true,
        tier: "pro",
        via: "sync_snapshots",
        mode,
        profileError: profileErr.message,
      });
    }

    return NextResponse.json({
      ok: true,
      tier: "pro",
      via: "profiles+sync_snapshots",
      mode,
      productId,
      packageName,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "play-verify failed" },
      { status: 500 }
    );
  }
}
