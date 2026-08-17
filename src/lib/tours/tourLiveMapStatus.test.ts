/**
 * npx tsx src/lib/tours/tourLiveMapStatus.test.ts
 */
import assert from "node:assert/strict";
import { HONESTY_CYCLEWAY_DE } from "../routing/graphhopperHints";
import { discoverUi } from "../i18n/discoverUi";
import { tourLiveMapStatus } from "./tourLiveMapStatus";

function assertNoEngine(line: string, label: string) {
  const lower = line.toLowerCase();
  assert.ok(!lower.includes("graphhopper"), `${label}: ${line}`);
  assert.ok(!lower.includes("valhalla"), `${label}: ${line}`);
  assert.ok(!lower.includes("osrm"), `${label}: ${line}`);
  assert.ok(!lower.includes("openrouteservice"), `${label}: ${line}`);
  assert.ok(!lower.includes("cache"), `${label}: ${line}`);
  assert.ok(!lower.includes("point_to_point"), `${label}: ${line}`);
  assert.ok(!lower.includes("out_and_back"), `${label}: ${line}`);
}

const base = {
  distanceM: 12300,
  durationS: 45 * 60,
};

for (const engine of ["graphhopper", "valhalla", "osrm", "openrouteservice"] as const) {
  const line = tourLiveMapStatus({ ...base, engine });
  assert.equal(line, "12.3 km · 45 min", engine);
  assertNoEngine(line, engine);
}

const withHonesty = tourLiveMapStatus({
  ...base,
  engine: "graphhopper",
  warnings: [HONESTY_CYCLEWAY_DE],
});
assert.equal(withHonesty, `12.3 km · 45 min · ${HONESTY_CYCLEWAY_DE}`);
assertNoEngine(withHonesty, "honesty");

for (const lang of ["de", "en", "fr", "it", "nl"] as const) {
  const mapped = tourLiveMapStatus(
    { ...base, engine: "valhalla", warnings: [HONESTY_CYCLEWAY_DE] },
    lang,
  );
  assert.ok(mapped.includes(discoverUi(lang).honestyCycleway), lang);
  assertNoEngine(mapped, `honesty-${lang}`);
}

const oa = tourLiveMapStatus({ ...base, engine: "Outdooractive" });
assert.ok(oa.includes("Outdooractive"));
assert.ok(oa.startsWith("12.3 km · 45 min"));
assertNoEngine(oa, "outdooractive");

const cached = tourLiveMapStatus({
  ...base,
  engine: "osrm",
  cached: true,
  shape: "loop",
});
assert.equal(cached, "12.3 km · 45 min · gemerkt · Rundkurs");
assertNoEngine(cached, "cached-loop");

const p2p = tourLiveMapStatus({
  ...base,
  engine: "graphhopper",
  shape: "point_to_point",
});
assert.equal(p2p, "12.3 km · 45 min · Strecke");
assertNoEngine(p2p, "p2p");

const oab = tourLiveMapStatus({
  ...base,
  engine: "valhalla",
  shape: "out_and_back",
});
assert.equal(oab, "12.3 km · 45 min · Hin und zurück");
assertNoEngine(oab, "out-and-back");

const editorial = tourLiveMapStatus({
  ...base,
  engine: "editorial",
  warnings: [
    "Kuratierte Tour-Geometrie (redaktionell). ?forceLive=1 für Engine-Route.",
  ],
});
assert.equal(editorial, "12.3 km · 45 min");
assertNoEngine(editorial, "editorial");
assert.ok(!editorial.toLowerCase().includes("forcelive"));
assert.ok(!editorial.toLowerCase().includes("engine"));

const liveMeta = tourLiveMapStatus({
  ...base,
  engine: "graphhopper",
  warnings: [
    "Tour-Geometrie aus Live-Routing um den Tour-Pin (Annäherung).",
    "Route ab Standort/Suche — Live-Engine, kein Community-Track.",
  ],
});
assert.equal(liveMeta, "12.3 km · 45 min");
assertNoEngine(liveMeta, "live-meta");
assert.ok(!liveMeta.toLowerCase().includes("engine"));

console.log("tourLiveMapStatus.test.ts OK");
