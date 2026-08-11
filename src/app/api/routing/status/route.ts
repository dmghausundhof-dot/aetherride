import { NextResponse } from "next/server";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
  isUsingPublicOsrm,
} from "@/lib/routing/engine";
import {
  clientRoutingNotice,
  hasPublicRoutingHint,
  sanitizeClientRoutingNotice,
  type RoutingStatusPayload,
} from "@/lib/routing/routingStatus";

/**
 * GET /api/routing/status — konfiguriert vs. Smoke-verifiziert (kein Fake-Live).
 * Optional: ?probe=1 — leichter Network-Check (OSRM/GraphHopper/Valhalla).
 *
 * Client notices never mention Routing-Key / API_KEY / env var names.
 * Configured graphhopper|osrm|valhalla → notice:null (silent).
 */
export async function GET(req: Request) {
  const engine = configuredRoutingEngine();
  const configured = isLiveRoutingConfigured();
  const liveVerified = hasPublicRoutingHint();
  const publicOsrm = isUsingPublicOsrm();
  let notice = sanitizeClientRoutingNotice(
    clientRoutingNotice({
      configured,
      engine,
      liveVerified,
      publicOsrm,
    })
  );

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
          payload.notice = sanitizeClientRoutingNotice(
            "Live-Routing OK (öffentliches OSRM). Für Produktion eigenen Routing-Endpunkt setzen."
          );
        } else {
          // Configured live engine probe OK — keep silent.
          payload.notice = null;
        }
      }
    } catch (e) {
      payload.probe = {
        ok: false,
        ms: Date.now() - t0,
        detail: e instanceof Error ? e.message : "probe failed",
      };
      // Probe errors may include env/key names from engine throws — never surface raw.
      if (payload.probe.detail && SECRETISH_DETAIL.test(payload.probe.detail)) {
        payload.probe.detail = "probe failed";
      }
    }
  }

  payload.notice = sanitizeClientRoutingNotice(payload.notice);
  return NextResponse.json(payload);
}

const SECRETISH_DETAIL =
  /Routing[- ]?Key|API[_ ]?KEY|GRAPHHOPPER|VALHALLA|OSRM|STADIA|missing|secret/i;
