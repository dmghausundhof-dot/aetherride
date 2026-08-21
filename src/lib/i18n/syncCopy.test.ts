/**
 * Run: npx tsx src/lib/i18n/syncCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { syncCopy } from "./syncCopy";
import { summarizePayload } from "../sync/webSync";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(syncCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(syncCopy(lang)).sort(), keys, lang);
  }
}

function testSummary() {
  assert.equal(summarizePayload(null, "de"), "leer");
  assert.equal(summarizePayload(null, "en"), "empty");
  const empty = summarizePayload(
    { bikes: [], rides: [], savedRoutes: [], routeCollections: [] } as never,
    "fr"
  );
  assert.ok(empty.includes("parcours"), empty);
  assert.ok(!empty.includes("Touren"), empty);
}

function testMessages() {
  assert.equal(syncCopy("en").title, "Sync conflict");
  assert.ok(syncCopy("en").pulled("1 Bikes").includes("cloud"));
  assert.doesNotMatch(syncCopy("en").hint, /dieses Gerät/);
}

function testWiring() {
  const panel = readFileSync(
    "src/components/sync/SyncConflictPanel.tsx",
    "utf8"
  );
  assert.ok(panel.includes("syncCopy"), "panel uses copy");
  assert.ok(!panel.includes("Sync-Konflikt"), "title is copy");
  const page = readFileSync("src/app/profile/page.tsx", "utf8");
  assert.ok(page.includes("runWebSync(lang)"), "profile passes lang to sync");
  const web = readFileSync("src/lib/sync/webSync.ts", "utf8");
  assert.ok(web.includes("syncCopy"), "webSync presents in chrome lang");
}

testParity();
testSummary();
testMessages();
testWiring();
console.log("syncCopy.test.ts OK");
