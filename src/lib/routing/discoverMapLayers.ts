import type { MapRouteLayer } from "@/components/MapView";
import type { PlanDraft, QuickOption } from "@/lib/routing/planDraft";
import type { TrailSegment } from "@/lib/routing/trailSegments";
import { buildElevationFromTrack } from "@/lib/routing/elevationProfile";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";

/** Build MapView layers from draft + quick alts + trail overlay */
export function buildDiscoverMapLayers(opts: {
  draft: PlanDraft;
  quickOptions: QuickOption[];
  activeQuickId?: string | null;
  trails: TrailSegment[];
  showTrails: boolean;
}): MapRouteLayer[] {
  const { draft, quickOptions, activeQuickId, trails, showTrails } = opts;
  const layers: MapRouteLayer[] = [];

  if (showTrails) {
    for (const t of trails) {
      layers.push({
        id: `trail-${t.id}`,
        geometry: t.geometry,
        role: "trail",
      });
    }
  }

  for (const q of quickOptions) {
    const isActive =
      activeQuickId === q.id ||
      (draft.mode === "quick" && draft.label === q.label);
    if (isActive) continue;
    layers.push({
      id: `alt-${q.id}`,
      geometry: q.result.geometry,
      role: "alt",
    });
  }

  if (draft.layers?.approach) {
    layers.push({
      id: "approach",
      geometry: draft.layers.approach,
      role: "approach",
    });
  }
  if (draft.layers?.tour && draft.layers.tour.coordinates.length >= 2) {
    const tourApprox =
      draft.computed?.engine?.includes("demo") ||
      draft.computed?.engine?.includes("pin") ||
      draft.label?.includes("Näherung") ||
      draft.label?.includes("(Idee)");
    layers.push({
      id: "tour-track",
      geometry: draft.layers.tour,
      role: tourApprox ? "approx" : "tour",
    });
  }
  if (draft.layers?.trail && !showTrails) {
    layers.push({
      id: "attached-trail",
      geometry: draft.layers.trail,
      role: "trail",
    });
  }

  if (draft.computed?.geometry && draft.computed.geometry.coordinates.length >= 2) {
    // When we have approach+tour layers, still show merged as active outline
    // unless it's pure tour adopt without parts
    const hasParts = Boolean(
      draft.layers?.approach || draft.layers?.tour || draft.layers?.trail
    );
    if (!hasParts || draft.mode === "quick" || draft.mode === "point_to_point") {
      layers.push({
        id: "active",
        geometry: draft.computed.geometry,
        role:
          draft.computed.engine?.includes("pin") ||
          draft.computed.engine?.includes("demo")
            ? "approx"
            : "active",
      });
    } else if (!draft.layers?.tour && !draft.layers?.trail) {
      layers.push({
        id: "active",
        geometry: draft.computed.geometry,
        role: "active",
      });
    } else {
      // hybrid with parts: active = merged lightly, tour/trail already drawn
      layers.push({
        id: "active-merged",
        geometry: draft.computed.geometry,
        role: "active",
        opacity: 0.35,
        width: 6,
      });
    }
  }

  return layers;
}

/** Stub elevation from LineString (synthetic climb for UI). */
export function elevationFromGeometry(
  geometry: GeoJSON.LineString | null | undefined
): ElevationProfile | null {
  if (!geometry?.coordinates?.length) return null;
  const track = (geometry.coordinates as [number, number][]).map(
    ([lng, lat], i) => ({
      lng,
      lat,
      elev: 400 + Math.sin(i / 4) * 40 + i * 1.2,
    })
  );
  return buildElevationFromTrack(track, "demo");
}
