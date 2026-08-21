/**
 * npx tsx src/lib/routing/planDraft.pin.test.ts
 */
import assert from "node:assert/strict";
import {
  applyBrowseMapPin,
  discoverSelectedTourLine,
  emptyDraft,
  endOf,
  shouldHideDiscoverTourRibbon,
  startOf,
} from "./planDraft";

const gps: [number, number] = [8.69, 49.41];
const pin: [number, number] = [8.7, 49.4];

const labels = {
  startLabel: "Start (Karte)",
  endLabel: "Ziel (Karte)",
  myPosLabel: "Meine Position",
};

const withGps = applyBrowseMapPin(emptyDraft("gravel"), pin, {
  gps,
  ...labels,
});
assert.deepEqual(startOf(withGps), gps, "GPS is start");
assert.deepEqual(endOf(withGps), pin, "pin is dest");

const noGps = applyBrowseMapPin(emptyDraft("gravel"), pin, labels);
assert.equal(startOf(noGps), null, "without GPS the pin is not a field start");
assert.deepEqual(endOf(noGps), pin, "without GPS the pin is dest");

const noGpsAgain = applyBrowseMapPin(noGps, [8.71, 49.39], labels);
assert.equal(startOf(noGpsAgain), null, "second pin is not a field start");
assert.deepEqual(endOf(noGpsAgain), [8.71, 49.39], "second pin replaces dest");

const pickingStart = applyBrowseMapPin(emptyDraft("gravel"), pin, {
  gps,
  picking: "start",
  ...labels,
});
assert.deepEqual(startOf(pickingStart), pin, "explicit start pick keeps the pin");

assert.equal(
  shouldHideDiscoverTourRibbon({
    planning: true,
    hasStart: true,
    hasEnd: true,
  }),
  true
);
assert.equal(
  shouldHideDiscoverTourRibbon({
    planning: false,
    hasStart: true,
    hasEnd: true,
  }),
  true,
  "A–B hides leftover catalog ribbons even after leaving Planen"
);
assert.equal(
  shouldHideDiscoverTourRibbon({
    planning: false,
    hasStart: false,
    hasEnd: true,
  }),
  true,
  "dest-only pin hides leftover catalog ribbons"
);

const tourPreview: ReturnType<typeof emptyDraft> = {
  ...emptyDraft("gravel"),
  mode: "tour",
  waypoints: [
    { id: "start", role: "start", lngLat: [8.6, 49.3], label: "Tourstart" },
  ],
  computed: {
    distanceM: 12000,
    durationS: 2400,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.6, 49.3],
        [8.61, 49.31],
      ],
    },
    engine: "tour-adopt",
    profile: "gravel",
  },
  layers: {
    tour: {
      type: "LineString",
      coordinates: [
        [8.6, 49.3],
        [8.61, 49.31],
      ],
    },
  },
};
const afterTour = applyBrowseMapPin(tourPreview, pin, { gps, ...labels });
assert.deepEqual(startOf(afterTour), gps, "tour leftover: GPS is start");
assert.deepEqual(endOf(afterTour), pin, "tour leftover: pin is dest");
assert.equal(afterTour.computed, null, "drops leftover tour line");
assert.equal(afterTour.mode, "point_to_point");
assert.equal(afterTour.layers, undefined);

const adopted: ReturnType<typeof emptyDraft> = {
  ...emptyDraft("gravel"),
  waypoints: [
    { id: "start", role: "start", lngLat: [8.6, 49.3], label: "Tourstart" },
    { id: "end", role: "end", lngLat: [8.62, 49.32], label: "Tourende" },
  ],
  computed: {
    distanceM: 8000,
    durationS: 1600,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.6, 49.3],
        [8.62, 49.32],
      ],
    },
    engine: "tour-adopt",
    profile: "gravel",
  },
};
const afterAdopt = applyBrowseMapPin(adopted, pin, { gps, ...labels });
assert.deepEqual(startOf(afterAdopt), gps, "adopt leftover: GPS replaces tour start");
assert.deepEqual(endOf(afterAdopt), pin, "adopt leftover: pin replaces tour end");
assert.equal(afterAdopt.waypoints.filter((w) => w.role === "via").length, 0);

const liveAb: ReturnType<typeof emptyDraft> = {
  ...emptyDraft("gravel"),
  waypoints: [
    { id: "start", role: "start", lngLat: gps, label: "Ich" },
    { id: "end", role: "end", lngLat: [8.71, 49.41], label: "Alt" },
    { id: "via-1", role: "via", lngLat: [8.705, 49.405] },
  ],
  computed: {
    distanceM: 4000,
    durationS: 900,
    geometry: {
      type: "LineString",
      coordinates: [gps, [8.71, 49.41]],
    },
    engine: "graphhopper",
    profile: "gravel",
  },
};
const afterLive = applyBrowseMapPin(liveAb, pin, { gps, ...labels });
assert.deepEqual(startOf(afterLive), gps, "keeps GPS start");
assert.deepEqual(endOf(afterLive), pin, "long-press replaces dest, not via");
assert.equal(
  afterLive.waypoints.filter((w) => w.role === "via").length,
  0,
  "drops old vias when dest moves"
);
assert.equal(
  afterLive.computed?.engine,
  "graphhopper",
  "stale street line stays until the new dest route arrives"
);

const tourLine = {
  type: "LineString" as const,
  coordinates: [
    [8.6, 49.3],
    [8.61, 49.31],
  ],
};
assert.ok(
  discoverSelectedTourLine({
    draft: tourPreview,
    hideRibbon: true,
    previewing: true,
    cached: null,
  }),
  "plan sheet still keeps tour plates on the preview line"
);
assert.equal(
  discoverSelectedTourLine({
    draft: liveAb,
    hideRibbon: true,
    previewing: false,
    cached: tourLine,
  }),
  null,
  "live A–B does not inherit leftover seed plates"
);
assert.ok(
  discoverSelectedTourLine({
    draft: emptyDraft("gravel"),
    hideRibbon: false,
    previewing: false,
    cached: tourLine,
  }),
  "browse cache places plates when the ribbon is on"
);

console.log("planDraft.pin.test.ts OK");
