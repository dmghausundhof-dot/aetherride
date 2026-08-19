/**
 * npx tsx src/lib/community/groupMemberTour.test.ts
 */
import assert from "node:assert/strict";
import {
  importMemberTourFromInvite,
  tourShareForGroupInvite,
} from "./groupMemberTour";
import { decodeGroupInvite, encodeGroupInvite } from "./rideGroupInvite";
import type { RideGroup } from "./types";
import type { SavedRoute } from "@/types/route";

const route: SavedRoute = {
  id: "gpx-neckar",
  name: "Neckar",
  distanceKm: 12,
  elevationM: 80,
  durationMin: 40,
  savedAt: "2026-08-15T08:00:00.000Z",
  source: "import",
  geometry: {
    type: "LineString",
    coordinates: [
      [8.68, 49.4],
      [8.7, 49.41],
      [8.72, 49.42],
    ],
  },
};

const group: RideGroup = {
  id: "11111111-1111-1111-1111-111111111111",
  hostUserId: "host-1",
  savedRouteId: "gpx-neckar",
  title: "Neckar",
  startWindowStart: "2026-08-15T08:00:00.000Z",
  startWindowEnd: "2026-08-15T12:00:00.000Z",
  joinCode: "K7M2NP",
  status: "open",
  livePinsAllowed: true,
  createdAt: "2026-08-15T08:00:00.000Z",
  onServer: true,
  visibility: "private",
};

const tour = tourShareForGroupInvite({
  savedRouteId: group.savedRouteId,
  route,
});
assert.ok(tour);
assert.equal(tour.includeTrack, true);

const token = encodeGroupInvite(group, tour);
const payload = decodeGroupInvite(token);
assert.ok(payload?.tour);
const imported = importMemberTourFromInvite({ payload, existing: [] });
assert.equal(imported?.id, "gpx-neckar");
assert.ok((imported?.geometry?.coordinates.length ?? 0) >= 2);
assert.equal(
  importMemberTourFromInvite({ payload, existing: [route] }),
  null
);

assert.equal(
  tourShareForGroupInvite({
    savedRouteId: "r-bodensee-road",
    catalogTourId: "r-bodensee-road",
    route,
  }),
  undefined
);

console.log("groupMemberTour ok");
