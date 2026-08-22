/**
 * Honest surface + mtb:scale — never weather, never ORS SAC as S-grade.
 * Run: npx tsx src/lib/routing/routeHonesty.test.ts
 */
import assert from "node:assert/strict";
import {
  attachRouteHonesty,
  clipBandsToKm,
  dominantHonestScale,
  honestyFromOsmTrails,
  mergeHonestyIntoElevation,
  orsSurfaceCodeToOsm,
  planManualComputeVisible,
  scaleFromConditionHint,
  scaleFromOrsTrailDifficulty,
  surfaceBandsAfterTrim,
  surfaceBandsFromOrs,
  surfaceBandsFromVertexRanges,
} from "./routeHonesty";

function testWeatherNeverScale() {
  for (const hint of ["wet_likely", "damp_possible", "dry_likely", "closed"]) {
    assert.equal(scaleFromConditionHint(hint), null, hint);
  }
  assert.equal(scaleFromConditionHint(null), null);
}

function testOrsTrailDifficultyNeverScale() {
  assert.equal(scaleFromOrsTrailDifficulty(0), null);
  assert.equal(scaleFromOrsTrailDifficulty(3), null);
  assert.equal(scaleFromOrsTrailDifficulty(6), null);
}

function testGhSurfaceBands() {
  const coords: [number, number][] = [
    [8.4, 48.6],
    [8.41, 48.6],
    [8.42, 48.6],
    [8.43, 48.6],
  ];
  const bands = surfaceBandsFromVertexRanges(coords, [
    [0, 2, "asphalt"],
    [2, 3, "fine_gravel"],
  ]);
  assert.equal(bands.length, 2);
  assert.equal(bands[0].surface, "asphalt");
  assert.equal(bands[1].surface, "fine_gravel");
  assert.ok(bands[0].toKm > bands[0].fromKm);
}

function testOrsSurfaceCodes() {
  assert.equal(orsSurfaceCodeToOsm(3), "asphalt");
  assert.equal(orsSurfaceCodeToOsm(9), "gravel");
  assert.equal(orsSurfaceCodeToOsm(10), "earth");
  assert.equal(orsSurfaceCodeToOsm(0), null);
  const line: [number, number][] = [
    [8.4, 48.6],
    [8.45, 48.6],
  ];
  const fromRanges = surfaceBandsFromOrs(
    {
      surfaces: [{ id: 3, label: "Asphalt", distanceM: 8000 }],
      waytypes: [],
      surfaceRanges: [[0, 1, 3]],
    },
    line
  );
  assert.equal(fromRanges[0]?.surface, "asphalt");
  const fromSummary = surfaceBandsFromOrs(
    {
      surfaces: [{ id: 9, label: "Schotter", distanceM: 4000 }],
      waytypes: [],
    },
    line
  );
  assert.equal(fromSummary[0]?.surface, "gravel");
}

function testOsmScaleProjection() {
  const line: [number, number][] = [
    [8.4, 48.64],
    [8.41, 48.64],
    [8.42, 48.64],
  ];
  const trails = [
    {
      mtbScale: "S2",
      surface: "dirt",
      geometry: {
        coordinates: [
          [8.4001, 48.6401],
          [8.4199, 48.6401],
        ],
      },
    },
  ];
  const h = honestyFromOsmTrails(line, trails);
  assert.ok(
    h.scaleBands.some((b) => b.scale === "S2"),
    "OSM mtb:scale S2 should land on the ribbon"
  );
  assert.ok(h.surfaceBands.some((b) => b.surface === "dirt"));
  assert.equal(dominantHonestScale(h.scaleBands), "S2");
}

function testSacAndWeatherNotScale() {
  const line: [number, number][] = [
    [8.4, 48.64],
    [8.41, 48.64],
  ];
  const sac = honestyFromOsmTrails(line, [
    {
      difficulty: "T3",
      geometry: { coordinates: line },
    },
  ]);
  assert.ok(
    sac.scaleBands.every((b) => b.scale == null || !b.scale.startsWith("S")),
    "SAC / T-grade must not become S-scale"
  );
  assert.equal(dominantHonestScale([{ fromKm: 0, toKm: 1, scale: null }]), null);
}

function testAttachKeepsEngineSurface() {
  const result = attachRouteHonesty(
    {
      geometry: {
        type: "LineString" as const,
        coordinates: [
          [8.4, 48.6],
          [8.41, 48.6],
        ],
      },
      surfaceBands: [{ fromKm: 0, toKm: 1, surface: "asphalt" }],
    },
    {
      trails: [
        {
          mtbScale: "S1",
          surface: "dirt",
          geometry: {
            coordinates: [
              [8.4, 48.6],
              [8.41, 48.6],
            ],
          },
        },
      ],
    }
  );
  assert.equal(result.surfaceBands[0].surface, "asphalt");
  assert.equal(dominantHonestScale(result.scaleBands), "S1");
}

function testMergeElevation() {
  const empty = {
    surfaceBands: [{ fromKm: 0, toKm: 1, surface: null }],
    scaleBands: [{ fromKm: 0, toKm: 1, scale: null }],
  };
  const merged = mergeHonestyIntoElevation(empty, {
    surfaceBands: [{ fromKm: 0, toKm: 1, surface: "gravel" }],
    scaleBands: [{ fromKm: 0, toKm: 1, scale: "S0" }],
  });
  assert.equal(merged.surfaceBands[0].surface, "gravel");
  assert.equal(merged.scaleBands[0].scale, "S0");
}

function testTrimAndClip() {
  const orig: [number, number][] = [
    [8.4, 48.6],
    [8.41, 48.6],
    [8.42, 48.6],
    [8.43, 48.6],
  ];
  const trimmed = orig.slice(1);
  const bands = surfaceBandsAfterTrim(orig, trimmed, [
    [0, 1, "grass"],
    [1, 3, "asphalt"],
  ]);
  assert.ok(bands.some((b) => b.surface === "asphalt"));
  const clipped = clipBandsToKm(
    [{ fromKm: 0, toKm: 2, surface: "asphalt" }],
    0.5,
    1.2
  );
  assert.equal(clipped[0].fromKm, 0.5);
  assert.equal(clipped[0].toKm, 1.2);
}

function testManualCompute() {
  assert.equal(
    planManualComputeVisible({
      hasStart: true,
      hasEnd: true,
      routingBusy: false,
      hasComputed: false,
    }),
    true
  );
  assert.equal(
    planManualComputeVisible({
      hasStart: true,
      hasEnd: true,
      routingBusy: false,
      hasComputed: true,
    }),
    false
  );
  assert.equal(
    planManualComputeVisible({
      hasStart: true,
      hasEnd: true,
      routingBusy: true,
      hasComputed: false,
    }),
    false
  );
}

testWeatherNeverScale();
testOrsTrailDifficultyNeverScale();
testGhSurfaceBands();
testOrsSurfaceCodes();
testOsmScaleProjection();
testSacAndWeatherNotScale();
testAttachKeepsEngineSurface();
testMergeElevation();
testTrimAndClip();
testManualCompute();
console.log("routeHonesty.test.ts OK");
