/**
 * npx tsx src/lib/routing/planDraft.edit.test.ts
 */
import assert from "node:assert/strict";
import {
  applyPlanMapLongPress,
  applyPlanMapTap,
  closeLoop,
  emptyDraft,
  endOf,
  insertViaAlong,
  isClosedLoop,
  moveWaypoint,
  setStart,
  setWaypoint,
  nextPlanSlot,
  orderedWaypoints,
  planDistanceTicks,
  planDistanceTickStepM,
  planElevSegmentSteep,
  planViaMapCaption,
  planLineSlice,
  planShapeRouteId,
  planSteepLineSlices,
  planSurfaceIsUnpaved,
  planSurfaceKind,
  planSurfaceLineSlices,
  fillShortFlagGaps,
  planUnpavedLineSlices,
  planElevScrubT,
  planFarTapInsertsVia,
  planEditorMapTapAddsVia,
  planLongPressSetsDest,
  planMapTapInsertsViaAlong,
  planReshapeHandles,
  planReshapeHandleStepM,
  joinPlanLineToPins,
  planRubberBandLngLat,
  planRibbonDimOpacity,
  planGrabHandleOpacity,
  planRibbonLegendKinds,
  planShapeKmChip,
  plannedRouteTapRadiusM,
  planDragAlongLabelKm,
  pushPlanUndo,
  shouldKeepStaleDiscoverLine,
  isPlanCustomizableLine,
  planLeftoverTourWipesOnTap,
  planBusyBlocksDestReplace,
  planRibbonAllowsGrab,
  planMapShowsRoutingWait,
  planMapHistoryFabsVisible,
  planWebStartInAppRequiresSave,
  planWebRideHandoffId,
  planDraftGeometryKey,
  planReuseSavedHandoffId,
  planMapAdaptingHintOnMap,
  planParkedFingerClearsWhenIdle,
  planMapHintAnchorLngLat,
  planMapDestWaitHintOnMap,
  planMapDestWaitCopy,
  planFingerHintChipW,
  planLineGrabYieldsToPinch,
  planLineGrabBecomesExclusive,
  planLineHoldCancelsOnMove,
  PLAN_LINE_HOLD_CANCEL_PX,
  PLAN_LINE_HOLD_MS,
  PLAN_LINE_GRAB_MOVE_PX,
  planLineCoachCopy,
  planLineCoachIsCompact,
  planLineCoachIsXCompact,
  planRibbonLegendCompact,
  planChevronIconOpacity,
  PLAN_RIBBON_GRAB_HALO_WIDTH,
  applyFarmTrimPinSnap,
  snapPlanPinToStreetLine,
  planLineCoachShouldShow,
  planEditorSheetMaxVh,
  planEditorSheetRecedes,
  planMapStopHintVisible,
  PLAN_STOP_HINT_MS,
  planFingerHintPlacement,
  viasOf,
  reorderWaypoints,
  startOf,
  swapStartEnd,
} from "./planDraft";

const a: [number, number] = [8.67, 49.4];
const b: [number, number] = [8.71, 49.41];
const c: [number, number] = [8.69, 49.405];
const d: [number, number] = [8.7, 49.408];

function draftAB() {
  return {
    ...emptyDraft("gravel"),
    waypoints: [
      { id: "start", role: "start" as const, lngLat: a, label: "A" },
      { id: "end", role: "end" as const, lngLat: b, label: "B" },
    ],
  };
}

const labels = {
  startLabel: "Start",
  endLabel: "Ziel",
  myPosLabel: "Ich",
};

assert.equal(nextPlanSlot(emptyDraft("gravel")), "start");
assert.equal(nextPlanSlot(draftAB()), "via");
assert.equal(
  nextPlanSlot(setStart(emptyDraft("gravel"), [8.68, 49.4], "A")),
  "end"
);

const swapped = swapStartEnd(draftAB());
assert.deepEqual(startOf(swapped), b);
assert.deepEqual(endOf(swapped), a);
assert.equal(swapped.waypoints[0]?.label, "B");

const withVia = {
  ...draftAB(),
  waypoints: [
    { id: "start", role: "start" as const, lngLat: a, label: "A" },
    { id: "via-1", role: "via" as const, lngLat: c, label: "Café" },
    { id: "via-2", role: "via" as const, lngLat: d, label: "Quelle" },
    { id: "end", role: "end" as const, lngLat: b, label: "B" },
  ],
};
const swappedVias = swapStartEnd(withVia);
assert.deepEqual(
  swappedVias.waypoints.filter((w) => w.role === "via").map((w) => w.label),
  ["Quelle", "Café"],
  "swap reverses via order"
);

