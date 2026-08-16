#!/usr/bin/env node
/**
 * OSM-Grid / Overpass → way-level bike overlay (cycleway/path/track).
 *
 * For small city bboxes only. Does not download planet or france-latest.osm.pbf.
 * Does not rebuild Valhalla.
 *
 *   node scripts/routing/build-bike-overlay-overpass.mjs annecy lyon paris
 *   node scripts/routing/build-bike-overlay-overpass.mjs annecy --upload
 */
import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";
import { fileURLToPath } from "url";
import crypto from "crypto";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "../..");

const ENDPOINTS = [
  "https://overpass.openstreetmap.fr/api/interpreter",
  "https://overpass.private.coffee/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
];

const CELL = 0.18;
const FORBIDDEN = /planet-latest|planet\.osm|(^|\/)france-latest\.osm\.pbf/i;

function parseArgs(argv) {
  const ids = [];
  let upload = false;
  for (const a of argv) {
    if (a === "--upload") upload = true;
    else if (!a.startsWith("--")) ids.push(a);
  }
  return { ids, upload };
}

function diskFreeGb() {
  const r = spawnSync("df", ["-BG", "/"], { encoding: "utf8" });
  const line = (r.stdout || "").trim().split("\n")[1] || "";
  const parts = line.split(/\s+/);
  const avail = Number(String(parts[3] || "").replace(/G$/i, ""));
  return Number.isFinite(avail) ? avail : 0;
}

function isQuota(err) {
  const m = String(err?.message || err || "").toLowerCase();
  return (
    m.includes("509") ||
    m.includes("429") ||
    m.includes("bandwidth") ||
    m.includes("too many requests")
  );
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

function cellsForBbox(bbox) {
  const [w, s, e, n] = bbox;
  if (e - w <= CELL + 0.02 && n - s <= CELL + 0.02) return [bbox];
  const cells = [];
  for (let lat = s; lat < n; lat += CELL) {
    for (let lng = w; lng < e; lng += CELL) {
      cells.push([
        lng,
        lat,
        Math.min(e, lng + CELL + 0.01),
        Math.min(n, lat + CELL + 0.01),
      ]);
    }
  }
  return cells;
}

function queryForCell(bbox) {
  const [w, s, e, n] = bbox;
  return `
[out:json][timeout:90][maxsize:134217728];
(
  way["highway"~"^(cycleway|path|track|bridleway)$"](${s},${w},${n},${e});
  way["bicycle"="designated"](${s},${w},${n},${e});
  way["mtb:scale"](${s},${w},${n},${e});
  way["cycleway"](${s},${w},${n},${e});
);
out geom;
`.trim();
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function overpass(query) {
  const tmp = path.join(
    ROOT,
    "data/routing/dist/_basemap",
    `overlay-overpass-${process.pid}.json`
  );
  fs.mkdirSync(path.dirname(tmp), { recursive: true });
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
          "User-Agent: FlowLine/bike-overlay (https://aetherride.app)",
          "--data-urlencode",
          `data=${query}`,
          url,
        ],
        { encoding: "utf8" }
      );
      const body = fs.existsSync(tmp) ? fs.readFileSync(tmp, "utf8") : "";
      if (r.status !== 0) {
        lastErr = new Error(
          `${url} curl ${r.status} ${(r.stderr || "").slice(0, 80)} ${body.slice(0, 120)}`
        );
        continue;
      }
      const json = JSON.parse(body);
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

function featuresFromOverpass(json) {
  const features = [];
  for (const el of json.elements || []) {
    if (el.type !== "way" || !el.geometry || el.geometry.length < 2) continue;
    const tags = el.tags || {};
    const coords = el.geometry.map((g) => [g.lon, g.lat]);
    features.push({
      type: "Feature",
      properties: {
        ...tags,
        "@id": `way/${el.id}`,
        highway: tags.highway || "",
        name: tags.name || tags["name:de"] || "",
      },
      geometry: { type: "LineString", coordinates: coords },
    });
  }
  return features;
}

function runClassify(inPath, outPath) {
  const r = spawnSync(
    "npx",
    ["tsx", path.join(ROOT, "scripts/routing/classify-bike-overlay.ts"), "--in", inPath, "--out", outPath],
    { cwd: ROOT, stdio: "inherit" }
  );
  if (r.status !== 0) throw new Error("classify-bike-overlay failed");
}

function runTippecanoe(geojson, pmtiles) {
  const outDir = path.dirname(pmtiles);
  const inName = path.basename(geojson);
  const outName = path.basename(pmtiles);
  if (spawnSync("tippecanoe", ["-v"], { stdio: "ignore" }).status === 0) {
    const r = spawnSync(
      "tippecanoe",
      [
        "-o",
        outName,
        "--force",
        "--layer=bike",
        "--minimum-zoom=9",
        "--maximum-zoom=14",
        "--drop-densest-as-needed",
        "--simplification=10",
        inName,
      ],
      { cwd: outDir, stdio: "inherit" }
    );
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
      "--minimum-zoom=9",
      "--maximum-zoom=14",
      "--drop-densest-as-needed",
      "--simplification=10",
      `/data/${inName}`,
    ],
    { stdio: "inherit" }
  );
  if (r.status !== 0) throw new Error("tippecanoe failed");
}

