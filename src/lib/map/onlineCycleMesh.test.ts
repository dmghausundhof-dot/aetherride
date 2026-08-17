/**
 * npx tsx src/lib/map/onlineCycleMesh.test.ts
 */
import assert from "node:assert/strict";
import { overlayHintFromRegistry, detailOverlayRegionIdForPoint } from "../coverage/dachRegions";
import {
  BIKE_WAYS_MIN_ZOOM,
  DETAIL_BIKE_OVERLAY_PACKS,
  DACH_WAYS_PMTILES_URL,
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
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("annecy"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("lyon"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("paris"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("amsterdam"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("utrecht"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("rotterdam"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("den-haag"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("strasbourg"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("bordeaux"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("nantes"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("toulouse"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("nice"));
assert.ok(DETAIL_BIKE_OVERLAY_PACKS.has("marseille"));
assert.equal(packHasDetailBikeOverlay("berlin"), false);
assert.equal(BIKE_WAYS_MIN_ZOOM, 10);

assert.equal(
  onlineCycleMeshPmtilesUrl(8.54, 47.37),
  ONLINE_CYCLE_MESH_PMTILES_URL
);
assert.equal(onlineCycleMeshPmtilesUrl(-30, 0), null);
assert.ok(
  onlineCycleMeshPmtilesUrl(2.35, 48.86)?.includes(
    "cycle-routes-france-west.pmtiles"
  )
);
assert.ok(
  !onlineCycleMeshPmtilesUrl(2.35, 48.86)?.endsWith("/cycle-routes.pmtiles"),
  "Paris must not stream the DACH mesh"
);
assert.ok(
  onlineCycleMeshPmtilesUrl(4.9, 52.37)?.includes("cycle-routes-benelux.pmtiles")
);
assert.ok(
  onlineCycleMeshPmtilesUrl(-0.13, 51.51)?.includes(
    "cycle-routes-uk-south.pmtiles"
  )
);
assert.ok(
  onlineCycleMeshPmtilesUrl(2.17, 41.39)?.includes(
    "cycle-routes-catalonia-pyrenees.pmtiles"
  )
);
assert.ok(
  onlineCycleMeshPmtilesUrl(12.33, 45.44)?.includes(
    "cycle-routes-italy-north.pmtiles"
  )
);
assert.ok(
  onlineCycleMeshPmtilesUrl(7.27, 43.7)?.includes(
    "cycle-routes-alps-south.pmtiles"
  )
);
assert.ok(
  onlineCycleMeshPmtilesUrl(12.5, 41.9)?.includes(
    "cycle-routes-italy-center.pmtiles"
  )
);
assert.ok(
  onlineCycleMeshPmtilesUrl(16.7, 40.2)?.includes(
    "cycle-routes-italy-south.pmtiles"
  )
);

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
assert.equal(berlinZ13.kind, "ways");
assert.equal(berlinZ13.url, DACH_WAYS_PMTILES_URL);

const berlinZ10 = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 13.405,
  lat: 52.52,
  zoom: 10,
});
assert.equal(berlinZ10.kind, "ways");
assert.equal(berlinZ10.url, DACH_WAYS_PMTILES_URL);

const berlinZ9 = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 13.405,
  lat: 52.52,
  zoom: 9,
});
assert.equal(berlinZ9.kind, "mesh");
assert.equal(berlinZ9.url, ONLINE_CYCLE_MESH_PMTILES_URL);

const wienZ13 = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 16.373,
  lat: 48.208,
  zoom: 13,
});
assert.equal(wienZ13.kind, "ways");
assert.equal(wienZ13.url, DACH_WAYS_PMTILES_URL);

const hamburgAtlas = chooseOnlineBikeOverlay({
  regionId: "hamburg",
  lng: 9.993,
  lat: 53.551,
  zoom: 8,
});
assert.equal(hamburgAtlas.kind, "mesh");
assert.equal(hamburgAtlas.url, ONLINE_CYCLE_MESH_PMTILES_URL);

const parisAtlas = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 2.35,
  lat: 48.86,
  zoom: 8,
});
assert.equal(parisAtlas.kind, "mesh");
assert.ok(parisAtlas.url?.includes("cycle-routes-france-west.pmtiles"));

const parisWays = chooseOnlineBikeOverlay({
  regionId: "paris",
  lng: 2.35,
  lat: 48.86,
  zoom: 13,
});
assert.equal(parisWays.kind, "ways");
assert.ok(parisWays.url?.includes("/paris/bike-overlay.pmtiles"));

const lyonWays = chooseOnlineBikeOverlay({
  regionId: "lyon",
  lng: 4.835,
  lat: 45.76,
  zoom: 13,
});
assert.equal(lyonWays.kind, "ways");
assert.ok(lyonWays.url?.includes("/lyon/bike-overlay.pmtiles"));

const annecyWays = chooseOnlineBikeOverlay({
  regionId: "annecy",
  lng: 6.13,
  lat: 45.9,
  zoom: 13,
});
assert.equal(annecyWays.kind, "ways");
assert.ok(annecyWays.url?.includes("/annecy/bike-overlay.pmtiles"));

const amsterdamAtlas = chooseOnlineBikeOverlay({
  regionId: null,
  lng: 4.9,
  lat: 52.37,
  zoom: 8,
});
assert.equal(amsterdamAtlas.kind, "mesh");
assert.ok(amsterdamAtlas.url?.includes("cycle-routes-benelux.pmtiles"));

const amsterdamWays = chooseOnlineBikeOverlay({
  regionId: "amsterdam",
  lng: 4.9,
  lat: 52.37,
  zoom: 13,
});
assert.equal(amsterdamWays.kind, "ways");
assert.ok(amsterdamWays.url?.includes("/amsterdam/bike-overlay.pmtiles"));

const denHaagWays = chooseOnlineBikeOverlay({
  regionId: detailOverlayRegionIdForPoint(4.3, 52.08),
  lng: 4.3,
  lat: 52.08,
  zoom: 12,
});
assert.equal(denHaagWays.kind, "ways");
assert.ok(denHaagWays.url?.includes("/den-haag/bike-overlay.pmtiles"));

const strasbourgWays = chooseOnlineBikeOverlay({
  regionId: "strasbourg",
  lng: 7.75,
  lat: 48.58,
  zoom: 13,
});
assert.equal(strasbourgWays.kind, "ways");
assert.ok(strasbourgWays.url?.includes("/strasbourg/bike-overlay.pmtiles"));

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
assert.equal(detailOverlayRegionIdForPoint(2.35, 48.86), "paris");
assert.equal(detailOverlayRegionIdForPoint(4.835, 45.76), "lyon");
assert.equal(detailOverlayRegionIdForPoint(6.13, 45.9), "annecy");
assert.equal(detailOverlayRegionIdForPoint(4.9, 52.37), "amsterdam");
assert.equal(detailOverlayRegionIdForPoint(4.3, 52.08), "den-haag");
assert.equal(detailOverlayRegionIdForPoint(7.75, 48.58), "strasbourg");

const freiburgWays = chooseOnlineBikeOverlay({
  regionId: detailOverlayRegionIdForPoint(7.85, 47.99),
  lng: 7.85,
  lat: 47.99,
  zoom: 13,
});
assert.equal(freiburgWays.kind, "ways");
assert.ok(freiburgWays.url?.includes("/schwarzwald-nord/bike-overlay.pmtiles"));

console.log("onlineCycleMesh.test.ts ok");
