/**
 * Run: npx tsx src/lib/i18n/guidesCopy.test.ts
 */
import assert from "node:assert/strict";
import { GUIDES, getGuide, listGuideSlugs } from "../content/guides";
import {
  guideFor,
  guideCategoryLabel,
  listGuidesGroupedFor,
} from "./guidesCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDePassthrough() {
  for (const slug of listGuideSlugs()) {
    const a = getGuide(slug);
    const b = guideFor(slug, "de");
    assert.deepEqual(b, a, slug);
  }
}

function testParity() {
  for (const lang of langs) {
    const grouped = listGuidesGroupedFor(lang);
    const slugs = grouped.flatMap((g) => g.guides.map((x) => x.slug));
    assert.deepEqual([...slugs].sort(), [...listGuideSlugs()].sort(), lang);
    for (const g of GUIDES) {
      const loc = guideFor(g.slug, lang);
      assert.ok(loc, `${lang} ${g.slug}`);
      assert.equal(loc!.body.length, g.body.length, `${lang} ${g.slug} body`);
      assert.equal(
        loc!.relatedHrefs?.length ?? 0,
        g.relatedHrefs?.length ?? 0,
        `${lang} ${g.slug} related`,
      );
      assert.deepEqual(
        (loc!.relatedHrefs ?? []).map((r) => r.href),
        (g.relatedHrefs ?? []).map((r) => r.href),
        `${lang} ${g.slug} hrefs`,
      );
    }
    assert.equal(guideCategoryLabel(lang).ebike, "E-Bike");
  }
}

function testChromeLangs() {
  const en = guideFor("web-vs-app", "en");
  assert.ok(en?.title.includes("Website vs. app"));
  assert.notEqual(en?.title, getGuide("web-vs-app")?.title);
  const fr = guideFor("platz-ohne-feed", "fr");
  assert.ok(fr?.title.includes("Platz"));
  assert.ok(fr?.title.includes("Stimmen"));
  const it = guideFor("laden-ohne-zweite-kasse", "it");
  assert.ok(it?.title.includes("Shopify"));
}

testDePassthrough();
testParity();
testChromeLangs();
console.log("guidesCopy.test.ts OK");
