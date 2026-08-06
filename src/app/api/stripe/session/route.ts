import { NextRequest, NextResponse } from "next/server";
import {
  isStripeDemandDocumented,
  retrieveCheckoutSession,
  stripeEnvPresent,
} from "@/lib/shop/stripeCheckout";
import {
  findOrderBySession,
  listStripeOrders,
} from "@/lib/shop/stripeOrders";

/**
 * GET ?session_id= — Session-Status nach Return von Stripe
 * GET ohne Param — letzte Orders (Demo)
 */
export async function GET(req: NextRequest) {
  const sessionId = req.nextUrl.searchParams.get("session_id");
  if (!sessionId) {
    const orders = await listStripeOrders(10);
    return NextResponse.json({
      demandDocumented: isStripeDemandDocumented(),
      ...stripeEnvPresent(),
      orders,
    });
  }

  const local = await findOrderBySession(sessionId);
  if (!stripeEnvPresent().secret) {
    return NextResponse.json({
      sessionId,
      localOrder: local,
      payment_status: local?.paymentStatus ?? null,
      note: "Kein STRIPE_SECRET_KEY — nur lokaler Order-Stand.",
    });
  }

  try {
    const session = await retrieveCheckoutSession(sessionId);
    return NextResponse.json({
      sessionId,
      payment_status: session?.payment_status ?? null,
      status: session?.status ?? null,
      amount_total: session?.amount_total ?? null,
      currency: session?.currency ?? null,
      localOrder: local,
    });
  } catch (e) {
    return NextResponse.json(
      {
        error: e instanceof Error ? e.message : "Session-Abruf fehlgeschlagen",
        localOrder: local,
      },
      { status: 400 }
    );
  }
}