const looped = closeLoop(draftAB(), "Start");
assert.deepEqual(endOf(looped), a);
assert.equal(isClosedLoop(looped), true);
assert.equal(isClosedLoop(draftAB()), false);

const moved = moveWaypoint(draftAB(), "end", c);
assert.deepEqual(endOf(moved), c);
assert.equal(moved.computed, null);

const named = setWaypoint(draftAB(), "end", c, "Markt");
assert.deepEqual(endOf(named), c);
assert.equal(named.waypoints.find((w) => w.role === "end")?.label, "Markt");

const reordered = reorderWaypoints(withVia, 1, 2);
assert.deepEqual(
  orderedWaypoints(reordered).map((w) => w.label),
  ["A", "Quelle", "Café", "B"]
);

const startToEnd = reorderWaypoints(draftAB(), 0, 1);
assert.deepEqual(startOf(startToEnd), b);
assert.deepEqual(endOf(startToEnd), a);

const line: [number, number][] = [a, c, d, b];
const inserted = insertViaAlong(draftAB(), [8.69, 49.406], { line, label: "Mitte" });
assert.equal(inserted.waypoints.filter((w) => w.role === "via").length, 1);
assert.equal(inserted.waypoints.find((w) => w.role === "via")?.label, "Mitte");

const firstTap = applyPlanMapTap(emptyDraft("gravel"), b, {
  gps: a,
  ...labels,
});
assert.deepEqual(startOf(firstTap), a, "GPS is start");
assert.deepEqual(endOf(firstTap), b, "first tap is dest");

const second = applyPlanMapTap(firstTap, c, labels);
assert.equal(
  second.waypoints.filter((w) => w.role === "via").length,
  1,
  "second far tap after A+B inserts a via"
);
assert.deepEqual(startOf(second), a);
assert.deepEqual(endOf(second), b, "dest stays; long-press replaces dest");

const viaPick = applyPlanMapTap(firstTap, c, {
  ...labels,
  picking: "via",
});
assert.equal(viaPick.waypoints.filter((w) => w.role === "via").length, 1);

const alongTap = applyPlanMapTap(firstTap, c, {
  ...labels,
  line,
});
assert.equal(
  alongTap.waypoints.filter((w) => w.role === "via").length,
  1,
  "tap near the line inserts a via"
);
assert.deepEqual(endOf(alongTap), b, "dest stays when shaping the line");

const farTap = applyPlanMapTap(firstTap, [8.5, 49.2], {
  ...labels,
  line,
});
assert.equal(
  farTap.waypoints.filter((w) => w.role === "via").length,
  1,
  "far tap with a live line inserts a via through that point"
);
assert.deepEqual(endOf(farTap), b, "dest stays when including a far point");

const pickEnd = applyPlanMapTap(firstTap, [8.5, 49.2], {
  ...labels,
  line,
  picking: "end",
});
assert.equal(pickEnd.waypoints.filter((w) => w.role === "via").length, 0);
assert.deepEqual(endOf(pickEnd), [8.5, 49.2], "pick-end still sets dest");

const altDest = applyPlanMapTap(alongTap, [8.5, 49.2], {
  ...labels,
  line,
  forceEnd: true,
});
assert.deepEqual(endOf(altDest), [8.5, 49.2], "alt/hold sets dest");
assert.equal(
  altDest.waypoints.filter((w) => w.role === "via").length,
  1,
  "alt dest keeps vias"
);

const holdDest = applyPlanMapLongPress(alongTap, [8.5, 49.2], {
  ...labels,
  line,
});
assert.deepEqual(endOf(holdDest), [8.5, 49.2], "long-press far sets dest");
assert.equal(
  holdDest.waypoints.filter((w) => w.role === "via").length,
  1,
  "long-press dest keeps vias"
);

const holdOnLine = applyPlanMapLongPress(alongTap, c, { ...labels, line });
assert.deepEqual(endOf(holdOnLine), c, "hold on painted line is dest, not via");
assert.equal(
  holdOnLine.waypoints.filter((w) => w.role === "via").length,
  1,
  "hold on line keeps existing vias"
);

assert.equal(
  planFarTapInsertsVia({
    hasStart: true,
    hasEnd: true,
    hasLiveLine: true,
  }),
  true
);
assert.equal(
  planFarTapInsertsVia({
    hasStart: true,
    hasEnd: true,
    hasLiveLine: false,
  }),
  true,
  "A+B is enough — waiting on the engine still inserts via"
);
assert.equal(
  planEditorMapTapAddsVia({
    editorActive: true,
    hasStart: true,
    hasEnd: true,
    pickingStartOrEnd: false,
  }),
  true
);
assert.equal(
  planEditorMapTapAddsVia({
    editorActive: true,
    hasStart: true,
    hasEnd: true,
    pickingStartOrEnd: true,
  }),
  false
);
assert.equal(
  planLongPressSetsDest({
    hasStart: true,
    hasEnd: true,
    tapHitsLine: true,
  }),
  true,
  "hold sets dest even on the painted line"
);
assert.equal(
  holdOnLine.waypoints.filter((w) => w.role === "via").length,
  1,
  "hold on line keeps existing vias"
);

