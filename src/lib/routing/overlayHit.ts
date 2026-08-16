/**
 * Overlay tap → same identity as Overpass (`osm-way-{id}`).
 * Tile props: name, osm_id, mtb_scale, highway. Surface via Overpass if missing.
 */

import {
  normalizeMtbScale,
  parseOsmWayId,
  type OsmTrail,
} from "@/lib/coverage/osmLive";
import type { TrailSegment } from "./trailSegments";
import { BIKE_OVERLAY_LAYER_IDS } from "./bikeOverlayMap";

export { parseOsmWayId };

export const BIKE_OVERLAY_QUERY_LAYER_IDS = Object.values(BIKE_OVERLAY_LAYER_IDS);

/** Region PMTiles typically stop at z14; overzoom still hit-tests, named Overpass fills gaps. */
export const BIKE_OVERLAY_VECTOR_MAX_ZOOM = 14;

export type OverlayWayHit = {
  osmId: string;
  id: string;
  name: string;
  mtbScale: string;
  highway?: string;
  surface?: string;
  geometry: [number, number][];
  center: [number, number];
  url: string;
  hasOsmName: boolean;
};

function lineCoords(geometry: {
  type?: string;
  coordinates?: unknown;
} | null | undefined): [number, number][] {
  if (!geometry?.coordinates) return [];
  const type = geometry.type;
  const coords = geometry.coordinates;
  const lines: unknown[] =
    type === "MultiLineString" && Array.isArray(coords)
      ? (coords as unknown[])
      : [coords];
  const out: [number, number][] = [];
  for (const line of lines) {
    if (!Array.isArray(line)) continue;
    for (const c of line) {
      if (!Array.isArray(c) || c.length < 2) continue;
      const lng = Number(c[0]);
      const lat = Number(c[1]);
      if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
      out.push([lng, lat]);
    }
  }
  return out;
}

export function overlayFeatureToHit(feat: {
  properties?: Record<string, unknown> | null;
  geometry?: { type?: string; coordinates?: unknown } | null;
}): OverlayWayHit | null {
  const props = feat.properties ?? {};
  const osmId = parseOsmWayId(
    props.osm_id ?? props.osmId ?? props["@id"] ?? props.id
  );
  if (!osmId) return null;
  const geometry = lineCoords(feat.geometry);
  const mid = geometry[Math.floor(geometry.length / 2)] ?? [0, 0];
  const rawName = String(props.name ?? props["name:de"] ?? "").trim();
  const mtbScale = normalizeMtbScale(
    String(props.mtb_scale ?? props["mtb:scale"] ?? "")
  );
  const highway = String(props.highway ?? "").trim() || undefined;
  const surface = String(props.surface ?? props.tracktype ?? "").trim() || undefined;
  const name =
    rawName ||
    (mtbScale !== "offen"
      ? `Trail ${mtbScale}`
      : highway === "cycleway"
        ? "Radweg"
        : "Pfad");
  return {
    osmId,
    id: `osm-way-${osmId}`,
    name,
    mtbScale,
    highway,
    surface,
    geometry,
    center: mid,
    url: `https://www.openstreetmap.org/way/${osmId}`,
    hasOsmName: Boolean(rawName),
  };
}

export function overlayHitToSegment(hit: OverlayWayHit): TrailSegment {
  return {
    id: hit.id,
    name: hit.name,
    geometry: { type: "LineString", coordinates: hit.geometry },
    difficulty: hit.mtbScale,
    provider: "osm",
    center: hit.center,
    surface: hit.surface,
    highway: hit.highway,
    url: hit.url,
    hasOsmName: hit.hasOsmName,
  };
}

export function osmTrailToSegment(t: {
  id?: string;
  name?: string;
  mtbScale?: string;
  difficulty?: string;
  geometry?: [number, number][] | GeoJSON.Position[];
  center?: [number, number];
  surface?: string;
  highway?: string;
  url?: string;
  hasOsmName?: boolean;
  lengthKm?: number;
}): TrailSegment | null {
  const id = String(t.id ?? "").trim();
  const name = String(t.name ?? "").trim();
  const geom = Array.isArray(t.geometry) ? t.geometry : [];
  const coordinates: [number, number][] = [];
  for (const c of geom) {
    if (!Array.isArray(c) || c.length < 2) continue;
    const lng = Number(c[0]);
    const lat = Number(c[1]);
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
    coordinates.push([lng, lat]);
  }
  if (!id || !name || coordinates.length < 2) return null;
  const mid = t.center ?? coordinates[Math.floor(coordinates.length / 2)];
  const center: [number, number] = [
    Number(mid[0]),
    Number(mid[1]),
  ];
  if (!Number.isFinite(center[0]) || !Number.isFinite(center[1])) return null;
  return {
    id,
    name,
    geometry: { type: "LineString", coordinates },
    difficulty: t.mtbScale || t.difficulty,
    provider: "osm",
    center,
    surface: t.surface,
    highway: t.highway,
    url: t.url ?? (parseOsmWayId(id) ? `https://www.openstreetmap.org/way/${parseOsmWayId(id)}` : undefined),
    hasOsmName:
      t.hasOsmName ??
      (Boolean(name) &&
        name !== "Pfad" &&
        name !== "Radweg" &&
        !/^Trail S/i.test(name)),
  };
}

export function osmTrailFromApi(t: OsmTrail): TrailSegment | null {
  return osmTrailToSegment(t);
}

export function trailSurfaceLabelDe(raw?: string | null): string | undefined {
  if (!raw) return undefined;
  const s = raw.toLowerCase().trim();
  if (s === "asphalt" || s === "paved" || s === "concrete") return "Asphalt";
  if (s === "gravel" || s === "fine_gravel" || s === "compacted") return "Schotter";
  if (s === "ground" || s === "dirt" || s === "earth" || s === "unpaved") {
    return "Naturweg";
  }
  if (s === "grass") return "Gras";
  if (s === "wood" || s === "boardwalk") return "Holz";
  return raw;
}

export function trailHighwayLabelDe(raw?: string | null): string | undefined {
  if (!raw) return undefined;
  const s = raw.toLowerCase().trim();
  if (s === "path") return "Pfad";
  if (s === "track") return "Forstweg";
  if (s === "cycleway") return "Radweg";
  if (s === "bridleway") return "Reitweg";
  if (s === "footway") return "Fußweg";
  return raw;
}
