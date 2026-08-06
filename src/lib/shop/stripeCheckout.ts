/**
 * F-SHP-003 Stripe Checkout — ehrlicher Stub
 *
 * Ohne STRIPE_SECRET_KEY: Draft + Hinweis, kein Fake-Payment-Success.
 * Mit Key (Produktion): Session-Shape vorbereitet — Web-Demo default ohne Key.
 * Physische Waren: kein Apple IAP.
 */

import type { MarketplaceCheckoutDraft } from "./marketplace";

export type StripeCheckoutStatus =
  | "not_configured"
  | "draft_only"
  | "session_ready_shape"
  | "blocked_no_demand";

export interface StripeCheckoutPlan {
  status: StripeCheckoutStatus;
  hasSecretKey: boolean;
  publishableKeyPresent: boolean;
  /** Nur Shape — kein echter Stripe-SDK-Call in der Web-Demo */
  sessionCreateShape: {
    mode: "payment";
    line_items: { price_data: { currency: string; unit_amount: number; product_data: { name: string } }; quantity: number }[];
    success_url: string;
    cancel_url: string;
    shipping_options?: unknown[];
  } | null;
  messageDe: string;
}

export function stripeEnvPresent(): {
  secret: boolean;
  publishable: boolean;
} {
  return {
    secret: Boolean(
      typeof process !== "undefined" && process.env.STRIPE_SECRET_KEY
    ),
    publishable: Boolean(
      typeof process !== "undefined" &&
        (process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ||
          process.env.STRIPE_PUBLISHABLE_KEY)
    ),
  };
}

export function planStripeCheckout(
  draft: MarketplaceCheckoutDraft,
  opts?: { demandDocumented?: boolean; baseUrl?: string }
): StripeCheckoutPlan {
  const env = stripeEnvPresent();
  const base = opts?.baseUrl ?? "https://app.aetherride.demo";
  if (!opts?.demandDocumented) {
    return {
      status: "blocked_no_demand",
      hasSecretKey: env.secret,
      publishableKeyPresent: env.publishable,
      sessionCreateShape: null,
      messageDe:
        "Marketplace/Stripe laut Spec erst bei belegter Nachfrage — Affiliate bleibt Default.",
    };
  }
  if (!env.secret) {
    return {
      status: "not_configured",
      hasSecretKey: false,
      publishableKeyPresent: env.publishable,
      sessionCreateShape: null,
      messageDe:
        "Kein STRIPE_SECRET_KEY — kein Checkout, kein Fake-Payment-Success.",
    };
  }
  const line_items = draft.items.map((i) => ({
    price_data: {
      currency: "eur",
      unit_amount: Math.round(i.priceEur * 100),
      product_data: { name: i.name },
    },
    quantity: i.qty,
  }));
  if (draft.shippingEur > 0) {
    line_items.push({
      price_data: {
        currency: "eur",
        unit_amount: Math.round(draft.shippingEur * 100),
        product_data: { name: "Versand" },
      },
      quantity: 1,
    });
  }
  return {
    status: "session_ready_shape",
    hasSecretKey: true,
    publishableKeyPresent: env.publishable,
    sessionCreateShape: {
      mode: "payment",
      line_items,
      success_url: `${base}/checkout?stripe=success`,
      cancel_url: `${base}/checkout?stripe=cancel`,
    },
    messageDe:
      "Session-Shape bereit — echter stripe.checkout.sessions.create erst mit SDK + Key (nicht in Web-Demo ausgeführt).",
  };
}
