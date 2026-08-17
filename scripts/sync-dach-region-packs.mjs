#!/usr/bin/env node
/**
 * Sync offline pack stubs + Dart overlay from data/routing/dach-regions.json.
 * Does not download OSM — catalog stubs only (same shape as existing berlin.json).
 */
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const file = JSON.parse(
  readFileSync(join(root, "data/routing/dach-regions.json"), "utf8")
);

const regions = file.regions;
const packs = regions.filter((r) => r.kind === "pack");
const builtAt = "2026-08-13T00:00:00Z";

function writePackStub(r) {
  const regionPath = join(root, "data/routing/regions", `${r.id}.json`);
  const manifestPath = join(root, "data/routing/manifests", `${r.id}.json`);
  const region = {
    id: r.id,
    name: r.name,
    bbox: r.bbox,
    osm: {
      geofabrik: r.geofabrik || "",
      note: `${r.country} extract, auf bbox clippen. Graph-only via Overpass.`,
    },
    graph: { maxNodes: 80000, maxEdges: 120000 },
    outputDir: `data/routing/dist/${r.id}`,
    valhalla: { tile_dir: "tiles", config: "valhalla.json" },
    cdn: { baseUrl: "", pack: `${r.id}.tar.zst` },
  };
  const manifest = {
    id: r.id,
    name: r.name,
    bbox: r.bbox,
    builtAt,
    engines: { offline_graph: true, valhalla_tiles: false },
    files: {},
    cdn: {
      baseUrl: "",
      pack: `${r.id}.tar.zst`,
      packGz: `${r.id}.tar.gz`,
    },
    shipped: {
      note: "Catalog stub — download falls back to bundled offline_graph until full pack is built",
    },
  };
  mkdirSync(dirname(regionPath), { recursive: true });
  mkdirSync(dirname(manifestPath), { recursive: true });
  writeFileSync(regionPath, JSON.stringify(region, null, 2) + "\n");
  writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
}

for (const r of packs) writePackStub(r);

const dartRegions = packs
  .map((r) => {
    const bbox = r.bbox.map((n) => JSON.stringify(n)).join(", ");
    const name = r.name.replace(/'/g, "\\'");
    return `  OverlayRegion(id: '${r.id}', name: '${name}', bbox: [${bbox}]),`;
  })
  .join("\n");

const dart = `/// DACH overlay-pack bboxes — generated from data/routing/dach-regions.json.
/// [west, south, east, north]
/// Do not edit by hand — run: node scripts/sync-dach-region-packs.mjs
class OverlayRegion {
  const OverlayRegion({
    required this.id,
    required this.name,
    required this.bbox,
  });

  final String id;
  final String name;
  final List<double> bbox;

  bool contains(double lng, double lat) =>
      lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
}

class OverlayPackRef {
  const OverlayPackRef({required this.id, required this.name});
  final String id;
  final String name;
}

const kOverlayRegions = <OverlayRegion>[
${dartRegions}
];

const kOverlayPackCatalog = <OverlayPackRef>[
${packs
  .map((r) => {
    const name = r.name.replace(/'/g, "\\'");
    return `  OverlayPackRef(id: '${r.id}', name: '${name}'),`;
  })
  .join("\n")}
];

OverlayRegion? overlayRegionById(String id) {
  for (final r in kOverlayRegions) {
    if (r.id == id) return r;
  }
  return null;
}

OverlayRegion? overlayRegionForPoint(double lng, double lat) {
  final hits = [
    for (final r in kOverlayRegions)
      if (r.contains(lng, lat)) r,
  ];
  if (hits.isEmpty) return null;
  hits.sort((a, b) {
    final aa = (a.bbox[2] - a.bbox[0]) * (a.bbox[3] - a.bbox[1]);
    final bb = (b.bbox[2] - b.bbox[0]) * (b.bbox[3] - b.bbox[1]);
    return aa.compareTo(bb);
  });
  return hits.first;
}
`;

writeFileSync(
  join(root, "mobile/lib/data/routing/overlay_regions.dart"),
  dart
);

console.log(
  `sync-dach-region-packs: ${packs.length} packs, ${regions.length - packs.length} envelopes`
);
