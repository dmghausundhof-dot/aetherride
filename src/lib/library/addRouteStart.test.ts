/**
 * npx tsx src/lib/library/addRouteStart.test.ts
 */
import assert from "node:assert/strict";
import {
  isPlaceholderMapCenter,
  parseDiscoverViewport,
  resolveAddRouteStart,
  WEB_DISCOVER_FALLBACK,
} from "./addRouteStart";

const berlin: [number, number] = [13.4, 52.52];
const heidelbergLive: [number, number] = [8.694, 49.409];

assert.equal(resolveAddRouteStart({}), null);
assert.equal(resolveAddRouteStart({ gps: null, map: null }), null);

const gps = resolveAddRouteStart({ gps: berlin, map: [8.69, 49.41] });
assert.equal(gps?.source, "gps");
assert.deepEqual(gps?.lngLat, berlin);

const mapOnly = resolveAddRouteStart({ map: berlin });
assert.equal(mapOnly?.source, "map");
assert.deepEqual(mapOnly?.lngLat, berlin);

assert.equal(
  resolveAddRouteStart({ map: WEB_DISCOVER_FALLBACK }),
  null,
  "Web-Kaltstart ist kein Startpin",
);
assert.equal(resolveAddRouteStart({ map: [6.5, 47.2] }), null);
assert.ok(isPlaceholderMapCenter(WEB_DISCOVER_FALLBACK));

const liveHd = resolveAddRouteStart({ gps: heidelbergLive });
assert.equal(liveHd?.source, "gps");
assert.deepEqual(liveHd?.lngLat, heidelbergLive);

assert.equal(parseDiscoverViewport({ lat: 52.52, lng: 13.4, zoom: 5 }), null);
const vp = parseDiscoverViewport({ lat: 52.52, lng: 13.4, zoom: 12 });
assert.equal(vp?.lat, 52.52);
assert.equal(vp?.lng, 13.4);
assert.equal(
  parseDiscoverViewport({
    lat: WEB_DISCOVER_FALLBACK[1],
    lng: WEB_DISCOVER_FALLBACK[0],
    zoom: 13,
  }),
  null,
);

assert.equal(resolveAddRouteStart({ gps: [200, 91] }), null);

console.log("addRouteStart.test.ts OK");
