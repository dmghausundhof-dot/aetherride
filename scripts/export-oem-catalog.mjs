#!/usr/bin/env node
/**
 * Export curated OEM ComponentModel[] + bikes → data/catalog/oem-seed.json
 * for catalog-upsert-supabase.mjs (replaces synthetic bulk-seed).
 *
 * Usage: npx tsx scripts/export-oem-catalog.ts
 * (This .mjs is a thin wrapper; logic lives in the .ts companion.)
 */
import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ts = path.join(__dirname, "export-oem-catalog.ts");
const r = spawnSync("npx", ["tsx", ts], { stdio: "inherit", shell: true });
process.exit(r.status ?? 1);
