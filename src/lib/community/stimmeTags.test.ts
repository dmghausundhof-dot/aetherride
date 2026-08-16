/**
 * npx tsx src/lib/community/stimmeTags.test.ts
 */
import assert from "node:assert/strict";
import { parseStimmeTags } from "./stimmeTags";

assert.deepEqual(
  parseStimmeTags(["nass", "top", "zu", "nass", "unknown", "baustelle"]),
  ["nass", "top", "zu"]
);
assert.deepEqual(parseStimmeTags(null), []);
assert.deepEqual(parseStimmeTags(["NASS", "viel los"]), ["nass", "viel_los"]);

console.log("stimmeTags.test.ts OK");
