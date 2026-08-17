#!/usr/bin/env npx tsx
/**
 * Classify + tile + upload DACH-wide ways overlay.
 *
 * Fetch lives in build-dach-ways-from-geofabrik.sh (regional extracts,
 * not germany-latest / planet). Overpass is not the default path.
 *
 *   npx tsx scripts/routing/build-dach-ways-overlay.ts --ingest-seq FILE
 *   npx tsx scripts/routing/build-dach-ways-overlay.ts --tile
 *   npx tsx scripts/routing/build-dach-ways-overlay.ts --skip-fetch --upload
 */
import fs from "fs";
import path from "path";
import readline from "readline";
import { spawnSync } from "child_process";
import { fileURLToPath } from "url";
import { classifyBikeWay } from "../../src/lib/routing/bikeOverlayClass";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "../..");
const DACH_BBOX: [number, number, number, number] = [5.8, 45.75, 17.25, 55.15];
const MIN_LEN_M = 40;
const PATH_TRACK = new Set(["path", "track", "bridleway", "footway"]);
const ROAD_LIKE = new Set([
  "primary",
  "secondary",
  "tertiary",
  "unclassified",
  "residential",
  "service",
]);
const CYCLEWAY_INFRA = new Set([
  "lane",
  "track",
  "share_busway",
  "opposite_lane",
  "opposite_track",
  "shared_lane",
]);

function parseArgs(argv: string[]) {
  const out = {
    upload: argv.includes("--upload"),
    skipFetch: argv.includes("--skip-fetch"),
    tile: argv.includes("--tile"),
    ingestSeq: null as string | null,
  };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--ingest-seq") out.ingestSeq = argv[++i] ?? null;
  }
  return out;
}

function round5(n: number) {
  return Math.round(n * 1e5) / 1e5;
}

