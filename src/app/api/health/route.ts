import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "ok",
    service: "AetherRide API",
    version: "1.0.0",
    features: {
      orders: true,
      sensorIngestion: "planned",
      routing: "planned",
      vectorRecommendations: "planned",
    },
    timestamp: new Date().toISOString(),
  });
}
