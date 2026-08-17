/**
 * Run: npx tsx src/lib/i18n/productCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  PRODUCT_DOORS,
  SCREEN_GROUPS,
  WEB_APP_MATRIX,
  WORKFLOWS,
} from "../content/productMap";
import { productCopy } from "./productCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDeMatchesSource() {
  const p = productCopy("de");
  assert.deepEqual(
    p.doors.map((d) => d.href),
    PRODUCT_DOORS.map((d) => d.href),
  );
  assert.equal(p.doors[0]?.title, PRODUCT_DOORS[0].title);
  assert.equal(p.matrix.length, WEB_APP_MATRIX.length);
  assert.deepEqual(
    p.workflows.map((w) => w.id),
    WORKFLOWS.map((w) => w.id),
  );
  assert.equal(p.screenGroups.length, SCREEN_GROUPS.length);
}

function testParity() {
  const de = productCopy("de");
  for (const lang of langs) {
    const p = productCopy(lang);
    assert.deepEqual(
      p.doors.map((d) => d.href),
      de.doors.map((d) => d.href),
      lang,
    );
    const doorTour = {
      de: "Touren",
      en: "Tours",
      fr: "Parcours",
      it: "Percorsi",
    } as const;
    assert.equal(p.doors[2]?.title, doorTour[lang], `${lang} tours door`);
    assert.equal(p.matrix.length, de.matrix.length, lang);
    assert.deepEqual(
      p.workflows.map((w) => w.id),
      de.workflows.map((w) => w.id),
      lang,
    );
    for (let i = 0; i < de.workflows.length; i++) {
      assert.deepEqual(
        p.workflows[i]!.steps.map((s) => s.href),
        de.workflows[i]!.steps.map((s) => s.href),
        `${lang} ${de.workflows[i]!.id}`,
      );
    }
    assert.equal(p.screenGroups.length, de.screenGroups.length, lang);
    for (let g = 0; g < de.screenGroups.length; g++) {
      assert.deepEqual(
        p.screenGroups[g]!.screens.map((s) => s.href),
        de.screenGroups[g]!.screens.map((s) => s.href),
        `${lang} group ${g}`,
      );
    }
    assert.ok(
      p.matrix.some((row) => /Tipp|Tip|Astuce|Consigli/i.test(row.feature)),
      lang,
    );
  }
}

testDeMatchesSource();
testParity();
console.log("productCopy.test.ts OK");
