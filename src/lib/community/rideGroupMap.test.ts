/**
 * npx tsx src/lib/community/rideGroupMap.test.ts
 */
import assert from "node:assert/strict";
import { canShowMeetingOnExplore } from "./rideGroup";
import { groupMeetPinsOnExplore } from "./rideGroupMap";
import type { RideGroup } from "./types";

const now = new Date("2026-08-18T10:00:00.000Z");

function group(partial: Partial<RideGroup> & Pick<RideGroup, "id">): RideGroup {
  return {
    hostUserId: "host",
    savedRouteId: "tour-1",
    title: "Zoo",
    startWindowStart: "2026-08-18T08:00:00.000Z",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    joinCode: "ABCDEF",
    status: "open",
    livePinsAllowed: true,
    createdAt: "2026-08-18T08:00:00.000Z",
    visibility: "public",
    ...partial,
  };
}

assert.equal(
  canShowMeetingOnExplore({
    visibility: "public",
    status: "open",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: false,
    now,
  }),
  true
);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "private",
    status: "open",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: false,
    now,
  }),
  false
);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "private",
    status: "open",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: true,
    now,
  }),
  true
);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "public",
    status: "closed",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: true,
    now,
  }),
  false
);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "public",
    status: "open",
    startWindowEnd: "2026-08-18T09:00:00.000Z",
    isMember: false,
    now,
  }),
  false
);

const pins = groupMeetPinsOnExplore({
  groups: [
    group({
      id: "11111111-1111-1111-1111-111111111111",
      meetingPoint: "Parkplatz Zoo 49.4076, 8.6908",
    }),
    group({
      id: "22222222-2222-2222-2222-222222222222",
      visibility: "private",
      meetingPoint: "Heim 49.41, 8.70",
    }),
    group({
      id: "33333333-3333-3333-3333-333333333333",
      meetingPoint: "Nur Text ohne Koordinaten",
    }),
    group({
      id: "44444444-4444-4444-4444-444444444444",
      status: "closed",
      meetingPoint: "Zu 49.40, 8.69",
    }),
  ],
  memberGroupIds: [],
  now,
  centerFor: (g) =>
    g.id.startsWith("3333") ? { lat: 49.5, lng: 8.6 } : null,
});

assert.equal(pins.length, 2);
assert.equal(pins[0]?.placeId, "meet-11111111-1111-1111-1111-111111111111");
assert.equal(pins[0]?.lat, 49.4076);
assert.equal(pins[0]?.lng, 8.6908);
assert.equal(pins[0]?.label, "Parkplatz Zoo");
assert.equal(pins[1]?.lat, 49.5);
assert.equal(pins[1]?.label, "Nur Text ohne Koordinaten");

const ownPrivate = groupMeetPinsOnExplore({
  groups: [
    group({
      id: "22222222-2222-2222-2222-222222222222",
      visibility: "private",
      meetingPoint: "Heim 49.41, 8.70",
    }),
  ],
  memberGroupIds: ["22222222-2222-2222-2222-222222222222"],
  now,
});
assert.equal(ownPrivate.length, 1);
assert.equal(ownPrivate[0]?.label, "Heim");

console.log("rideGroupMap.test.ts OK");
