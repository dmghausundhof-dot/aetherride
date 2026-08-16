/**
 * npx tsx src/lib/map/onlineBasemap.test.ts
 */
import assert from "node:assert/strict";
import {
  archiveIdFromStyleUrl,
  basemapArchiveIdForLngLat,
  envLocksOnlineBasemapStyle,
  isCdnOverviewBasemap,
  isOverviewOnlyBasemap,
  isStreetLevelBasemap,
  MAP_ATTRIBUTION,
  ONLINE_BASEMAP_ARCHIVES,
  ONLINE_BASEMAP_RIDER,
  onlineBasemapStyleUrl,
  riderBasemap,
} from "./onlineBasemap";

assert.equal(basemapArchiveIdForLngLat(8.54, 47.37), "dach-z11");
assert.equal(basemapArchiveIdForLngLat(2.35, 48.86), "france-west-z11");
assert.equal(basemapArchiveIdForLngLat(7.27, 43.7), "alps-south-z11");
assert.equal(basemapArchiveIdForLngLat(10.75, 45.58), "alps-south-z11");
assert.equal(basemapArchiveIdForLngLat(4.9, 52.37), "benelux-z11");
assert.equal(basemapArchiveIdForLngLat(12.33, 45.44), "italy-north-z11");
assert.equal(basemapArchiveIdForLngLat(12.5, 41.9), "italy-center-z11");
assert.equal(basemapArchiveIdForLngLat(14.27, 40.85), "italy-center-z11");
assert.equal(basemapArchiveIdForLngLat(16.87, 41.12), "italy-south-z11");
assert.equal(basemapArchiveIdForLngLat(2.17, 41.39), "catalonia-pyrenees-z11");
assert.equal(basemapArchiveIdForLngLat(-0.13, 51.51), "uk-south-z11");
assert.equal(
  onlineBasemapStyleUrl(4.9, 52.37).includes("benelux-z11-style.json"),
  true
);
assert.equal(
  onlineBasemapStyleUrl(7.27, 43.7).includes("alps-south-z11-style.json"),
  true
);
assert.equal(
  onlineBasemapStyleUrl(2.35, 48.86, onlineBasemapStyleUrl(8.54, 47.37)).includes(
    "france-west-z11-style.json"
  ),
  true
);
assert.equal(envLocksOnlineBasemapStyle(""), false);
assert.equal(envLocksOnlineBasemapStyle(undefined), false);
assert.equal(
  envLocksOnlineBasemapStyle(
    "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json"
  ),
  false
);
assert.equal(
  envLocksOnlineBasemapStyle("https://tiles.openfreemap.org/styles/liberty"),
  true
);
assert.equal(
  isCdnOverviewBasemap(
    "https://cdn.example/offline-packs/basemap/alps-south-z11-style.json"
  ),
  true
);
assert.equal(
  archiveIdFromStyleUrl(
    "file:///data/user/0/app/files/basemap/france-west-z11-style.json"
  ),
  "france-west-z11"
);
assert.equal(
  basemapArchiveIdForLngLat(4.83, 45.76, "france-west-z11"),
  "france-west-z11"
);

assert.equal(basemapArchiveIdForLngLat(14.44, 50.08), "dach-z11");
assert.equal(ONLINE_BASEMAP_ARCHIVES.length, 9);
for (const a of ONLINE_BASEMAP_ARCHIVES) {
  assert.equal(isOverviewOnlyBasemap(a.styleUrl), true, a.id);
  assert.equal(isStreetLevelBasemap(a.styleUrl), false, a.id);
}
assert.equal(
  isStreetLevelBasemap("https://tiles.openfreemap.org/styles/liberty"),
  true
);
assert.equal(ONLINE_BASEMAP_RIDER.length, 9);
assert.equal(ONLINE_BASEMAP_RIDER[0].name, "DACH");
assert.equal(ONLINE_BASEMAP_RIDER[1].name, "Frankreich");
assert.equal(ONLINE_BASEMAP_RIDER[8].name, "Südengland");
for (const r of ONLINE_BASEMAP_RIDER) {
  assert.equal(r.name.includes("z11"), false);
  assert.ok(r.teaser.length > 20);
  assert.ok(r.hole.length > 20);
}
assert.equal(riderBasemap("uk-south-z11").name, "Südengland");
assert.ok(MAP_ATTRIBUTION.includes("OpenStreetMap"));
assert.ok(MAP_ATTRIBUTION.includes("Protomaps"));

console.log("onlineBasemap.test.ts ok");
