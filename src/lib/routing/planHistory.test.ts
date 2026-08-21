/**
 * npx tsx src/lib/routing/planHistory.test.ts
 */
import assert from "node:assert/strict";
import { emptyDraft, setEnd, setStart } from "./planDraft";
import {
  emptyPlanHistory,
  planEditKey,
  pushPlanHistory,
  redoPlanHistory,
  undoPlanHistory,
} from "./planHistory";

const start = setStart(emptyDraft("gravel"), [8.67, 49.4], "A");
const ab = setEnd(start, [8.71, 49.41], "B");
assert.notEqual(planEditKey(start), planEditKey(ab), "dest change is an edit");

const flatter = { ...ab, variant: "flatter" as const };
assert.notEqual(
  planEditKey(ab),
  planEditKey(flatter),
  "variant change is an edit (flatter/unpaved undo)"
);

let h = emptyPlanHistory();
h = pushPlanHistory(h, start);
const undone = undoPlanHistory(h, ab);
assert.ok(undone, "undo has a snap");
assert.deepEqual(undone!.draft.waypoints, start.waypoints);
assert.equal(undone!.history.past.length, 0);
assert.equal(undone!.history.future.length, 1);

const redone = redoPlanHistory(undone!.history, undone!.draft);
assert.ok(redone, "redo restores dest");
assert.deepEqual(redone!.draft.waypoints, ab.waypoints);

h = emptyPlanHistory();
h = pushPlanHistory(h, ab);
const undoneVariant = undoPlanHistory(h, flatter);
assert.ok(undoneVariant, "variant undo has a snap");
assert.equal(undoneVariant!.draft.variant ?? "planned", "planned");
assert.equal(undoneVariant!.history.future.length, 1);
const redoneVariant = redoPlanHistory(
  undoneVariant!.history,
  undoneVariant!.draft
);
assert.equal(redoneVariant!.draft.variant, "flatter");

assert.equal(undoPlanHistory(emptyPlanHistory(), ab), null, "empty past");
assert.equal(redoPlanHistory(emptyPlanHistory(), ab), null, "empty future");

const startLine = {
  ...start,
  computed: {
    engine: "graphhopper",
    distanceM: 800,
    durationS: 180,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.67, 49.4],
        [8.68, 49.405],
      ],
    },
    profile: "gravel",
  },
};
const withLine = {
  ...ab,
  computed: {
    engine: "osrm",
    distanceM: 1200,
    durationS: 240,
    geometry: {
      type: "LineString",
      coordinates: [
        [8.67, 49.4],
        [8.71, 49.41],
      ],
    },
    profile: "gravel",
  },
};
const kept = undoPlanHistory(
  pushPlanHistory(emptyPlanHistory(), startLine),
  withLine
);
assert.equal(
  kept?.draft.computed?.engine,
  "graphhopper",
  "undo restores the previous ribbon immediately"
);

console.log("planHistory.test.ts OK");
