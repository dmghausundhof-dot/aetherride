import { NextResponse } from "next/server";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
  isUsingPublicOsrm,
} from "@/lib/routing/engine";
import {
  DEMO_ROUTING_NOTICE,
  UNVERIFIED_ROUTING_NOTICE,
  hasPublicRoutingHint,
  type RoutingStatusPayload,
} from "@/lib/routing/routingStatus";

/**
 * GET /api/routing/status — konfiguriert vs. Smoke-verifiziert (kein Fake-Live).
 * Optional: ?probe=1 — leichter Network-Check (OSRM/GraphHopper/Valhalla).
 */
export async function GET(req: Request) {
  const engine = configuredRoutingEngine();
  const configured = isLiveRoutingConfigured();
  const liveVerified = hasPublicRoutingHint();
  const publicOsrm = isUsingPublicOsrm();
  let notice: string | null = null;
  if (!configured) notice = DEMO_ROUTING_NOTICE;
  else if (publicOsrm) {
    notice =
      "Live-Routing über öffentliches OSRM (Dev/Demo). Produktion: GRAPHHOPPER_API_KEY, VALHALLA_URL oder OSRM_URL setzen.";
  } else if (!liveVerified) notice = UNVERIFIED_ROUTING_NOTICE;

  const payload: RoutingStatusPayload & {
    publicOsrm?: boolean;
    probe?: { ok: boolean; ms?: number; detail?: string };
  } = {
    configured,
    engine,
    liveVerified: liveVerified || (configured && publicOsrm),
    notice,
    publicOsrm,
  };

  const url = new URL(req.url);
  if (url.searchParams.get("probe") === "1" && configured) {
    const t0 = Date.now();
    try {
      // Kleiner Probe-Punkt bei Heidelberg
      const from: [number, number] = [8.68, 49.41];
      const to: [number, number] = [8.70, 49.42];
      const { computeRoute } = await import("@/lib/routing/engine");
      const r = await computeRoute("road", from, to);
      payload.probe = {
        ok: r.engine !== "demo" || r.geometry.coordinates.length >= 2,
        ms: Date.now() - t0,
        detail: `${r.engine} · ${(r.distanceM / 1000).toFixed(1)} km`,
      };
      if (payload.probe.ok && r.engine !== "demo") {
        payload.liveVerified = true;
        if (publicOsrm) {
          payload.notice =
            "Live-Routing OK (öffentliches OSRM). Für Produktion eigenen Engine-Key setzen.";
        } else if (!hasPublicRoutingHint()) {
          payload.notice = null;
        }
      }
    } catch (e) {
      payload.probe = {
        ok: false,
        ms: Date.now() - t0,
        detail: e instanceof Error ? e.message : "probe failed",
      };
    }
  }

  return NextResponse.json(payload);
}