const band = planRubberBandLngLat({
  start: a,
  end: b,
  vias: [],
  finger: [8.69, 49.42],
  line,
  dragging: "line",
});
assert.equal(band.length, 3);
assert.deepEqual(band[1], [8.69, 49.42]);

const startBand = planRubberBandLngLat({
  start: a,
  end: b,
  vias: [],
  finger: [8.66, 49.39],
  line,
  dragging: "start",
});
assert.equal(startBand.length, 2);
assert.deepEqual(startBand[0], [8.66, 49.39]);

const keepLine: [number, number][] = [
  [8.6, 49.4],
  [8.62, 49.401],
  [8.64, 49.402],
  [8.66, 49.403],
  [8.68, 49.404],
  [8.7, 49.405],
  [8.72, 49.406],
];
const keepVia: [number, number] = [8.66, 49.403];
const keepBand = planRubberBandLngLat({
  start: keepLine[0]!,
  end: keepLine[keepLine.length - 1]!,
  vias: [keepVia],
  finger: [8.69, 49.42],
  line: keepLine,
  dragging: "line",
});
assert.ok(keepBand.length > 3, "kept street geometry plus rubber span");
assert.ok(keepBand.some((p) => p[0] === 8.69 && p[1] === 49.42));
assert.deepEqual(keepBand[0], keepLine[0]);
assert.deepEqual(keepBand[keepBand.length - 1], keepLine[keepLine.length - 1]);
assert.ok(
  keepBand.some((p) => p[0] === 8.62 && p[1] === 49.401),
  "head before the via stays on the live line"
);

const keepStart = planRubberBandLngLat({
  start: keepLine[0]!,
  end: keepLine[keepLine.length - 1]!,
  vias: [keepVia],
  finger: [8.59, 49.39],
  line: keepLine,
  dragging: "start",
});
assert.deepEqual(keepStart[0], [8.59, 49.39]);
assert.ok(keepStart.length > 2);
assert.deepEqual(keepStart[keepStart.length - 1], keepLine[keepLine.length - 1]);

assert.ok(plannedRouteTapRadiusM(18) <= 28.01);
assert.ok(plannedRouteTapRadiusM(9) >= 199);

const lineHit = applyPlanMapTap(firstTap, [8.5, 49.2], {
  ...labels,
  line,
  lineHit: true,
});
assert.equal(
  lineHit.waypoints.filter((w) => w.role === "via").length,
  1,
  "visual line hit inserts a via even if the pin is coarse"
);

assert.equal(planShapeRouteId("active"), true);
assert.equal(planShapeRouteId("alt-1"), false);
assert.equal(planShapeRouteId("steep-0"), true);
assert.equal(planShapeRouteId("unpaved-1"), true);
assert.equal(planShapeRouteId("paved-0"), true);
assert.equal(planShapeRouteId("gravel-2"), true);
assert.equal(
  planMapTapInsertsViaAlong({
    hasStart: true,
    hasEnd: true,
    crossTrackM: 40,
  }),
  true
);
assert.equal(
  planMapTapInsertsViaAlong({
    hasStart: true,
    hasEnd: true,
    picking: "end",
    crossTrackM: 10,
  }),
  false
);

const longLine: [number, number][] = [];
for (let i = 0; i <= 20; i++) longLine.push([8.67 + i * 0.01, 49.28 + i * 0.004]);
const handles = planReshapeHandles({ line: longLine, vias: [] });
assert.ok(handles.length >= 2, "reshape handles sit mid-route");
const blockedHandles = planReshapeHandles({
  line: longLine,
  vias: [[handles[0]!.lng, handles[0]!.lat]],
});
assert.equal(
  blockedHandles.some(
    (h) =>
      Math.abs(h.lat - handles[0]!.lat) < 1e-5 &&
      Math.abs(h.lng - handles[0]!.lng) < 1e-5
  ),
  false
);

const shortLine: [number, number][] = [
  [8.67, 49.4],
  [8.6735, 49.4025],
];
assert.ok(
  planReshapeHandles({ line: shortLine, vias: [] }).length >= 1,
  "short A–B still gets a midpoint handle"
);

