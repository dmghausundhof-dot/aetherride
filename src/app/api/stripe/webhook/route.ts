import { NextRequest, NextResponse } from "next/server";
import {
  getStripeClient,
  getStripeWebhookSecret,
} from "@/lib/shop/stripeCheckout";
import { recordStripeOrder } from "@/lib/shop/stripeOrders";

export const runtime = "nodejs";

/**
 * Stripe Webhook — checkout.session.completed
 * Benötigt STRIPE_WEBHOOK_SECRET. Kein Fake-Success ohne Signatur.
 */
export async function POST(req: NextRequest) {
  const stripe = getStripeClient();
  const secret = getStripeWebhookSecret();
  if (!stripe || !secret) {
    return NextResponse.json(
      {
        error:
          "Webhook nicht konfiguriert (STRIPE_SECRET_KEY / STRIPE_WEBHOOK_SECRET).",
      },
      { status: 503 }
    );
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return NextResponse.json({ error: "Missing stripe-signature" }, { status: 400 });
  }

  const rawBody = await req.text();
  let event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, secret);
  } catch (e) {
    console.error("[stripe/webhook] signature", e);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    await recordStripeOrder({
      stripeSessionId: session.id,
      paymentStatus: session.payment_status ?? "unknown",
      amountTotal: session.amount_total,
      currency: session.currency,
      customerEmail: session.customer_details?.email ?? session.customer_email,
      userId: session.metadata?.userId || null,
      raw: {
        mode: session.mode,
        status: session.status,
        metadata: session.metadata,
      },
    });
  }

  return NextResponse.json({ received: true, type: event.type });
}
