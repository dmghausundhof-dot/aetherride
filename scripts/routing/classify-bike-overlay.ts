#!/usr/bin/env npx tsx
/**
 * Classify osmium GeoJSON/GeoJSONSeq → bike overlay FeatureCollection.
 *
 * Usage:
 *   npx tsx scripts/routing/classify-bike-overlay.ts \
 *     --in bike-ways.geojsonseq --out bike-overlay.geojson
 *
 * Next rebuild (optional props — Discover already Overpass-looks up by osm_id):
 * - Keep writing `surface` / `tracktype` so overlay coloring and tap sheets
 *   can skip Overpass.
 * - Keep writing `mtb_scale` as S0/S1/S2/S3+ (3–6 collapsed to S3+, never sac_scale).
 * Vector maxzoom is typically 14; Discover hit-tests overlay layers past that
 * and can show named Overpass ways when overzoomed.
 */
import fs from "fs";
import readline from "readline";
import path from "path";
import { classifyBikeWay } from "../../src/lib/routing/bikeOverlayClass";

function parseArgs(argv: string[]) {
  const out = {
    input: null as string | null,
    outPath: null as string | null,
    sampleOut: null as string | null,
    sampleBbox: null as string | null,
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--in") out.input = argv[++i];
    else if (a === "--out") out.outPath = argv[++i];
    else if (a === "--sample-out") out.sampleOut = argv[++i];
    else if (a === "--sample-bbox") out.sampleBbox = argv[++i];
  }
  return out;
}

function round5(n: number) {
  return Math.round(n * 1e5) / 1e5;
}

function pathLengthM(coords: number[][]) {
  const R = 6371000;
  let sum = 0;
  for (let i = 1; i < coords.length; i++) {
    const [lng1, lat1] = coords[i - 1];
    const [lng2, lat2] = coords[i];
    const p1 = (lat1 * Math.PI) / 180;
    const p2 = (lat2 * Math.PI) / 180;
    const dp = ((lat2 - lat1) * Math.PI) / 180;
    const dl = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dp / 2) ** 2 +
      Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) ** 2;
    sum += 2 * R * Math.asin(Math.sqrt(a));
  }
  return sum;
}

function simplifyCoords(coords: unknown[]): number[][] {
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
  return out;
}

function inBbox(coords: number[][], bbox: number[]) {
  const [w, s, e, n] = bbox;
  for (const [lng, lat] of coords) {
    if (lng >= w && lng <= e && lat >= s && lat <= n) return true;
  }
  return false;
}

function tagsFromProps(props: Record<string, unknown> | null | undefined) {
  if (!props || typeof props !== "object") return {};
  const tags: Record<string, string | undefined> = {};
  for (const [k, v] of Object.entries(props)) {
    if (typeof v === "string") tags[k] = v;
  }
  if (props.tags && typeof props.tags === "object") {
    for (const [k, v] of Object.entries(props.tags as Record<string, unknown>)) {
      if (typeof v === "string") tags[k] = v;
    }
  }
  return tags;
}

async function* readFeatures(filePath: string) {
  const fd = fs.openSync(filePath, "r");
  const buf = Buffer.alloc(256);
  const n = fs.readSync(fd, buf, 0, 256, 0);
  fs.closeSync(fd);
  const first = buf.subarray(0, n).toString("utf8");
  if (first.trimStart().startsWith("{") && first.includes("FeatureCollection")) {
    const json = JSON.parse(fs.readFileSync(filePath, "utf8"));
    for (const f of json.features ?? []) yield f;
    return;
  }
  const rl = readline.createInterface({
    input: fs.createReadStream(filePath),
    crlfDelay: Infinity,
  });
  for await (const line of rl) {
    const t = line.replace(/^\u001e/, "").trim();
    if (!t) continue;
    try {
      const obj = JSON.parse(t);
      if (obj.type === "Feature") yield obj;
      else if (obj.type === "FeatureCollection") {
        for (const f of obj.features ?? []) yield f;
      }
    } catch {
      /* skip */
    }
  }
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.input || !args.outPath) {
    console.error("Need --in and --out");
    process.exit(1);
  }
  const sampleBbox = args.sampleBbox
    ? args.sampleBbox.split(",").map(Number)
    : null;

  const features: object[] = [];
  const sample: object[] = [];
  const counts: Record<string, number> = {
    mtb: 0,
    mtb_unrated: 0,
    gravel: 0,
    road: 0,
    urban: 0,
    hidden: 0,
    short: 0,
  };

  for await (const feat of readFeatures(args.input)) {
    if (!feat || feat.type !== "Feature") continue;
    const geom = feat.geometry;
    if (
      !geom ||
      (geom.type !== "LineString" && geom.type !== "MultiLineString")
    ) {
      continue;
    }
    const lines =
      geom.type === "LineString" ? [geom.coordinates] : geom.coordinates;
    const tags = tagsFromProps(feat.properties);
    const classified = classifyBikeWay(tags);
    if (classified.bikeClass === "hidden") {
      counts.hidden++;
      continue;
    }
    for (const rawLine of lines) {
      const coords = simplifyCoords(rawLine);
      if (coords.length < 2) continue;
      if (pathLengthM(coords) < 40) {
        counts.short++;
        continue;
      }
      const id =
        feat.properties?.["@id"] ??
        feat.properties?.id ??
        feat.id ??
        undefined;
      const outFeat = {
        type: "Feature",
        properties: {
          bike_class: classified.bikeClass,
          mtb_scale: classified.mtbScale ?? "",
          highway: feat.properties?.highway ?? "",
          name: feat.properties?.name || feat.properties?.["name:de"] || "",
          osm_id: id != null ? String(id) : "",
          surface: tags.surface || "",
        },
        geometry: { type: "LineString", coordinates: coords },
      };
      features.push(outFeat);
      counts[classified.bikeClass] = (counts[classified.bikeClass] ?? 0) + 1;
      if (sampleBbox && inBbox(coords, sampleBbox) && sample.length < 80) {
        sample.push(outFeat);
      }
    }
  }

  fs.mkdirSync(path.dirname(args.outPath), { recursive: true });
  fs.writeFileSync(
    args.outPath,
    JSON.stringify({ type: "FeatureCollection", features })
  );
  console.log(
    JSON.stringify(
      {
        features: features.length,
        bytes: fs.statSync(args.outPath).size,
        counts,
      },
      null,
      2
    )
  );

  if (args.sampleOut) {
    fs.mkdirSync(path.dirname(args.sampleOut), { recursive: true });
    fs.writeFileSync(
      args.sampleOut,
      JSON.stringify({ type: "FeatureCollection", features: sample })
    );
    console.log(
      `sample ${sample.length} features → ${args.sampleOut} (${fs.statSync(args.sampleOut).size} bytes)`
    );
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
