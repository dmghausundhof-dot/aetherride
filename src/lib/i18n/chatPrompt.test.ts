/**
 * Run: npx tsx src/lib/i18n/chatPrompt.test.ts
 */
import assert from "node:assert/strict";
import {
  chatLangFromBody,
  chatSystemPrompt,
  chatUserMessage,
} from "./chatPrompt";

function testDeExact() {
  const s = chatSystemPrompt("de", "42 km (range.low)", "Garage: 1 Rad");
  assert.ok(s.startsWith("Du bist FlowLine KI-Coach."));
  assert.ok(s.includes("Whitelist-Zahlen: 42 km (range.low)"));
  assert.ok(s.includes("Fakten: Garage: 1 Rad"));
  assert.ok(s.includes("Antwort kurz auf Deutsch"));
  assert.equal(
    chatUserMessage("de", "Reichweite?", "42 km"),
    "Nutzerfrage: Reichweite?\nEngine-Rohantwort: 42 km",
  );
  assert.ok(chatSystemPrompt("de", "", "").includes("keine"));
}

function testLangs() {
  assert.ok(chatSystemPrompt("en", "1 km", "x").includes("English"));
  assert.ok(chatSystemPrompt("fr", "1 km", "x").startsWith("Tu es"));
  assert.ok(chatSystemPrompt("it", "1 km", "x").startsWith("Sei il"));
  assert.ok(chatSystemPrompt("nl", "1 km", "x").startsWith("Je bent"));
  assert.ok(chatUserMessage("en", "Q", "A").startsWith("User question:"));
  assert.ok(chatSystemPrompt("en", "", "").includes("none"));
  assert.ok(chatSystemPrompt("fr", "1", "f").includes("allemand"));
}

function testSanitize() {
  assert.equal(chatLangFromBody("fr-CH"), "fr");
  assert.equal(chatLangFromBody("en_US"), "en");
  assert.equal(chatLangFromBody("nl"), "nl");
  assert.equal(chatLangFromBody(undefined), "de");
  assert.equal(chatLangFromBody(1), "de");
}

testDeExact();
testLangs();
testSanitize();
console.log("chatPrompt.test.ts OK");
