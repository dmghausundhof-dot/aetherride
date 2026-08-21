/**
 * Run: npx tsx src/lib/i18n/openRideCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { openRideCopy } from "./openRideCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(openRideCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(openRideCopy(lang)).sort(), keys, lang);
  }
}

function testCopy() {
  assert.equal(openRideCopy("de").title, "App öffnen");
  assert.equal(openRideCopy("en").title, "Open the app");
  assert.equal(openRideCopy("fr").openNow, "Ouvrir l’app maintenant");
  assert.doesNotMatch(openRideCopy("en").handingNav, /nativen/);
}

function testWiring() {
  const page = readFileSync("src/app/open/ride/page.tsx", "utf8");
  assert.ok(page.includes("openRideCopy"), "open ride uses copy");
  assert.ok(!page.includes("Geplante Tour wird"), "hand-off is copy");
}

testParity();
testCopy();
testWiring();
console.log("openRideCopy.test.ts OK");
