/**
 * npx tsx src/lib/community/rideGroup.test.ts
 */
import assert from "node:assert/strict";
import {
  canAttachCourse,
  needsMemberTrack,
  canJoinRideGroup,
  canJoinByTypedCode,
  canJoinWithoutInviteToken,
  isTypedJoinCode,
  formatGroupWhen,
  formatRideGroupDurationHours,
  listedPublicJoinGroups,
  generateJoinCode,
  normalizeJoinCode,
  canShowMeetingOnExplore,
  extendRideGroupWindowEnd,
  friendRosterName,
  friendUnnamedNumbers,
  groupListedOnExplore,
  isEventWindowOpen,
  isRideGroupExtendBody,
  keepLocalRideGroupAfterCloud,
  nextActiveMeeting,
  parseGroupListing,
  parseMeetingPoint,
  parseRideGroupExtend,
  platzGroupPrimaryIsInvite,
  parseRideGroupWindow,
  pointInPrivacyZones,
  quantizeGroupCoord,
  resolvePresenceVisibility,
  RIDE_GROUP_JOIN_CODE_LEN,
} from "./rideGroup";

assert.equal(generateJoinCode(() => 0).length, RIDE_GROUP_JOIN_CODE_LEN);
assert.equal(generateJoinCode(() => 0), "AAAAAA");
assert.equal(normalizeJoinCode(" ab-c2 d3 "), "ABC2D3");
assert.equal(normalizeJoinCode("k7m2np"), "K7M2NP");
assert.equal(normalizeJoinCode("IO01AB"), "AB");
assert.equal(groupListedOnExplore(), false);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "public",
    status: "open",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: false,
    now: new Date("2026-08-18T10:00:00.000Z"),
  }),
  true
);
assert.equal(
  canShowMeetingOnExplore({
    visibility: "private",
    status: "open",
    startWindowEnd: "2026-08-18T16:00:00.000Z",
    isMember: false,
    now: new Date("2026-08-18T10:00:00.000Z"),
  }),
  false
);
assert.equal(parseGroupListing(undefined), "private");
assert.equal(parseGroupListing("public"), "public");
assert.equal(canJoinWithoutInviteToken("private"), false);
assert.equal(canJoinWithoutInviteToken("public"), true);
assert.equal(canJoinByTypedCode("private"), false);
assert.equal(canJoinByTypedCode("public"), true);
assert.equal(isTypedJoinCode("k7-m2 np"), true);
assert.equal(isTypedJoinCode("AB"), false);

