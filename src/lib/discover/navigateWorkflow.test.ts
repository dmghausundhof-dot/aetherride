/**
 * Run: npx tsx src/lib/discover/navigateWorkflow.test.ts
 */
import assert from "node:assert/strict";
import {
  beginNavigateIntent,
  discoverExploreMapTapOpensPlan,
  discoverTourDeepLinkOpensPlan,
  discoverTourDeepLinkStripTour,
  discoverMappeRouteOpensPlan,
  discoverMappeDeepLinkStripRoute,
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
assert.equal(
  discoverExploreMapTapOpensPlan({ sheetMode: "quick", picking: false }),
  true
);
assert.equal(
  discoverExploreMapTapOpensPlan({ sheetMode: "tours", picking: false }),
  true
);
assert.equal(
  discoverExploreMapTapOpensPlan({ sheetMode: "plan", picking: false }),
  false
);
assert.equal(
  discoverExploreMapTapOpensPlan({ sheetMode: "quick", picking: true }),
  false
);
assert.equal(
  discoverTourDeepLinkOpensPlan({ hasTourId: true }),
  true
);
assert.equal(
  discoverTourDeepLinkOpensPlan({ hasTourId: false }),
  false
);
assert.equal(
  discoverTourDeepLinkStripTour("/discover?panel=plan&tour=r-heidelberg-city"),
  "/discover?panel=plan"
);
assert.equal(
  discoverTourDeepLinkStripTour(
    "/discover?panel=plan&tour=idea-koenigstuhl&profile=gravel"
  ),
  "/discover?panel=plan&profile=gravel"
);
assert.equal(
  discoverTourDeepLinkStripTour("/discover?panel=plan"),
  "/discover?panel=plan"
);
assert.equal(
  discoverMappeRouteOpensPlan({ panelPlan: true, hasRouteId: true }),
  true
);
assert.equal(
  discoverMappeRouteOpensPlan({ panelPlan: false, hasRouteId: true }),
  false
);
assert.equal(
  discoverMappeDeepLinkStripRoute(
    "/discover?panel=plan&route=mappe-1&profile=gravel"
  ),
  "/discover?panel=plan&profile=gravel"
);

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
