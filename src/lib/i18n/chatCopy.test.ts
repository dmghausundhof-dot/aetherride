/**
 * Run: npx tsx src/lib/i18n/chatCopy.test.ts
 */
import assert from "node:assert/strict";
import { chatCopy } from "./chatCopy";

function testDe() {
  const c = chatCopy("de");
  assert.equal(c.title, "Mehr fragen");
  assert.ok(c.welcome.includes("Garage"));
  assert.equal(c.prompts.length, 7);
  assert.equal(c.prompts[0].tool, "watch");
  assert.ok(c.freeProFoot.includes("Free"));
  assert.ok(c.freeProFoot.includes("Pro"));
}

function testParity() {
  for (const lang of ["de", "en", "fr", "it"] as const) {
    const c = chatCopy(lang);
    assert.equal(c.prompts.length, 7, lang);
    assert.ok(c.freeProFoot.includes("Free"), lang);
    assert.ok(c.freeProFoot.includes("Pro"), lang);
  }
  assert.notEqual(chatCopy("de").send, chatCopy("en").send);
  assert.ok(chatCopy("fr").welcome.includes("Demande"));
}

testDe();
testParity();
console.log("chatCopy.test.ts OK");
