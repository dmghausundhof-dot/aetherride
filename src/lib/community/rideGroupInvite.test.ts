/**
 * npx tsx src/lib/community/rideGroupInvite.test.ts
 */
import assert from "node:assert/strict";
import {
  encodeGroupInvite,
  groupInviteShareText,
  parsePastedGroupJoin,
} from "./rideGroupInvite";
import type { RideGroup } from "./types";

const group: RideGroup = {
  id: "11111111-1111-1111-1111-111111111111",
  hostUserId: "host-1",
  savedRouteId: "r-bodensee-road",
  catalogTourId: "r-bodensee-road",
  title: "Bodensee",
  startWindowStart: "2026-08-15T08:00:00.000Z",
  startWindowEnd: "2026-08-15T12:00:00.000Z",
  joinCode: "K7M2NP",
  status: "open",
  livePinsAllowed: true,
  createdAt: "2026-08-15T08:00:00.000Z",
  onServer: true,
  visibility: "private",
};

const token = encodeGroupInvite(group);
const https = `https://aetherride.vercel.app/library?group=${group.id}&g=${token}`;
const scheme = `aetherride://platz?group=${group.id}&g=${token}`;

const fromHttps = parsePastedGroupJoin(https);
assert.equal(fromHttps?.ref, group.id);
assert.equal(fromHttps?.token, token);

const share = `Zusammen raus: Bodensee\n${https}\n${scheme}\n\nPrivat: nur wer diesen Link hat.`;
const fromShare = parsePastedGroupJoin(share);
assert.equal(fromShare?.ref, group.id);
assert.equal(fromShare?.token, token);

const fromScheme = parsePastedGroupJoin(scheme);
assert.equal(fromScheme?.ref, group.id);
assert.equal(fromScheme?.token, token);

assert.equal(parsePastedGroupJoin(""), null);
assert.equal(parsePastedGroupJoin("xyz"), null);
assert.equal(parsePastedGroupJoin("AB"), null);
assert.equal(parsePastedGroupJoin(group.id)?.ref, group.id);
assert.equal(parsePastedGroupJoin("k7-m2 np")?.ref, "K7M2NP");
assert.equal(parsePastedGroupJoin("K7M2NP")?.ref, "K7M2NP");

const publicShare = groupInviteShareText({
  title: "Bodensee",
  url: https,
  code: "K7M2NP",
  visibility: "public",
});
assert.ok(publicShare.includes("Code: K7M2NP"));
const privateShare = groupInviteShareText({
  title: "Bodensee",
  url: https,
  code: "K7M2NP",
  visibility: "private",
});
assert.equal(privateShare.includes("Code: K7M2NP"), false);

console.log("rideGroupInvite.test.ts OK");
