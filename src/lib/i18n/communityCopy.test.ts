/**
 * Run: npx tsx src/lib/i18n/communityCopy.test.ts
 */
import assert from "node:assert/strict";
import { COMMUNITY_FEATURES, COMMUNITY_OUT } from "../content/communityMap";
import { communityCopy } from "./communityCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDe() {
  const c = communityCopy("de");
  assert.equal(c.features.length, COMMUNITY_FEATURES.length);
  assert.deepEqual(
    c.features.map((f) => f.href),
    COMMUNITY_FEATURES.map((f) => f.href),
  );
  assert.equal(c.out.length, COMMUNITY_OUT.length);
}

function testParity() {
  const de = communityCopy("de");
  for (const lang of langs) {
    const c = communityCopy(lang);
    assert.deepEqual(
      c.features.map((f) => f.href),
      de.features.map((f) => f.href),
      lang,
    );
    assert.equal(c.features[0]?.title, "Platz", lang);
    assert.equal(c.features[1]?.title, "Stimmen", lang);
    assert.equal(c.out.length, de.out.length, lang);
    assert.ok(c.out.some((line) => line.includes("Stimmen")), lang);
  }
}

testDe();
testParity();
console.log("communityCopy.test.ts OK");
