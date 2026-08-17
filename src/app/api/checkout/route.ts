import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { COMMERCE_CLOSED, isCommerceOpen } from "@/lib/config/appStage";
import { appUrl, getStripe } from "@/lib/stripe";

/** Marketplace one-time Checkout (physische Waren — kein IAP). */
export async function POST(req: Request) {
  if (!isCommerceOpen()) {
    return NextResponse.json(COMMERCE_CLOSED, { status: 403 });
  }
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "login_required" }, { status: 401 });
    }

    const body = await req.json();
    const items = Array.isArray(body.items) ? body.items : [];
    const shippingEur = Number(body.shippingEur ?? 5.9);
    const legalAccepted = Boolean(body.legalAccepted);

    if (!legalAccepted) {
      return NextResponse.json(
        { error: "legal_not_accepted" },
        { status: 400 }
      );
    }
    if (items.length === 0) {
      return NextResponse.json({ error: "empty_cart" }, { status: 400 });
    }

    const line_items = items.map(
      (i: { name: string; priceEur: number; qty: number }) => ({
        quantity: Math.max(1, Number(i.qty) || 1),
        price_data: {
          currency: "eur",
          unit_amount: Math.round(Number(i.priceEur) * 100),
          product_data: { name: String(i.name).slice(0, 120) },
        },
      })
    );

    if (shippingEur > 0) {
      line_items.push({
        quantity: 1,
        price_data: {
          currency: "eur",
          unit_amount: Math.round(shippingEur * 100),
          product_data: { name: "Versand" },
        },
      });
    }

    const totalCents = line_items.reduce(
      (s: number, li: { quantity: number; price_data: { unit_amount: number } }) =>
        s + li.quantity * li.price_data.unit_amount,
      0
    );

    const stripe = getStripe();
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items,
      success_url: `${appUrl()}/checkout?marketplace=success`,
      cancel_url: `${appUrl()}/shop?marketplace=cancel`,
      client_reference_id: user.id,
      metadata: {
        supabase_user_id: user.id,
        kind: "marketplace",
      },
    });

    const { error } = await supabase.from("orders").insert({
      user_id: user.id,
      stripe_session_id: session.id,
      status: "pending",
      line_items: items,
      total_cents: totalCents,
      currency: "eur",
    });

    if (error) {
      console.error("[checkout] order insert", error.message);
    }

    return NextResponse.json({ url: session.url });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "checkout failed" },
      { status: 500 }
    );
  }
}
