#!/usr/bin/env node
/**
 * Bulk upsert catalog into Supabase (G-4 path).
 * Usage:
 *   SUPABASE_SERVICE_ROLE_KEY=... node scripts/catalog-upsert-supabase.mjs [path/to.json]
 *
 * Also writes Completeness KPI to catalog_meta.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { createClient } from "@supabase/supabase-js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const inputPath =
  process.argv[2] || path.join(root, "data/catalog/extra-seed.json");

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error("Need NEXT_PUBLIC_SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY");
  process.exit(1);
}

const REQUIRED_BY_SLOT = {
  fork: ["travel_mm", "steerer", "wheel_size"],
  rear_shock: ["eye_to_eye_mm", "stroke_mm"],
  tire_front: ["etrto", "wheel_size"],
  tire_rear: ["etrto", "wheel_size"],
  brake_front: ["rotor_max_mm", "mount"],
  brake_rear: ["rotor_max_mm", "mount"],
};

function isComplete(slot, attrs) {
  const req = REQUIRED_BY_SLOT[slot];
  if (!req) return Boolean(attrs && Object.keys(attrs).length > 0);
  return req.every((k) => attrs?.[k] != null && attrs[k] !== "");
}

const raw = JSON.parse(fs.readFileSync(inputPath, "utf8"));
const components = raw.components || [];
const manufacturers = raw.manufacturers || [];

const sb = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const rows = components.map((c) => {
  const attributes = c.attributes || {};
  return {
    id: c.id,
    slot: c.slot,
    manufacturer: c.manufacturer,
    model: c.model,
    year: c.year ?? null,
    attributes,
    interface_complete: isComplete(c.slot, attributes),
    source: c.source || "import",
    updated_at: new Date().toISOString(),
  };
});

const bikeRows = [];
for (const m of manufacturers) {
  for (const b of m.bikes || []) {
    bikeRows.push({
      id: b.id,
      manufacturer_id: m.id,
      manufacturer_name: m.name,
      name: b.name,
      category: b.category,
      year: b.year ?? null,
      oem_components: b.oem_components || b.components || [],
      updated_at: new Date().toISOString(),
    });
  }
}

async function upsertChunks(table, data, chunkSize = 200) {
  for (let i = 0; i < data.length; i += chunkSize) {
    const chunk = data.slice(i, i + chunkSize);
    const { error } = await sb.from(table).upsert(chunk, { onConflict: "id" });
    if (error) throw new Error(`${table}: ${error.message}`);
    console.log(`${table}: upserted ${i + chunk.length}/${data.length}`);
  }
}

await upsertChunks("component_models", rows);
if (bikeRows.length) await upsertChunks("catalog_bikes", bikeRows);

const { count: modelCount } = await sb
  .from("component_models")
  .select("*", { count: "exact", head: true });
const { count: completeCount } = await sb
  .from("component_models")
  .select("*", { count: "exact", head: true })
  .eq("interface_complete", true);

const hash = `sha1:${Buffer.from(JSON.stringify(rows.map((r) => r.id).sort()))
  .toString("base64")
  .slice(0, 16)}`;

await sb.from("catalog_meta").upsert({
  id: 1,
  model_count: modelCount ?? rows.length,
  complete_count: completeCount ?? rows.filter((r) => r.interface_complete).length,
  catalog_hash: hash,
  updated_at: new Date().toISOString(),
});

const n = modelCount ?? rows.length;
console.log(
  JSON.stringify(
    {
      ok: true,
      model_count: n,
      complete_count: completeCount,
      g4_progress_pct: Math.round((n / 3000) * 1000) / 10,
      target: 3000,
    },
    null,
    2
  )
);
