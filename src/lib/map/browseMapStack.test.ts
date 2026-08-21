/**
 * npx tsx src/lib/map/browseMapStack.test.ts
 */
import assert from "node:assert/strict";
import {
  BROWSE_LIVE_STACK_BOTTOM_TO_TOP,
  BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP,
  browseNetworkBeforeLayerId,
  browseNetworkBeforeLayerIdFromGet,
  browseNetworkSitsBelowLabels,
  browseStackOrderOk,
} from "./browseMapStack";
import { addBikeOverlayLayers, BIKE_OVERLAY_LAYER_IDS } from "../routing/bikeOverlayMap";
import { BIKE_OVERLAY_COLORS } from "../routing/bikeOverlayClass";

assert.equal(browseNetworkBeforeLayerId(["roads", "pois", "places"]), "pois");
assert.equal(browseNetworkBeforeLayerId(["roads", "places"]), "places");
assert.equal(browseNetworkBeforeLayerId(["background", "roads"]), undefined);
assert.equal(
  browseNetworkBeforeLayerIdFromGet((id) => (id === "transportation_name" ? {} : undefined)),
  "transportation_name"
);

const stacked = [
  "background",
  "earth",
  "roads",
  ...BROWSE_LIVE_STACK_BOTTOM_TO_TOP,
  ...BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP,
  "pois",
  "places",
];
assert.ok(browseNetworkSitsBelowLabels(stacked));
assert.ok(
  browseStackOrderOk(stacked, [
    ...BROWSE_LIVE_STACK_BOTTOM_TO_TOP,
    ...BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP,
  ])
);

const pathsOnTop = [
  "roads",
  "osm-live-cycleway",
  "osm-live-path",
  "pois",
];
assert.equal(
  browseStackOrderOk(pathsOnTop, BROWSE_LIVE_STACK_BOTTOM_TO_TOP),
  false,
  "paths must not sit above cycleways"
);

const overlayOnLabels = [
  "roads",
  "pois",
  "bike-overlay-mtb-unrated",
  "bike-overlay-road",
];
assert.equal(browseNetworkSitsBelowLabels(overlayOnLabels), false);

assert.equal(BIKE_OVERLAY_COLORS.unrated, "#2E7D32");
assert.equal(BIKE_OVERLAY_COLORS.dirt, "#2E7D32");
assert.equal(BIKE_OVERLAY_COLORS.road, "#1565C0");
assert.equal(BIKE_OVERLAY_COLORS.urban, "#1565C0");
assert.notEqual(BIKE_OVERLAY_COLORS.unrated, "#90A4AE");

const added: { id: string; before?: string }[] = [];
const existing = new Set(["background", "roads", "pois", "places"]);
addBikeOverlayLayers(
  {
    getSource: () => undefined,
    addSource: () => {},
    getLayer: (id) =>
      existing.has(id) || added.some((l) => l.id === id) ? {} : undefined,
    addLayer: (spec, before) => {
      const id = (spec as { id: string }).id;
      added.push({ id, before });
      existing.add(id);
    },
    setLayoutProperty: () => {},
    setPaintProperty: () => {},
    setFilter: () => {},
  },
  {
    url: "https://example.test/bike-overlay.pmtiles",
    kind: "pmtiles",
    family: "road",
    visible: true,
  }
);
assert.deepEqual(
  added.map((l) => l.id),
  [...BROWSE_OVERLAY_STACK_BOTTOM_TO_TOP]
);
assert.ok(added.every((l) => l.before === "pois"));
assert.equal(added[0].id, BIKE_OVERLAY_LAYER_IDS.mtb_unrated);
assert.equal(added[added.length - 1].id, BIKE_OVERLAY_LAYER_IDS.urban);

console.log("browseMapStack.test.ts OK");
