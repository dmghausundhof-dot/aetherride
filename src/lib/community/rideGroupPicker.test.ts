/**
 * npx tsx src/lib/community/rideGroupPicker.test.ts
 */
import assert from "node:assert/strict";
import type { SavedRoute } from "@/types/route";
import {
  RIDE_GROUP_PICKER_NEARBY_KM,
  RIDE_GROUP_PICKER_NEARBY_MAX,
  catalogTourAsSaved,
  listMineForGroupCreate,
  listNearbyCatalogForGroupCreate,
  resolveGroupPickerOrigin,
  savedIdsForGroupPicker,
} from "./rideGroupPicker";

function stub(id: string, extra: Partial<SavedRoute> = {}): SavedRoute {
  return {
    id,
    name: id,
    distanceKm: 10,
    elevationM: 100,
    durationMin: 40,
    savedAt: extra.savedAt ?? "2026-08-01T00:00:00.000Z",
    source: "import",
    ...extra,
  };
}

const mine = listMineForGroupCreate([
  stub("gpx-neckar", { visibility: "private", name: "Privat" }),
  stub("freeride", { name: "Zusammen" }),
  stub("r-bodensee-road", {
    catalogTourId: "r-bodensee-road",
    savedAt: "2026-08-02T00:00:00.000Z",
  }),
]);
assert.equal(mine.length, 2, "private + catalog, no freeride");
assert.equal(mine[0].id, "r-bodensee-road", "newest first");
assert.equal(mine[1].id, "gpx-neckar");

const hd = { lat: 49.41, lng: 8.705 };
const nearby = listNearbyCatalogForGroupCreate({
  origin: hd,
  excludeIds: [],
});
assert.ok(
  nearby.length > 2,
  `Heidelberg picker should list more than 2 nearby, got ${nearby.length}`
);
assert.ok(nearby.length <= RIDE_GROUP_PICKER_NEARBY_MAX);
assert.ok(
  nearby.every((t) => t.distanceFromOriginKm <= RIDE_GROUP_PICKER_NEARBY_KM)
);

const excluded = listNearbyCatalogForGroupCreate({
  origin: hd,
  excludeIds: savedIdsForGroupPicker([
    stub("local-hd", { catalogTourId: "r-heidelberg-city" }),
  ]),
});
assert.ok(
  !excluded.some((t) => t.id === "r-heidelberg-city"),
  "already saved catalog id stays out of nearby"
);

assert.equal(listNearbyCatalogForGroupCreate({ origin: null, excludeIds: [] }).length, 0);

const asSaved = catalogTourAsSaved(nearby[0]);
assert.equal(asSaved.catalogTourId, nearby[0].id);
assert.notEqual(asSaved.visibility, "shared");

const withTrack = stub("gpx-neckar", {
  geometry: { type: "LineString", coordinates: [[8.68, 49.4], [8.7, 49.41]] },
});
assert.equal(
  resolveGroupPickerOrigin({
    gps: { lat: 49.5, lng: 8.5 },
    map: { lat: 48.1, lng: 11.5 },
    saved: [withTrack],
  })?.kind,
  "gps"
);
assert.equal(
  resolveGroupPickerOrigin({
    map: { lat: 48.1, lng: 11.5 },
    saved: [withTrack],
  })?.kind,
  "map"
);
assert.equal(resolveGroupPickerOrigin({ saved: [withTrack] })?.kind, "saved");
assert.equal(resolveGroupPickerOrigin({ saved: [stub("no-geo")] }), null);

console.log("rideGroupPicker ok");
