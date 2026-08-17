/**
 * Coverage copy uses the CDN catalog module, never Node fs.
 * npx tsx src/lib/map/offlineCoverage.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { summarizeOfflinePacks } from "../routing/offlinePackCatalog";

const coverageSrc = readFileSync("src/lib/map/offlineCoverage.ts", "utf8");
assert.equal(coverageSrc.includes("fs/promises"), false);
assert.equal(coverageSrc.includes('lib/routing/offlinePacks"'), false);
assert.ok(coverageSrc.includes("offlinePackCatalog"));

const kartenSrc = readFileSync("src/app/(marketing)/karten/page.tsx", "utf8");
assert.equal(kartenSrc.includes("lib/routing/offlinePacks"), false);

const homeSrc = readFileSync(
  "src/components/landing/HomePageBody.tsx",
  "utf8"
);
assert.equal(homeSrc.includes("KartenCoverageSection"), false);

const summary = summarizeOfflinePacks([
  {
    id: "aachen",
    name: "Aachen",
    bbox: null,
    builtAt: null,
    engines: null,
    hasManifest: true,
    downloadable: true,
    status: "ready",
    bytes: 100,
    cdn: null,
  },
]);
assert.equal(summary.ready, 1);
assert.equal(summary.total, 1);

console.log("offlineCoverage.test.ts OK");