const pinJoin = joinPlanLineToPins(
  [
    [8.6702, 49.4001],
    [8.69, 49.405],
    [8.7098, 49.4099],
  ],
  { start: [8.67, 49.4], end: [8.71, 49.41] }
);
assert.deepEqual(pinJoin[0], [8.67, 49.4]);
assert.deepEqual(pinJoin[pinJoin.length - 1], [8.71, 49.41]);
const farJoin = joinPlanLineToPins(
  [
    [8.6702, 49.4001],
    [8.69, 49.405],
  ],
  { start: [8.8, 49.5], end: [8.69, 49.405] }
);
assert.equal(farJoin[0][0], 8.6702, "far pin is not a crow-flies cut");

const farmStreet: [number, number] = [8.67, 49.4];
const farmPin: [number, number] = [8.6711, 49.4];
assert.deepEqual(
  snapPlanPinToStreetLine(farmPin, farmStreet),
  farmStreet,
  "farm-trim dest pin moves onto the street"
);
assert.equal(
  snapPlanPinToStreetLine([8.67005, 49.4], farmStreet),
  null,
  "tiny gap stays put"
);
assert.equal(
  snapPlanPinToStreetLine([8.70, 49.4], farmStreet),
  null,
  "kilometre-scale gap is not a street snap"
);
const farmSnap = applyFarmTrimPinSnap({
  start: [8.66, 49.39],
  end: farmPin,
  line: [[8.66, 49.39], farmStreet],
  warnings: ["Kein Weg bis zum Pin — Ziel liegt an der Straße."],
  startIsGps: true,
});
assert.equal(farmSnap.snappedStart, false, "GPS start stays");
assert.equal(farmSnap.snappedEnd, true);
assert.deepEqual(farmSnap.end, farmStreet);
assert.equal(
  applyFarmTrimPinSnap({
    start: farmStreet,
    end: farmPin,
    line: [[8.66, 49.39], farmStreet],
    warnings: [],
  }).snappedEnd,
  false,
  "no farm warning, no snap"
);

assert.equal(planLineCoachShouldShow(null), true);
assert.equal(planLineCoachShouldShow("1"), false);
assert.equal(planLineCoachShouldShow(String(Date.now())), false);
assert.equal(
  planLineCoachShouldShow(String(Date.now() - 15 * 86400000)),
  true
);
assert.equal(planEditorSheetMaxVh({ shaping: false }), 56);
assert.equal(planEditorSheetMaxVh({ shaping: true }), 0);
assert.equal(
  planEditorSheetRecedes({ rubberBand: true, adapting: false }),
  true
);
assert.equal(
  planEditorSheetRecedes({ rubberBand: false, adapting: true }),
  true
);
assert.equal(
  planEditorSheetRecedes({ rubberBand: false, adapting: false }),
  false
);
assert.equal(
  planMapStopHintVisible({
    hasStopAt: true,
    waitHintOnMap: false,
    rubberBand: false,
  }),
  true
);
assert.equal(
  planMapStopHintVisible({
    hasStopAt: true,
    waitHintOnMap: true,
    rubberBand: false,
  }),
  false
);
assert.equal(
  planMapStopHintVisible({
    hasStopAt: true,
    waitHintOnMap: false,
    rubberBand: true,
  }),
  false
);
assert.equal(PLAN_STOP_HINT_MS, 3200);
{
  const mid = planFingerHintPlacement({
    fingerX: 180,
    fingerY: 200,
    mapW: 360,
    mapH: 640,
    chipW: 176,
    chipH: 40,
  });
  assert.equal(mid.left, 180 - 88);
  assert.equal(mid.top, 200 + 16);
  const br = planFingerHintPlacement({
    fingerX: 340,
    fingerY: 600,
    mapW: 360,
    mapH: 640,
    chipW: 176,
    chipH: 40,
    avoidRight: 56,
  });
  assert.ok(br.left + 176 <= 360 - 8 - 56);
  assert.ok(br.top < 600, "chip flips above a low finger");
  const above = planFingerHintPlacement({
    fingerX: 180,
    fingerY: 200,
    mapW: 360,
    mapH: 640,
    chipW: 244,
    chipH: 40,
    preferAbove: true,
  });
  assert.equal(above.top, 200 - 40 - 12);
  assert.equal(planFingerHintChipW({ undo: false, firstAb: false }), 176);
  assert.equal(planFingerHintChipW({ undo: true, firstAb: false }), 228);
  assert.equal(planFingerHintChipW({ undo: false, firstAb: true }), 244);
  assert.equal(planFingerHintChipW({ undo: true, firstAb: true }), 280);
}

