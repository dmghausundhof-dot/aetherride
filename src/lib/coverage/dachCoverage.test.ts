/**
 * DACH overlay completeness — named region for every probe city.
 * Run: npx tsx src/lib/coverage/dachCoverage.test.ts
 */
import assert from "node:assert/strict";
import { overlayRegionForPoint } from "./regions";
import {
  DACH_COMPLETENESS_PROBES,
  DACH_ENVELOPE_REGIONS,
  DACH_PACK_REGIONS,
  dachCoverageStats,
  dachRegionForPoint,
  overlayHintFromRegistry,
} from "./dachRegions";
import { pointInDach } from "./dach";

const stats = dachCoverageStats();
assert.equal(stats.missingProbes.length, 0, `unnamed probes: ${stats.missingProbes.join(",")}`);
assert.ok(stats.packs >= 17, `expected ≥17 packs, got ${stats.packs}`);
assert.ok(stats.envelopes >= 16, `expected DE/AT/CH envelopes, got ${stats.envelopes}`);
assert.equal(stats.probesNamed, stats.probesTotal);

assert.equal(overlayRegionForPoint(16.373, 48.208)?.id, "wien");
assert.equal(overlayRegionForPoint(11.575, 48.137)?.id, "muenchen");
assert.equal(overlayRegionForPoint(8.541, 47.376)?.id, "zuerich");
assert.equal(overlayRegionForPoint(9.993, 53.551)?.id, "hamburg");

const leipzig = overlayHintFromRegistry(12.37, 51.34);
assert.ok(leipzig.regionId, "Leipzig must be named");
assert.ok(
  leipzig.mode === "region_pack" || leipzig.mode === "dach_live",
  `Leipzig mode ${leipzig.mode}`
);

const graz = overlayHintFromRegistry(15.44, 47.07);
assert.ok(graz.regionId, "Graz must be named");

const genf = overlayHintFromRegistry(6.15, 46.2);
assert.ok(genf.regionId, "Genf must be named");

const ocean = overlayHintFromRegistry(-30, 0);
assert.equal(ocean.mode, "live_osm");
assert.equal(ocean.regionId, null);
assert.equal(ocean.pmtilesPath, null);

const heidelberg = overlayHintFromRegistry(8.68, 49.41);
assert.equal(heidelberg.mode, "region_pack");
assert.ok(
  heidelberg.pmtilesPath?.includes("/rhein-neckar/bike-overlay.pmtiles"),
  "detail overlay pack keeps way-level tiles"
);

const passau = overlayHintFromRegistry(13.43, 48.57);
assert.equal(passau.mode, "dach_live");
assert.ok(
  passau.pmtilesPath?.includes("/basemap/cycle-routes.pmtiles"),
  "DACH envelope uses signed cycle-route mesh"
);

const paris = overlayHintFromRegistry(2.35, 48.86);
assert.equal(paris.mode, "region_pack");
assert.ok(
  paris.pmtilesPath?.includes("/paris/bike-overlay.pmtiles"),
  "Paris pack streams ways, not the DACH mesh"
);

const amsterdam = overlayHintFromRegistry(4.9, 52.37);
assert.equal(amsterdam.mode, "region_pack");
assert.ok(
  amsterdam.pmtilesPath?.includes("/amsterdam/bike-overlay.pmtiles"),
  "Amsterdam pack streams ways over Benelux atlas mesh"
);

assert.equal(pointInDach(51.34, 12.37), true);

for (const p of DACH_COMPLETENESS_PROBES) {
  const hit = dachRegionForPoint(p.lng, p.lat);
  assert.ok(hit, `no region for ${p.id}`);
  assert.ok(pointInDach(p.lat, p.lng), `${p.id} should be in DACH`);
}

const ids = new Set(DACH_PACK_REGIONS.map((r) => r.id));
assert.ok(ids.has("berlin"));
assert.ok(ids.has("graz"));
assert.ok(ids.has("leipzig"));
assert.ok(ids.has("zermatt"));
assert.ok(ids.has("st-moritz"));
assert.ok(ids.has("davos"));
assert.ok(ids.has("villach"));
assert.equal(overlayRegionForPoint(7.75, 46.02)?.id, "zermatt");
assert.equal(overlayRegionForPoint(9.84, 46.49)?.id, "st-moritz");
assert.equal(overlayRegionForPoint(9.84, 46.8)?.id, "davos");
assert.equal(overlayRegionForPoint(13.85, 46.61)?.id, "villach");
assert.equal(overlayRegionForPoint(14.31, 46.62)?.id, "klagenfurt");
assert.ok(DACH_ENVELOPE_REGIONS.some((r) => r.id === "de-bayern"));
assert.ok(DACH_ENVELOPE_REGIONS.some((r) => r.id === "ch-tessin"));

console.log(
  `dachCoverage.test.ts OK — ${stats.packs} packs, ${stats.envelopes} envelopes, ${stats.probesNamed} probes`
);
