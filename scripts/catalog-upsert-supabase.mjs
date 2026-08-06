#!/usr/bin/env node
/**
 * Bulk upsert catalog into Supabase.
 * Prefer OEM seed (data/catalog/oem-seed.json) over synthetic bulk-seed.
 * Usage:
 *   SUPABASE_SERVICE_ROLE_KEY=... npm run catalog:upsert-oem
 *   SUPABASE_SERVICE_ROLE_KEY=... node scripts/catalog-upsert-supabase.mjs [path/to.json]
 *
 * Env REPLACE_SYNTHETIC=1 deletes rows with source synthetic_seed / bulk_seed first.
 * Also writes Completeness KPI to catalog_meta.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { createClient } from "@supabase/supabase-js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const inputPath =
  process.argv[2] || path.join(root, "data/catalog/oem-seed.json");

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error("Need NEXT_PUBLIC_SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY");
  process.exit(1);
}

const REQUIRED_BY_SLOT = {
  fork: [["travel_mm"], ["steerer_type", "steerer"], ["wheel_size"]],
  rear_shock: [["eye_to_eye_mm"], ["stroke_mm"]],
  tire_front: [["etrto"], ["wheel_size"]],
  tire_rear: [["etrto"], ["wheel_size"]],
  brake_front: [["max_rotor_mm", "rotor_max_mm"], ["brake_mount", "mount"]],
  brake_rear: [["max_rotor_mm", "rotor_max_mm"], ["brake_mount", "mount"]],
  frame: [["shock_eye_to_eye_mm"], ["shock_stroke_mm"], ["shock_mount_type"]],
};

function hasAny(attrs, keys) {
  return keys.some((k) => attrs?.[k] != null && attrs[k] !== "");
}

function isComplete(slot, attrs) {
  const req = REQUIRED_BY_SLOT[slot];
  if (!req) return Boolean(attrs && Object.keys(attrs).length > 0);
  return req.every((group) => hasAny(attrs, group));
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

if (process.env.REPLACE_SYNTHETIC === "1") {
  const { error: delErr, count } = await sb
    .from("component_models")
    .delete({ count: "exact" })
    .in("source", ["synthetic_seed", "bulk_seed", "g4_scale5"]);
  if (delErr) throw new Error(`delete synthetic: ${delErr.message}`);
  console.log(`deleted synthetic rows: ${count ?? "?"}`);
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

const hash = `oem:${Buffer.from(JSON.stringify(rows.map((r) => r.id).sort()))
  .toString("base64")
  .slice(0, 16)}`;

const complete =
  completeCount ?? rows.filter((r) => r.interface_complete).length;
const n = modelCount ?? rows.length;

await sb.from("catalog_meta").upsert({
  id: 1,
  model_count: n,
  complete_count: complete,
  catalog_hash: hash,
  updated_at: new Date().toISOString(),
});

console.log(
  JSON.stringify(
    {
      ok: true,
      model_count: n,
      complete_count: complete,
      oem_complete_pct: n ? Math.round((complete / n) * 1000) / 10 : 0,
      g4_quantity_note: "OEM-kuratiert; Spec-3000 nur mit echten Modellspecs",
      g4_progress_pct: Math.round((n / 3000) * 1000) / 10,
      target: 3000,
    },
    null,
    2
  )
);
