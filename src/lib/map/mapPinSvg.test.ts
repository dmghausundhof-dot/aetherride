/**
 * npx tsx src/lib/map/mapPinSvg.test.ts
 */
import assert from "node:assert/strict";
import {
  browseTourPinText,
  browseTourTimeLabel,
} from "./browseTourPinLabel";
import {
  MAP_TAP_AFTER_CAMERA_MS,
  mapClickAfterCameraGesture,
} from "./mapTapGesture";
import {
  compactFlowlineMarkSvg,
  coveragePlacePoiKind,
  mapPinAnchor,
  mapPinDisplaySize,
  mapPoiDisplaySize,
  mapPoiKindFromRaw,
  mapPinSvg,
  pinGlyphForCategory,
  PIN_OVAL_PATH,
  poiPinSrc,
  routePinSrc,
  resolveMapPinKind,
  routeChevronSvg,
  sportGlyphSvg,
} from "./mapPinSvg";
import {
  browsePoiPinText,
  placeTourPoiStops,
  poiFracFitsAlong,
  browseCoveragePinText,
} from "./tourPoiStops";

assert.equal(resolveMapPinKind("tour-abc"), "tour");
assert.equal(resolveMapPinKind("tour-pin"), "tour");
assert.equal(resolveMapPinKind("idea"), "tour");
assert.equal(resolveMapPinKind("meet-1"), "meet");
assert.equal(resolveMapPinKind("wp-1"), "drop");
assert.equal(resolveMapPinKind("wp-1", "tour"), "tour");

assert.equal(mapPinAnchor("tour"), "bottom");
assert.equal(mapPinAnchor("drop"), "bottom");
assert.equal(mapPinAnchor("meet"), "bottom");
assert.equal(mapPinAnchor("start"), "bottom");
assert.equal(mapPinAnchor("finish"), "bottom");
assert.equal(mapPinAnchor("via"), "center");

assert.equal(mapPinDisplaySize("tour").w, 36);

