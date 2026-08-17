/**
 * npx tsx src/lib/routing/routeResultMessage.test.ts
 */
import assert from "node:assert/strict";
import { discoverStatus, discoverUi } from "../i18n/discoverUi";
import { HONESTY_CYCLEWAY_DE } from "./graphhopperHints";
import { routeResultMessage } from "./planDraft";
import type { ClientRouteResult } from "./profiles";

function stub(engine: string, warnings?: string[]): ClientRouteResult {
  return {
    distanceM: 12300,
    durationS: 45 * 60,
    geometry: { type: "LineString", coordinates: [[8, 49], [8.1, 49.1]] },
    engine,
    profile: "gravel",
    warnings,
  };
}

function assertNoEngine(line: string, label: string) {
  const lower = line.toLowerCase();
  assert.ok(!lower.includes("graphhopper"), `${label}: ${line}`);
  assert.ok(!lower.includes("valhalla"), `${label}: ${line}`);
  assert.ok(!lower.includes("osrm"), `${label}: ${line}`);
}

for (const engine of ["graphhopper", "valhalla", "osrm"] as const) {
  const line = routeResultMessage(stub(engine));
  assert.equal(line, "12.3 km · 45 min", engine);
  assertNoEngine(line, engine);
}

const withHonesty = routeResultMessage(
  stub("graphhopper", [HONESTY_CYCLEWAY_DE]),
);
assert.equal(withHonesty, `12.3 km · 45 min · ${HONESTY_CYCLEWAY_DE}`);
assertNoEngine(withHonesty, "honesty");

for (const lang of ["de", "en", "fr", "it"] as const) {
  const mapped = discoverStatus(withHonesty, lang);
  assert.ok(mapped.includes(discoverUi(lang).honestyCycleway), lang);
  assertNoEngine(mapped, `mapped-${lang}`);
}

assert.equal(
  discoverStatus("12.3 km · 45 min · valhalla", "fr"),
  "12.3 km · 45 min",
);
assert.equal(
  discoverStatus("12.3 km · 45 min · graphhopper", "en"),
  "12.3 km · 45 min",
);
assert.ok(
  discoverStatus("Heidelbergwald · 12.3 km · 45 min", "de").includes(
    "Heidelbergwald",
  ),
);
assert.ok(
  discoverStatus("12.3 km · 45 min · Outdooractive", "en").includes(
    "Outdooractive",
  ),
);

console.log("routeResultMessage.test.ts OK");
