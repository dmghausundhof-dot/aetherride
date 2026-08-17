/**
 * Overlay ingest must copy OSM surface + tracktype onto tiles.
 * Run: npx tsx scripts/routing/classify-bike-overlay.test.ts
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), "../..");

function testDachIngestCopiesSurface() {
  const src = fs.readFileSync(
    path.join(ROOT, "scripts/routing/build-dach-ways-overlay.ts"),
    "utf8"
  );
  assert.match(src, /surface: tags\.surface \|\| ""/);
  assert.match(src, /tracktype: tags\.tracktype \|\| ""/);
}

function testClassifyWritesSurfaceAndTracktype() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "aether-overlay-"));
  const input = path.join(dir, "in.geojsonseq");
  const output = path.join(dir, "out.geojson");
  fs.writeFileSync(
    input,
    JSON.stringify({
      type: "Feature",
      properties: {
        "@id": "way/1",
        highway: "cycleway",
        surface: "asphalt",
        tracktype: "grade1",
        name: "Testweg",
      },
      geometry: {
        type: "LineString",
        coordinates: [
          [8.68, 49.41],
          [8.695, 49.41],
        ],
      },
    }) + "\n"
  );
  const r = spawnSync(
    "npx",
    [
      "tsx",
      path.join(ROOT, "scripts/routing/classify-bike-overlay.ts"),
      "--in",
      input,
      "--out",
      output,
    ],
    { cwd: ROOT, encoding: "utf8" }
  );
  assert.equal(r.status, 0, r.stderr || r.stdout);
  const json = JSON.parse(fs.readFileSync(output, "utf8"));
  const props = json.features[0].properties;
  assert.equal(props.surface, "asphalt");
  assert.equal(props.tracktype, "grade1");
  fs.rmSync(dir, { recursive: true, force: true });
}

testDachIngestCopiesSurface();
testClassifyWritesSurfaceAndTracktype();
console.log("classify-bike-overlay.test.ts OK");
