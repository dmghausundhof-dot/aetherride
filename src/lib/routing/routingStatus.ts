/**
 * Routing-Status für UI: konfiguriert vs. Demo.
 * `NEXT_PUBLIC_ROUTING_LIVE` erst nach erfolgreichem Smoke setzen — sonst kein Fake-Live.
 */

export type RoutingStatusPayload = {
  configured: boolean;
  engine: "valhalla" | "osrm" | "graphhopper" | "openrouteservice" | "demo";
  /** Nur true nach manuellem Smoke (NEXT_PUBLIC_ROUTING_LIVE). */
  liveVerified: boolean;
  notice: string | null;
};

export const DEMO_ROUTING_NOTICE =
  "Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert.";

export const UNVERIFIED_ROUTING_NOTICE =
  "Routing-Key gesetzt — Live noch nicht verifiziert. Bei Fehlern Demo-Geometrie.";

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

/**
 * Consumer UI gate for DEMO_ROUTING_NOTICE / UNVERIFIED_ROUTING_NOTICE.
 * API may still return `notice` — Prod rider surfaces must never show it
 * unless showRoutingDebugUi() is on.
 */
export function consumerRoutingNotice(
  notice: string | null | undefined
): string | null {
  if (!showRoutingDebugUi()) return null;
  const t = notice?.trim();
  return t ? t : null;
}
