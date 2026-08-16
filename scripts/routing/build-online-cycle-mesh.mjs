#!/usr/bin/env node
/**
 * OSM-Grid → signed cycle-route mesh (icn/ncn/rcn + tagged MTB relations).
 *
 * Not a contraction-hierarchy mesh and not a named OSM-Mesh product —
 * signed OSM route relations, queried cell-by-cell via Overpass.
 *
 * Does not download Geofabrik / planet / france-latest.osm.pbf.
 * Does not rebuild Valhalla. Does not rewrite basemap style JSON.
 *
 *   node scripts/routing/build-online-cycle-mesh.mjs
 *   node scripts/routing/build-online-cycle-mesh.mjs --dach-only   (default)
 *   node scripts/routing/build-online-cycle-mesh.mjs --all
 *   node scripts/routing/build-online-cycle-mesh.mjs --upload
 */
import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "../..");

const ENDPOINTS = [
  "https://overpass.openstreetmap.fr/api/interpreter",
  "https://overpass.private.coffee/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
];

/** Same bbox as the dach-z11 online basemap archive. */
const DACH = { id: "dach", bbox: [5.8, 45.75, 17.25, 55.15] };

const STEP = 2.4;
const OVERLAP = 0.04;
const MIN_LEN_M = 180;
const RANK = { icn: 4, ncn: 3, rcn: 2, mtb: 1, lcn: 0, "": 0 };

function parseArgs(argv) {
  const all = argv.includes("--all");
  return {
    dachOnly: !all,
    upload: argv.includes("--upload"),
    skipFetch: argv.includes("--skip-fetch"),
  };
}

function round5(n) {
  return Math.round(n * 1e5) / 1e5;
}

