/**
 * npx tsx src/lib/community/placesMerger.test.ts
 */
import assert from "node:assert/strict";
import {
  isMissingMapPlacesTable,
  mergeCommunityPlaces,
  normalizePlaceKind,
  parseMeetingLatLng,
} from "./placesMerger";

assert.equal(normalizePlaceKind("bike_shop"), "shop");
assert.equal(normalizePlaceKind("POI"), "other");
assert.equal(isMissingMapPlacesTable({ code: "42P01" }), true);
assert.equal(isMissingMapPlacesTable({ message: "relation map_places does not exist" }), true);

const empty = mergeCommunityPlaces({});
assert.equal(empty.places.length, 0);
assert.ok(empty.honesty.includes("Keine Orte"));

const merged = mergeCommunityPlaces({
  coverage: [
    {
      id: "g1",
      name: "Café am Feld",
      kind: "cafe",
      lat: 49.41,
      lng: 8.67,
      source: "coverage",
    },
  ],
  mapPlaces: [
    {
      id: "g1-dup",
      name: "Café am Feld",
      kind: "cafe",
      lat: 49.41,
      lng: 8.67,
      source: "map_places",
    },
    {
      id: "u1",
      name: "Quelle",
      kind: "water",
      lat: 49.42,
      lng: 8.68,
      source: "map_places",
    },
  ],
  stimmePins: [
    {
      id: "s1",
      name: "nass",
      kind: "tip",
      lat: 49.415,
      lng: 8.675,
      source: "stimme",
      tourId: "seed-1",
    },
  ],
  meet: {
    id: "meet-1",
    name: "Parkplatz",
    kind: "meet",
    lat: 49.4,
    lng: 8.66,
    source: "meet",
  },
});
assert.equal(merged.places.length, 4);
assert.equal(merged.places[0].source, "coverage");
assert.ok(merged.honesty.includes("4"));

const coord = parseMeetingLatLng("Parkplatz Zoo 49.4076, 8.6908");
assert.equal(coord?.lat, 49.4076);
assert.equal(coord?.lng, 8.6908);
assert.equal(coord?.label, "Parkplatz Zoo");
assert.equal(parseMeetingLatLng("Parkplatz Zoo"), null);

console.log("placesMerger.test.ts OK");
