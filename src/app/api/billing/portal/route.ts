import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { appUrl, getStripe } from "@/lib/stripe";

export async function POST() {
  try {
    const supabase = await createClient();
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
        { error: "no_stripe_customer" },
        { status: 400 }
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
      { status: 500 }
    );
  }
}
