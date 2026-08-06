#!/usr/bin/env node
/**
 * Overpass enrichment for MTB/DH tagging quality (S6).
 * Queries mtb:scale / mtb:scale:imba density in a bbox; writes report JSON.
 *
 * Usage:
 *   node scripts/overpass-mtb-enrichment.mjs [minLat] [minLon] [maxLat] [maxLon]
 * Default bbox: Black Forest sample.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

const [minLat, minLon, maxLat, maxLon] = [
  parseFloat(process.argv[2] || "47.7"),
  parseFloat(process.argv[3] || "7.5"),
  parseFloat(process.argv[4] || "48.2"),
  parseFloat(process.argv[5] || "8.3"),
];

const query = `
[out:json][timeout:60];
(
  way["highway"~"path|track|cycleway"](${minLat},${minLon},${maxLat},${maxLon});
);
out tags;
`;

const endpoints = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
];

async function fetchOverpass() {
  let lastErr;
  for (const ep of endpoints) {
    try {
      const res = await fetch(ep, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `data=${encodeURIComponent(query)}`,
      });
      if (!res.ok) throw new Error(`${ep} ${res.status}`);
      return res.json();
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr;
}

const data = await fetchOverpass();
const elements = data.elements || [];
let withScale = 0;
let withImba = 0;
let withSurface = 0;
const scaleHist = {};

for (const el of elements) {
  const t = el.tags || {};
  if (t["mtb:scale"] != null) {
    withScale++;
    scaleHist[t["mtb:scale"]] = (scaleHist[t["mtb:scale"]] || 0) + 1;
  }
  if (t["mtb:scale:imba"] != null) withImba++;
  if (t.surface) withSurface++;
}

const report = {
  generatedAt: new Date().toISOString(),
  bbox: { minLat, minLon, maxLat, maxLon },
  ways: elements.length,
  with_mtb_scale: withScale,
  with_mtb_scale_imba: withImba,
  with_surface: withSurface,
  mtb_scale_coverage_pct:
    elements.length === 0
      ? 0
      : Math.round((withScale / elements.length) * 1000) / 10,
  scale_histogram: scaleHist,
  note: "Use for catalog/routing quality; does not replace Valhalla graph.",
};

const outDir = path.join(root, "data/geo");
fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, "overpass-mtb-report.json");
fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
console.log("wrote", outPath);
