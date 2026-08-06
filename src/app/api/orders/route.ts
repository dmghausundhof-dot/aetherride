import { NextRequest, NextResponse } from "next/server";

const orders: unknown[] = [];

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const order = {
      ...body,
      receivedAt: new Date().toISOString(),
      backendStatus: "accepted",
    };
    orders.push(order);
    console.log("[AetherRide API] Order received:", order.id || "unknown");
    return NextResponse.json({ success: true, orderId: order.id }, { status: 201 });
  } catch {
    return NextResponse.json({ error: "Invalid payload" }, { status: 400 });
  }
}

export async function GET() {
  return NextResponse.json({
    count: orders.length,
    orders: orders.slice(0, 20),
  });
}
