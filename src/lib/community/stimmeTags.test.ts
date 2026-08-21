/**
 * npx tsx src/lib/community/stimmeTags.test.ts
 */
import assert from "node:assert/strict";
import { parseStimmeTags, STIMME_FORM_TAG_WIRES } from "./stimmeTags";

assert.deepEqual(
  parseStimmeTags(["nass", "top", "zu", "nass", "unknown", "baustelle"]),
  ["nass", "top", "zu"]
);
assert.deepEqual(parseStimmeTags(null), []);
assert.deepEqual(parseStimmeTags(["NASS", "viel los"]), ["nass", "viel_los"]);
assert.deepEqual([...STIMME_FORM_TAG_WIRES], ["nass", "zu", "viel_los"]);
assert.ok(!STIMME_FORM_TAG_WIRES.includes("top" as never));
assert.ok(!STIMME_FORM_TAG_WIRES.includes("baustelle" as never));

console.log("stimmeTags.test.ts OK");
