import { NextResponse } from "next/server";
import type Stripe from "stripe";
import { createAdminClient } from "@/lib/supabase/admin";
import { getStripe } from "@/lib/stripe";
import { upsertSubscriptionTierInSyncSnapshot } from "@/lib/billing/syncTier";
import { isCommerceOpen } from "@/lib/config/appStage";

export const runtime = "nodejs";

async function setProFromSubscription(
  admin: ReturnType<typeof createAdminClient>,
  sub: Stripe.Subscription
) {
  const userId =
    sub.metadata?.supabase_user_id ||
    (typeof sub.customer === "string" ? null : null);
  const customerId =
    typeof sub.customer === "string" ? sub.customer : sub.customer.id;

  const status = sub.status;
  const active = status === "active" || status === "trialing";

  let resolvedUserId = userId;
  if (!resolvedUserId) {
    const { data } = await admin
      .from("profiles")
      .select("id")
      .eq("stripe_customer_id", customerId)
      .maybeSingle();
    resolvedUserId = data?.id ?? null;
  }
  if (!resolvedUserId) return;

  await admin
    .from("profiles")
    .update({
      subscription_tier: active ? "pro" : "free",
      subscription_status: status,
      stripe_customer_id: customerId,
      stripe_subscription_id: sub.id,
      updated_at: new Date().toISOString(),
    })
    .eq("id", resolvedUserId);

  await upsertSubscriptionTierInSyncSnapshot(
    admin,
    resolvedUserId,
    active ? "pro" : "free",
    { stripeSubscriptionId: sub.id }
  );
}

export async function POST(req: Request) {
  if (!isCommerceOpen()) {
    return NextResponse.json({
      ok: true,
      ignored: true,
      reason: "commerce_closed",
    });
  }
  const stripe = getStripe();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    return NextResponse.json(
      { error: "STRIPE_WEBHOOK_SECRET missing" },
      { status: 500 }
    );
  }

  const raw = await req.text();
  const sig = req.headers.get("stripe-signature");
  if (!sig) {
    return NextResponse.json({ error: "no signature" }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(raw, sig, secret);
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "invalid signature" },
      { status: 400 }
    );
  }

  const admin = createAdminClient();

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId =
          session.metadata?.supabase_user_id || session.client_reference_id;
        const kind = session.metadata?.kind;

        if (kind === "marketplace" && session.id) {
          await admin
            .from("orders")
            .update({
              status: "paid",
              stripe_payment_intent_id:
                typeof session.payment_intent === "string"
                  ? session.payment_intent
                  : session.payment_intent?.id ?? null,
              updated_at: new Date().toISOString(),
            })
            .eq("stripe_session_id", session.id);
        }

        if (
          kind === "pro_subscription" &&
          userId &&
          session.subscription
        ) {
          const subId =
            typeof session.subscription === "string"
              ? session.subscription
              : session.subscription.id;
          const sub = await stripe.subscriptions.retrieve(subId);
          await setProFromSubscription(admin, sub);
        }
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.created": {
        const sub = event.data.object as Stripe.Subscription;
        await setProFromSubscription(admin, sub);
        break;
      }
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const customerId =
          typeof sub.customer === "string" ? sub.customer : sub.customer.id;
        const { data } = await admin
          .from("profiles")
          .select("id")
          .eq("stripe_customer_id", customerId)
          .maybeSingle();
        if (data?.id) {
          await admin
            .from("profiles")
            .update({
              subscription_tier: "free",
              subscription_status: "canceled",
              stripe_subscription_id: null,
              updated_at: new Date().toISOString(),
            })
            .eq("id", data.id);
          await upsertSubscriptionTierInSyncSnapshot(admin, data.id, "free");
        }
        break;
      }
      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const customerId =
          typeof invoice.customer === "string"
            ? invoice.customer
            : invoice.customer?.id;
        if (customerId) {
          await admin
            .from("profiles")
            .update({
              subscription_status: "past_due",
              updated_at: new Date().toISOString(),
            })
            .eq("stripe_customer_id", customerId);
        }
        break;
      }
      default:
        break;
    }
  } catch (e) {
    console.error("[stripe webhook]", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "handler failed" },
      { status: 500 }
    );
  }

  return NextResponse.json({ received: true });
}
