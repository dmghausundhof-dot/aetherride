/**
 * DACH region registry — `data/routing/dach-regions.json`.
 * Packs = optional offline overlays. Envelopes fill holes so every in-DACH
 * GPS has a named region. Live routing is ORS/GraphHopper, not pack-gated.
 */

import dachRaw from "../../../data/routing/dach-regions.json";
import {
  detailBikeOverlayPmtilesUrl,
  ONLINE_PACK_CDN_ROOT,
  onlineCycleMeshGeojsonUrl,
  onlineCycleMeshPmtilesUrl,
  packHasDetailBikeOverlay,
} from "../map/onlineCycleMesh";
import { pointInDach } from "./dach";

export type DachRegionKind = "pack" | "envelope";

export type DachRegion = {
  id: string;
  name: string;
  country: string;
  kind: DachRegionKind;
  /** [west, south, east, north] */
  bbox: [number, number, number, number];
  center: [number, number];
  geofabrik?: string;
  sports?: string[];
};

type DachFile = {
  version: number;
  note?: string;
  regions: DachRegion[];
};

const file = dachRaw as DachFile;

export const DACH_REGIONS: DachRegion[] = file.regions.map((r) => ({
  ...r,
  bbox: r.bbox as [number, number, number, number],
  center: r.center as [number, number],
}));

export const DACH_PACK_REGIONS = DACH_REGIONS.filter((r) => r.kind === "pack");
export const DACH_ENVELOPE_REGIONS = DACH_REGIONS.filter(
  (r) => r.kind === "envelope"
);

export function pointInBbox(
  lng: number,
  lat: number,
  bbox: [number, number, number, number]
): boolean {
  const [w, s, e, n] = bbox;
  return lng >= w && lng <= e && lat >= s && lat <= n;
}

function smallestHit(hits: DachRegion[]): DachRegion {
  const copy = [...hits];
  copy.sort((a, b) => {
    const aa = (a.bbox[2] - a.bbox[0]) * (a.bbox[3] - a.bbox[1]);
    const bb = (b.bbox[2] - b.bbox[0]) * (b.bbox[3] - b.bbox[1]);
    return aa - bb;
  });
  return copy[0];
}

/** Tight riding pack first; envelope fills the rest of DACH. */
export function dachRegionForPoint(
  lng: number,
  lat: number
): DachRegion | null {
  const packHits = DACH_PACK_REGIONS.filter((r) =>
    pointInBbox(lng, lat, r.bbox)
  );
  if (packHits.length) return smallestHit(packHits);
  const envHits = DACH_ENVELOPE_REGIONS.filter((r) =>
    pointInBbox(lng, lat, r.bbox)
  );
  if (envHits.length) return smallestHit(envHits);
  return null;
}

/** Smallest Hausberg pack with a CDN ways overlay covering this point. */
export function detailOverlayRegionIdForPoint(
  lng: number,
  lat: number
): string | null {
  const hits = DACH_PACK_REGIONS.filter(
    (r) => pointInBbox(lng, lat, r.bbox) && packHasDetailBikeOverlay(r.id)
  );
  if (!hits.length) return null;
  return smallestHit(hits).id;
}

export type OverlayMode = "region_pack" | "dach_live" | "live_osm";

export type OverlayHint = {
  regionId: string | null;
  regionName: string | null;
  mode: OverlayMode;
  kind: DachRegionKind | null;
  pmtilesPath: string | null;
  geojsonPath: string | null;
};

function meshPaths(lng: number, lat: number): {
  pmtilesPath: string | null;
  geojsonPath: string | null;
} {
  return {
    pmtilesPath: onlineCycleMeshPmtilesUrl(lng, lat),
    geojsonPath: onlineCycleMeshGeojsonUrl(lng, lat),
  };
}

export function overlayHintFromRegistry(
  lng: number,
  lat: number
): OverlayHint {
  const region = dachRegionForPoint(lng, lat);
  const mesh = meshPaths(lng, lat);
  if (region?.kind === "pack") {
    const detail = packHasDetailBikeOverlay(region.id);
    return {
      regionId: region.id,
      regionName: region.name,
      mode: "region_pack",
      kind: "pack",
      pmtilesPath: detail
        ? detailBikeOverlayPmtilesUrl(region.id)
        : mesh.pmtilesPath,
      geojsonPath: detail
        ? `${ONLINE_PACK_CDN_ROOT}/${region.id}/bike-overlay.geojson`
        : mesh.geojsonPath,
    };
  }
  if (region?.kind === "envelope") {
    return {
      regionId: region.id,
      regionName: region.name,
      mode: "dach_live",
      kind: "envelope",
      ...mesh,
    };
  }
  if (pointInDach(lat, lng)) {
    return {
      regionId: "dach",
      regionName: "DACH live",
      mode: "dach_live",
      kind: null,
      ...mesh,
    };
  }
  if (mesh.pmtilesPath) {
    return {
      regionId: "cycle-mesh",
      regionName: "Radnetz",
      mode: "live_osm",
      kind: null,
      ...mesh,
    };
  }
  return {
    regionId: null,
    regionName: null,
    mode: "live_osm",
    kind: null,
    pmtilesPath: null,
    geojsonPath: null,
  };
}

