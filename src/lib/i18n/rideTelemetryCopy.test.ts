/**
 * Run: npx tsx src/lib/i18n/rideTelemetryCopy.test.ts
 */
import assert from "node:assert/strict";
import { rideTelemetryCopy } from "./rideTelemetryCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDe() {
  const c = rideTelemetryCopy("de");
  assert.equal(c.title, "Strecke & Neigung");
  assert.ok(c.hint.includes("Lücken"));
  assert.ok(!c.hint.includes("interpol"));
}

function testParity() {
  const keys = Object.keys(rideTelemetryCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(rideTelemetryCopy(lang)).sort(), keys, lang);
    const c = rideTelemetryCopy(lang);
    assert.ok(c.climb.length > 0, lang);
    assert.ok(c.descent.length > 0, lang);
    assert.notEqual(c.title, c.title.toUpperCase(), lang);
  }
  assert.ok(rideTelemetryCopy("de").openGarage.includes("Rad"));
  assert.notEqual(
    rideTelemetryCopy("nl").openGarage,
    rideTelemetryCopy("en").openGarage,
  );
  assert.ok(rideTelemetryCopy("nl").openGarage.toLowerCase().includes("fiets"));
}

testDe();
testParity();
console.log("rideTelemetryCopy.test.ts OK");