function haversineM(lng1: number, lat1: number, lng2: number, lat2: number) {
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

function pathLengthM(coords: number[][]) {
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

function simplify(coords: unknown[]) {
  const out: number[][] = [];
  let last: number[] | null = null;
  for (const c of coords) {
    if (!Array.isArray(c) || c.length < 2) continue;
    const lng = round5(Number(c[0]));
    const lat = round5(Number(c[1]));
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
    if (last && last[0] === lng && last[1] === lat) continue;
    last = [lng, lat];
    out.push(last);
  }
  if (out.length <= 64) return out;
  const step = Math.max(1, Math.floor(out.length / 64));
  const slim = out.filter((_, i) => i % step === 0);
  const end = out[out.length - 1];
  if (slim[slim.length - 1] !== end) slim.push(end);
  return slim;
}

function clipLine(coords: number[][], bbox: [number, number, number, number]) {
  const keep: number[][] = [];
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

function tagsFromProps(props: Record<string, unknown> | null | undefined) {
  const tags: Record<string, string | undefined> = {};
  if (!props) return tags;
  for (const [k, v] of Object.entries(props)) {
    if (k.startsWith("@")) continue;
    if (typeof v === "string") tags[k] = v;
  }
  return tags;
}

function cyclewayInfra(tags: Record<string, string | undefined>) {
  for (const key of [
    "cycleway",
    "cycleway:left",
    "cycleway:right",
    "cycleway:both",
  ]) {
    const v = (tags[key] || "").toLowerCase();
    if (CYCLEWAY_INFRA.has(v)) return true;
  }
  return false;
}

function keepDachWay(tags: Record<string, string | undefined>) {
  const hw = (tags.highway || "").toLowerCase();
  const bicycle = (tags.bicycle || "").toLowerCase();
  if (hw === "cycleway") return true;
  if (PATH_TRACK.has(hw)) return true;
  if (cyclewayInfra(tags)) return true;
  if (ROAD_LIKE.has(hw) && bicycle === "designated") return true;
  return false;
}

function loadEnv() {
  const env: Record<string, string> = {};
  const p = path.join(ROOT, ".env.local");
  if (!fs.existsSync(p)) return env;
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
  return env;
}

async function storagePut(
  env: Record<string, string>,
  objectPath: string,
  filePath: string,
  contentType: string
) {
  const size = fs.statSync(filePath).size;
  if (size > 40 * 1024 * 1024) {
    const r = spawnSync(
      "python3",
      [
        path.join(ROOT, "scripts/routing/tus-upload-storage.py"),
        filePath,
        objectPath,
        "--content-type",
        contentType,
      ],
      { stdio: "inherit", cwd: ROOT }
    );
    if (r.status !== 0) throw new Error(`tus upload ${objectPath} failed`);
    return;
  }
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
    throw new Error(
      `storage_put ${objectPath} HTTP ${res.status} ${text.slice(0, 200)}`
    );
  }
}

function runTippecanoe(geojsonseq: string, pmtiles: string) {
  const outDir = path.dirname(pmtiles);
  const inName = path.basename(geojsonseq);
  const outName = path.basename(pmtiles);
  const args = [
    "-o",
    outName,
    "--force",
    "--layer=bike",
    "--minimum-zoom=10",
    "--maximum-zoom=13",
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
      `${process.getuid?.() ?? 0}:${process.getgid?.() ?? 0}`,
      "-v",
      `${outDir}:/data`,
      "aetherride-tippecanoe",
      "-o",
      `/data/${outName}`,
      "--force",
      "--layer=bike",
      "--minimum-zoom=10",
      "--maximum-zoom=13",
      "--drop-densest-as-needed",
      "--simplification=12",
      `/data/${inName}`,
    ],
    { stdio: "inherit" }
  );
  if (r.status !== 0) throw new Error("tippecanoe failed");
}

async function loadSeenIds(seqPath: string, seen: Set<string>) {
  if (!fs.existsSync(seqPath)) return;
  const rl = readline.createInterface({
    input: fs.createReadStream(seqPath),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    const t = line.trim();
    if (!t) continue;
    try {
      const obj = JSON.parse(t) as { properties?: { osm_id?: string } };
      const id = obj.properties?.osm_id;
      if (id) seen.add(id);
    } catch {
      /* skip */
    }
  }
}

async function ingestSeq(inputPath: string, seqPath: string) {
  const seen = new Set<string>();
  await loadSeenIds(seqPath, seen);
  let added = 0;
  let skipped = 0;
  const counts: Record<string, number> = {};
  const rl = readline.createInterface({
    input: fs.createReadStream(inputPath),
    crlfDelay: Infinity,
  });
  const buf: string[] = [];
  const flush = () => {
    if (!buf.length) return;
    fs.appendFileSync(seqPath, buf.join("\n") + "\n");
    buf.length = 0;
  };
  for await (const line of rl) {
    const t = line.replace(/^\u001e/, "").trim();
    if (!t) continue;
    let feat: {
      type?: string;
      geometry?: { type?: string; coordinates?: unknown };
      properties?: Record<string, unknown>;
      id?: unknown;
    };
    try {
      feat = JSON.parse(t);
    } catch {
      continue;
    }
    if (feat.type !== "Feature" || !feat.geometry) continue;
    const geom = feat.geometry;
    if (geom.type !== "LineString" && geom.type !== "MultiLineString") continue;
    const tags = tagsFromProps(feat.properties);
    if (!keepDachWay(tags)) {
      skipped += 1;
      continue;
    }
    const classified = classifyBikeWay(tags);
    if (classified.bikeClass === "hidden") {
      skipped += 1;
      continue;
    }
    const lines =
      geom.type === "LineString" ? [geom.coordinates] : geom.coordinates;
    if (!Array.isArray(lines)) continue;
    const rawId =
      feat.properties?.["@id"] ?? feat.properties?.id ?? feat.id ?? "";
    const osmId = String(rawId);
    if (osmId && seen.has(osmId)) {
      skipped += 1;
      continue;
    }
    for (const rawLine of lines as unknown[]) {
      if (!Array.isArray(rawLine)) continue;
      const coords = clipLine(simplify(rawLine), DACH_BBOX);
      if (coords.length < 2 || pathLengthM(coords) < MIN_LEN_M) continue;
      if (osmId) seen.add(osmId);
      buf.push(
        JSON.stringify({
          type: "Feature",
          properties: {
            bike_class: classified.bikeClass,
            mtb_scale: classified.mtbScale ?? "",
            highway: tags.highway || "",
            name: tags.name || tags["name:de"] || "",
            osm_id: osmId,
          },
          geometry: { type: "LineString", coordinates: coords },
        })
      );
      counts[classified.bikeClass] = (counts[classified.bikeClass] || 0) + 1;
      added += 1;
      if (buf.length >= 400) flush();
    }
  }
  flush();
  console.log(
    JSON.stringify({ ingest: path.basename(inputPath), added, skipped, counts })
  );
}

async function tileAndMaybeUpload(upload: boolean) {
  const outDir = path.join(ROOT, "data/routing/dist/_basemap");
  const seqPath = path.join(outDir, "dach-ways.geojsonseq");
  const pmtilesPath = path.join(outDir, "dach-ways.pmtiles");
  const metaPath = path.join(outDir, "dach-ways.json");
  if (!fs.existsSync(seqPath) || fs.statSync(seqPath).size < 2000) {
    throw new Error("dach-ways.geojsonseq too small");
  }
  console.log("==> tippecanoe z10–z13");
  runTippecanoe(seqPath, pmtilesPath);
  const magic = Buffer.alloc(8);
  const fd = fs.openSync(pmtilesPath, "r");
  fs.readSync(fd, magic, 0, 8, 0);
  fs.closeSync(fd);
  if (magic.toString("utf8", 0, 7) !== "PMTiles") {
    throw new Error("dach-ways.pmtiles missing PMTiles magic");
  }
  const pmBytes = fs.statSync(pmtilesPath).size;
  console.log("pmtiles", pmBytes);
  if (pmBytes > 2 * 1024 * 1024 * 1024) {
    throw new Error("dach-ways.pmtiles exceeds 2 GiB — refuse upload");
  }
  const meta = {
    id: "dach-ways",
    name: "DACH Wege",
    layer: "bike",
    sourceLayer: "bike",
    bbox: DACH_BBOX,
    highways: ["cycleway", "path", "track"],
    minzoom: 10,
    maxzoom: 13,
    builtAt: new Date().toISOString(),
    bytes: pmBytes,
    pmtiles: "basemap/dach-ways.pmtiles",
  };
  fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2) + "\n");
  if (upload) {
    const env = loadEnv();
    console.log("==> upload dach-ways");
    await storagePut(
      env,
      "basemap/dach-ways.pmtiles",
      pmtilesPath,
      "application/vnd.pmtiles"
    );
    await storagePut(env, "basemap/dach-ways.json", metaPath, "application/json");
    console.log("UPLOADED basemap/dach-ways.pmtiles");
  }
  console.log("DONE", seqPath, pmtilesPath, pmBytes);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const outDir = path.join(ROOT, "data/routing/dist/_basemap");
  fs.mkdirSync(outDir, { recursive: true });
  const seqPath = path.join(outDir, "dach-ways.geojsonseq");
  if (args.ingestSeq) {
    await ingestSeq(args.ingestSeq, seqPath);
    return;
  }
  if (args.tile || args.upload) {
    await tileAndMaybeUpload(args.upload);
    return;
  }
  throw new Error(
    "use bash scripts/routing/build-dach-ways-from-geofabrik.sh (or --ingest-seq / --tile / --upload)"
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
