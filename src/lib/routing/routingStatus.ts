/**
 * Routing-Status für UI: konfiguriert vs. Demo.
 * `NEXT_PUBLIC_ROUTING_LIVE` erst nach erfolgreichem Smoke setzen — sonst kein Fake-Live.
 *
 * Client-visible notices must NEVER mention Routing-Key / API_KEY / env var names.
 */

export type RoutingStatusPayload = {
  configured: boolean;
  engine: "valhalla" | "osrm" | "graphhopper" | "demo";
  /** Nur true nach manuellem Smoke (NEXT_PUBLIC_ROUTING_LIVE). */
  liveVerified: boolean;
  notice: string | null;
};

export const DEMO_ROUTING_NOTICE =
  "Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert.";

/** @deprecated Prefer notice:null for configured live engines — kept for tests/docs only. */
export const UNVERIFIED_ROUTING_NOTICE =
  "Live-Routing konfiguriert — Verifikation ausstehend.";

const SECRETISH =
  /Routing[- ]?Key|API[_ ]?KEY|GRAPHHOPPER|VALHALLA_URL|OSRM_URL|STADIA|Bearer\s|secret/i;

/** Strip or null-out any client notice that leaks ops/secret chrome. */
export function sanitizeClientRoutingNotice(
  notice: string | null | undefined
): string | null {
  if (notice == null) return null;
  const t = notice.trim();
  if (!t) return null;
  if (SECRETISH.test(t)) return null;
  return t;
}

/**
 * Client-facing status notice.
 * Prefer `null` when a real engine is configured (graphhopper/osrm/valhalla).
 */
export function clientRoutingNotice(opts: {
  configured: boolean;
  engine: RoutingStatusPayload["engine"];
  liveVerified: boolean;
  publicOsrm: boolean;
}): string | null {
  if (!opts.configured || opts.engine === "demo") {
    return DEMO_ROUTING_NOTICE;
  }
  if (opts.publicOsrm) {
    return "Live-Routing über öffentliches OSRM (Dev/Demo). Produktion: eigenen Routing-Endpunkt setzen.";
  }
  // Configured GraphHopper / OSRM / Valhalla — silent (no Routing-Key chrome).
  if (
    opts.engine === "graphhopper" ||
    opts.engine === "osrm" ||
    opts.engine === "valhalla"
  ) {
    return null;
  }
  return DEMO_ROUTING_NOTICE;
}

/** Manueller Override für UI (nach erfolgreichem Smoke). */
export function hasPublicRoutingHint(): boolean {
  return Boolean(
    process.env.NEXT_PUBLIC_ROUTING_LIVE === "1" ||
      process.env.NEXT_PUBLIC_ROUTING_LIVE === "true"
  );
}

/**
 * Q-BAR-DIS-01: Demo / unverified routing chrome (banners).
 * Fail-closed: ONLY true when NEXT_PUBLIC_SHOW_ROUTING_DEBUG === "1"
 * (not "true", not unset). Geometry fallback stays silent.
 */
export function showRoutingDebugUi(): boolean {
  return process.env.NEXT_PUBLIC_SHOW_ROUTING_DEBUG === "1";
}