function shaEntry(filePath) {
  const buf = fs.readFileSync(filePath);
  const digest = crypto.createHash("sha256").update(buf).digest("hex");
  return { bytes: buf.length, sha256: digest, sha256_16: digest.slice(0, 16) };
}

function updateManifest(region, outDir) {
  const manifestPath = path.join(ROOT, "data/routing/manifests", `${region.id}.json`);
  const distManifest = path.join(outDir, "manifest.json");
  let base = {};
  if (fs.existsSync(manifestPath)) {
    base = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  }
  const files = { ...(base.files || {}) };
  const engines = { ...(base.engines || {}) };
  for (const name of ["bike-overlay.geojson", "bike-overlay.pmtiles"]) {
    const p = path.join(outDir, name);
    if (fs.existsSync(p)) files[name] = shaEntry(p);
  }
  engines.bike_overlay =
    fs.existsSync(path.join(outDir, "bike-overlay.pmtiles")) ||
    fs.existsSync(path.join(outDir, "bike-overlay.geojson"));
  const cdn = { ...(base.cdn || region.cdn || {}) };
  if (!cdn.baseUrl) {
    cdn.baseUrl = `https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/${region.id}`;
  }
  const manifest = {
    ...base,
    id: region.id,
    name: region.name || base.name,
    bbox: region.bbox || base.bbox,
    builtAt: new Date().toISOString(),
    engines,
    files,
    cdn,
    overlay: {
      layer: "bike",
      pmtiles: fs.existsSync(path.join(outDir, "bike-overlay.pmtiles"))
        ? "bike-overlay.pmtiles"
        : null,
      geojson: fs.existsSync(path.join(outDir, "bike-overlay.geojson"))
        ? "bike-overlay.geojson"
        : null,
      sourceLayer: "bike",
      property: "bike_class",
    },
  };
  const text = JSON.stringify(manifest, null, 2) + "\n";
  fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
  fs.writeFileSync(manifestPath, text);
  fs.writeFileSync(distManifest, text);
  return manifest;
}

