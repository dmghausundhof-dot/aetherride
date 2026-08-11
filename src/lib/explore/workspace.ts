/**
 * Explore Workspace — einheitliches Modell für Discover + Planner.
 *
 * Konkurrenz (Komoot / RWGPS / AllTrails / Strava):
 * - Ein Desktop-Cockpit: Karte + Side-Panel (nicht App-Sheet).
 * - Sport/Profil first-class Filter.
 * - Planen und Entdecken teilen dieselbe Route-Draft und Map-Layers.
 * - Web = Planung/SEO; App = Nav (Deep Link).
 *
 * AetherRide besser:
 * - Bike-Intelligence (aktives Bike → Profil/Match).
 * - Honesty: engine/editorial/demo klar.
 * - Garage + Setup im selben Account-Sync.
 * - Ein Draft-Objekt (PlanDraft) für Quick/Plan/Tour.
 */

import type { RoutingProfile } from "@/lib/routing/profiles";
import type { PlanDraft, PlanMode } from "@/lib/routing/planDraft";

export type ExplorePanel = "discover" | "plan" | "library" | "nearby";

export type ExploreWorkspaceState = {
  panel: ExplorePanel;
  profile: RoutingProfile;
  mapCenter: [number, number];
  /** User GPS if known */
  userPos: [number, number] | null;
  draft: PlanDraft;
  /** Search place query */
  placeQuery: string;
  minutes: number;
};

export type ExploreUrlState = {
  panel?: ExplorePanel;
  profile?: RoutingProfile;
  lat?: number;
  lng?: number;
  route?: string;
  sport?: string;
  q?: string;
};

export function parseExploreSearchParams(
  sp: URLSearchParams
): ExploreUrlState {
  const panel = sp.get("panel") as ExplorePanel | null;
  const profile = sp.get("profile") as RoutingProfile | null;
  const lat = Number(sp.get("lat"));
  const lng = Number(sp.get("lng") ?? sp.get("lon"));
  return {
    panel:
      panel === "discover" ||
      panel === "plan" ||
      panel === "library" ||
      panel === "nearby"
        ? panel
        : undefined,
    profile: profile || undefined,
    lat: Number.isFinite(lat) ? lat : undefined,
    lng: Number.isFinite(lng) ? lng : undefined,
    route: sp.get("route") ?? undefined,
    sport: sp.get("sport") ?? undefined,
    q: sp.get("q") ?? undefined,
  };
}

export function exploreHref(state: ExploreUrlState): string {
  const p = new URLSearchParams();
  if (state.panel && state.panel !== "discover") p.set("panel", state.panel);
  if (state.profile) p.set("profile", state.profile);
  if (state.lat != null && state.lng != null) {
    p.set("lat", String(state.lat));
    p.set("lng", String(state.lng));
  }
  if (state.route) p.set("route", state.route);
  if (state.sport) p.set("sport", state.sport);
  if (state.q) p.set("q", state.q);
  const q = p.toString();
  return q ? `/discover?${q}` : "/discover";
}

/** Map PlanMode (internal) ↔ ExplorePanel */
export function panelFromPlanMode(mode: PlanMode): ExplorePanel {
  if (mode === "point_to_point" || mode === "hybrid") return "plan";
  if (mode === "tour") return "discover";
  return "nearby";
}

export const EXPLORE_PANEL_LABELS: Record<ExplorePanel, string> = {
  discover: "Touren",
  plan: "Planen",
  library: "Bibliothek",
  nearby: "Hier & Jetzt",
};
