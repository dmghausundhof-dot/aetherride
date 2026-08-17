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
  const out = { region: null, input: null, outPath: null, geojson: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--input") out.input = argv[++i];
    else if (a === "--out") out.outPath = argv[++i];
    else if (a === "--geojson") out.geojson = argv[++i];
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

/** Avoid Math.min(...arr) — spreading 80k+ coords exceeds V8 argument limits. */
function bboxOf(nodes) {
  if (!nodes.length) return [0, 0, 0, 0];
  let minLng = Infinity;
  let minLat = Infinity;
  let maxLng = -Infinity;
  let maxLat = -Infinity;
  for (const n of nodes) {
    if (n.lng < minLng) minLng = n.lng;
    if (n.lat < minLat) minLat = n.lat;
    if (n.lng > maxLng) maxLng = n.lng;
    if (n.lat > maxLat) maxLat = n.lat;
  }
  return [minLng, minLat, maxLng, maxLat];
}

function trimConnected(nodes, edges, maxNodes, maxEdges, seedLat, seedLng) {
  if (nodes.length <= maxNodes && edges.length <= maxEdges) {
    return { nodes, edges };
  }
  const adj = new Map();
  for (const e of edges) {
    if (!adj.has(e.from)) adj.set(e.from, []);
    if (!adj.has(e.to)) adj.set(e.to, []);
    adj.get(e.from).push(e.to);
    adj.get(e.to).push(e.from);
  }
  const clat =
    seedLat ?? nodes.reduce((s, n) => s + n.lat, 0) / nodes.length;
  const clng =
    seedLng ?? nodes.reduce((s, n) => s + n.lng, 0) / nodes.length;
  const ranked = [...nodes].sort(
    (a, b) =>
      (a.lat - clat) ** 2 +
      (a.lng - clng) ** 2 -
      ((b.lat - clat) ** 2 + (b.lng - clng) ** 2)
  );

  const keep = new Set();
  const MIN_COMPONENT = 64;

  function component(seed) {
    const out = [];
    const seen = new Set([seed]);
    const q = [seed];
    let qi = 0;
    while (qi < q.length) {
      const cur = q[qi++];
      out.push(cur);
      for (const nxt of adj.get(cur) || []) {
        if (seen.has(nxt) || keep.has(nxt)) continue;
        seen.add(nxt);
        q.push(nxt);
      }
    }
    return out;
  }

  for (const n of ranked) {
    if (keep.size >= maxNodes) break;
    if (keep.has(n.id)) continue;
    const comp = component(n.id);
    if (comp.length < MIN_COMPONENT && keep.size > 0) continue;
    for (const id of comp) {
      keep.add(id);
      if (keep.size >= maxNodes) break;
    }
  }

  if (keep.size === 0) {
    for (const n of ranked) {
      keep.add(n.id);
      if (keep.size >= maxNodes) break;
    }
  }

  return {
    nodes: nodes.filter((n) => keep.has(n.id)),
    edges: edges
      .filter((e) => keep.has(e.from) && keep.has(e.to))
      .slice(0, maxEdges),
  };
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
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
  ];
  let lastErr;
  for (const url of endpoints) {
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const res = await fetch(url, {
          method: "POST",
          body: `data=${encodeURIComponent(query)}`,
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          signal: AbortSignal.timeout(180_000),
        });
        if (res.status === 429 || res.status === 504) {
          lastErr = new Error(`${url} ${res.status}`);
          // Overpass rate limits: back off hard before next try/endpoint
          await new Promise((r) => setTimeout(r, 20_000 * (attempt + 1)));
          continue;
        }
        if (!res.ok) throw new Error(`${url} ${res.status}`);
        return await res.json();
      } catch (err) {
        lastErr = err;
        await new Promise((r) => setTimeout(r, 5_000 * (attempt + 1)));
      }
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
    const trimmed = trimConnected(nodes, edges, maxNodes, maxEdges);
    nodes = trimmed.nodes;
    edges.length = 0;
    edges.push(...trimmed.edges);
  }

  const bbox = bboxOf(nodes);

  return {
    version: 1,
    source: "osm",
    bbox,
    nodes,
    edges,
  };
}