async function buildRegion(id, upload) {
  const regionFile = path.join(ROOT, "data/routing/regions", `${id}.json`);
  if (!fs.existsSync(regionFile)) throw new Error(`missing ${regionFile}`);
  const region = JSON.parse(fs.readFileSync(regionFile, "utf8"));
  const geofabrik = String(region.osm?.geofabrik || "");
  if (FORBIDDEN.test(geofabrik)) {
    throw new Error(`refusing forbidden extract for ${id}`);
  }
  const bbox = region.bbox;
  if (!Array.isArray(bbox) || bbox.length !== 4) {
    throw new Error(`bad bbox for ${id}`);
  }
  const outDir = path.join(ROOT, "data/routing/dist", id);
  fs.mkdirSync(outDir, { recursive: true });
  const rawPath = path.join(outDir, "bike-ways.overpass.geojson");
  const overlayPath = path.join(outDir, "bike-overlay.geojson");
  const pmtilesPath = path.join(outDir, "bike-overlay.pmtiles");

  const cells = cellsForBbox(bbox);
  console.log(`==> overlay ${id} cells=${cells.length} bbox=${bbox.join(",")}`);
  const byId = new Map();
  let quotaHit = false;
  let i = 0;
  for (const cell of cells) {
    if (quotaHit) break;
    i += 1;
    process.stdout.write(`fetch ${id} ${i}/${cells.length} … `);
    try {
      const json = await overpass(queryForCell(cell));
      const feats = featuresFromOverpass(json);
      let added = 0;
      for (const f of feats) {
        const key = f.properties["@id"];
        if (!byId.has(key)) {
          byId.set(key, f);
          added += 1;
        }
      }
      console.log(`+${added} (total ${byId.size})`);
    } catch (err) {
      console.log(`FAIL ${err instanceof Error ? err.message : err}`);
      if (isQuota(err)) {
        console.log(`==> Overpass quota on ${id} — skip remaining cells`);
        quotaHit = true;
      }
    }
    await sleep(400);
  }

  if (byId.size < 40) {
    console.log(`SKIP ${id}: only ${byId.size} ways`);
    return { id, skipped: true, reason: "few_ways", ways: byId.size };
  }

  fs.writeFileSync(
    rawPath,
    JSON.stringify({ type: "FeatureCollection", features: [...byId.values()] })
  );
  console.log(`==> classify ${id}`);
  runClassify(rawPath, overlayPath);
  console.log(`==> tippecanoe ${id}`);
  runTippecanoe(overlayPath, pmtilesPath);
  const manifest = updateManifest(region, outDir);

  if (upload) {
    const env = loadEnv();
    await storagePut(
      env,
      `${id}/bike-overlay.pmtiles`,
      pmtilesPath,
      "application/vnd.pmtiles"
    );
    await storagePut(
      env,
      `${id}/bike-overlay.geojson`,
      overlayPath,
      "application/geo+json"
    );
    await storagePut(
      env,
      `${id}/manifest.json`,
      path.join(outDir, "manifest.json"),
      "application/json"
    );
    console.log(`UPLOADED ${id}/bike-overlay.pmtiles`);
  }

  return {
    id,
    skipped: false,
    ways: byId.size,
    overlayBytes: fs.statSync(overlayPath).size,
    pmtilesBytes: fs.statSync(pmtilesPath).size,
    overlay: manifest.overlay,
  };
}

async function main() {
  const joined = process.argv.slice(2).join(" ");
  if (FORBIDDEN.test(joined)) {
    throw new Error("refusing planet / france-latest.osm.pbf");
  }
  const free = diskFreeGb();
  if (free < 8) throw new Error(`disk ${free} GB < 8 GB — stop`);
  const args = parseArgs(process.argv.slice(2));
  if (!args.ids.length) {
    throw new Error("need region ids, e.g. annecy lyon paris");
  }
  console.log(`==> bike overlays ${args.ids.join(",")} disk=${free}G`);
  const results = [];
  for (const id of args.ids) {
    if (diskFreeGb() < 8) {
      console.log("STOP disk < 8 GB");
      break;
    }
    try {
      results.push(await buildRegion(id, args.upload));
    } catch (err) {
      console.log(`SKIP ${id}: ${err instanceof Error ? err.message : err}`);
      results.push({
        id,
        skipped: true,
        reason: String(err instanceof Error ? err.message : err).slice(0, 180),
      });
    }
  }
  console.log("DONE", JSON.stringify(results, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
