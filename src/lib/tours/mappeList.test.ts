/**
 * npx tsx src/lib/tours/mappeList.test.ts
 */
import assert from "node:assert/strict";
import {
  applyElevBackfill,
  filterMappeQuery,
  mappeCardStatParts,
  mappeCardStats,
  mappeCollectionRestLine,
  mappeCollectionTrackCount,
  mappeCollectionTracks,
  mappeElevLooksInvented,
  mappeElevSpark,
  mappeFaceTag,
  mappeSourceChip,
  mappeStartAwayKm,
  mappeTrackClimbM,
  savedRouteHasTrack,
  savedRouteIsLoop,
  savedRouteNeedsElevBackfill,
  savedRouteTrackCoords,
  sortMappe,
} from "./mappeList";
import type { SavedRoute } from "@/types/route";

function route(
  id: string,
  name: string,
  savedAt: string,
  km: number,
  coords: number[][] = [],
  elevationM = 120,
  source: SavedRoute["source"] = "engine",
): SavedRoute {
  return {
    id,
    name,
    distanceKm: km,
    elevationM,
    durationMin: 40,
    savedAt,
    source,
    geometry:
      coords.length >= 2
        ? { type: "LineString", coordinates: coords }
        : undefined,
  };
}

const a = route("a", "Neckar", "2026-08-10T00:00:00.000Z", 16, [
  [8.6, 49.4],
  [8.7, 49.5],
]);
const b = route("b", "Alpenpass", "2026-08-16T00:00:00.000Z", 42);

assert.deepEqual(
  sortMappe([a, b], "recent").map((r) => r.id),
  ["b", "a"],
);
assert.deepEqual(
  sortMappe([a, b], "distance").map((r) => r.id),
  ["b", "a"],
);
assert.deepEqual(
  sortMappe([a, b], "name").map((r) => r.id),
  ["b", "a"],
);
assert.equal(filterMappeQuery([a, b], "neck").length, 1);
assert.equal(mappeCardStats(a), "16 km · 120 hm · 40 min");
assert.deepEqual(mappeCardStatParts(a), { km: "16 km", hm: "120 hm", min: "40 min" });
assert.equal(mappeCardStats(b), "");
assert.equal(mappeCardStatParts(b), null);
assert.equal(savedRouteHasTrack(a), true);
assert.equal(savedRouteHasTrack(b), false);
assert.equal(savedRouteTrackCoords(a).length, 2);
assert.equal(savedRouteTrackCoords(b).length, 0);
assert.deepEqual(
  savedRouteTrackCoords({
    ...a,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
    },
  }),
  [
    [8.6, 49.4, 110],
    [8.7, 49.5, 180],
  ],
);

const layered: SavedRoute = {
  ...b,
  layers: {
    tour: {
      type: "LineString",
      coordinates: [
        [8.1, 49.1],
        [8.2, 49.2],
      ],
    },
  },
};
assert.equal(savedRouteHasTrack(layered), true);
assert.equal(savedRouteTrackCoords(layered).length, 2);

const looped = route("c", "Schleife", "2026-08-18T00:00:00.000Z", 12.4, [
  [8.68, 49.4],
  [8.7, 49.41],
  [8.72, 49.4],
  [8.7, 49.39],
  [8.68, 49.4],
]);
assert.equal(savedRouteIsLoop(a), false);
assert.equal(savedRouteIsLoop(b), false);
assert.equal(savedRouteIsLoop(looped), true);
assert.equal(mappeCardStatParts(looped)?.km, "12.4 km");

assert.equal(
  mappeSourceChip("import", {
    import: "Import",
    planned: "Geplant",
    recorded: "Aufgezeichnet",
  }),
  "Import",
);
assert.equal(
  mappeSourceChip("engine", {
    import: "Import",
    planned: "Geplant",
    recorded: "Aufgezeichnet",
  }),
  null,
);
assert.equal(
  mappeSourceChip("recorded", {
    import: "Import",
    planned: "Geplant",
    recorded: "Aufgezeichnet",
  }),
  "Aufgezeichnet",
);
assert.equal(mappeFaceTag("S2"), "S2");
assert.equal(mappeFaceTag("import"), null);
assert.equal(mappeFaceTag("mixed/urban"), null);
assert.deepEqual(
  mappeElevSpark([
    [8.6, 49.4, 100],
    [8.61, 49.4, 110],
    [8.62, 49.4, 140],
    [8.63, 49.4, 130],
  ]),
  [0, 10 / 40, 1, 30 / 40],
);
assert.deepEqual(
  mappeElevSpark([
    [8.6, 49.4],
    [8.61, 49.4],
  ]),
  [],
);
assert.equal(
  mappeStartAwayKm(
    [
      [8.67, 49.4],
      [8.71, 49.41],
    ],
    49.4,
    8.67,
  ),
  null,
);
const far = mappeStartAwayKm(
  [
    [8.67, 49.4],
    [8.71, 49.41],
  ],
  52.52,
  13.4,
);
assert.ok(far != null && far > 400);
assert.equal(mappeStartAwayKm([], 49.4, 8.67), null);

