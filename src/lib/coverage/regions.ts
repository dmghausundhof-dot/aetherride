/**
 * Offline region packs / bike-overlay bboxes.
 * Source of truth: `data/routing/dach-regions.json` (packs + DACH envelopes).
 * Packs are optional; live OSM + OpenRouteService cover the rest of DACH.
 */

import {
  DACH_PACK_REGIONS,
  DACH_REGIONS,
  dachRegionForPoint,
  overlayHintFromRegistry,
  pointInBbox,
  type DachRegion,
  type OverlayHint,
  type OverlayMode,
} from "./dachRegions";

export type OverlayRegion = {
  id: string;
  name: string;
  /** [west, south, east, north] */
  bbox: [number, number, number, number];
};

export type { OverlayHint, OverlayMode };

/** Riding packs only — historic 17 plus DACH metro/trail packs. */
export const OVERLAY_REGIONS: OverlayRegion[] = DACH_PACK_REGIONS.map((r) => ({
  id: r.id,
  name: r.name,
  bbox: r.bbox,
}));

export { pointInBbox };

export function overlayRegionForPoint(
  lng: number,
  lat: number
): OverlayRegion | null {
  const hit = dachRegionForPoint(lng, lat);
  if (!hit || hit.kind !== "pack") return null;
  return { id: hit.id, name: hit.name, bbox: hit.bbox };
}

export function overlayHintForPoint(lng: number, lat: number): OverlayHint {
  return overlayHintFromRegistry(lng, lat);
}

export function allDachRegions(): DachRegion[] {
  return DACH_REGIONS;
}
