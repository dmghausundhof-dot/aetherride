/**
 * Dump public catalog pins for OSRM prebake.
 *   npx tsx scripts/export-public-tours.ts
 */
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { listPublicTours } from "../src/lib/catalog/publicTours";

const out = join("data/catalog/public-tours-export.json");
mkdirSync(dirname(out), { recursive: true });
const tours = listPublicTours().map((t) => ({
  id: t.id,
  name: t.name,
  loop: t.loop,
  distanceKm: t.distanceKm,
  durationMin: t.durationMin,
  lng: t.center[0],
  lat: t.center[1],
  regionSlug: t.regionSlug,
}));
writeFileSync(out, `${JSON.stringify(tours, null, 2)}\n`);
console.log("wrote", out, tours.length);
