/**
 * npx tsx src/lib/routing/snapTrailCorridor.test.ts
 */
import assert from "node:assert/strict";
import {
  applyCorridorCyclewaySnap,
  applyCorridorTrailSnap,
  clipTrailLastMile,
  destLiesOnTrail,
  pickCyclewaysAlongRoute,
  pickTrailAlongRoute,
  snapPointOntoTrails,
  spliceTrailIntoRoute,
  viaMaySnapOntoTrail,
} from "./snapTrailCorridor";
import type { ClientRouteResult } from "./profiles";
import type { TrailSegment } from "./trailSegments";
import { HONESTY_CYCLEWAY_DE } from "./graphhopperHints";

const from: [number, number] = [8.7, 49.4];
const to: [number, number] = [8.72, 49.4];
const routeGeom: GeoJSON.LineString = {
  type: "LineString",
  coordinates: [
    [8.7, 49.4],
    [8.71, 49.4],
    [8.72, 49.4],
  ],
};
const route: ClientRouteResult = {
  distanceM: 1450,
  durationS: 400,
  geometry: routeGeom,
  engine: "graphhopper",
  profile: "mtb_allmountain",
};

function trail(
  id: string,
  coords: [number, number][],
  extra: Partial<TrailSegment> = {},
): TrailSegment {
  const mid = coords[Math.floor(coords.length / 2)] ?? coords[0];
  return {
    id,
    name: id,
    provider: "osm",
    center: mid,
    geometry: { type: "LineString", coordinates: coords },
    highway: "path",
    difficulty: "S1",
    surface: "ground",
    ...extra,
  };
}

const parallel = trail("parallel", [
  [8.705, 49.40072],
  [8.712, 49.40072],
  [8.718, 49.40072],
]);

const onRoute = trail("on-route", [
  [8.705, 49.4],
  [8.712, 49.4],
  [8.718, 49.4],
]);

const far = trail("far", [
  [8.7, 49.42],
  [8.71, 49.42],
  [8.72, 49.42],
]);

const picked = pickTrailAlongRoute({
  profile: "mtb_allmountain",
  from,
  to,
  route,
  trails: [far, parallel, onRoute],
});
assert.equal(picked?.id, "parallel", "picks the nearby missed trail");

const skippedOn = pickTrailAlongRoute({
  profile: "mtb_allmountain",
  from,
  to,
  route,
  trails: [onRoute],
});
assert.equal(skippedOn, null, "skips trail already on the engine line");

const skippedFar = pickTrailAlongRoute({
  profile: "mtb_allmountain",
  from,
  to,
  route,
  trails: [far],
});
assert.equal(skippedFar, null, "skips distant trail");

const skippedRoad = pickTrailAlongRoute({
  profile: "road",
  from,
  to,
  route: { ...route, profile: "road" },
  trails: [parallel],
});
assert.equal(skippedRoad, null, "road profile does not auto-snap singletrack");

const skippedCityTrail = pickTrailAlongRoute({
  profile: "urban",
  from,
  to,
  route: { ...route, profile: "urban" },
  trails: [parallel],
});
assert.equal(
  skippedCityTrail,
  null,
  "City does not trail-corridor-snap path/track (cycleway snap is separate)",
);

const skippedEbikeTrail = pickTrailAlongRoute({
  profile: "ebike",
  from,
  to,
  route: { ...route, profile: "ebike" },
  trails: [parallel],
});
assert.equal(skippedEbikeTrail, null, "E-Bike City does not trail-snap");

const reversed = pickTrailAlongRoute({
  profile: "mtb_allmountain",
  from,
  to,
  route,
  trails: [
    trail("rev", [
      [8.718, 49.40072],
      [8.712, 49.40072],
      [8.705, 49.40072],
    ]),
  ],
});
assert.ok(reversed, "orients reversed trail toward start");
const c0 = reversed!.geometry.coordinates[0] as [number, number];
assert.ok(c0[0] < 8.71, "entry is the western end after orient");

