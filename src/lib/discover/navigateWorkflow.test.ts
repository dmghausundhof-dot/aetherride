/**
 * Run: npx tsx src/lib/discover/navigateWorkflow.test.ts
 */
import assert from "node:assert/strict";
import {
  beginNavigateIntent,
  discoverRundkursActive,
  placeHitAppliesAsDestination,
  shouldForceLoopOnlyFromNearMe,
} from "./navigateWorkflow";

assert.equal(
  discoverRundkursActive({
    loopOnly: true,
    nearMeRouteMode: "loop",
    sheetMode: "plan",
  }),
  true
);
assert.equal(
  discoverRundkursActive({
    loopOnly: false,
    nearMeRouteMode: "loop",
    sheetMode: "plan",
  }),
  false,
  "NearMe-Rundkurs zwingt Navigieren nicht"
);
assert.equal(
  discoverRundkursActive({
    loopOnly: false,
    nearMeRouteMode: "loop",
    sheetMode: "quick",
  }),
  true
);
assert.equal(
  shouldForceLoopOnlyFromNearMe({
    nearMeRouteMode: "loop",
    sheetMode: "plan",
  }),
  false
);
assert.equal(
  shouldForceLoopOnlyFromNearMe({
    nearMeRouteMode: "loop",
    sheetMode: "quick",
  }),
  true
);

assert.equal(placeHitAppliesAsDestination("plan"), true);
assert.equal(placeHitAppliesAsDestination("quick"), false);

const frankfurt = {
  label: "Frankfurt (Main) Hauptbahnhof",
  lat: 50.107,
  lng: 8.664,
};
const intent = beginNavigateIntent({
  hasEnd: false,
  lastPlace: frankfurt,
});
assert.equal(intent.addrTarget, "end");
assert.equal(intent.pickTarget, "end");
assert.equal(intent.destination?.label, frankfurt.label);

const alreadyHasEnd = beginNavigateIntent({
  hasEnd: true,
  lastPlace: frankfurt,
});
assert.equal(alreadyHasEnd.destination, null);

const fromPending = beginNavigateIntent({
  hasEnd: false,
  lastPlace: null,
  pendingHits: [frankfurt],
});
assert.equal(fromPending.destination?.label, frankfurt.label);

console.log("navigateWorkflow.test.ts OK");