const mark = compactFlowlineMarkSvg();
assert.match(mark, /#E57532/);
assert.match(mark, /#818C7B/);
assert.match(mark, /#3A4046/);

const tour = mapPinSvg("tour", "#2A2E32");
assert.match(tour, /<svg /);
assert.ok(tour.includes(PIN_OVAL_PATH));
assert.match(tour, /#2A2E32/);
assert.match(tour, /#E57532/);
assert.match(tour, /translate\(18\.4 21\.5\)/);

const active = mapPinSvg("tour", "#FF6A00");
assert.match(active, /#FF6A00/);
assert.notEqual(active, tour);

const drop = mapPinSvg("drop", "#43A047");
assert.match(drop, /#43A047/);
assert.equal(drop.includes(PIN_OVAL_PATH), false);

const inject = mapPinSvg("tour", '"><script>');
assert.ok(!inject.includes("<script>"));
assert.match(inject, /#2A2E32/);

const start = mapPinSvg("start", "#2E7D32");
assert.ok(start.includes(PIN_OVAL_PATH));
assert.match(start, /M26 21\.2 L26 38\.8/);
assert.match(start, /feDropShadow/);
assert.equal(mapPinDisplaySize("start").w, 32);
assert.equal(mapPinDisplaySize("start").h, 40);
assert.equal(routePinSrc("start"), "/map/pins/pin-start.png");
assert.equal(routePinSrc("start", "#7A8B73"), "/map/pins/pin-start-out.png");

const finish = mapPinSvg("finish");
assert.equal(finish.includes("clipPath"), false);
assert.match(finish, /M25\.8 18\.2 H42\.8/);
assert.match(finish, /#FF6A00/);
assert.match(finish, /#F4F1EC/);
assert.equal(mapPinDisplaySize("finish").w, 32);
assert.equal(mapPinDisplaySize("finish").h, 40);
assert.equal(mapPinAnchor("finish"), "bottom");
assert.equal(mapPinDisplaySize("via").w, 30);
assert.equal(routePinSrc("finish"), "/map/pins/pin-finish.png");
assert.equal(routePinSrc("via"), "/map/pins/pin-via.png");
assert.equal(routePinSrc("meet"), "/map/pins/pin-meet.png");

const poiCafe = mapPinSvg("poi", "#2A2E32", "mark", "cafe");
const poiView = mapPinSvg("poi", "#2A2E32", "mark", "viewpoint");
assert.match(poiCafe, /#F4F1EC/);
assert.match(poiCafe, /#FF6A00/);
assert.match(poiCafe, /stroke-width="3.2"/);
assert.match(poiCafe, /#1A120C/);
assert.notEqual(poiCafe, poiView);
assert.equal(mapPinAnchor("poi"), "bottom");
assert.equal(mapPinDisplaySize("poi").w, 32);
assert.equal(mapPinDisplaySize("poi").h, 40);
assert.equal(mapPoiDisplaySize(false).w, 32);
assert.equal(mapPoiDisplaySize(true).w, 36);
assert.equal(poiPinSrc("place"), "/map/pins/poi.png");
assert.equal(poiPinSrc("cafe"), "/map/pins/poi-cafe.png");
assert.equal(mapPoiKindFromRaw("cafe"), "cafe");
assert.equal(mapPoiKindFromRaw("café"), "cafe");
assert.equal(mapPoiKindFromRaw("kultur"), "culture");
assert.equal(mapPoiKindFromRaw("Kultur"), "culture");
assert.equal(mapPoiKindFromRaw("Café"), "cafe");
assert.equal(mapPoiKindFromRaw("aussicht"), "viewpoint");
assert.equal(mapPoiKindFromRaw("see"), "water");
assert.equal(mapPoiKindFromRaw("bahn"), "transit");
assert.equal(mapPoiKindFromRaw("park"), "place");
assert.equal(coveragePlacePoiKind("cafe"), "cafe");
assert.equal(coveragePlacePoiKind("shop"), "place");
assert.equal(coveragePlacePoiKind("repair"), "place");
assert.equal(coveragePlacePoiKind("other"), null);
assert.equal(browsePoiPinText(2, "Café am Feld", 11), "2");
assert.equal(browsePoiPinText(2, "Café am Feld", 12), "2 · Café am Feld");
assert.equal(browseCoveragePinText("Neckarwiese", 11), "");
assert.equal(browseCoveragePinText("Neckarwiese", 12), "Neckarwiese");
assert.equal(
  browseCoveragePinText("Kiosk do Bairro / Café Bairro", 12),
  "Kiosk do Bair…"
);
const along = placeTourPoiStops({
  stops: [
    { id: "start-flag", atMin: 0, title: "Start", kind: "trailhead" },
    { id: "cafe-1", atMin: 20, title: "Café", kind: "cafe" },
  ],
  durationMin: 50,
  geometry: {
    type: "LineString",
    coordinates: [
      [13.4, 52.5],
      [13.45, 52.52],
    ],
  },
  zoom: 13,
  selectedId: "cafe-1",
});
assert.equal(along.length, 1);
assert.equal(along[0].id, "cafe-1");
assert.equal(along[0].poiKind, "cafe");
assert.equal(along[0].selected, true);
assert.equal(poiFracFitsAlong(0.04, []), false);
assert.equal(poiFracFitsAlong(0.5, [0.48]), false);
assert.equal(poiFracFitsAlong(0.5, [0.2]), true);
assert.equal(
  placeTourPoiStops({
    stops: [{ id: "near", atMin: 2, title: "Nah", kind: "cafe" }],
    durationMin: 50,
    geometry: {
      type: "LineString",
      coordinates: [
        [13.4, 52.5],
        [13.45, 52.52],
      ],
    },
    zoom: 13,
  }).length,
  0
);
assert.equal(
  placeTourPoiStops({
    stops: [{ id: "x", atMin: 10, title: "X", kind: "cafe" }],
    durationMin: 50,
    geometry: null,
    zoom: 13,
  }).length,
  0
);

const via = mapPinSvg("via", "#FF6A00");
assert.match(via, /#F4F1EC/);
assert.match(via, /#FF6A00/);

assert.equal(pinGlyphForCategory("mtb_am"), "mtb");
assert.equal(pinGlyphForCategory("emtb"), "emtb");
assert.equal(pinGlyphForCategory("gravel"), "gravel");
assert.equal(pinGlyphForCategory("etrekking"), "gravel");
assert.equal(pinGlyphForCategory("road"), "road");
assert.equal(pinGlyphForCategory("urban"), "urban");
assert.equal(pinGlyphForCategory("hiking"), "hike");
assert.equal(pinGlyphForCategory("dh"), "dh");
assert.equal(pinGlyphForCategory("unknown"), "mark");

const mtb = sportGlyphSvg("mtb");
assert.match(mtb, /cx="10"/);
assert.match(mtb, /cx="38"/);
assert.match(mtb, /#FF6A00/);
assert.match(mtb, /r="7"/);
const emtb = sportGlyphSvg("emtb");
assert.ok(emtb.length > mtb.length);
assert.match(emtb, /M28\.4 2\.2/);
const hike = sportGlyphSvg("hike");
assert.equal(hike.includes('cx="10"'), false);
assert.match(hike, /cx="22"/);
assert.match(hike, /M29\.4 3\.2/);
const road = sportGlyphSvg("road");
assert.match(road, /Q26\.4 4/);
const dh = sportGlyphSvg("dh");
assert.match(dh, /<rect /);

const tourMtb = mapPinSvg("tour", "#2A2E32", "mtb");
assert.notEqual(tourMtb, tour);
assert.match(tourMtb, /cx="10"/);
assert.match(tourMtb, /translate\(16\.6 19\.6\)/);
assert.equal(tourMtb.includes("<script>"), false);

assert.equal(browseTourTimeLabel(45), "45′");
assert.equal(browseTourTimeLabel(0), "");
assert.equal(
  browseTourPinText({ durationMin: 45, selected: false, zoom: 10 }),
  ""
);
assert.equal(
  browseTourPinText({ durationMin: 45, selected: false, zoom: 11 }),
  "45′"
);
assert.equal(
  browseTourPinText({
    durationMin: 45,
    selected: true,
    zoom: 12,
    name: "Neckarwiese",
  }),
  "45′"
);
assert.equal(
  browseTourPinText({
    durationMin: 45,
    selected: true,
    zoom: 13,
    name: "Neckarwiese",
  }),
  "45′ · Neckarwiese"
);
assert.equal(MAP_TAP_AFTER_CAMERA_MS, 280);
assert.equal(mapClickAfterCameraGesture(100, 200), true);
assert.equal(mapClickAfterCameraGesture(300, 200), false);

const chevron = routeChevronSvg();
assert.match(chevron, /<svg /);
assert.match(chevron, /M24 10/);
assert.match(chevron, /#FFFFFF/);

console.log("mapPinSvg ok");