const spliced = spliceTrailIntoRoute(route, parallel);
assert.ok(spliced, "splices parallel trail into engine line");
const lats = (spliced!.geometry.coordinates as [number, number][]).map(
  (c) => c[1],
);
assert.ok(
  lats.some((lat) => lat > 49.4005),
  "spliced geometry includes the offset trail",
);
assert.ok(
  (spliced!.warnings ?? []).some((w) => w.includes("in die Navi übernommen")),
  "adds rider-facing trail warning",
);
assert.ok(
  (spliced!.steps ?? []).some((s) => s.instruction.startsWith("Trail ")),
  "adds trail nav step",
);

const noSpan = spliceTrailIntoRoute(
  route,
  trail("dot", [
    [8.71, 49.40072],
    [8.7102, 49.40072],
  ]),
);
assert.equal(noSpan, null, "refuses a trail that does not span the corridor");

const cityRoute: ClientRouteResult = {
  distanceM: 1450,
  durationS: 400,
  geometry: {
    type: "LineString",
    coordinates: [
      [8.7, 49.4],
      [8.705, 49.4],
      [8.71, 49.4],
      [8.715, 49.4],
      [8.72, 49.4],
    ],
  },
  engine: "graphhopper",
  profile: "urban",
};

const cycleNear = trail(
  "rad-nah",
  [
    [8.705, 49.40036],
    [8.712, 49.40036],
    [8.718, 49.40036],
  ],
  {
    highway: "cycleway",
    name: "Neckarweg",
    difficulty: "open",
    surface: "asphalt",
  },
);
const cycleFar = trail(
  "rad-fern",
  [
    [8.705, 49.40072],
    [8.712, 49.40072],
    [8.718, 49.40072],
  ],
  {
    highway: "cycleway",
    name: "zu weit",
    difficulty: "open",
    surface: "asphalt",
  },
);
const pathBeside = trail(
  "pfad",
  [
    [8.705, 49.40036],
    [8.712, 49.40036],
    [8.718, 49.40036],
  ],
  { highway: "path", name: "Parkpfad" },
);

const cityPicked = pickCyclewaysAlongRoute({
  profile: "urban",
  from,
  to,
  route: cityRoute,
  trails: [cycleFar, pathBeside, cycleNear],
});
assert.equal(cityPicked.length, 1, "city snap takes the close cycleway only");
assert.equal(cityPicked[0]?.id, "rad-nah");

assert.deepEqual(
  pickCyclewaysAlongRoute({
    profile: "mtb_allmountain",
    from,
    to,
    route: { ...cityRoute, profile: "mtb_allmountain" },
    trails: [cycleNear],
  }),
  [],
  "MTB does not use the city cycleway picker",
);

const west = trail(
  "west",
  [
    [8.705, 49.40036],
    [8.709, 49.40036],
  ],
  { highway: "cycleway", name: "West", difficulty: "open", surface: "asphalt" },
);
const east = trail(
  "east",
  [
    [8.713, 49.40036],
    [8.718, 49.40036],
  ],
  { highway: "cycleway", name: "Ost", difficulty: "open", surface: "asphalt" },
);
const slices = pickCyclewaysAlongRoute({
  profile: "urban",
  from,
  to,
  route: cityRoute,
  trails: [west, east],
});
assert.equal(slices.length, 2, "keeps non-overlapping cycleway slices");
assert.ok(slices[0]!.id === "east", "destination-first order for splicing");

const citySnapped = applyCorridorCyclewaySnap({
  profile: "urban",
  from,
  to,
  route: {
    ...cityRoute,
    warnings: [HONESTY_CYCLEWAY_DE],
  },
  trails: [west, east],
});
assert.ok(
  (citySnapped.warnings ?? []).some((w) =>
    w.includes("2 Radweg-Abschnitte in die Navi übernommen"),
  ),
  "one summary warning for several slices",
);
assert.equal(
  (citySnapped.warnings ?? []).some((w) =>
    w.startsWith("Wenig eigener Radweg"),
  ),
  false,
  "drops the honesty warning after a successful snap",
);
const snappedLats = (
  citySnapped.geometry.coordinates as [number, number][]
).map((c) => c[1]);
assert.ok(
  snappedLats.some((lat) => lat > 49.4002),
  "spliced geometry includes the cycleway",
);
assert.ok(
  (citySnapped.steps ?? []).some(
    (s) =>
      s.instruction.toLowerCase().includes("radweg") ||
      s.instruction.includes("West") ||
      s.instruction.includes("Ost"),
  ),
  "adds Radweg nav steps",
);

