import type { MapRouteLayer } from "@/components/MapView";
import type { PlanDraft, QuickOption } from "@/lib/routing/planDraft";
import type { TrailSegment } from "@/lib/routing/trailSegments";
import { buildElevationFromTrack } from "@/lib/routing/elevationProfile";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";
import {
  isHonestLoop,
  isOutAndBackQuickOption,
  sanitizeDraftForRundkurs,
} from "@/lib/discover/loopHonesty";
import {
  getProfile,
  isLabeledTrailSuitable,
  isRideProfileId,
  type RideProfileId,
} from "@/lib/routing/profiles";

/** Build MapView layers from draft + quick alts + trail overlay */
export function buildDiscoverMapLayers(opts: {
  draft: PlanDraft;
  quickOptions: QuickOption[];
  activeQuickId?: string | null;
  trails: TrailSegment[];
  showTrails: boolean;
  /** D-60-LOOP-FILTER-01: strip out-and-back / non-closed from map. */
  rundkursOnly?: boolean;
  /** Filtert/highlighted Seed-Trails nach RideProfile (S0–S3+). */
  rideProfileId?: RideProfileId | null;
}): MapRouteLayer[] {
  const {
    quickOptions: rawQuick,
    activeQuickId,
    trails,
    showTrails,
    rundkursOnly = false,
    rideProfileId = null,
  } = opts;
  const draft = rundkursOnly
    ? sanitizeDraftForRundkurs(opts.draft)
    : opts.draft;
  const quickOptions = rundkursOnly
    ? rawQuick.filter((q) => !isOutAndBackQuickOption(q))
    : rawQuick;
  const layers: MapRouteLayer[] = [];
  const ride =
    rideProfileId && isRideProfileId(rideProfileId)
      ? getProfile(rideProfileId)
      : null;

  if (showTrails) {
    for (const t of trails) {
      if (
        ride &&
        !isLabeledTrailSuitable(ride.id, t.difficulty)
      ) {
        continue;
      }
      layers.push({
        id: `trail-${t.id}`,
        geometry: t.geometry,
        role: "trail",
        color: ride?.trailHighlightColor,
        width: ride ? 3.4 : undefined,
        opacity: ride ? 0.9 : undefined,
      });
    }
  }

  for (const q of quickOptions) {
    const isActive =
      activeQuickId === q.id ||
      (draft.mode === "quick" && draft.label === q.label);
    if (isActive) continue;
    if (rundkursOnly) {
      const coords = (q.result.geometry?.coordinates ?? []) as [
        number,
        number,
      ][];
      if (!isHonestLoop({ loopFlag: true, trackLngLat: coords })) continue;
    }
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
      color: ride?.trailHighlightColor,
      width: ride ? 3.4 : undefined,
      opacity: ride ? 0.9 : undefined,
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

/**
 * @deprecated Synthetic climb from flat LineString — DO NOT use on Discover/Planner
 * consumer UI. Prefer real/sanitized ascent (seed/API) or omit hm.
 * Kept for debug/tests only; invents `120 + sin` elev with source "demo".
 */
export function elevationFromGeometry(
  geometry: GeoJSON.LineString | null | undefined
): ElevationProfile | null {
  if (!geometry?.coordinates?.length) return null;
  const track = (geometry.coordinates as [number, number][]).map(
    ([lng, lat], i) => ({
      lng,
      lat,
      elev: 120 + Math.sin(i / 6) * 12,
    })
  );
  return buildElevationFromTrack(track, "demo");
}
