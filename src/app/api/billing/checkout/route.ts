import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  appUrl,
  getStripe,
  STRIPE_PRICE_PRO_MONTHLY,
  STRIPE_PRICE_PRO_YEARLY,
} from "@/lib/stripe";

export async function POST(req: Request) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user?.email) {
      return NextResponse.json({ error: "login_required" }, { status: 401 });
    }

    const body = await req.json();
    const interval = body.interval === "year" ? "year" : "month";
    const priceId =
      interval === "year" ? STRIPE_PRICE_PRO_YEARLY : STRIPE_PRICE_PRO_MONTHLY;

    const { data: profile } = await supabase
      .from("profiles")
      .select("stripe_customer_id")
      .eq("id", user.id)
      .maybeSingle();

    const stripe = getStripe();
    let customerId = profile?.stripe_customer_id as string | null;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_user_id: user.id },
      });
      customerId = customer.id;
      await supabase
        .from("profiles")
        .update({ stripe_customer_id: customerId })
        .eq("id", user.id);
    }

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${appUrl()}/profile?billing=success`,
      cancel_url: `${appUrl()}/profile?billing=cancel`,
      client_reference_id: user.id,
      metadata: {
        supabase_user_id: user.id,
        kind: "pro_subscription",
        interval,
      },
      subscription_data: {
        metadata: {
          supabase_user_id: user.id,
          kind: "pro_subscription",
        },
      },
    });

    return NextResponse.json({ url: session.url });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "checkout failed" },
      { status: 500 }
    );
  }
}
