/**
 * Run: npx tsx src/lib/i18n/chatCopy.test.ts
 */
import assert from "node:assert/strict";
import { chatCopy } from "./chatCopy";

function testDe() {
  const c = chatCopy("de");
  assert.equal(c.title, "Mehr fragen");
  assert.ok(c.welcome.includes("Rad"));
  assert.ok(!c.welcome.includes("Garage"));
  assert.equal(c.prompts[1].label, "Rad-Überblick");
  assert.equal(c.prompts.length, 8);
  assert.equal(c.prompts[0].tool, "watch");
  assert.ok(c.freeProFoot.includes("Free"));
  assert.ok(c.freeProFoot.includes("Pro"));
}

function testParity() {
  for (const lang of ["de", "en", "fr", "it", "nl"] as const) {
    const c = chatCopy(lang);
    assert.equal(c.prompts.length, 8, lang);
    assert.ok(c.freeProFoot.includes("Free"), lang);
    assert.ok(c.freeProFoot.includes("Pro"), lang);
  }
  assert.notEqual(chatCopy("de").send, chatCopy("en").send);
  assert.ok(chatCopy("fr").welcome.includes("Demande"));
  assert.equal(chatCopy("nl").send, "Versturen");
  assert.ok(chatCopy("en").rideStats("3", "12.4", "80").includes("12.4"));
  assert.ok(chatCopy("fr").incompleteData.length > 8);
  assert.ok(chatCopy("en").rangeEbikeOnly.toLowerCase().includes("e-bike"));
  assert.ok(chatCopy("nl").inboxEmpty.length > 8);
}

testDe();
testParity();
console.log("chatCopy.test.ts OK");
