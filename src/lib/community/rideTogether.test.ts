/**
 * npx tsx src/lib/community/rideTogether.test.ts
 */
import assert from "node:assert/strict";
import { canShowMeetingOnExplore } from "./rideGroup";
import {
  canAddSessionMember,
  canJoinSessionByCode,
  isFreerideRide,
  isSessionRouteId,
  nearbyFromLooks,
  pickRequestSession,
  sessionClosesAfterLeave,
  stopLookClosesSession,
  stopLookClosesSoloSession,
  sessionListedPublicly,
  listedPlannedGroups,
  matePair,
  pickGroupForRide,
  plannedMeetingOnly,
  sanitizeTogetherLabel,
  togetherBucket,
  RIDE_TOGETHER_ROUTE_ID,
} from "./rideTogether";

assert.equal(isSessionRouteId(RIDE_TOGETHER_ROUTE_ID), true);
assert.equal(isSessionRouteId("tour"), false);
assert.equal(isFreerideRide(null), true);
assert.equal(isFreerideRide("engine-1"), false);
assert.equal(canJoinSessionByCode("freeride"), true);
assert.equal(canJoinSessionByCode("tour"), false);
assert.equal(canAddSessionMember(19), true);
assert.equal(canAddSessionMember(20), false);
assert.equal(sessionClosesAfterLeave(1), false);
assert.equal(sessionClosesAfterLeave(0), true);
assert.equal(stopLookClosesSession(), false);
assert.equal(stopLookClosesSoloSession(), true);
assert.equal(sessionListedPublicly(), false);
assert.equal(pickRequestSession(1, 1), "from");
assert.equal(pickRequestSession(8, 1), "from");
assert.equal(pickRequestSession(1, 8), "to");
assert.equal(pickRequestSession(5, 12), "none");
assert.equal(pickRequestSession(20, 1), "from");

assert.deepEqual(
  nearbyFromLooks({
    selfLat: 49.4094,
    selfLng: 8.6948,
    selfId: "me",
    looks: [
      { user_id: "seeker", lat: 49.4094, lng: 8.6948, display_label: "Sam" },
      { user_id: "mate", lat: 49.4094, lng: 8.6948, display_label: "Hidden" },
      { user_id: "me", lat: 49.4094, lng: 8.6948, display_label: "Self" },
    ],
    labels: new Map(),
    excludeUserIds: ["mate"],
  }),
  [{ userId: "seeker", label: "Sam", bucket: "beside" }]
);

assert.equal(sanitizeTogetherLabel("  Luka   Flow  "), "Luka Flow");
assert.equal(sanitizeTogetherLabel("x".repeat(40)).length, 24);

assert.deepEqual(matePair("b", "a"), { lo: "a", hi: "b" });
assert.equal(matePair("a", "a"), null);

assert.equal(
  togetherBucket(49.4094, 8.6948, 49.4094, 8.6948),
  "beside"
);
assert.equal(
  togetherBucket(49.4094, 8.6948, 49.5, 8.8),
  null
);

const session = {
  id: "s1",
  savedRouteId: "freeride",
  createdAt: "2026-08-19T10:00:00.000Z",
  onServer: true,
};
const planned = {
  id: "p1",
  savedRouteId: "r-bodensee-road",
  catalogTourId: "r-bodensee-road",
  createdAt: "2026-08-19T09:00:00.000Z",
  onServer: true,
};

assert.equal(
  pickGroupForRide({
    rideRouteId: null,
    groups: [session, planned],
    memberCounts: { s1: 1, p1: 2 },
    idOf: (g) => g.id,
  }),
  null
);
assert.equal(
  pickGroupForRide({
    rideRouteId: null,
    groups: [session, planned],
    memberCounts: { s1: 2, p1: 2 },
    idOf: (g) => g.id,
  })?.id,
  "s1"
);
assert.equal(
  pickGroupForRide({
    rideRouteId: null,
    groups: [session],
    memberCounts: { s1: 20 },
    idOf: (g) => g.id,
  })?.id,
  "s1"
);
assert.equal(
  pickGroupForRide({
    rideRouteId: "r-bodensee-road",
    groups: [session, planned],
    memberCounts: { s1: 2, p1: 2 },
    idOf: (g) => g.id,
  })?.id,
  "p1"
);
assert.equal(
  pickGroupForRide({
    rideRouteId: "saved-hd",
    catalogTourId: "r-bodensee-road",
    groups: [session, planned],
    memberCounts: { s1: 2, p1: 2 },
    idOf: (g) => g.id,
  })?.id,
  "p1"
);
assert.equal(
  pickGroupForRide({
    rideRouteId: "r-other-city",
    groups: [session, planned],
    memberCounts: { s1: 2, p1: 2 },
    idOf: (g) => g.id,
  }),
  null
);

assert.deepEqual(
  listedPlannedGroups([session, planned]).map((g) => g.id),
  ["p1"]
);
assert.equal(
  plannedMeetingOnly(
    [
      {
        status: "open",
        startWindowStart: "2026-08-19T08:00:00.000Z",
        startWindowEnd: "2026-08-19T16:00:00.000Z",
        savedRouteId: "freeride",
      },
    ],
    new Date("2026-08-19T10:00:00.000Z")
  ),
  null
);

assert.equal(
  canShowMeetingOnExplore({
    visibility: "public",
    status: "open",
    startWindowEnd: "2026-08-19T16:00:00.000Z",
    isMember: false,
    now: new Date("2026-08-19T10:00:00.000Z"),
    savedRouteId: "freeride",
  }),
  false
);

console.log("rideTogether.test.ts ok");
