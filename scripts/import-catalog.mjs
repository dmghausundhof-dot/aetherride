#!/usr/bin/env node
/**
 * Catalog import pipeline (Gate G-4 path).
 * Usage: node scripts/import-catalog.mjs [path/to.json]
 * Writes src/lib/catalog/imported.json for runtime merge.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const inputPath =
  process.argv[2] || path.join(root, "data/catalog/extra-seed.json");
const outPath = path.join(root, "src/lib/catalog/imported.json");

function fail(msg) {
  console.error("import-catalog:", msg);
  process.exit(1);
}

if (!fs.existsSync(inputPath)) fail(`missing ${inputPath}`);

const raw = JSON.parse(fs.readFileSync(inputPath, "utf8"));
const manufacturers = raw.manufacturers || [];
const components = raw.components || [];

if (!Array.isArray(manufacturers) || manufacturers.length === 0) {
  fail("manufacturers[] required");
}

const bikeIds = new Set();
const mfrIds = new Set();
for (const m of manufacturers) {
  if (!m.id || !m.name || !Array.isArray(m.bikes)) {
    fail(`invalid manufacturer ${JSON.stringify(m?.id)}`);
  }
  if (mfrIds.has(m.id)) fail(`duplicate manufacturer ${m.id}`);
  mfrIds.add(m.id);
  for (const b of m.bikes) {
    if (!b.id || !b.name || !b.category) fail(`invalid bike under ${m.id}`);
    if (bikeIds.has(b.id)) fail(`duplicate bike ${b.id}`);
    bikeIds.add(b.id);
  }
}

const compIds = new Set();
for (const c of components) {
  if (!c.id || !c.slot || !c.manufacturer || !c.model) {
    fail(`invalid component ${JSON.stringify(c?.id)}`);
  }
  if (compIds.has(c.id)) fail(`duplicate component ${c.id}`);
  compIds.add(c.id);
}

const payload = {
  importedAt: new Date().toISOString(),
  source: path.relative(root, inputPath),
  manufacturers,
  components,
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(payload, null, 2) + "\n");

console.log(
  `OK → ${path.relative(root, outPath)} · ${manufacturers.length} manufacturers · ${bikeIds.size} bikes · ${compIds.size} components`
);
