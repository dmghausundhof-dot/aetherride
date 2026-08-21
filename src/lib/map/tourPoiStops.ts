/**
 * Selected-tour seed POI stops on the browse map.
 * Positions along existing track geometry — never invents a catalog.
 */
import { pointAlongLine } from "@/lib/geo/trackMath";
import { mapPoiKindFromRaw, type MapPoiKind } from "@/lib/map/mapPinSvg";
import type { RoutePoiStop } from "@/lib/routing/suggestions";

export const TOUR_POI_MAX = 8;
/** Skip trailhead-on-start and finish-stack. */
export const POI_FRAC_MIN = 0.06;
export const POI_FRAC_MAX = 0.94;
export const POI_FRAC_GAP = 0.05;

export function poiFracFitsAlong(frac: number, placed: number[]): boolean {
  if (frac < POI_FRAC_MIN || frac > POI_FRAC_MAX) return false;
  return placed.every((p) => Math.abs(p - frac) >= POI_FRAC_GAP);
}

/** Number-only below zoom 12 — Android `_mapZoom >= 12` / browsePinZoomBand. */
export function browsePoiPinText(
  index: number,
  title: string,
  zoom: number
): string {
  if (zoom < 12) return String(index);
  const t = title.trim();
  return t ? `${index} · ${t}` : String(index);
}

/** Coverage names only at zoom 12+ — match Android plates. */
export function browseCoveragePinText(name: string, zoom: number): string {
  if (zoom < 12) return "";
  const t = name.trim();
  if (!t) return "";
  return t.length > 14 ? `${t.slice(0, 13)}…` : t;
}

export type PlacedTourPoi = {
  id: string;
  lngLat: [number, number];
  poiKind: MapPoiKind;
  label: string;
  selected: boolean;
  index: number;
};

export function placeTourPoiStops(opts: {
  stops: RoutePoiStop[] | undefined;
  durationMin: number;
  geometry: GeoJSON.LineString | null | undefined;
  zoom: number;
  selectedId?: string | null;
  max?: number;
}): PlacedTourPoi[] {
  const stops = opts.stops;
  const geom = opts.geometry;
  if (!stops?.length || opts.durationMin <= 0) return [];
  if (!geom?.coordinates || geom.coordinates.length < 2) return [];
  const out: PlacedTourPoi[] = [];
  const max = opts.max ?? TOUR_POI_MAX;
  const placed: number[] = [];
  let index = 0;
  for (const poi of stops) {
    if (out.length >= max) break;
    index += 1;
    if (poi.atMin <= 0) continue;
    const frac = poi.atMin / opts.durationMin;
    if (!poiFracFitsAlong(frac, placed)) continue;
    const pt = pointAlongLine(geom, frac);
    const id = poi.id || `poi-${index}`;
    placed.push(frac);
    out.push({
      id,
      lngLat: [pt.lng, pt.lat],
      poiKind: mapPoiKindFromRaw(poi.kind),
      label: browsePoiPinText(index, poi.title, opts.zoom),
      selected: opts.selectedId === id,
      index,
    });
  }
  return out;
}
