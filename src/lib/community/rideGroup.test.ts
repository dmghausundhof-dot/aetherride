/**
 * npx tsx src/lib/community/rideGroup.test.ts
 */
import assert from "node:assert/strict";
import {
  canAttachCourse,
  canJoinRideGroup,
  canJoinWithoutInviteToken,
  formatGroupWhen,
  generateJoinCode,
  groupListedOnExplore,
  isEventWindowOpen,
  keepLocalRideGroupAfterCloud,
  nextActiveMeeting,
  parseGroupListing,
  parseMeetingPoint,
  parseRideGroupWindow,
  pointInPrivacyZones,
  quantizeGroupCoord,
  resolvePresenceVisibility,
  RIDE_GROUP_JOIN_CODE_LEN,
} from "./rideGroup";

assert.equal(generateJoinCode(() => 0).length, RIDE_GROUP_JOIN_CODE_LEN);
assert.equal(generateJoinCode(() => 0), "AAAAAA");
assert.equal(groupListedOnExplore(), false);
assert.equal(parseGroupListing(undefined), "private");
assert.equal(parseGroupListing("public"), "public");
assert.equal(canJoinWithoutInviteToken("private"), false);
assert.equal(canJoinWithoutInviteToken("public"), true);

assert.equal(
  canAttachCourse({ id: "gpx-neckar", visibility: "private" }),
  false
);
assert.equal(
  canAttachCourse({ id: "gpx-neckar", visibility: "shared" }),
  true
);
assert.equal(
  canAttachCourse({
    id: "local-copy",
    catalogTourId: "idea-koenigstuhl",
    visibility: "private",
  }),
  true
);

assert.equal(
  isEventWindowOpen(
    "2026-08-15T09:10:00.000Z",
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  true
);
assert.equal(
  isEventWindowOpen(
    "2026-08-15T08:00:00.000Z",
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  false
);
assert.equal(
  isEventWindowOpen(
    "2026-08-15T09:10:00.000Z",
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "closed"
  ),
  false
);

assert.equal(
  canJoinRideGroup(
    "2026-08-15T08:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "scheduled"
  ),
  true
);
assert.equal(
  canJoinRideGroup(
    "2026-08-15T14:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  false
);

const win = parseRideGroupWindow({
  startsAt: "2026-08-16T08:00:00.000Z",
  durationHours: 3,
  now: new Date("2026-08-16T06:00:00.000Z"),
});
assert.ok(!("error" in win));
if (!("error" in win)) {
  assert.equal(win.durationHours, 3);
  assert.equal(win.status, "scheduled");
  assert.equal(win.end.toISOString(), "2026-08-16T11:00:00.000Z");
}
const silent = parseRideGroupWindow({
  now: new Date("2026-08-16T10:00:00.000Z"),
});
assert.ok(!("error" in silent));
if (!("error" in silent)) {
  assert.equal(silent.durationHours, 3);
  assert.equal(silent.status, "open");
}

assert.equal(
  formatGroupWhen(
    "2026-08-16T08:00:00.000Z",
    "2026-08-16T11:00:00.000Z",
    new Date("2026-08-14T10:00:00.000Z")
  ),
  "So 10:00 · 3 h"
);
assert.equal(
  formatGroupWhen(
    "2026-08-16T08:00:00.000Z",
    "2026-08-16T11:00:00.000Z",
    new Date("2026-08-16T12:00:00.000Z")
  ),
  "zu — So 10:00"
);
assert.equal(parseMeetingPoint("  Parkplatz Schwimmbad  "), "Parkplatz Schwimmbad");
assert.equal(parseMeetingPoint("   "), undefined);

const q = quantizeGroupCoord(49.4094, 8.6948);
assert.equal(q.lat, Math.round(49.4094 / 0.0005) * 0.0005);
assert.notEqual(q.lat, 49.4094);

assert.equal(
  pointInPrivacyZones(47.448, 12.148, [
    { lat: 47.448, lng: 12.148, radiusM: 200 },
  ]),
  true
);
assert.equal(
  pointInPrivacyZones(47.46, 12.16, [
    { lat: 47.448, lng: 12.148, radiusM: 200 },
  ]),
  false
);

const base = {
  isMember: true,
  livePinsAllowed: true,
  liveOptIn: true,
  inEventWindow: true,
  inPrivacyZone: false,
  hasFix: true,
  ageMs: 4_000,
};
assert.equal(resolvePresenceVisibility(base), "live");
assert.equal(
  resolvePresenceVisibility({ ...base, isMember: false }),
  "hidden_not_member"
);
assert.equal(
  resolvePresenceVisibility({ ...base, liveOptIn: false }),
  "hidden_opt_out"
);
assert.equal(
  resolvePresenceVisibility({ ...base, inEventWindow: false }),
  "hidden_window"
);
assert.equal(
  resolvePresenceVisibility({ ...base, inPrivacyZone: true }),
  "hidden_zone"
);
assert.equal(
  resolvePresenceVisibility({ ...base, ageMs: 120_000 }),
  "stale"
);
assert.equal(
  resolvePresenceVisibility({ ...base, ageMs: 400_000 }),
  "hidden_offline"
);
assert.equal(
  resolvePresenceVisibility({ ...base, hasFix: false, ageMs: null }),
  "hidden_offline"
);

assert.equal(
  keepLocalRideGroupAfterCloud({ onServer: false, selfIsHost: true }),
  true
);
assert.equal(
  keepLocalRideGroupAfterCloud({ onServer: false, selfIsHost: false }),
  false
);
assert.equal(
  keepLocalRideGroupAfterCloud({ onServer: true, selfIsHost: true }),
  false
);

const now = new Date("2026-08-17T12:00:00.000Z");
assert.equal(
  nextActiveMeeting(
    [
      {
        status: "closed" as const,
        startWindowStart: "2026-08-17T11:00:00.000Z",
        startWindowEnd: "2026-08-17T14:00:00.000Z",
        id: "closed",
      },
      {
        status: "open" as const,
        startWindowStart: "2026-08-17T08:00:00.000Z",
        startWindowEnd: "2026-08-17T11:00:00.000Z",
        id: "ended",
      },
      {
        status: "scheduled" as const,
        startWindowStart: "2026-08-17T18:00:00.000Z",
        startWindowEnd: "2026-08-17T21:00:00.000Z",
        id: "later",
      },
      {
        status: "open" as const,
        startWindowStart: "2026-08-17T13:00:00.000Z",
        startWindowEnd: "2026-08-17T16:00:00.000Z",
        id: "soon",
      },
    ],
    now,
  )?.id,
  "soon",
);

console.log("rideGroup policy ok");
