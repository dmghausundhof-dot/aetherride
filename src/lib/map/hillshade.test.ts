/**
 * npx tsx src/lib/map/hillshade.test.ts
 */
import assert from "node:assert/strict";
import {
  HILLSHADE_LAYER,
  HILLSHADE_LAYER_ID,
  HILLSHADE_SOURCE,
  HILLSHADE_SOURCE_ID,
  applyHillshade,
  hillshadeBeforeLayerId,
} from "./hillshade";

assert.equal(HILLSHADE_SOURCE.type, "raster-dem");
assert.equal(HILLSHADE_SOURCE.encoding, "terrarium");
assert.equal(HILLSHADE_LAYER.type, "hillshade");
assert.equal(HILLSHADE_LAYER.source, HILLSHADE_SOURCE_ID);

assert.equal(
  hillshadeBeforeLayerId((id) => (id === "roads" ? {} : undefined)),
  "roads"
);
assert.equal(
  hillshadeBeforeLayerId(() => undefined),
  undefined
);

const added: string[] = [];
const sources = new Set<string>(["protomaps"]);
const layers = new Set<string>();
applyHillshade({
  getSource: (id) => (sources.has(id) ? {} : undefined),
  addSource: (id) => {
    sources.add(id);
    added.push(`src:${id}`);
  },
  getLayer: (id) => (layers.has(id) ? {} : id === "roads" ? {} : undefined),
  addLayer: (_spec, before) => {
    layers.add(HILLSHADE_LAYER_ID);
    added.push(`layer:${before ?? "top"}`);
  },
});
assert.deepEqual(added, [`src:${HILLSHADE_SOURCE_ID}`, "layer:roads"]);

applyHillshade({
  getSource: () => undefined,
  addSource: () => {
    throw new Error("OSM fallback must not add DEM");
  },
  getLayer: () => undefined,
  addLayer: () => {
    throw new Error("OSM fallback must not add hillshade");
  },
});

applyHillshade({
  getSource: (id) =>
    id === HILLSHADE_SOURCE_ID || id === "protomaps" ? {} : undefined,
  addSource: () => {
    throw new Error("source already there");
  },
  getLayer: (id) => (id === HILLSHADE_LAYER_ID ? {} : undefined),
  addLayer: () => {
    throw new Error("layer already there");
  },
});

console.log("hillshade.test.ts ok");
