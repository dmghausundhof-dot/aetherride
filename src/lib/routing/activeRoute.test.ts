/**
 * Smoke-Tests: ActiveRoute / Navi-Cues / Track-Math.
 * Ausführen: npx tsx src/lib/routing/activeRoute.test.ts
 */
process.env.ALLOW_DEMO_CONTENT = "true";

import assert from "node:assert/strict";
import { buildDemoGeometry, centerOfGeometry } from "./demoGeometry";
import { buildNavCues, cueBannerText, nextCue } from "./navCues";
import {
  activeRouteFromSuggestion,
  activeRouteFromSaved,
  savedRouteForWebRideHandoff,
  activeRouteForWebRideBridge,
  webRideBridgeNeedsTrack,
} from "./activeRoute";
import type { RouteSuggestion } from "./suggestions";
import type { SavedRoute } from "@/types/route";
import { pointAlongLine, trackDistanceM } from "@/lib/geo/trackMath";

const sample: RouteSuggestion = {
  id: "r-kaltenbronn",
  name: "Kaltenbronn Runde",
  category: "mtb_am",
  distanceKm: 34,
  elevationM: 980,
  durationMin: 160,
  mtbScale: "S1–S2",
  surface: "trail/root",
  loop: true,
  uncertainKmPct: 10,
  matchScore: 88,
  reasons: ["a", "b", "c"],
};

const g = buildDemoGeometry("r-kaltenbronn", 34);
assert.equal(g.type, "LineString");
assert.ok(g.coordinates.length > 40);
const [lng, lat] = centerOfGeometry(g);
assert.ok(lng > 8);
assert.ok(lat > 48);

const cues = buildNavCues(g);
assert.ok(cues.length > 1, `expected turn cues, got ${cues.length}`);
assert.equal(cues[cues.length - 1].instruction, "Ziel erreicht");
const nxt = nextCue(cues, 0);
assert.ok(nxt);
assert.notEqual(nxt!.cue.instruction, "Ziel erreicht");
assert.match(cueBannerText(nxt!.cue, nxt!.remainingM), /In /);

const ar = activeRouteFromSuggestion(sample);
assert.equal(ar.geometry, null);
assert.equal(ar.source, "suggestion");

const arLive = activeRouteFromSuggestion(sample, g);
assert.ok((arLive.geometry?.coordinates.length ?? 0) > 10);
assert.equal(arLive.source, "engine");

const handoff = savedRouteForWebRideHandoff({
  id: sample.id,
  name: sample.name,
  distanceKm: sample.distanceKm,
  elevationM: sample.elevationM,
  durationMin: sample.durationMin,
  geometry: g,
  source: "suggestion",
});
assert.ok(handoff);
assert.equal(handoff!.id, sample.id);
assert.equal(activeRouteForWebRideBridge(handoff)?.id, sample.id);
assert.equal(
  savedRouteForWebRideHandoff({
    id: "engine-1",
    name: "x",
    distanceKm: 1,
    durationMin: 10,
    geometry: g,
  }),
  null,
  "ephemeral engine ids are not library handoffs"
);
assert.equal(
  savedRouteForWebRideHandoff({
    id: "ok",
    name: "x",
    distanceKm: 1,
    durationMin: 10,
    geometry: null,
  }),
  null
);
assert.equal(webRideBridgeNeedsTrack(2), true);
assert.equal(webRideBridgeNeedsTrack(1), false);
assert.equal(webRideBridgeNeedsTrack(null), false);

const layeredOnly: SavedRoute = {
  id: "mappe-layer",
  name: "Layer Tour",
  distanceKm: 2,
  elevationM: 0,
  durationMin: 20,
  savedAt: new Date().toISOString(),
  source: "planned",
  geometry: null,
  layers: {
    tour: {
      type: "LineString",
      coordinates: [
        [8.6, 49.4],
        [8.7, 49.5],
      ],
    },
  },
};
assert.equal(activeRouteFromSaved(layeredOnly)?.geometry?.coordinates.length, 2);
assert.equal(
  activeRouteFromSaved({ ...layeredOnly, layers: undefined }),
  null,
  "pin-only stays null"
);

const a = pointAlongLine(g, 0);
const b = pointAlongLine(g, 0.5);
assert.notEqual(a.lat, b.lat);
const dist = trackDistanceM([
  { lat: a.lat, lng: a.lng, time: 0 },
  { lat: b.lat, lng: b.lng, time: 1 },
]);
assert.ok(dist > 100);

console.log("activeRoute.test.ts: ok");