const tickLine: [number, number][] = [];
for (let i = 0; i <= 40; i++) tickLine.push([8.67 + i * 0.012, 49.28]);
const ticks = planDistanceTicks({ line: tickLine, zoom: 14 });
assert.ok(ticks.length >= 1, "distance ticks on a long line");
assert.equal(planDistanceTicks({ line: tickLine, zoom: 10 }).length, 0);
const sparseTicks = planDistanceTicks({ line: tickLine, zoom: 12 });
const denseTicks = planDistanceTicks({ line: tickLine, zoom: 16 });
assert.ok(denseTicks.length > sparseTicks.length, "ticks denser when zoomed in");
assert.equal(planDistanceTickStepM(12), 5000);
assert.equal(planDistanceTickStepM(16), 1000);
assert.equal(planViaMapCaption("Café König"), "Café König");
assert.equal(planViaMapCaption("Punkt auf der Karte"), null);
assert.equal(planViaMapCaption("Via 1"), null);

assert.equal(
  planElevSegmentSteep({ fromM: 100, toM: 120, distM: 100 }),
  true
);
assert.equal(
  planElevSegmentSteep({ fromM: 100, toM: 101, distM: 100 }),
  false
);

assert.equal(planSurfaceIsUnpaved("gravel"), true);
assert.equal(planSurfaceIsUnpaved("asphalt"), false);
assert.equal(planSurfaceKind("asphalt"), "asphalt");
assert.equal(planSurfaceKind("fine_gravel"), "gravel");
assert.equal(planSurfaceKind("dirt"), "trail");
assert.equal(planSurfaceKind("xyz"), null);

const gradeLine: [number, number][] = [];
for (let i = 0; i <= 12; i++) gradeLine.push([8.67 + i * 0.008, 49.4]);
const steepElev = gradeLine.map((_, i) => (i >= 4 && i <= 7 ? 100 + (i - 4) * 80 : 100));
const steepSlices = planSteepLineSlices({ line: gradeLine, elevM: steepElev });
assert.ok(steepSlices.length >= 1, "steep ribbon slices from grade");
assert.ok(steepSlices.every((s) => s.length >= 2));

const mid = planLineSlice(gradeLine, 400, 1200);
assert.ok(mid.length >= 2, "line slice keeps geometry");
const unpaved = planUnpavedLineSlices({
  line: gradeLine,
  bands: [{ fromKm: 0.4, toKm: 1.6, surface: "gravel" }],
});
assert.ok(unpaved.length >= 1, "unpaved ribbon from surface band");
const mixedSurf = planSurfaceLineSlices({
  line: gradeLine,
  bands: [
    { fromKm: 0, toKm: 0.8, surface: "asphalt" },
    { fromKm: 0.8, toKm: 1.6, surface: "gravel" },
    { fromKm: 1.6, toKm: 2.4, surface: "dirt" },
  ],
});
assert.ok(mixedSurf.some((s) => s.kind === "asphalt"));
assert.ok(mixedSurf.some((s) => s.kind === "gravel"));
assert.ok(mixedSurf.some((s) => s.kind === "trail"));

const bridged = planSurfaceLineSlices({
  line: gradeLine,
  bands: [
    { fromKm: 0, toKm: 0.4, surface: "asphalt" },
    { fromKm: 0.4, toKm: 0.46, surface: null },
    { fromKm: 0.46, toKm: 1.2, surface: "asphalt" },
  ],
});
assert.equal(bridged.length, 1, "short unknown OSM gap stays one asphalt band");
assert.equal(bridged[0]?.kind, "asphalt");
assert.equal(planElevScrubT(500, 2000), 0.25);
assert.equal(planElevScrubT(0, 0), null);

const gapFlags = [true, false, true];
fillShortFlagGaps(gapFlags, [0, 20, 50, 90], 80);
assert.deepEqual(gapFlags, [true, true, true], "short steep gaps merge");
const keepGap = [true, false, true];
fillShortFlagGaps(keepGap, [0, 20, 200, 240], 80);
assert.deepEqual(keepGap, [true, false, true], "long flats stay unmerged");

const undone = pushPlanUndo([], draftAB(), alongTap);
assert.equal(undone.length, 1);
assert.equal(pushPlanUndo(undone, alongTap, alongTap).length, 1, "no-op skip");

const noGpsFirst = applyPlanMapTap(emptyDraft("gravel"), a, labels);
assert.equal(startOf(noGpsFirst), null, "without GPS the pin is not a field start");
assert.deepEqual(endOf(noGpsFirst), a, "without GPS the pin is dest");

const withIdentity = setStart(
  {
    ...draftAB(),
    computed: {
      distanceM: 12000,
      durationS: 2400,
      geometry: { type: "LineString", coordinates: line },
      engine: "test",
      profile: "gravel",
    },
    baseTour: {
      id: "t1",
      name: "Odenwald",
      provider: "seed",
      geometry: { type: "LineString", coordinates: line },
      distanceKm: 42,
      durationMin: 140,
      elevationM: 780,
      loop: true,
      surface: "gravel",
    },
  },
  c
);
assert.equal(withIdentity.computed, null);
assert.equal(withIdentity.baseTour?.name, "Odenwald", "adapt identity survives pin edits");
assert.equal(withIdentity.baseTour?.geometry, null);