function haversineM(lng1, lat1, lng2, lat2) {
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

function pathLengthM(coords) {
  let sum = 0;
  for (let i = 1; i < coords.length; i++) {
    sum += haversineM(
      coords[i - 1][0],
      coords[i - 1][1],
      coords[i][0],
      coords[i][1]
    );
  }
  return sum;
}

function simplify(coords) {
  const out = [];
  let last = null;
  for (const c of coords) {
    if (!Array.isArray(c) || c.length < 2) continue;
    const lng = round5(Number(c[0]));
    const lat = round5(Number(c[1]));
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
    if (last && last[0] === lng && last[1] === lat) continue;
    last = [lng, lat];
    out.push(last);
  }
  if (out.length <= 96) return out;
  const step = Math.max(1, Math.floor(out.length / 96));
  const slim = out.filter((_, i) => i % step === 0);
  const end = out[out.length - 1];
  if (slim[slim.length - 1] !== end) slim.push(end);
  return slim;
}

function parseNetwork(tags) {
  const route = String(tags.route || "").toLowerCase();
  const network = String(tags.network || "").toLowerCase();
  const ref = String(tags.ref || "")
    .toUpperCase()
    .replace(/\s+/g, "");
  if (network.includes("icn") || /^EV\d/.test(ref) || /^D-?ROUTE/.test(ref)) {
    return "icn";
  }
  if (network.includes("ncn")) return "ncn";
  if (network.includes("rcn")) return "rcn";
  if (network.includes("lcn")) return "lcn";
  if (route === "mtb") return "mtb";
  return "";
}

function classify(tags) {
  const route = String(tags.route || "").toLowerCase();
  const network = parseNetwork(tags);
  if (network === "lcn" || network === "") {
    return { bikeClass: "hidden", network };
  }
  if (route === "mtb") {
    return { bikeClass: "mtb", network };
  }
  if (route !== "bicycle" && route !== "cycling") {
    return { bikeClass: "hidden", network: "" };
  }
  if (network === "icn" || network === "ncn" || network === "rcn") {
    return { bikeClass: "road", network };
  }
  return { bikeClass: "hidden", network: "" };
}

function cellsForBbox(bbox) {
  const [w, s, e, n] = bbox;
  const cells = [];
  for (let lat = s; lat < n; lat += STEP) {
    for (let lng = w; lng < e; lng += STEP) {
      const west = Math.max(w, lng - OVERLAP);
      const south = Math.max(s, lat - OVERLAP);
      const east = Math.min(e, lng + STEP + OVERLAP);
      const north = Math.min(n, lat + STEP + OVERLAP);
      if (east - west < 0.2 || north - south < 0.2) continue;
      cells.push([west, south, east, north]);
    }
  }
  return cells;
}

function cellKey(bbox) {
  return bbox.map((n) => n.toFixed(3)).join(",");
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function overpass(query) {
  const tmp = path.join(
    ROOT,
    "data/routing/dist/_basemap",
    `overpass-${process.pid}.json`
  );
  let lastErr;
  for (const url of ENDPOINTS) {
    try {
      const r = spawnSync(
        "curl",
        [
          "-sS",
          "-f",
          "-m",
          "180",
          "-o",
          tmp,
          "-H",
          "Accept: application/json",
          "-H",
          "User-Agent: FlowLine/cycle-mesh (https://aetherride.app)",
          "--data-urlencode",
          `data=${query}`,
          url,
        ],
        { encoding: "utf8" }
      );
      if (r.status !== 0) {
        lastErr = new Error(`${url} curl ${r.status} ${(r.stderr || "").slice(0, 120)}`);
        continue;
      }
      const json = JSON.parse(fs.readFileSync(tmp, "utf8"));
      if (json.remark && /error|timeout/i.test(json.remark)) {
        lastErr = new Error(`${url} ${json.remark}`);
        continue;
      }
      return json;
    } catch (err) {
      lastErr = err;
    }
  }
  throw lastErr;
}

function clipLine(coords, bbox) {
  const keep = [];
  for (let i = 0; i < coords.length; i++) {
    const [lng, lat] = coords[i];
    const inside =
      lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
    const neighbor =
      (i > 0 &&
        coords[i - 1][0] >= bbox[0] &&
        coords[i - 1][1] >= bbox[1] &&
        coords[i - 1][0] <= bbox[2] &&
        coords[i - 1][1] <= bbox[3]) ||
      (i + 1 < coords.length &&
        coords[i + 1][0] >= bbox[0] &&
        coords[i + 1][1] >= bbox[1] &&
        coords[i + 1][0] <= bbox[2] &&
        coords[i + 1][1] <= bbox[3]);
    if (inside || neighbor) keep.push(coords[i]);
  }
  return keep;
}

function queryForCell(bbox) {
  const [w, s, e, n] = bbox;
  return `
[out:json][timeout:60][maxsize:134217728];
(
  relation["route"="bicycle"]["network"~"icn|ncn|rcn"](${s},${w},${n},${e});
  relation["route"="bicycle"]["ref"~"^EV"](${s},${w},${n},${e});
)->.rels;
way(r.rels)(${s},${w},${n},${e});
out geom;
`.trim();
}

function featuresFromOverpass(json, clipBbox) {
  const features = [];
  for (const el of json.elements || []) {
    if (el.type !== "way" || !el.geometry || el.geometry.length < 2) continue;
    const coords = clipLine(
      simplify(el.geometry.map((g) => [g.lon, g.lat])),
      clipBbox
    );
    if (coords.length < 2) continue;
    if (pathLengthM(coords) < MIN_LEN_M) continue;
    const tags = el.tags || {};
    features.push({
      type: "Feature",
      properties: {
        bike_class: "road",
        mtb_scale: "",
        network: parseNetwork(tags) || "rcn",
        name: tags.name || tags["name:de"] || tags.ref || "",
        ref: tags.ref || "",
        osm_id: `way/${el.id}`,
        highway: "cycleway",
      },
      geometry: { type: "LineString", coordinates: coords },
      _key: `way/${el.id}`,
    });
  }
  return features;
}

function loadEnv() {
  const env = {};
  for (const p of [
    path.join(ROOT, ".env.local"),
    path.join(ROOT, "../aetherride/.env.local"),
  ]) {
    if (!fs.existsSync(p)) continue;
    for (const line of fs.readFileSync(p, "utf8").split("\n")) {
      if (!line || line.startsWith("#") || !line.includes("=")) continue;
      const i = line.indexOf("=");
      const k = line.slice(0, i).trim();
      const v = line
        .slice(i + 1)
        .trim()
        .replace(/^['"]|['"]$/g, "");
      env[k] = v;
    }
  }
  return env;
}

async function storagePut(env, objectPath, filePath, contentType) {
  const supabaseUrl = (env.NEXT_PUBLIC_SUPABASE_URL || env.SUPABASE_URL || "").replace(
    /\/$/,
    ""
  );
  const key = env.SUPABASE_SERVICE_ROLE_KEY || "";
  if (!supabaseUrl || !key) {
    throw new Error("missing SUPABASE url or service role");
  }
  const body = fs.readFileSync(filePath);
  const url = `${supabaseUrl}/storage/v1/object/offline-packs/${objectPath}`;
  const headers = {
    Authorization: `Bearer ${key}`,
    apikey: key,
    "Content-Type": contentType,
    "x-upsert": "true",
    "cache-control": "max-age=86400",
  };
  let res = await fetch(url, { method: "POST", headers, body });
  if (res.status === 409 || res.status === 400) {
    res = await fetch(url, { method: "PUT", headers, body });
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`storage_put ${objectPath} HTTP ${res.status} ${text.slice(0, 200)}`);
  }
}

function runTippecanoe(geojson, pmtiles) {
  const outDir = path.dirname(pmtiles);
  const inName = path.basename(geojson);
  const outName = path.basename(pmtiles);
  const args = [
    "-o",
    outName,
    "--force",
    "--layer=bike",
    "--minimum-zoom=5",
    "--maximum-zoom=11",
    "--drop-densest-as-needed",
    "--simplification=12",
    inName,
  ];
  if (spawnSync("tippecanoe", ["-v"], { stdio: "ignore" }).status === 0) {
    const r = spawnSync("tippecanoe", args, { cwd: outDir, stdio: "inherit" });
    if (r.status !== 0) throw new Error("tippecanoe failed");
    return;
  }
  const r = spawnSync(
    "docker",
    [
      "run",
      "--rm",
      "-u",
      `${process.getuid()}:${process.getgid()}`,
      "-v",
      `${outDir}:/data`,
      "aetherride-tippecanoe",
      "-o",
      `/data/${outName}`,
      "--force",
      "--layer=bike",
      "--minimum-zoom=5",
      "--maximum-zoom=11",
      "--drop-densest-as-needed",
      "--simplification=12",
      `/data/${inName}`,
    ],
    { stdio: "inherit" }
  );
  if (r.status !== 0) throw new Error("tippecanoe failed");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const outDir = path.join(ROOT, "data/routing/dist/_basemap");
  fs.mkdirSync(outDir, { recursive: true });
  const geojsonPath = path.join(outDir, "cycle-routes.geojson");
  const pmtilesPath = path.join(outDir, "cycle-routes.pmtiles");
  const progressPath = path.join(outDir, "cycle-routes.progress.json");
  const metaPath = path.join(outDir, "cycle-routes.json");
  const clipBbox = DACH.bbox;
  const cells = cellsForBbox(clipBbox);
  console.log(
    `==> OSM cycle-route mesh cells=${cells.length} dachOnly=${args.dachOnly}`
  );

  if (!args.skipFetch || !fs.existsSync(geojsonPath)) {
    let done = new Set();
    const byKey = new Map();
    if (fs.existsSync(progressPath)) {
      try {
        const prev = JSON.parse(fs.readFileSync(progressPath, "utf8"));
        for (const k of prev.done || []) done.add(k);
        for (const f of prev.features || []) {
          if (f._key) byKey.set(f._key, f);
        }
        console.log(`==> resume done=${done.size} features=${byKey.size}`);
      } catch {
        done = new Set();
      }
    }

    let i = 0;
    for (const bbox of cells) {
      i += 1;
      const key = cellKey(bbox);
      const label = `${i}/${cells.length} ${bbox.map((n) => n.toFixed(2)).join(",")}`;
      if (done.has(key)) {
        console.log(`skip ${label}`);
        continue;
      }
      process.stdout.write(`fetch ${label} … `);
      try {
        const json = await overpass(queryForCell(bbox));
        const feats = featuresFromOverpass(json, clipBbox);
        let added = 0;
        for (const f of feats) {
          const prev = byKey.get(f._key);
          if (
            prev &&
            (RANK[prev.properties.network] || 0) >= (RANK[f.properties.network] || 0)
          ) {
            continue;
          }
          byKey.set(f._key, f);
          added += 1;
        }
        done.add(key);
        console.log(`+${added} (total ${byKey.size})`);
        fs.writeFileSync(
          progressPath,
          JSON.stringify({
            done: [...done],
            features: [...byKey.values()],
          })
        );
      } catch (err) {
        console.log(`FAIL ${err instanceof Error ? err.message : err}`);
      }
      await sleep(500);
    }

    const features = [...byKey.values()].map((f) => {
      const { _key, ...rest } = f;
      return rest;
    });
    const counts = {};
    for (const f of features) {
      const n = f.properties.network || f.properties.bike_class;
      counts[n] = (counts[n] || 0) + 1;
    }
    fs.writeFileSync(
      geojsonPath,
      JSON.stringify({ type: "FeatureCollection", features })
    );
    console.log(
      JSON.stringify(
        {
          features: features.length,
          bytes: fs.statSync(geojsonPath).size,
          counts,
        },
        null,
        2
      )
    );
  } else {
    console.log(`==> skip fetch (exists ${geojsonPath})`);
  }

  if (!fs.existsSync(geojsonPath) || fs.statSync(geojsonPath).size < 2000) {
    throw new Error("cycle-routes.geojson too small");
  }

  const fc = JSON.parse(fs.readFileSync(geojsonPath, "utf8"));
  const counts = {};
  for (const f of fc.features || []) {
    const n = f.properties?.network || f.properties?.bike_class;
    counts[n] = (counts[n] || 0) + 1;
  }

  console.log("==> tippecanoe z5–z11");
  runTippecanoe(geojsonPath, pmtilesPath);
  console.log("pmtiles", fs.statSync(pmtilesPath).size);

  const meta = {
    id: "cycle-routes",
    name: "DACH Radnetz",
    layer: "bike",
    sourceLayer: "bike",
    bbox: clipBbox,
    networks: ["icn", "ncn", "rcn"],
    minzoom: 5,
    maxzoom: 11,
    builtAt: new Date().toISOString(),
    features: (fc.features || []).length,
    counts,
    pmtiles: "basemap/cycle-routes.pmtiles",
  };
  fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2) + "\n");

  if (args.upload) {
    const env = loadEnv();
    console.log("==> upload cycle-routes");
    await storagePut(
      env,
      "basemap/cycle-routes.pmtiles",
      pmtilesPath,
      "application/vnd.pmtiles"
    );
    await storagePut(env, "basemap/cycle-routes.json", metaPath, "application/json");
    if (fs.existsSync(geojsonPath)) {
      await storagePut(
        env,
        "basemap/cycle-routes.geojson",
        geojsonPath,
        "application/geo+json"
      );
    }
    console.log("UPLOADED basemap/cycle-routes.pmtiles");
  }

  console.log("DONE", geojsonPath, pmtilesPath);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
