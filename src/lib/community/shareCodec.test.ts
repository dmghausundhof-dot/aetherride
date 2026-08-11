/**
 * npx tsx src/lib/community/shareCodec.test.ts
 */
import assert from "node:assert/strict";
import {
  decodeSharePayload,
  encodeSharePayload,
} from "./shareCodec";

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

console.log("shareCodec.test.ts OK");