const liveAb = {
  ...draftAB(),
  computed: {
    distanceM: 5000,
    durationS: 900,
    geometry: { type: "LineString" as const, coordinates: line },
    engine: "graphhopper",
    profile: "gravel" as const,
  },
};
const viaKept = insertViaAlong(liveAb, [8.69, 49.406], { line, label: "Mitte" });
assert.equal(viaKept.computed?.engine, "graphhopper", "stale street line stays on via insert");
const destKept = applyPlanMapTap(liveAb, [8.5, 49.2], labels);
assert.equal(destKept.computed?.engine, "graphhopper", "far dest replace keeps stale line");
assert.equal(
  shouldKeepStaleDiscoverLine({
    leftoverTourRibbon: false,
    liveStreetCoordinateCount: 4,
    engine: "graphhopper",
  }),
  true
);
assert.equal(
  shouldKeepStaleDiscoverLine({
    leftoverTourRibbon: true,
    liveStreetCoordinateCount: 4,
    engine: "graphhopper",
  }),
  false
);

assert.equal(
  isPlanCustomizableLine({ engine: "tour-adopt", coordinateCount: 4 }),
  true
);
assert.equal(
  isPlanCustomizableLine({ engine: "tour-pin", coordinateCount: 4 }),
  false
);
assert.equal(
  planLeftoverTourWipesOnTap({ leftover: true, hasStart: true, hasEnd: true }),
  false
);
assert.equal(
  planLeftoverTourWipesOnTap({ leftover: true, hasStart: true, hasEnd: false }),
  true
);
assert.equal(
  planBusyBlocksDestReplace({ routingBusy: true, hasStart: true, hasEnd: true }),
  true
);
assert.equal(
  planBusyBlocksDestReplace({
    routingBusy: true,
    hasStart: true,
    hasEnd: true,
    forceEnd: true,
  }),
  false
);
assert.equal(
  planRibbonAllowsGrab({
    editorActive: true,
    hasLiveStreetLine: true,
    approx: false,
  }),
  true
);
assert.equal(
  planRibbonAllowsGrab({
    editorActive: true,
    hasLiveStreetLine: true,
    approx: true,
  }),
  false
);
assert.ok(PLAN_RIBBON_GRAB_HALO_WIDTH >= 28);
assert.equal(
  planMapShowsRoutingWait({
    editorActive: true,
    routingBusy: true,
    hasStart: true,
    hasEnd: true,
  }),
  true
);
assert.equal(
  planMapShowsRoutingWait({
    editorActive: true,
    routingBusy: false,
    hasStart: true,
    hasEnd: true,
  }),
  false
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: true,
    mapHintOnMap: false,
    rubberBand: false,
    coachVisible: false,
  }),
  true,
  "idle plan shows history FABs"
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: true,
    mapHintOnMap: true,
    rubberBand: false,
    coachVisible: false,
  }),
  false,
  "stop/wait chip owns Undo — hide FABs"
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: true,
    mapHintOnMap: false,
    rubberBand: true,
    coachVisible: false,
  }),
  false,
  "rubber-band hides FABs"
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: true,
    mapHintOnMap: false,
    rubberBand: false,
    coachVisible: true,
  }),
  false,
  "coach hides FABs"
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: true,
    mapHintOnMap: false,
    rubberBand: false,
    coachVisible: false,
    routingWaitBanner: true,
  }),
  false,
  "routing-wait banner hides FABs"
);
assert.equal(
  planMapHistoryFabsVisible({
    editorActive: true,
    hasHistory: false,
    mapHintOnMap: false,
    rubberBand: false,
    coachVisible: false,
  }),
  false
);
assert.equal(
  planWebStartInAppRequiresSave({ hasComputed: true }),
  true
);
assert.equal(
  planWebStartInAppRequiresSave({ hasComputed: false }),
  false
);
assert.equal(
  planWebStartInAppRequiresSave({ hasComputed: true, asGroup: true }),
  false,
  "group-create leaves Discover — no ride bridge"
);
assert.equal(planWebRideHandoffId("saved-1"), "saved-1");
assert.equal(planWebRideHandoffId("engine-99"), null);
assert.equal(planWebRideHandoffId(null), null);
{
  const key = planDraftGeometryKey({
    coordinates: [
      [8.1, 49.1],
      [8.2, 49.2],
      [8.3, 49.3],
    ],
    viaCount: 1,
    distanceM: 1234.6,
  });
  assert.ok(key);
  assert.equal(
    planDraftGeometryKey({
      coordinates: [
        [8.1, 49.1],
        [8.2, 49.2],
        [8.3, 49.3],
      ],
      viaCount: 1,
      distanceM: 1234.6,
    }),
    key
  );
  assert.notEqual(
    planDraftGeometryKey({
      coordinates: [
        [8.1, 49.1],
        [8.2, 49.2],
        [8.3, 49.3],
      ],
      viaCount: 2,
      distanceM: 1234.6,
    }),
    key
  );
  assert.equal(
    planReuseSavedHandoffId({
      lastSavedId: "saved-9",
      lastSavedGeomKey: key,
      currentGeomKey: key,
    }),
    "saved-9"
  );
  assert.equal(
    planReuseSavedHandoffId({
      lastSavedId: "saved-9",
      lastSavedGeomKey: key,
      currentGeomKey: key + "|x",
    }),
    null
  );
  assert.equal(
    planReuseSavedHandoffId({
      lastSavedId: "engine-1",
      lastSavedGeomKey: key,
      currentGeomKey: key,
    }),
    null
  );
}
assert.equal(
  planParkedFingerClearsWhenIdle(true),
  false,
  "keep parked finger while reshape is in flight"
);
assert.equal(
  planParkedFingerClearsWhenIdle(false),
  true,
  "drop parked finger when engine is idle"
);
assert.deepEqual(
  planMapHintAnchorLngLat({
    adaptingAt: [8.7, 49.4],
    parkedFinger: [8.1, 49.1],
  }),
  [8.7, 49.4],
  "dest/stop pin wins over parked reshape finger"
);
assert.deepEqual(
  planMapHintAnchorLngLat({
    adaptingAt: null,
    parkedFinger: [8.1, 49.1],
  }),
  [8.1, 49.1],
  "finger adapting uses parked point"
);
assert.equal(
  planMapHintAnchorLngLat({
    adaptingAt: null,
    parkedFinger: null,
  }),
  null
);
assert.equal(
  planMapAdaptingHintOnMap({
    routingBusy: true,
    hasLiveLine: true,
    hasFinger: true,
  }),
  true
);
assert.equal(
  planMapAdaptingHintOnMap({
    routingBusy: true,
    hasLiveLine: true,
    hasFinger: false,
  }),
  false,
  "without parked finger, dest-wait owns the chip"
);

