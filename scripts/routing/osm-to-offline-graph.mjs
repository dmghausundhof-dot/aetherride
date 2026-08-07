#!/usr/bin/env node
/**
 * Build offline_graph.json (v1) from OSM Overpass JSON or OSM XML/JSON export.
 * Same region config as tile builds → identical coverage as Valhalla extracts.
 *
 * Usage:
 *   node scripts/routing/osm-to-offline-graph.mjs data/routing/regions/schwarzwald-nord.json
 *   node scripts/routing/osm-to-offline-graph.mjs --input /tmp/overpass.json --out path/graph.json
 *
 * Fetches Overpass if --input omitted.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "../..");

const HIGHWAYS = new Set([
  "path",
  "track",
  "cycleway",
  "bridleway",
  "footway",
  "residential",
  "tertiary",
  "unclassified",
  "service",
  "living_street",
  "secondary",
  "primary",
]);

function parseArgs(argv) {
  const out = { region: null, input: null, outPath: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--input") out.input = argv[++i];
    else if (a === "--out") out.outPath = argv[++i];
    else if (!a.startsWith("-")) out.region = a;
  }
  return out;
}

function loadRegion(p) {
  const abs = path.isAbsolute(p) ? p : path.join(root, p);
  return JSON.parse(fs.readFileSync(abs, "utf8"));
}

function haversineM(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const p1 = (lat1 * Math.PI) / 180;
  const p2 = (lat2 * Math.PI) / 180;
  const dp = ((lat2 - lat1) * Math.PI) / 180;
  const dl = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dp / 2) ** 2 +
    Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

function mtbScale(tags) {
  const raw = tags["mtb:scale"] ?? tags["mtb:scale:imba"];
  if (raw == null) return null;
  const n = parseInt(String(raw).replace(/[^0-9].*$/, ""), 10);
  return Number.isFinite(n) ? n : null;
}

function surface(tags) {
  return tags.surface || tags.tracktype || "ground";
}

async function fetchOverpass(bbox) {
  // bbox: [west, south, east, north] = [minLng, minLat, maxLng, maxLat]
  const [w, s, e, n] = bbox;
  const query = `
[out:json][timeout:120];
(
  way["highway"~"^(path|track|cycleway|bridleway|footway|residential|tertiary|unclassified|service|living_street)$"](${s},${w},${n},${e});
);
out body;
>;
out skel qt;
`;
  const endpoints = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
  ];
  let lastErr;
  for (const url of endpoints) {
    try {
      const res = await fetch(url, {
        method: "POST",
        body: query,
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
      });
      if (!res.ok) throw new Error(`${url} ${res.status}`);
      return await res.json();
    } catch (err) {
      lastErr = err;
    }
  }
  throw lastErr;
}

function buildGraph(osm, opts = {}) {
  const maxNodes = opts.maxNodes ?? 25000;
  const maxEdges = opts.maxEdges ?? 40000;
  const nodesById = new Map();
  for (const el of osm.elements || []) {
    if (el.type === "node") {
      nodesById.set(el.id, { lat: el.lat, lng: el.lon });
    }
  }

  const usedNodeIds = new Set();
  const edges = [];
  for (const el of osm.elements || []) {
    if (el.type !== "way" || !el.nodes || el.nodes.length < 2) continue;
    const tags = el.tags || {};
    const hw = tags.highway;
    if (!HIGHWAYS.has(hw)) continue;
    // skip steps / motorways if tagged oddly
    if (tags.area === "yes") continue;

    for (let i = 0; i < el.nodes.length - 1; i++) {
      const a = el.nodes[i];
      const b = el.nodes[i + 1];
      const na = nodesById.get(a);
      const nb = nodesById.get(b);
      if (!na || !nb) continue;
      const length_m = haversineM(na.lat, na.lng, nb.lat, nb.lng);
      if (length_m < 1 || length_m > 5000) continue;
      usedNodeIds.add(a);
      usedNodeIds.add(b);
      edges.push({
        from: `n${a}`,
        to: `n${b}`,
        length_m: Math.round(length_m * 10) / 10,
        highway: hw,
        mtb_scale: mtbScale(tags),
        surface: surface(tags),
        bidirectional: tags.oneway !== "yes" && tags.oneway !== "1",
      });
      if (edges.length >= maxEdges) break;
    }
    if (edges.length >= maxEdges) break;
  }

  let nodes = [...usedNodeIds].map((id) => {
    const n = nodesById.get(id);
    return { id: `n${id}`, lat: n.lat, lng: n.lng };
  });

  if (nodes.length > maxNodes || edges.length > maxEdges) {
    // Keep a spatially central connected subgraph (BFS), not "first N edges".
    const adj = new Map();
    for (const e of edges) {
      if (!adj.has(e.from)) adj.set(e.from, []);
      if (!adj.has(e.to)) adj.set(e.to, []);
      adj.get(e.from).push(e.to);
      adj.get(e.to).push(e.from);
    }
    const clat = nodes.reduce((s, n) => s + n.lat, 0) / nodes.length;
    const clng = nodes.reduce((s, n) => s + n.lng, 0) / nodes.length;
    let seed = nodes[0].id;
    let best = Infinity;
    for (const n of nodes) {
      const d = (n.lat - clat) ** 2 + (n.lng - clng) ** 2;
      if (d < best) {
        best = d;
        seed = n.id;
      }
    }
    const keep = new Set();
    const q = [seed];
    keep.add(seed);
    while (q.length && keep.size < maxNodes) {
      const cur = q.shift();
      for (const nxt of adj.get(cur) || []) {
        if (keep.has(nxt)) continue;
        keep.add(nxt);
        q.push(nxt);
        if (keep.size >= maxNodes) break;
      }
    }
    nodes = nodes.filter((n) => keep.has(n.id));
    const filtered = edges
      .filter((e) => keep.has(e.from) && keep.has(e.to))
      .slice(0, maxEdges);
    edges.length = 0;
    edges.push(...filtered);
  }

  const lats = nodes.map((n) => n.lat);
  const lngs = nodes.map((n) => n.lng);
  const bbox =
    nodes.length > 0
      ? [
          Math.min(...lngs),
          Math.min(...lats),
          Math.max(...lngs),
          Math.max(...lats),
        ]
      : [0, 0, 0, 0];

  return {
    version: 1,
    source: "osm",
    bbox,
    nodes,
    edges,
  };
}

async function main() {
  const args = parseArgs(process.argv);
  let region = null;
  if (args.region) {
    region = loadRegion(args.region);
  } else {
    // default region
    region = loadRegion("data/routing/regions/schwarzwald-nord.json");
  }

  let osm;
  if (args.input) {
    osm = JSON.parse(fs.readFileSync(args.input, "utf8"));
  } else if (fs.existsSync("/tmp/overpass.json")) {
    // reuse recent fetch if present and bbox matches roughly
    osm = JSON.parse(fs.readFileSync("/tmp/overpass.json", "utf8"));
  } else {
    console.error("Fetching Overpass for", region.id, region.bbox);
    osm = await fetchOverpass(region.bbox);
  }

  const graph = buildGraph(osm, {
    maxNodes: region.graph?.maxNodes ?? 20000,
    maxEdges: region.graph?.maxEdges ?? 35000,
  });

  const outPath =
    args.outPath ||
    path.join(
      root,
      region.outputDir || `data/routing/dist/${region.id}`,
      "offline_graph.json"
    );
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(graph));
  console.log(
    JSON.stringify(
      {
        ok: true,
        region: region.id,
        out: outPath,
        nodes: graph.nodes.length,
        edges: graph.edges.length,
        bbox: graph.bbox,
      },
      null,
      2
    )
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
