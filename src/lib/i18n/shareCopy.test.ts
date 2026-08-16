/**
 * Run: npx tsx src/lib/i18n/shareCopy.test.ts
 */
import assert from "node:assert/strict";
import { shareCopy } from "./shareCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDe() {
  const s = shareCopy("de");
  assert.equal(s.title, "Link statt Feed");
  assert.equal(s.mappeTitle, "Mappe");
  assert.equal(s.toPlatz, "Zum Platz");
}

function testParity() {
  for (const lang of langs) {
    const s = shareCopy(lang);
    assert.equal(s.mappeTitle, "Mappe", lang);
    assert.ok(s.toPlatz.includes("Platz"), lang);
    assert.ok(s.foot.includes("Stimmen"), lang);
    assert.ok(s.adoptMappe.includes("Mappe"), lang);
    assert.ok(s.toursNoGps(2).includes("2"), lang);
    assert.ok(s.sharedSuffix("Alster").includes("Alster"), lang);
  }
}

testDe();
testParity();
console.log("shareCopy.test.ts OK");
