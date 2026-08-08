/**
 * Ob echte Routing-Engines konfiguriert sind (sonst Demo-Geometrie).
 * Client-sichtbar nur über NEXT_PUBLIC_* — Server kennt VALHALLA_URL etc.
 */
export function hasPublicRoutingHint(): boolean {
  return Boolean(
    process.env.NEXT_PUBLIC_ROUTING_LIVE === "1" ||
      process.env.NEXT_PUBLIC_ROUTING_LIVE === "true"
  );
}

export const DEMO_ROUTING_NOTICE =
  "Routen können Demo-Geometrie sein, solange kein Live-Routing konfiguriert ist.";
