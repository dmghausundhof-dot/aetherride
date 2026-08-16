/**
 * Run: npx tsx src/lib/i18n/faqCopy.test.ts
 */
import assert from "node:assert/strict";
import { FAQ_ITEMS } from "../content/faq";
import { faqItems } from "./faqCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDeIsSource() {
  const items = faqItems("de");
  assert.equal(items.length, FAQ_ITEMS.length);
  for (let i = 0; i < items.length; i++) {
    assert.equal(items[i]?.id, FAQ_ITEMS[i]?.id);
    assert.equal(items[i]?.q, FAQ_ITEMS[i]?.q);
    assert.equal(items[i]?.a, FAQ_ITEMS[i]?.a);
  }
}

function testParity() {
  const de = faqItems("de");
  const ids = de.map((item) => item.id);
  assert.equal(ids.length, new Set(ids).size);
  for (const lang of langs) {
    const items = faqItems(lang);
    assert.deepEqual(
      items.map((item) => item.id),
      ids,
      lang,
    );
    for (let i = 0; i < de.length; i++) {
      const a = de[i]!;
      const b = items[i]!;
      assert.ok(b.q.length > 8 && b.a.length > 40, `${lang} ${a.id}`);
      const deHrefs = (a.links ?? []).map((l) => l.href);
      const langHrefs = (b.links ?? []).map((l) => l.href);
      assert.deepEqual(langHrefs, deHrefs, `${lang} ${a.id} hrefs`);
    }
    assert.ok(items.some((item) => item.a.includes("Platz")));
    assert.ok(items.some((item) => item.a.includes("Stimmen")));
  }
}

function testChromeLangs() {
  assert.equal(faqItems("en").find((i) => i.id === "was")?.q, "What is FlowLine?");
  assert.ok(faqItems("fr").find((i) => i.id === "konto")?.a.includes("Non."));
  assert.ok(faqItems("it").find((i) => i.id === "preise")?.a.includes("€"));
}

testDeIsSource();
testParity();
testChromeLangs();
console.log("faqCopy.test.ts OK");
