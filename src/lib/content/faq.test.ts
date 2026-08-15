/**
 * Run: npx tsx src/lib/content/faq.test.ts
 */
import assert from "node:assert/strict";
import { FAQ_ITEMS } from "./faq";

function testFaqIdsUnique() {
  const ids = FAQ_ITEMS.map((item) => item.id);
  assert.equal(ids.length, new Set(ids).size);
  assert.ok(FAQ_ITEMS.length >= 8);
  assert.ok(FAQ_ITEMS.every((item) => item.q.length > 8 && item.a.length > 40));
}

testFaqIdsUnique();
console.log("faq.test.ts OK");
