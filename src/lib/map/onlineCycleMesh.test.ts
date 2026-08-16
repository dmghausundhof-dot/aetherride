/**
 * npx tsx src/lib/map/onlineCycleMesh.test.ts
 */
import assert from "node:assert/strict";
import { overlayHintFromRegistry, detailOverlayRegionIdForPoint } from "../coverage/dachRegions";
import {
  BIKE_WAYS_MIN_ZOOM,
  DETAIL_BIKE_OVERLAY_PACKS,
  ONLINE_CYCLE_MESH_PMTILES_URL,
  ONLINE_PACK_CDN_ROOT,
  chooseOnlineBikeOverlay,
  detailBikeOverlayPmtilesUrl,
  onlineCycleMeshPmtilesUrl,
  overlayHref,
  packHasDetailBikeOverlay,
} from "./onlineCycleMesh";

assert.equal(packHasDetailBikeOverlay("rhein-neckar"), true);
assert.equal(packHasDetailBikeOverlay("berlin"), false);
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("innsbruck"));
assert.equal(BIKE_WAYS_MIN_ZOOM, 12);

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

const zermattHint = overlayHintFromRegistry(7.75, 46.02);
assert.ok(
  zermattHint.pmtilesPath?.includes("/zermatt/bike-overlay.pmtiles"),
  "detail pack streams CDN ways tiles"
);

const rnUrl = detailBikeOverlayPmtilesUrl("rhein-neckar");
assert.ok(rnUrl?.startsWith(ONLINE_PACK_CDN_ROOT));
assert.ok(rnUrl?.endsWith("/rhein-neckar/bike-overlay.pmtiles"));
assert.equal(detailBikeOverlayPmtilesUrl("berlin"), null);

const hdMesh = chooseOnlineBikeOverlay({
  regionId: "rhein-neckar",
  lng: 8.68,
  lat: 49.41,
  zoom: 8,
});
assert.equal(hdMesh.kind, "mesh");
assert.equal(hdMesh.url, ONLINE_CYCLE_MESH_PMTILES_URL);

const hdWays = chooseOnlineBikeOverlay({
  regionId: "rhein-neckar",
  lng: 8.68,
  lat: 49.41,
  zoom: 13,
});
assert.equal(hdWays.kind, "ways");
assert.ok(hdWays.url?.includes("/rhein-neckar/bike-overlay.pmtiles"));

const berlinZ13 = chooseOnlineBikeOverlay({
  regionId: "berlin",
  lng: 13.405,
  lat: 52.52,
  zoom: 13,
});
assert.equal(berlinZ13.kind, "mesh");
assert.equal(berlinZ13.url, ONLINE_CYCLE_MESH_PMTILES_URL);

const paris = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 2.35,
  lat: 48.86,
  zoom: 13,
});
assert.equal(paris.kind, "none");
assert.equal(paris.url, null);

const zermattWays = chooseOnlineBikeOverlay({
  regionId: "zermatt",
  lng: 7.75,
  lat: 46.02,
  zoom: 13,
});
assert.equal(zermattWays.kind, "ways");
assert.ok(zermattWays.url?.includes("/zermatt/bike-overlay.pmtiles"));

assert.equal(detailOverlayRegionIdForPoint(8.68, 49.41), "rhein-neckar");
assert.equal(detailOverlayRegionIdForPoint(7.85, 47.99), "schwarzwald-nord");
assert.equal(detailOverlayRegionIdForPoint(13.405, 52.52), null);

const freiburgWays = chooseOnlineBikeOverlay({
  regionId: detailOverlayRegionIdForPoint(7.85, 47.99),
  lng: 7.85,
  lat: 47.99,
  zoom: 13,
});
assert.equal(freiburgWays.kind, "ways");
assert.ok(freiburgWays.url?.includes("/schwarzwald-nord/bike-overlay.pmtiles"));

console.log("onlineCycleMesh.test.ts ok");
