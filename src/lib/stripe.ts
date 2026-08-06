import Stripe from "stripe";

let stripeSingleton: Stripe | null = null;

export function getStripe(): Stripe {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new Error("Missing STRIPE_SECRET_KEY");
  }
  if (!stripeSingleton) {
    stripeSingleton = new Stripe(key, {
      apiVersion: "2026-07-29.dahlia",
      typescript: true,
    });
  }
  return stripeSingleton;
}

export function appUrl(): string {
  return (
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    "http://localhost:3000"
  );
}

export const STRIPE_PRICE_PRO_MONTHLY =
  process.env.STRIPE_PRICE_PRO_MONTHLY || "price_1U1Y85KBFshbSSA7faFIXtiZ";
export const STRIPE_PRICE_PRO_YEARLY =
  process.env.STRIPE_PRICE_PRO_YEARLY || "price_1U1Y85KBFshbSSA7Ez6I4qyi";
