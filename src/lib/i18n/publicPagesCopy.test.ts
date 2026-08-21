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
    const routing = p.pricing.rows.find((r) =>
      /routing|routage/i.test(r.feature),
    );
    assert.ok(routing, `${lang} offline routing row`);
    assert.equal(routing!.free, true, `${lang} routing on free`);
    assert.equal(routing!.pro, true, `${lang} routing on pro`);
    assert.match(routing!.feature, /pack/i, `${lang} says pack`);
    assert.doesNotMatch(
      routing!.feature,
      /region|région|regio/i,
      `${lang} no region`,
    );
    const offlineReason = p.download.reasons.find((r) =>
      /offline|hors ligne/i.test(r.title),
    );
    assert.ok(offlineReason, `${lang} offline download reason`);
    assert.match(offlineReason!.body, /pack/i, `${lang} download pack`);
  }
}

function testChromeLangs() {
  assert.equal(publicPagesCopy("nl").contact.title, "Schrijf ons");
}

testDe();
testParity();
testChromeLangs();
console.log("publicPagesCopy.test.ts OK");
