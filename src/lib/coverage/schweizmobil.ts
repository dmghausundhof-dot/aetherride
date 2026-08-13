/**
 * SchweizMobil OGD (CH only, CC BY) via geo.admin.ch identify.
 * Enrichment names — not MapLibre tile truth. Fail-soft.
 */

import { pointInSwitzerland } from "./dach";

export type SchweizMobilHit = {
  id: string;
  name: string;
  layer: string;
  source: "schweizmobil_ogd";
};

export async function fetchSchweizMobilNear(opts: {
  lat: number;
  lng: number;
}): Promise<{ hits: SchweizMobilHit[]; warning?: string; attribution: string }> {
  const attribution = "SchweizMobil / geo.admin.ch (CC BY)";
  if (!pointInSwitzerland(opts.lat, opts.lng)) {
    return { hits: [], attribution };
  }
  const d = 0.15;
  const mapExtent = `${opts.lng - d},${opts.lat - d},${opts.lng + d},${opts.lat + d}`;
  const url = new URL(
    "https://api3.geo.admin.ch/rest/services/api/MapServer/identify"
  );
  url.searchParams.set("geometryType", "esriGeometryPoint");
  url.searchParams.set("geometry", `${opts.lng},${opts.lat}`);
  url.searchParams.set("sr", "4326");
  url.searchParams.set(
    "layers",
    "all:ch.astra.veloland,ch.astra.mountainbikeland"
  );
  url.searchParams.set("mapExtent", mapExtent);
  url.searchParams.set("imageDisplay", "400,400,96");
  url.searchParams.set("tolerance", "80");
  url.searchParams.set("geometryFormat", "geojson");
  url.searchParams.set("lang", "de");
  url.searchParams.set("returnGeometry", "false");
  try {
    const res = await fetch(url.toString(), {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(4000),
      next: { revalidate: 3600 },
    });
    if (!res.ok) {
      return { hits: [], attribution, warning: `SchweizMobil ${res.status}` };
    }
    const json = (await res.json()) as {
      results?: Array<{
        layerBodId?: string;
        featureId?: string | number;
        attributes?: Record<string, unknown>;
      }>;
    };
    const hits: SchweizMobilHit[] = [];
    for (const r of json.results ?? []) {
      const attrs = r.attributes ?? {};
      const name = String(
        attrs.name || attrs.route_nr || attrs.nummer || attrs.label || ""
      ).trim();
      if (!name) continue;
      hits.push({
        id: `ch-${r.layerBodId ?? "ogd"}-${r.featureId ?? hits.length}`,
        name,
        layer: String(r.layerBodId ?? "ch.astra.veloland"),
        source: "schweizmobil_ogd",
      });
      if (hits.length >= 8) break;
    }
    return { hits, attribution };
  } catch (e) {
    return {
      hits: [],
      attribution,
      warning: e instanceof Error ? e.message : "schweizmobil_failed",
    };
  }
}