assert.equal(
  canAttachCourse({ id: "gpx-neckar", visibility: "private" }),
  true
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
assert.equal(canAttachCourse({ id: "freeride" }), false);
assert.equal(canAttachCourse({ id: "" }), false);
assert.equal(needsMemberTrack({ savedRouteId: "gpx-neckar" }), true);
assert.equal(
  needsMemberTrack({
    savedRouteId: "saved-abc",
    catalogTourId: "r-heidelberg-city",
  }),
  false
);
assert.equal(needsMemberTrack({ savedRouteId: "r-bodensee-road" }), false);
assert.equal(needsMemberTrack({ savedRouteId: "freeride" }), false);

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
assert.equal(
  isEventWindowOpen(
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  true,
  "Fenster genau am Start ist offen"
);
assert.equal(
  isEventWindowOpen(
    "2026-08-15T13:00:00.000Z",
    "2026-08-15T09:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  true,
  "Fenster genau am Ende ist noch offen"
);
assert.equal(
  canJoinRideGroup(
    "2026-08-15T13:00:00.000Z",
    "2026-08-15T13:00:00.000Z",
    "open"
  ),
  true
);
assert.equal(formatRideGroupDurationHours(0.25, ","), "15 Min");
assert.equal(formatRideGroupDurationHours(1.25, ","), "1,25 h");
assert.equal(formatRideGroupDurationHours(0.5, ","), "30 Min");
assert.equal(
  listedPublicJoinGroups(
    [
      {
        id: "closed",
        status: "closed" as const,
        startWindowEnd: "2026-08-19T18:00:00.000Z",
      },
      {
        id: "ended",
        status: "open" as const,
        startWindowEnd: "2026-08-19T10:00:00.000Z",
      },
      {
        id: "mine",
        status: "open" as const,
        startWindowEnd: "2026-08-19T18:00:00.000Z",
      },
      {
        id: "live",
        status: "open" as const,
        startWindowEnd: "2026-08-19T18:00:00.000Z",
      },
    ],
    ["mine"],
    new Date("2026-08-19T12:00:00.000Z"),
  ).map((g) => g.id).join(","),
  "live",
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
const half = parseRideGroupWindow({
  startsAt: "2026-08-16T08:00:00.000Z",
  durationHours: 1.5,
  now: new Date("2026-08-16T06:00:00.000Z"),
});
assert.ok(!("error" in half));
if (!("error" in half)) {
  assert.equal(half.durationHours, 1.5);
  assert.equal(half.end.toISOString(), "2026-08-16T09:30:00.000Z");
}
const five = parseRideGroupWindow({
  startsAt: "2026-08-16T08:00:00.000Z",
  durationHours: 5,
  now: new Date("2026-08-16T06:00:00.000Z"),
});
assert.ok(!("error" in five));
if (!("error" in five)) {
  assert.equal(five.durationHours, 5);
  assert.equal(five.end.toISOString(), "2026-08-16T13:00:00.000Z");
}
const byEnd = parseRideGroupWindow({
  startsAt: "2026-08-16T08:00:00.000Z",
  endsAt: "2026-08-16T09:15:00.000Z",
  now: new Date("2026-08-16T06:00:00.000Z"),
});
assert.ok(!("error" in byEnd));
if (!("error" in byEnd)) {
  assert.equal(byEnd.durationHours, 1.25);
}
assert.equal(
  "error" in parseRideGroupWindow({ durationHours: 0.1 }),
  true
);
assert.equal(
  "error" in parseRideGroupWindow({ durationHours: 13 }),
  true
);
const nowCap = new Date("2026-08-19T09:00:00.000Z");
assert.equal(
  "error" in
    parseRideGroupWindow({
      startsAt: new Date(
        nowCap.getTime() + 14 * 24 * 60 * 60 * 1000,
      ).toISOString(),
      durationHours: 3,
      now: nowCap,
    }),
  false,
);
assert.equal(
  "error" in
    parseRideGroupWindow({
      startsAt: new Date(
        nowCap.getTime() + 14 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000,
      ).toISOString(),
      durationHours: 3,
      now: nowCap,
    }),
  true,
);

assert.equal(
  formatGroupWhen(
    "2026-08-16T08:00:00.000Z",
    "2026-08-16T11:00:00.000Z",
    new Date("2026-08-14T10:00:00.000Z")
  ),
  "So 10:00 · 3 h"
);
assert.ok(
  formatGroupWhen(
    "2026-08-16T08:00:00.000Z",
    "2026-08-16T09:30:00.000Z",
    new Date("2026-08-14T10:00:00.000Z")
  ).includes("1.5 h")
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

assert.equal(
  friendUnnamedNumbers(
    [
      { userId: "host", displayLabel: "Host" },
      { userId: "bbb", displayLabel: "" },
      { userId: "aaa", displayLabel: "" },
    ],
    ["host"]
  ).aaa,
  1
);
assert.equal(
  friendRosterName({
    displayLabel: "",
    self: false,
    friendN: 2,
    fallbackSelf: "Du",
    fallbackOther: "Gast",
    friendLabel: (n) => `Freund ${n}`,
  }),
  "Freund 2"
);
assert.equal(platzGroupPrimaryIsInvite(true, 0), true);
assert.equal(platzGroupPrimaryIsInvite(true, 1), false);
assert.equal(platzGroupPrimaryIsInvite(false, 0), false);
assert.equal(platzGroupPrimaryIsInvite(true, 0, true), false);
assert.equal(platzGroupPrimaryIsInvite(true, 0, false), true);

assert.equal(
  extendRideGroupWindowEnd(
    new Date("2026-08-19T12:00:00.000Z"),
    new Date("2026-08-19T13:00:00.000Z"),
    1
  ).toISOString(),
  "2026-08-19T14:00:00.000Z"
);
assert.equal(
  extendRideGroupWindowEnd(
    new Date("2026-08-19T12:00:00.000Z"),
    new Date("2026-08-19T23:00:00.000Z"),
    1
  ).toISOString(),
  "2026-08-20T00:00:00.000Z"
);
assert.equal(
  extendRideGroupWindowEnd(
    new Date("2026-08-19T12:00:00.000Z"),
    new Date("2026-08-19T11:00:00.000Z"),
    1
  ).toISOString(),
  "2026-08-19T13:00:00.000Z"
);
assert.equal(
  extendRideGroupWindowEnd(
    new Date("2026-08-19T12:00:00.000Z"),
    new Date("2026-08-19T13:00:00.000Z"),
    0.5
  ).toISOString(),
  "2026-08-19T13:30:00.000Z"
);
assert.equal(
  extendRideGroupWindowEnd(
    new Date("2026-08-19T12:00:00.000Z"),
    new Date("2026-08-19T13:00:00.000Z"),
    2
  ).toISOString(),
  "2026-08-19T15:00:00.000Z"
);
const customEnd = parseRideGroupExtend({
  now: new Date("2026-08-19T12:00:00.000Z"),
  currentEnd: new Date("2026-08-19T13:00:00.000Z"),
  newEnd: "2026-08-19T16:00:00.000Z",
});
assert.ok(!("error" in customEnd));
if (!("error" in customEnd)) {
  assert.equal(customEnd.end.toISOString(), "2026-08-19T16:00:00.000Z");
}
const cappedEnd = parseRideGroupExtend({
  now: new Date("2026-08-19T12:00:00.000Z"),
  currentEnd: new Date("2026-08-19T13:00:00.000Z"),
  newEnd: "2026-08-20T08:00:00.000Z",
});
assert.ok(!("error" in cappedEnd));
if (!("error" in cappedEnd)) {
  assert.equal(cappedEnd.end.toISOString(), "2026-08-20T00:00:00.000Z");
}
assert.equal(
  "error" in
    parseRideGroupExtend({
      now: new Date("2026-08-19T12:00:00.000Z"),
      currentEnd: new Date("2026-08-19T13:00:00.000Z"),
      addHours: 0.1,
    }),
  true
);
assert.equal(
  isRideGroupExtendBody({
    id: "2e1d69e9-0889-4710-bc30-3ab866577bfb",
    addHours: 0.5,
  }),
  true
);
assert.equal(
  isRideGroupExtendBody({
    id: "2e1d69e9-0889-4710-bc30-3ab866577bfb",
    savedRouteId: "r-bodensee-road",
    addHours: 1,
  }),
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
