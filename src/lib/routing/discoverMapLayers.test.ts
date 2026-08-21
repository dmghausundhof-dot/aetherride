/**
 * Smoke-Tests Discover Map Layers + Trail-Attach Persistenz-Vertrag.
 * Ausführen: npx tsx src/lib/routing/discoverMapLayers.test.ts
 */
process.env.ALLOW_DEMO_CONTENT = "true";

import { buildDiscoverMapLayers, buildPlanGradeOverlayLayers } from "./discoverMapLayers";
import { emptyDraft, setEnd, setStart, type PlanDraft } from "./planDraft";
import { SEED_TRAILS } from "./trailSegments";
import type { ClientRouteResult } from "./profiles";
import { getProfile } from "./profiles";
import type { TrailSegment } from "./trailSegments";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const line = (coords: [number, number][]): GeoJSON.LineString => ({
  type: "LineString",
  coordinates: coords,
});

const fakeResult = (
  geometry: GeoJSON.LineString,
  distanceM = 5000
): ClientRouteResult => ({
  distanceM,
  durationS: 1800,
  geometry,
  engine: "test",
  profile: "mtb_allmountain",
});

function testLayersActiveAndAlt() {
  const activeGeom = line([
    [8.4, 48.6],
    [8.41, 48.61],
  ]);
  const altGeom = line([
    [8.4, 48.6],
    [8.42, 48.6],
  ]);
  const draft: PlanDraft = {
    ...emptyDraft("mtb_allmountain", [8.4, 48.6]),
    mode: "quick",
    label: "Kurz",
    computed: fakeResult(activeGeom),
  };
  const layers = buildDiscoverMapLayers({
    draft,
    quickOptions: [
      {
        id: "q1",
        label: "Kurz",
        reason: "test",
        result: fakeResult(activeGeom),
      },
      {
        id: "q2",
        label: "Lang",
        reason: "test",
        result: fakeResult(altGeom, 12000),
      },
    ],
    activeQuickId: "q1",
    trails: [],
    showTrails: false,
  });
  assert(
    layers.some((l) => l.role === "active"),
    "active layer missing"
  );
  assert(
    layers.some((l) => l.role === "alt" && l.id === "alt-q2"),
    "alt layer for non-active quick missing"
  );
  assert(
    !layers.some((l) => l.id === "alt-q1"),
    "active quick should not also be alt"
  );
}

function testHybridParts() {
  const approach = line([
    [8.4, 48.6],
    [8.41, 48.635],
  ]);
  const trail = SEED_TRAILS[0].geometry;
  const merged = line([
    ...(approach.coordinates as [number, number][]),
    ...(trail.coordinates as [number, number][]),
  ]);
  const draft: PlanDraft = {
    ...emptyDraft("mtb_allmountain", [8.4, 48.6]),
    mode: "hybrid",
    computed: fakeResult(merged),
    layers: { approach, trail },
  };
  const layers = buildDiscoverMapLayers({
    draft,
    quickOptions: [],
    trails: [],
    showTrails: false,
  });
  assert(
    layers.some((l) => l.role === "approach"),
    "approach missing"
  );
  assert(layers.some((l) => l.role === "trail"), "trail missing");
  assert(
    layers.some((l) => l.id === "active-merged" || l.role === "active"),
    "merged/active outline missing"
  );
}

async function testAttachAppendPersistsLayers() {
  // Ohne Netz: Persistenz-Vertrag anhand eines Hybrid-Drafts (wie nach attach).
  const approach = line([
    [8.4, 48.6],
    [8.41, 48.635],
  ]);
  const trail = SEED_TRAILS[0].geometry;
  const merged = line([
    ...(approach.coordinates as [number, number][]),
    ...(trail.coordinates as [number, number][]),
  ]);
  const draft: PlanDraft = {
    ...emptyDraft("mtb_allmountain", [8.4, 48.6]),
    mode: "hybrid",
    label: "Kaltenbronn Flow",
    computed: fakeResult(merged),
    layers: { approach, trail },
    attachedTrailId: SEED_TRAILS[0].id,
    waypoints: [
      { id: "start", role: "start", lngLat: [8.4, 48.6], label: "Start" },
      { id: "end", role: "end", lngLat: [8.438, 48.65], label: "Ziel" },
    ],
  };
  assert(draft.layers?.trail != null, "trail layer not set");
  assert(draft.computed?.geometry != null, "computed geometry missing");
  assert(draft.mode === "hybrid", "mode should be hybrid");
  const savedLayers = {
    approach: draft.layers?.approach,
    tour: draft.layers?.tour,
    trail: draft.layers?.trail,
  };
  assert(savedLayers.trail != null, "saved layers must include trail");
  assert(savedLayers.approach != null, "saved layers must include approach");
}

