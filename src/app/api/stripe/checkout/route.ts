import { NextRequest, NextResponse } from "next/server";
import { getSessionFromCookies } from "@/lib/auth/serverSession";
import { buildMarketplaceDraft } from "@/lib/shop/marketplace";
import {
  createStripeCheckoutSession,
  isStripeDemandDocumented,
  planStripeCheckout,
  stripeEnvPresent,
} from "@/lib/shop/stripeCheckout";

/**
 * POST: Checkout-Session erstellen (Redirect-URL)
 * Body: { items: { name, priceEur, qty }[], legalAccepted?: boolean }
 */
export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as {
      items?: { name?: string; priceEur?: number; qty?: number }[];
      legalAccepted?: boolean;
    };

    if (!body.legalAccepted) {
      return NextResponse.json(
        {
          error: "EU-Pflichtangaben müssen bestätigt sein.",
          code: "LEGAL_REQUIRED",
        },
        { status: 400 }
      );
    }

    const items = (body.items ?? [])
      .map((i) => ({
        name: String(i.name ?? "").trim(),
        priceEur: Number(i.priceEur) || 0,
        qty: Math.max(1, Math.floor(Number(i.qty) || 1)),
      }))
      .filter((i) => i.name && i.priceEur > 0);

    const draft = buildMarketplaceDraft(items);
    const session = await getSessionFromCookies();
    const result = await createStripeCheckoutSession(draft, {
      customerEmail: session?.email,
      userId: session?.id,
    });

    if (!result.ok) {
      const status =
        result.status === "blocked_no_demand"
          ? 403
          : result.status === "not_configured"
            ? 503
            : 400;
      return NextResponse.json(
        { error: result.messageDe, code: result.status },
        { status }
      );
    }

    return NextResponse.json({
      sessionId: result.sessionId,
      url: result.url,
      demandDocumented: isStripeDemandDocumented(),
    });
  } catch (e) {
    console.error("[stripe/checkout]", e);
    return NextResponse.json(
      { error: "Checkout fehlgeschlagen." },
      { status: 500 }
    );
  }
}

/** GET: Status ohne Secrets */
export async function GET() {
  const env = stripeEnvPresent();
  const demand = isStripeDemandDocumented();
  const plan = planStripeCheckout(buildMarketplaceDraft([]), {
    demandDocumented: demand,
  });
  return NextResponse.json({
    demandDocumented: demand,
    secretConfigured: env.secret,
    publishableConfigured: env.publishable,
    webhookConfigured: env.webhook,
    status: plan.status,
    messageDe: plan.messageDe,
    publishableKey: env.publishable
      ? process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ?? null
      : null,
  });
}