const stacked = mappeCollectionTracks(
  ["b", "a"],
  [a, b],
);
assert.equal(stacked.length, 1);
assert.equal(stacked[0]![0]![0], 8.6);
assert.equal(mappeCollectionTrackCount(["b", "a"], [a, b]), 1);

const zeroHm = route(
  "flat",
  "Flach",
  "2026-08-18T00:00:00.000Z",
  16,
  [
    [8.6, 49.4],
    [8.7, 49.5],
  ],
  0,
);
assert.equal(mappeCardStats(zeroHm), "16 km · 40 min");
assert.equal(mappeCardStatParts(zeroHm)?.hm, null);
assert.equal(
  mappeCardStatParts(
    route(
      "absurd",
      "Steil",
      "2026-08-18T00:00:00.000Z",
      16,
      [
        [8.6, 49.4],
        [8.7, 49.5],
      ],
      1670,
    ),
  )?.hm,
  null,
);

assert.equal(savedRouteNeedsElevBackfill(a), true);
assert.equal(
  savedRouteNeedsElevBackfill({
    ...a,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
    },
  }),
  false,
);
const kept = applyElevBackfill(
  a,
  [
    [8.6, 49.4, 110],
    [8.7, 49.5, 180],
  ],
  70,
);
assert.equal(kept?.elevationM, 120);
assert.equal(kept?.geometry?.coordinates?.[0]?.[2], 110);
const filled = applyElevBackfill(
  zeroHm,
  [
    [8.6, 49.4, 110],
    [8.7, 49.5, 180],
  ],
  70,
);
assert.equal(filled?.elevationM, 70);
assert.equal(
  applyElevBackfill(
    a,
    [
      [8.6, 49.4],
      [8.7, 49.5],
    ],
    70,
  ),
  null,
);
const layerPatch = applyElevBackfill(
  {
    ...b,
    layers: {
      tour: {
        type: "LineString",
        coordinates: [
          [8.1, 49.1],
          [8.2, 49.2],
        ],
      },
    },
  },
  [
    [8.1, 49.1, 90],
    [8.2, 49.2, 140],
  ],
  50,
);
assert.equal(layerPatch?.layers?.tour?.coordinates?.[0]?.[2], 90);

const invented = route(
  "pct",
  "Formel",
  "2026-08-18T00:00:00.000Z",
  16,
  [
    [8.6, 49.4],
    [8.7, 49.5],
  ],
  480,
);
assert.equal(mappeElevLooksInvented(480, 16), true);
assert.equal(mappeElevLooksInvented(480, 16, { source: "suggestion" }), false);
assert.equal(
  mappeElevLooksInvented(480, 16, { source: "import", hasRealElev: true }),
  false,
);
assert.equal(mappeElevLooksInvented(480, 16, { source: "import" }), true);
assert.equal(mappeElevLooksInvented(480, 16, { source: "recorded" }), false);
assert.equal(mappeCardStatParts(invented)?.hm, null);
assert.equal(
  applyElevBackfill(
    invented,
    [
      [8.6, 49.4, 110],
      [8.7, 49.5, 180],
    ],
    70,
  )?.elevationM,
  70,
);
assert.equal(
  mappeTrackClimbM([
    [8.6, 49.4, 110],
    [8.7, 49.5, 180],
  ]),
  70,
);
assert.equal(
  savedRouteNeedsElevBackfill(
    route(
      "pct-ele",
      "Formel mit ele",
      "2026-08-18T00:00:00.000Z",
      16,
      [
        [8.6, 49.4, 110],
        [8.7, 49.5, 180],
      ],
      480,
    ),
  ),
  true,
);

const catalog = route(
  "cat",
  "Katalog",
  "2026-08-18T00:00:00.000Z",
  16,
  [
    [8.6, 49.4],
    [8.7, 49.5],
  ],
  480,
  "suggestion",
);
assert.equal(mappeCardStatParts(catalog)?.hm, "480 hm");
assert.equal(
  applyElevBackfill(
    catalog,
    [
      [8.6, 49.4, 110],
      [8.7, 49.5, 180],
    ],
    70,
  )?.elevationM,
  480,
);
assert.equal(mappeCollectionRestLine("5 Touren", 2), "5 Touren · +2");
assert.equal(mappeCollectionRestLine("2 Touren", 0), "2 Touren");

console.log("mappeList.test.ts ok");