const adoptedDraft = {
  ...draftAB(),
  computed: {
    distanceM: 12000,
    durationS: 2400,
    geometry: { type: "LineString" as const, coordinates: line },
    engine: "tour-adopt",
    profile: "gravel" as const,
  },
  baseTour: {
    id: "t1",
    name: "Odenwald",
    provider: "seed" as const,
    geometry: { type: "LineString" as const, coordinates: line },
    distanceKm: 42,
    durationMin: 140,
    elevationM: 780,
    loop: true,
    surface: "gravel",
  },
};
const farOnAdopt = applyPlanMapTap(adoptedDraft, [8.5, 49.2], {
  ...labels,
  line,
  tourPreviewOnMap: true,
});
assert.equal(
  viasOf(farOnAdopt).length,
  1,
  "adopted tour far-tap inserts a via instead of wiping"
);
assert.deepEqual(startOf(farOnAdopt), a);
assert.deepEqual(endOf(farOnAdopt), b);
const viaOnAdopt = insertViaAlong(adoptedDraft, c, { line, label: "Mitte" });
assert.equal(
  viaOnAdopt.computed?.engine,
  "tour-adopt",
  "adopted track stays until the engine returns"
);

const busyKeep = applyPlanMapTap(draftAB(), [8.5, 49.2], {
  ...labels,
  routingBusy: true,
});
assert.deepEqual(endOf(busyKeep), b, "busy routing keeps dest");
assert.equal(
  viasOf(busyKeep).length,
  1,
  "far tap still inserts via while routing"
);

const tickLineDense: [number, number][] = [];
for (let i = 0; i <= 40; i++) tickLineDense.push([8.67 + i * 0.012, 49.28]);
const ticksClose = planDistanceTicks({ line: tickLineDense, zoom: 16 });
const ticksFar = planDistanceTicks({ line: tickLineDense, zoom: 12 });
assert.ok(
  ticksClose.length > ticksFar.length,
  "km ticks denser when zoomed in"
);
const zoomHandles = planReshapeHandles({
  line: tickLineDense,
  vias: [],
  zoom: 16,
});
const overviewHandles = planReshapeHandles({
  line: tickLineDense,
  vias: [],
  zoom: 12,
});
assert.ok(
  zoomHandles.length >= overviewHandles.length,
  "more grab discs when zoomed in"
);
assert.ok(
  zoomHandles.length > 5,
  "zoomed-in grab discs follow the ribbon every few hundred metres"
);
assert.equal(planReshapeHandleStepM(16) < planReshapeHandleStepM(12), true);

