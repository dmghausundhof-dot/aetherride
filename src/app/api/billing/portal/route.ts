import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { COMMERCE_CLOSED, isCommerceOpen } from "@/lib/config/appStage";
import { appUrl, getStripe } from "@/lib/stripe";

/** Cookie (Web) oder Authorization: Bearer (Mobile). */
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
      return NextResponse.json({ error: "login_required" }, { status: 401 });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("stripe_customer_id")
      .eq("id", user.id)
      .maybeSingle();

    if (!profile?.stripe_customer_id) {
      return NextResponse.json(
        {
          error: "no_stripe_customer",
          message:
            "Noch kein Stripe-Kunde — zuerst Pro über Checkout oder Play abonnieren.",
        },
        { status: 400 },
      );
    }

    const stripe = getStripe();
    const portal = await stripe.billingPortal.sessions.create({
      customer: profile.stripe_customer_id,
      return_url: `${appUrl()}/profile`,
    });

    return NextResponse.json({ url: portal.url });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "portal failed" },
      { status: 500 },
    );
  }
}