/** Cities that must resolve to a named DACH region (pack or envelope). */
export const DACH_COMPLETENESS_PROBES: Array<{
  id: string;
  lng: number;
  lat: number;
}> = [
  { id: "heidelberg", lng: 8.68, lat: 49.41 },
  { id: "freiburg", lng: 7.85, lat: 47.99 },
  { id: "stuttgart", lng: 9.18, lat: 48.78 },
  { id: "muenchen", lng: 11.575, lat: 48.137 },
  { id: "nuernberg", lng: 11.08, lat: 49.45 },
  { id: "frankfurt", lng: 8.68, lat: 50.11 },
  { id: "koeln", lng: 6.96, lat: 50.94 },
  { id: "duesseldorf", lng: 6.78, lat: 51.23 },
  { id: "essen", lng: 7.01, lat: 51.45 },
  { id: "hamburg", lng: 9.993, lat: 53.551 },
  { id: "berlin", lng: 13.405, lat: 52.52 },
  { id: "dresden", lng: 13.74, lat: 51.05 },
  { id: "leipzig", lng: 12.37, lat: 51.34 },
  { id: "hannover", lng: 9.73, lat: 52.37 },
  { id: "kiel", lng: 10.14, lat: 54.32 },
  { id: "rostock", lng: 12.14, lat: 54.09 },
  { id: "saarbruecken", lng: 7.0, lat: 49.23 },
  { id: "trier", lng: 6.64, lat: 49.75 },
  { id: "kassel", lng: 9.49, lat: 51.31 },
  { id: "erfurt", lng: 11.03, lat: 50.98 },
  { id: "magdeburg", lng: 11.63, lat: 52.12 },
  { id: "bremen", lng: 8.81, lat: 53.08 },
  { id: "aachen", lng: 6.08, lat: 50.78 },
  { id: "passau", lng: 13.43, lat: 48.57 },
  { id: "garmisch", lng: 11.1, lat: 47.49 },
  { id: "wien", lng: 16.373, lat: 48.208 },
  { id: "graz", lng: 15.44, lat: 47.07 },
  { id: "linz", lng: 14.29, lat: 48.31 },
  { id: "innsbruck", lng: 11.4, lat: 47.27 },
  { id: "salzburg", lng: 13.05, lat: 47.8 },
  { id: "klagenfurt", lng: 14.31, lat: 46.62 },
  { id: "villach", lng: 13.85, lat: 46.61 },
  { id: "bregenz", lng: 9.75, lat: 47.5 },
  { id: "zuerich", lng: 8.541, lat: 47.376 },
  { id: "bern", lng: 7.45, lat: 46.95 },
  { id: "basel", lng: 7.59, lat: 47.56 },
  { id: "genf", lng: 6.15, lat: 46.2 },
  { id: "lausanne", lng: 6.63, lat: 46.52 },
  { id: "luzern", lng: 8.31, lat: 47.05 },
  { id: "lugano", lng: 8.95, lat: 46.0 },
  { id: "chur", lng: 9.53, lat: 46.85 },
  { id: "zermatt", lng: 7.75, lat: 46.02 },
  { id: "st-moritz", lng: 9.84, lat: 46.49 },
  { id: "davos", lng: 9.84, lat: 46.8 },
  { id: "vaduz", lng: 9.52, lat: 47.14 },
];

export function dachCoverageStats(): {
  packs: number;
  envelopes: number;
  total: number;
  probesNamed: number;
  probesTotal: number;
  missingProbes: string[];
} {
  const missing: string[] = [];
  for (const p of DACH_COMPLETENESS_PROBES) {
    const hit = dachRegionForPoint(p.lng, p.lat);
    if (!hit) missing.push(p.id);
  }
  return {
    packs: DACH_PACK_REGIONS.length,
    envelopes: DACH_ENVELOPE_REGIONS.length,
    total: DACH_REGIONS.length,
    probesNamed: DACH_COMPLETENESS_PROBES.length - missing.length,
    probesTotal: DACH_COMPLETENESS_PROBES.length,
    missingProbes: missing,
  };
}
