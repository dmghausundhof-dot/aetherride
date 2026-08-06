import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ user: null });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select(
        "display_name, subscription_tier, subscription_status, stripe_customer_id"
      )
      .eq("id", user.id)
      .maybeSingle();

    return NextResponse.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: profile?.display_name ?? null,
        subscriptionTier: profile?.subscription_tier ?? "free",
        subscriptionStatus: profile?.subscription_status ?? "inactive",
        hasStripeCustomer: Boolean(profile?.stripe_customer_id),
      },
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "me failed", user: null },
      { status: 500 }
    );
  }
}
