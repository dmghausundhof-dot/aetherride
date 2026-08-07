import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";

/**
 * MVP Play Billing verify: non-empty purchaseToken → set profiles.subscription_tier = pro.
 * Full Google Play Developer API validation is out of scope for this shell.
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

    if (profileErr) {
      // Fallback: note tier in sync_snapshots payload when profiles column/update fails.
      const { data: snap } = await admin
        .from("sync_snapshots")
        .select("payload")
        .eq("user_id", user.id)
        .maybeSingle();
      const payload =
        snap?.payload && typeof snap.payload === "object"
          ? { ...(snap.payload as Record<string, unknown>) }
          : {};
      payload.subscriptionTier = "pro";
      payload.playPurchase = {
        productId,
        packageName,
        verifiedAt: now,
        tokenLen: purchaseToken.length,
      };
      payload.updatedAt = now;
      await admin.from("sync_snapshots").upsert(
        {
          user_id: user.id,
          payload,
          updated_at: now,
        },
        { onConflict: "user_id" }
      );
      return NextResponse.json({
        ok: true,
        tier: "pro",
        via: "sync_snapshots",
      });
    }

    return NextResponse.json({
      ok: true,
      tier: "pro",
      via: "profiles",
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
