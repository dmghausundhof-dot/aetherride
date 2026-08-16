/**
 * Run: npx tsx src/lib/i18n/aboutCopy.test.ts
 */
import assert from "node:assert/strict";
import { ABOUT_REFUSALS, ABOUT_STORY } from "../content/aboutPage";
import { aboutCopy } from "./aboutCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDe() {
  const a = aboutCopy("de");
  assert.equal(a.story.title, ABOUT_STORY.title);
  assert.equal(a.refusals.length, ABOUT_REFUSALS.length);
  assert.ok(a.status.body.includes("dmg hausundhof"));
  assert.ok(!JSON.stringify(a).includes("Musterstraße"));
}

function testParity() {
  const de = aboutCopy("de");
  for (const lang of langs) {
    const a = aboutCopy(lang);
    assert.equal(a.story.paragraphs.length, de.story.paragraphs.length, lang);
    assert.equal(a.refusals.length, de.refusals.length, lang);
    assert.equal(a.brand.pillars.length, 3, lang);
    assert.ok(a.refusals.some((r) => r.body.includes("Stimmen")), lang);
    assert.ok(!JSON.stringify(a).includes("Musterstraße"), lang);
  }
}

testDe();
testParity();
console.log("aboutCopy.test.ts OK");
