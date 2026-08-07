import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { upsertSubscriptionTierInSyncSnapshot } from "@/lib/billing/syncTier";

/**
 * Play Billing verify (2B):
 * - Always writes profiles.subscription_tier AND sync_snapshots.payload.subscriptionTier
 *   so Mobile LWW does not revert to free.
 * - Until 2A (Google Play Developer API): trusts non-empty purchaseToken
 *   (document as PLAY_VERIFY_STUB / trusted-token MVP).
 * - When GOOGLE_PLAY_SERVICE_ACCOUNT_JSON is set, real validation is expected (2A) —
 *   currently returns 501 so we do not fake Google checks.
 *
 * Ops: create Play product `aetherride_pro_monthly` (see mobile/README Billing).
 */
export async function POST(req: Request) {
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
      typeof body?.productId === "string" ? body.productId : null;
    const packageName =
      typeof body?.packageName === "string" ? body.packageName : null;

    if (!purchaseToken) {
      return NextResponse.json(
        { error: "purchaseToken required" },
        { status: 400 }
      );
    }

    const hasGoogleCreds = Boolean(
      process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON?.trim()
    );
    const forceStub = process.env.PLAY_VERIFY_STUB === "1";

    // 2A: credentials present and stub not forced → Google API (not wired yet).
    if (hasGoogleCreds && !forceStub) {
      return NextResponse.json(
        {
          error:
            "Google Play Developer API validation pending (2A). Set PLAY_VERIFY_STUB=1 for trusted-token path until then.",
        },
        { status: 501 }
      );
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
        mode: "trusted_token_mvp",
      },
    });

    if (profileErr) {
      return NextResponse.json({
        ok: true,
        tier: "pro",
        via: "sync_snapshots",
        profileError: profileErr.message,
      });
    }

    return NextResponse.json({
      ok: true,
      tier: "pro",
      via: "profiles+sync_snapshots",
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
