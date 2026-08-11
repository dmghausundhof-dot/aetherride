#!/usr/bin/env node
/**
 * Smoke: public tour catalog + sample geometry.
 * Usage: node scripts/smoke-tours-catalog.mjs [baseUrl]
 */
const base = (process.argv[2] || "https://aetherride.vercel.app").replace(
  /\/$/,
  ""
);

let failed = 0;
function ok(msg, extra) {
  console.log(`OK  ${msg}`, extra ?? "");
}
function fail(msg, extra) {
  failed++;
  console.error(`FAIL ${msg}`, extra ?? "");
}

const cat = await fetch(`${base}/api/tours/catalog`);
const catJ = await cat.json().catch(() => ({}));
if (!cat.ok || !Array.isArray(catJ.tours)) {
  fail("catalog", cat.status);
} else {
  ok("catalog", { count: catJ.count ?? catJ.tours.length });
  if ((catJ.count ?? catJ.tours.length) < 30) {
    fail("catalog density", `only ${catJ.count} tours (want ≥30)`);
  }
}

for (const sport of ["road", "urban", "gravel", "mtb", "ebike"]) {
  const r = await fetch(`${base}/api/tours/catalog?sport=${sport}`);
  const j = await r.json().catch(() => ({}));
  const n = j.tours?.length ?? 0;
  if (!r.ok || n < 1) fail(`catalog sport=${sport}`, n);
  else ok(`catalog sport=${sport}`, n);
}

// Sample geometry for a few known IDs
const sampleIds = [
  "r-heidelberg-city",
  "r-heidelberg-road",
  "r-mannheim-urban",
  "r-freiburg-road",
  "r-muenchen-urban",
];
for (const id of sampleIds) {
  const r = await fetch(
    `${base}/api/tours/geometry?id=${encodeURIComponent(id)}`
  );
  const j = await r.json().catch(() => ({}));
  const pts = j.geometry?.coordinates?.length ?? 0;
  if (!r.ok || pts < 2) fail(`geometry ${id}`, r.status);
  else ok(`geometry ${id}`, { pts, engine: j.engine });
}

console.log(failed ? `\nSMOKE TOURS FAIL ${failed}` : "\nSMOKE TOURS OK");
process.exit(failed ? 1 : 0);