function testRideProfileFiltersAndHighlightsTrails() {
  const s0: TrailSegment = {
    id: "s0-only",
    name: "Green",
    difficulty: "S0",
    provider: "seed",
    center: [8.4, 48.6],
    geometry: line([
      [8.4, 48.6],
      [8.41, 48.61],
    ]),
  };
  const s3: TrailSegment = {
    id: "s3-only",
    name: "DH Line",
    difficulty: "S3",
    provider: "seed",
    center: [8.4, 48.6],
    geometry: line([
      [8.42, 48.6],
      [8.43, 48.61],
    ]),
  };
  const draft = emptyDraft("downhill", [8.4, 48.6]);
  const dh = buildDiscoverMapLayers({
    draft,
    quickOptions: [],
    trails: [s0, s3],
    showTrails: true,
    rideProfileId: "downhill",
  });
  assert(
    !dh.some((l) => l.id === "trail-s0-only"),
    "Downhill hides S0 seed trails"
  );
  const highlighted = dh.find((l) => l.id === "trail-s3-only");
  assert(highlighted != null, "Downhill keeps S3 seed trails");
  assert(
    highlighted.color === getProfile("downhill").trailHighlightColor,
    "S3 trail uses DH highlight color"
  );

  const road = buildDiscoverMapLayers({
    draft: emptyDraft("road", [8.4, 48.6]),
    quickOptions: [],
    trails: [s0, s3],
    showTrails: true,
    rideProfileId: "road",
  });
  assert(
    !road.some((l) => l.id.startsWith("trail-")),
    "Road hides MTB seed trails"
  );
}

function testPendingAbGhost() {
  const draft = setEnd(
    setStart(emptyDraft("gravel"), [8.69, 49.41], "Ich"),
    [8.7, 49.4],
    "Ziel"
  );
  const pending = buildDiscoverMapLayers({
    draft,
    quickOptions: [],
    trails: [],
    showTrails: false,
  });
  assert(
    !pending.some((l) => l.id === "pending-ab"),
    "crow-flies GPS→pin must not look like a field route",
  );

  const live: PlanDraft = {
    ...draft,
    computed: fakeResult(
      line([
        [8.69, 49.41],
        [8.7, 49.4],
      ])
    ),
  };
  const routed = buildDiscoverMapLayers({
    draft: live,
    quickOptions: [],
    trails: [],
    showTrails: false,
  });
  assert(
    !routed.some((l) => l.id === "pending-ab"),
    "live street line replaces the pending ghost"
  );
}

function testGradeOverlays() {
  const line: [number, number][] = [];
  for (let i = 0; i <= 12; i++) line.push([8.67 + i * 0.008, 49.4]);
  const elevM = line.map((_, i) => (i >= 4 && i <= 7 ? 100 + (i - 4) * 80 : 100));
  const layers = buildPlanGradeOverlayLayers({
    line,
    elevM,
    surfaceBands: [
      { fromKm: 0, toKm: 0.4, surface: "asphalt" },
      { fromKm: 0.4, toKm: 1.6, surface: "gravel" },
      { fromKm: 1.6, toKm: 2.4, surface: "dirt" },
    ],
  });
  assert(
    layers.some((l) => l.role === "steep"),
    "steep overlay missing"
  );
  assert(
    layers.some((l) => l.role === "paved"),
    "paved overlay missing"
  );
  assert(
    layers.some((l) => l.role === "gravel"),
    "gravel overlay missing"
  );
  assert(
    layers.some((l) => l.role === "unpaved"),
    "unpaved overlay missing"
  );
}

async function main() {
  testLayersActiveAndAlt();
  testHybridParts();
  await testAttachAppendPersistsLayers();
  testRideProfileFiltersAndHighlightsTrails();
  testPendingAbGhost();
  testGradeOverlays();
  console.log("discoverMapLayers.test.ts: ok");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
