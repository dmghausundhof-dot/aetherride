/**
 * npx tsx src/lib/community/shareCodec.test.ts
 */
import assert from "node:assert/strict";
import {
  decodeSharePayload,
  decodeTourSharePayload,
  demoCollectionPayload,
  demoTourPayload,
  encodeSharePayload,
  encodeTourShareToken,
  isShareDemoToken,
} from "./shareCodec";
import type { SavedRoute } from "../../types/route";

const payload = {
  v: 1 as const,
  name: "Wochenende",
  routeIds: ["r-bodensee-road", "idea-kaiserstuhl-road"],
  routeNames: ["Bodensee", "Kaiserstuhl"],
  authorLabel: "Test",
  createdAt: "2026-08-11T00:00:00.000Z",
};

const token = encodeSharePayload(payload);
assert.ok(token.length > 10);
const back = decodeSharePayload(token);
assert.ok(back);
assert.equal(back!.name, "Wochenende");
assert.equal(back!.routeIds.length, 2);
assert.equal(decodeSharePayload("%%%"), null);

const gpx: SavedRoute = {
  id: "gpx-neckar",
  name: "Neckar",
  distanceKm: 22,
  elevationM: 180,
  durationMin: 80,
  savedAt: "2026-08-15T00:00:00.000Z",
  source: "import",
  geometry: {
    type: "LineString",
    coordinates: [
      [8.67, 49.4],
      [8.68, 49.41],
      [8.69, 49.42],
    ],
  },
};
const tourTok = encodeTourShareToken(gpx, "Test");
assert.equal(tourTok.includeTrack, true);
const tour = decodeTourSharePayload(tourTok.token);
assert.ok(tour);
assert.equal(tour!.kind, "tour");
assert.equal(tour!.id, "gpx-neckar");
assert.equal(tour!.includeTrack, true);
assert.equal(tour!.track?.length, 3);
assert.equal(decodeTourSharePayload(token), null);

assert.equal(isShareDemoToken("demo"), true);
assert.equal(isShareDemoToken("DEMO"), true);
const demoC = demoCollectionPayload();
assert.ok(demoC.routeIds.length >= 3);
assert.ok(demoC.routeIds.every((id) => id.startsWith("r-")));
const demoT = demoTourPayload();
assert.equal(demoT.kind, "tour");
assert.equal(demoT.includeTrack, false);
assert.ok(demoT.id);

console.log("shareCodec.test.ts OK");
