/**
 * npx tsx src/lib/map/onlineCycleMesh.test.ts
 */
import assert from "node:assert/strict";
import { overlayHintFromRegistry } from "../coverage/dachRegions";
import {
  DETAIL_BIKE_OVERLAY_PACKS,
  ONLINE_CYCLE_MESH_PMTILES_URL,
  onlineCycleMeshPmtilesUrl,
  overlayHref,
  packHasDetailBikeOverlay,
} from "./onlineCycleMesh";

assert.equal(packHasDetailBikeOverlay("rhein-neckar"), true);
assert.equal(packHasDetailBikeOverlay("berlin"), false);
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("innsbruck"));

assert.equal(
  onlineCycleMeshPmtilesUrl(8.54, 47.37),
  ONLINE_CYCLE_MESH_PMTILES_URL
);
assert.equal(onlineCycleMeshPmtilesUrl(-30, 0), null);
assert.equal(onlineCycleMeshPmtilesUrl(2.35, 48.86), null);

assert.equal(
  overlayHref("https://cdn.example/cycle-routes.pmtiles", "https://app.example"),
  "https://cdn.example/cycle-routes.pmtiles"
);
assert.equal(
  overlayHref("/api/offline/packs/vosges/bike-overlay.pmtiles", "https://app.example"),
  "https://app.example/api/offline/packs/vosges/bike-overlay.pmtiles"
);

const berlin = overlayHintFromRegistry(13.405, 52.52);
assert.equal(berlin.mode, "region_pack");
assert.equal(berlin.pmtilesPath, ONLINE_CYCLE_MESH_PMTILES_URL);

const zermatt = overlayHintFromRegistry(7.75, 46.02);
assert.ok(zermatt.pmtilesPath?.includes("/api/offline/packs/zermatt/"));

console.log("onlineCycleMesh.test.ts ok");
