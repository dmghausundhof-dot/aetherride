import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    ok: true,
    service: "aetherride",
    features: {
      orders: true,
      auth: true,
      sync: true,
      billing: true,
      chat: true,
      stripeWebhook: true,
      timescaledb: "planned",
      pgvector: "planned",
    },
    timestamp: new Date().toISOString(),
  });
}