function nodeId(lat, lng) {
  return `n${Math.round(lat * 1e7)}_${Math.round(lng * 1e7)}`;
}

/** GeoJSON from osmium export (LineString highways) → same graph shape. */
function buildGraphFromGeojson(fc, opts = {}) {
  const maxNodes = opts.maxNodes ?? 25000;
  const maxEdges = opts.maxEdges ?? 40000;
  const features = Array.isArray(fc?.features) ? fc.features : [];
  const nodeMap = new Map();
  const edges = [];

  for (const f of features) {
    const tags = f.properties || {};
    const hw = tags.highway;
    if (!HIGHWAYS.has(hw)) continue;
    const g = f.geometry;
    if (!g || (g.type !== "LineString" && g.type !== "MultiLineString")) continue;
    const lines =
      g.type === "LineString" ? [g.coordinates] : g.coordinates || [];
    for (const coords of lines) {
      if (!Array.isArray(coords) || coords.length < 2) continue;
      for (let i = 0; i < coords.length - 1; i++) {
        const a = coords[i];
        const b = coords[i + 1];
        if (!Array.isArray(a) || !Array.isArray(b) || a.length < 2 || b.length < 2) {
          continue;
        }
        const lng1 = Number(a[0]);
        const lat1 = Number(a[1]);
        const lng2 = Number(b[0]);
        const lat2 = Number(b[1]);
        if (![lat1, lng1, lat2, lng2].every(Number.isFinite)) continue;
        const length_m = haversineM(lat1, lng1, lat2, lng2);
        if (length_m < 1 || length_m > 5000) continue;
        const from = nodeId(lat1, lng1);
        const to = nodeId(lat2, lng2);
        if (from === to) continue;
        nodeMap.set(from, { id: from, lat: lat1, lng: lng1 });
        nodeMap.set(to, { id: to, lat: lat2, lng: lng2 });
        edges.push({
          from,
          to,
          length_m: Math.round(length_m * 10) / 10,
          highway: hw,
          mtb_scale: mtbScale(tags),
          surface: surface(tags),
          bidirectional: tags.oneway !== "yes" && tags.oneway !== "1",
        });
      }
    }
  }

  console.error(
    `geojson features=${features.length} collected nodes=${nodeMap.size} edges=${edges.length}`
  );
  let nodes = [...nodeMap.values()];
  let keptEdges = edges;
  if (nodes.length > maxNodes || keptEdges.length > maxEdges) {
    const trimmed = trimConnected(
      nodes,
      keptEdges,
      maxNodes,
      maxEdges,
      opts.seedLat,
      opts.seedLng
    );
    nodes = trimmed.nodes;
    keptEdges = trimmed.edges;
  }
  console.error(`trimmed nodes=${nodes.length} edges=${keptEdges.length}`);

  return {
    version: 1,
    source: "osm-geofabrik",
    bbox: bboxOf(nodes),
    nodes,
    edges: keptEdges,
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
  let graph;
  const graphOpts = {
    maxNodes: region.graph?.maxNodes ?? 20000,
    maxEdges: region.graph?.maxEdges ?? 35000,
    seedLat: (region.bbox[1] + region.bbox[3]) / 2,
    seedLng: (region.bbox[0] + region.bbox[2]) / 2,
  };
  if (args.geojson) {
    const fc = JSON.parse(fs.readFileSync(args.geojson, "utf8"));
    graph = buildGraphFromGeojson(fc, graphOpts);
  } else if (args.input) {
    osm = JSON.parse(fs.readFileSync(args.input, "utf8"));
    graph = buildGraph(osm, graphOpts);
  } else if (fs.existsSync("/tmp/overpass.json")) {
    osm = JSON.parse(fs.readFileSync("/tmp/overpass.json", "utf8"));
    graph = buildGraph(osm, graphOpts);
  } else {
    console.error("Fetching Overpass for", region.id, region.bbox);
    osm = await fetchOverpass(region.bbox);
    graph = buildGraph(osm, graphOpts);
  }

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
