/**
 * Run: npx tsx src/lib/i18n/publicPagesCopy.test.ts
 */
import assert from "node:assert/strict";
import { publicPagesCopy } from "./publicPagesCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDe() {
  const p = publicPagesCopy("de");
  assert.equal(p.pricing.title, "Free plant. Pro vertieft.");
  assert.equal(p.pricing.rows.length, 11);
  assert.ok(p.contact.workshopHint.includes("Werkstatt-Interesse"));
}

function testParity() {
  const de = publicPagesCopy("de");
  for (const lang of langs) {
    const p = publicPagesCopy(lang);
    assert.equal(p.pricing.rows.length, de.pricing.rows.length, lang);
    assert.equal(p.download.reasons.length, de.download.reasons.length, lang);
    assert.ok(p.pricing.rows.some((r) => r.feature.includes("Platz")), lang);
    assert.ok(p.contact.workshopHint.includes("Werkstatt-Interesse"), lang);
    assert.ok(p.pricing.yearHint.includes("€"), lang);
  }
}

function testChromeLangs() {
  assert.equal(publicPagesCopy("nl").contact.title, "Schrijf ons");
}

testDe();
testParity();
testChromeLangs();
console.log("publicPagesCopy.test.ts OK");