assert.equal(planDragAlongLabelKm(1500), "1.5");
assert.equal(planShapeKmChip(1500), "1.5 km");
assert.equal(planRibbonDimOpacity(0.96, false), 0.96);
assert.ok(Math.abs(planRibbonDimOpacity(0.96, true) - 0.0432) < 1e-6);
assert.equal(planRibbonDimOpacity(0.22, true), 0.028);
assert.equal(planGrabHandleOpacity(0.95, false), 0.95);
assert.ok(Math.abs(planGrabHandleOpacity(0.95, true) - 0.266) < 1e-6);
assert.equal(planGrabHandleOpacity(0.1, true), 0.14);
assert.equal(
  planMapAdaptingHintOnMap({
    routingBusy: true,
    hasLiveLine: true,
    hasFinger: true,
  }),
  true
);
assert.equal(
  planMapAdaptingHintOnMap({
    routingBusy: true,
    hasLiveLine: true,
    hasFinger: false,
  }),
  false
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: true,
    routingBusy: true,
    hasStart: true,
    hasEnd: true,
    fingerHint: false,
  }),
  true
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: true,
    routingBusy: true,
    hasStart: true,
    hasEnd: true,
    fingerHint: true,
  }),
  false
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: false,
    routingBusy: true,
    hasStart: true,
    hasEnd: true,
    fingerHint: false,
  }),
  false
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: true,
    routingBusy: false,
    hasStart: false,
    hasEnd: true,
    fingerHint: false,
  }),
  true
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: true,
    routingBusy: false,
    hasStart: true,
    hasEnd: true,
    fingerHint: false,
    destConfirm: true,
    hasLiveLine: false,
  }),
  true
);
assert.equal(
  planMapDestWaitHintOnMap({
    editorActive: true,
    routingBusy: false,
    hasStart: true,
    hasEnd: true,
    fingerHint: false,
    destConfirm: true,
    hasLiveLine: true,
  }),
  false
);
assert.equal(
  planMapDestWaitCopy({ hasStart: false, hasLiveLine: false }),
  "waitingGps"
);
assert.equal(
  planMapDestWaitCopy({ hasStart: true, hasLiveLine: false }),
  "firstAb"
);
assert.equal(
  planMapDestWaitCopy({ hasStart: true, hasLiveLine: true }),
  "adapting"
);
assert.equal(planLineGrabYieldsToPinch(1), false);
assert.equal(planLineGrabYieldsToPinch(2), true);
assert.equal(
  planLineGrabBecomesExclusive({ pointerCount: 1, movePx: 8 }),
  true
);
assert.equal(
  planLineGrabBecomesExclusive({ pointerCount: 2, movePx: 20 }),
  false
);
assert.equal(planLineHoldCancelsOnMove({ movePx: 5 }), false);
assert.equal(planLineHoldCancelsOnMove({ movePx: 6 }), true);
assert.ok(PLAN_LINE_HOLD_CANCEL_PX < PLAN_LINE_GRAB_MOVE_PX);
assert.equal(PLAN_LINE_HOLD_MS, 450);
assert.equal(planLineCoachIsCompact(699), true);
assert.equal(planLineCoachIsXCompact(639), true);
assert.equal(
  planLineCoachCopy({
    adopting: true,
    compact: true,
    full: "full",
    short: "short",
    adopt: "adopt",
  }),
  "adopt"
);
assert.equal(
  planLineCoachCopy({
    adopting: false,
    compact: true,
    full: "full",
    short: "short",
    adopt: "adopt",
  }),
  "short"
);
assert.equal(planRibbonLegendCompact(419), true);
assert.equal(planRibbonLegendCompact(420), false);
assert.equal(planChevronIconOpacity({ dimmed: true, fresh: true }), 0);
assert.equal(
  planChevronIconOpacity({ dimmed: false, fresh: true }) >
    planChevronIconOpacity({ dimmed: false, fresh: false }),
  true
);
assert.deepEqual(
  planRibbonLegendKinds({
    bands: [{ surface: "asphalt" }, { surface: "fine_gravel" }],
    hasSteep: true,
  }),
  ["asphalt", "gravel", "steep"]
);
assert.deepEqual(
  planRibbonLegendKinds({
    bands: [
      { surface: "asphalt", fromKm: 0, toKm: 1 },
      { surface: null, fromKm: 1, toKm: 1.05 },
    ],
  }),
  ["asphalt"]
);
assert.deepEqual(
  planRibbonLegendKinds({
    bands: [
      { surface: "asphalt", fromKm: 0, toKm: 1 },
      { surface: null, fromKm: 1, toKm: 1.2 },
    ],
  }),
  ["asphalt", "unknown"]
);

console.log("planDraft.edit.test.ts OK");