const onRoadCycle = trail(
  "schon-drauf",
  [
    [8.705, 49.4],
    [8.712, 49.4],
    [8.718, 49.4],
  ],
  {
    highway: "cycleway",
    name: "schon drauf",
    difficulty: "open",
    surface: "asphalt",
  },
);
assert.deepEqual(
  pickCyclewaysAlongRoute({
    profile: "urban",
    from,
    to,
    route: cityRoute,
    trails: [onRoadCycle],
  }),
  [],
  "skips a cycleway already on the engine line",
);

const s3 = trail(
  "s3-long",
  [
    [8.7, 49.401],
    [8.73, 49.401],
    [8.76, 49.401],
    [8.79, 49.401],
  ],
  { highway: "path", name: "S3 Rinne", difficulty: "S3", surface: "ground" },
);
const destOnS3: [number, number] = [8.76, 49.401];
assert.equal(destLiesOnTrail(s3, destOnS3), true, "tap sits on the S3 line");
const mile = clipTrailLastMile({
  coords: s3.geometry.coordinates as [number, number][],
  from: [8.74, 49.398],
  to: destOnS3,
});
assert.ok(mile, "clips last mile toward the tap");
const mileLngs = mile!.coords.map((c) => c[0]);
assert.ok(Math.max(...mileLngs) < 8.765, "does not continue past the tap");
assert.ok(mile!.lastMileM < 2500, "last mile stays bounded");
assert.ok(mile!.join[0] > 8.73, "does not enter at the far western trailhead");

const detourGh: ClientRouteResult = {
  distanceM: 12000,
  durationS: 2400,
  geometry: {
    type: "LineString",
    coordinates: [
      [8.74, 49.398],
      [8.7, 49.41],
      [8.68, 49.42],
      [8.79, 49.42],
      [8.76, 49.401],
    ],
  },
  engine: "graphhopper",
  profile: "mtb_allmountain",
};
const skippedFull = applyCorridorTrailSnap({
  profile: "mtb_allmountain",
  from: [8.74, 49.398],
  to: destOnS3,
  route: detourGh,
  trails: [s3],
});
assert.equal(
  skippedFull.distanceM,
  12000,
  "does not splice the whole S3 into a GH detour (join not on engine)",
);

const efficientGh: ClientRouteResult = {
  distanceM: 2200,
  durationS: 480,
  geometry: {
    type: "LineString",
    coordinates: [
      [8.74, 49.398],
      [8.745, 49.399],
      [8.75, 49.4005],
      [8.76, 49.401],
    ],
  },
  engine: "graphhopper",
  profile: "mtb_allmountain",
};
const lastMileSnap = applyCorridorTrailSnap({
  profile: "mtb_allmountain",
  from: [8.74, 49.398],
  to: destOnS3,
  route: efficientGh,
  trails: [s3],
});
const snapLngs = (lastMileSnap.geometry.coordinates as [number, number][]).map(
  (c) => c[0],
);
assert.ok(Math.max(...snapLngs) < 8.765, "spliced last mile stops at the tap");

const trailLine: [number, number][] = [
  [8.7, 49.401],
  [8.73, 49.401],
  [8.76, 49.401],
];
const snappedVia = snapPointOntoTrails([8.73, 49.4014], [trailLine]);
assert.ok(Math.abs(snappedVia[1] - 49.401) < 0.0002, "via snaps onto trail");
const farVia = snapPointOntoTrails([8.73, 49.5], [trailLine]);
assert.equal(farVia[1], 49.5, "far via stays put");
assert.equal(viaMaySnapOntoTrail(), true, "unlabeled map tap may snap");
assert.equal(viaMaySnapOntoTrail("  "), true);
assert.equal(viaMaySnapOntoTrail("49.41, 8.69"), true, "coord label may snap");
assert.equal(
  viaMaySnapOntoTrail("Café am Markt, Heidelberg"),
  false,
  "named place stays put"
);

console.log("snapTrailCorridor.test.ts OK");
