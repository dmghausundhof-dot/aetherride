/**
 * F-SHP-003 Stripe Checkout
 *
 * Gates (ehrlich):
 * 1) Nachfrage: STRIPE_DEMAND_DOCUMENTED=true (oder NEXT_PUBLIC_…)
 * 2) STRIPE_SECRET_KEY gesetzt
 * Sonst: kein Fake-Payment-Success. Affiliate bleibt Default.
 */

import Stripe from "stripe";
import type { MarketplaceCheckoutDraft } from "./marketplace";

export type StripeCheckoutStatus =
  | "not_configured"
  | "draft_only"
  | "session_ready"
  | "blocked_no_demand";

export interface StripeCheckoutPlan {
  status: StripeCheckoutStatus;
  hasSecretKey: boolean;
  publishableKeyPresent: boolean;
  demandDocumented: boolean;
  sessionCreateShape: {
    mode: "payment";
    line_items: {
      price_data: {
        currency: string;
        unit_amount: number;
        product_data: { name: string };
      };
      quantity: number;
    }[];
    success_url: string;
    cancel_url: string;
  } | null;
  messageDe: string;
}

export function isStripeDemandDocumented(): boolean {
  return (
    process.env.STRIPE_DEMAND_DOCUMENTED === "true" ||
    process.env.NEXT_PUBLIC_STRIPE_DEMAND_DOCUMENTED === "true"
  );
}

export function getStripePublishableKey(): string | null {
  return (
    process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY?.trim() ||
    process.env.STRIPE_PUBLISHABLE_KEY?.trim() ||
    null
  );
}

export function getStripeSecretKey(): string | null {
  return process.env.STRIPE_SECRET_KEY?.trim() || null;
}

export function getStripeWebhookSecret(): string | null {
  return process.env.STRIPE_WEBHOOK_SECRET?.trim() || null;
}

export function stripeEnvPresent(): {
  secret: boolean;
  publishable: boolean;
  webhook: boolean;
} {
  return {
    secret: Boolean(getStripeSecretKey()),
    publishable: Boolean(getStripePublishableKey()),
    webhook: Boolean(getStripeWebhookSecret()),
  };
}

export function getStripeClient(): Stripe | null {
  const key = getStripeSecretKey();
  if (!key) return null;
  return new Stripe(key, {
    apiVersion: "2026-07-29.dahlia",
    typescript: true,
  });
}

function siteBaseUrl(fallback?: string): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    process.env.SITE_URL?.trim() ||
    fallback ||
    "http://localhost:3000"
  ).replace(/\/$/, "");
}

export function buildCheckoutLineItems(draft: MarketplaceCheckoutDraft) {
  const line_items = draft.items.map((i) => ({
    price_data: {
      currency: "eur" as const,
      unit_amount: Math.round(i.priceEur * 100),
      product_data: { name: i.name },
    },
    quantity: i.qty,
  }));
  if (draft.shippingEur > 0) {
    line_items.push({
      price_data: {
        currency: "eur" as const,
        unit_amount: Math.round(draft.shippingEur * 100),
        product_data: { name: "Versand" },
      },
      quantity: 1,
    });
  }
  return line_items;
}

export function planStripeCheckout(
  draft: MarketplaceCheckoutDraft,
  opts?: { demandDocumented?: boolean; baseUrl?: string }
): StripeCheckoutPlan {
  const env = stripeEnvPresent();
  const demand =
    opts?.demandDocumented !== undefined
      ? opts.demandDocumented
      : isStripeDemandDocumented();
  const base = siteBaseUrl(opts?.baseUrl);

  if (!demand) {
    return {
      status: "blocked_no_demand",
      hasSecretKey: env.secret,
      publishableKeyPresent: env.publishable,
      demandDocumented: false,
      sessionCreateShape: null,
      messageDe:
        "Marketplace/Stripe laut Spec erst bei belegter Nachfrage — Affiliate bleibt Default. Setze STRIPE_DEMAND_DOCUMENTED=true.",
    };
  }
  if (!env.secret) {
    return {
      status: "not_configured",
      hasSecretKey: false,
      publishableKeyPresent: env.publishable,
      demandDocumented: true,
      sessionCreateShape: null,
      messageDe:
        "Kein STRIPE_SECRET_KEY — kein Checkout, kein Fake-Payment-Success.",
    };
  }

  const line_items = buildCheckoutLineItems(draft);
  return {
    status: "session_ready",
    hasSecretKey: true,
    publishableKeyPresent: env.publishable,
    demandDocumented: true,
    sessionCreateShape: {
      mode: "payment",
      line_items,
      success_url: `${base}/checkout?stripe=success`,
      cancel_url: `${base}/checkout?stripe=cancel`,
    },
    messageDe:
      "Stripe konfiguriert — Checkout-Session kann serverseitig erstellt werden.",
  };
}

export type CreateSessionResult =
  | {
      ok: true;
      sessionId: string;
      url: string;
    }
  | {
      ok: false;
      status: StripeCheckoutStatus | "empty_cart" | "stripe_error";
      messageDe: string;
    };

/** Echter stripe.checkout.sessions.create — nur Server */
export async function createStripeCheckoutSession(
  draft: MarketplaceCheckoutDraft,
  opts?: { customerEmail?: string | null; userId?: string | null }
): Promise<CreateSessionResult> {
  const plan = planStripeCheckout(draft);
  if (plan.status !== "session_ready" || !plan.sessionCreateShape) {
    return {
      ok: false,
      status: plan.status,
      messageDe: plan.messageDe,
    };
  }
  if (!draft.items.length) {
    return {
      ok: false,
      status: "empty_cart",
      messageDe: "Warenkorb leer.",
    };
  }

  const stripe = getStripeClient();
  if (!stripe) {
    return {
      ok: false,
      status: "not_configured",
      messageDe: "Stripe-Client nicht verfügbar.",
    };
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: plan.sessionCreateShape.line_items,
      success_url: `${plan.sessionCreateShape.success_url}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: plan.sessionCreateShape.cancel_url,
      customer_email: opts?.customerEmail || undefined,
      metadata: {
        source: "aetherride",
        userId: opts?.userId || "",
        itemCount: String(draft.items.length),
        totalEur: String(draft.totalEur),
      },
      shipping_address_collection: {
        allowed_countries: ["DE", "AT", "CH", "LI"],
      },
    });
    if (!session.url) {
      return {
        ok: false,
        status: "stripe_error",
        messageDe: "Stripe Session ohne URL.",
      };
    }
    return { ok: true, sessionId: session.id, url: session.url };
  } catch (e) {
    return {
      ok: false,
      status: "stripe_error",
      messageDe:
        e instanceof Error ? e.message : "Stripe Checkout fehlgeschlagen.",
    };
  }
}

export async function retrieveCheckoutSession(sessionId: string) {
  const stripe = getStripeClient();
  if (!stripe) return null;
  return stripe.checkout.sessions.retrieve(sessionId);
}
