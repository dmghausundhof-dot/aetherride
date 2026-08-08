import { NextResponse } from "next/server";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
} from "@/lib/routing/engine";
import {
  DEMO_ROUTING_NOTICE,
  UNVERIFIED_ROUTING_NOTICE,
  hasPublicRoutingHint,
  type RoutingStatusPayload,
} from "@/lib/routing/routingStatus";

/**
 * GET /api/routing/status — konfiguriert vs. Smoke-verifiziert (kein Fake-Live).
 */
export async function GET() {
  const engine = configuredRoutingEngine();
  const configured = isLiveRoutingConfigured();
  const liveVerified = hasPublicRoutingHint();
  let notice: string | null = null;
  if (!configured) notice = DEMO_ROUTING_NOTICE;
  else if (!liveVerified) notice = UNVERIFIED_ROUTING_NOTICE;

  const payload: RoutingStatusPayload = {
    configured,
    engine,
    liveVerified,
    notice,
  };
  return NextResponse.json(payload);
}
