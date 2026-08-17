/**
 * npx tsx src/lib/tours/routeVisibility.test.ts
 */
import assert from "node:assert/strict";
import type { SavedRoute } from "../../types/route";
import {
  allowsStimmen,
  filterSavedByVisibility,
  isShared,
  mayContributeRideTrack,
  mayContributeSavedGeometry,
  shareHonesty,
  shareableRouteIds,
  stimmenTourIdOf,
  visibilityOf,
  visibleInPublicExplore,
} from "./routeVisibility";

function route(partial: Partial<SavedRoute> & Pick<SavedRoute, "id">): SavedRoute {
  return {
    name: partial.name ?? "T",
    distanceKm: 10,
    elevationM: 100,
    durationMin: 40,
    savedAt: "2026-08-15T00:00:00.000Z",
    source: partial.source ?? "import",
    ...partial,
  };
}

assert.equal(visibilityOf({}), "private");
assert.equal(visibilityOf({ visibility: undefined }), "private");
assert.equal(visibilityOf({ visibility: "private" }), "private");
assert.equal(visibilityOf({ visibility: "shared" }), "shared");
assert.equal(isShared(route({ id: "gpx-1" })), false);

const priv = route({ id: "gpx-1", source: "import" });
const shared = route({ id: "gpx-2", source: "import", visibility: "shared" });
const catalog = route({
  id: "r-bodensee-road",
  source: "suggestion",
  catalogTourId: "r-bodensee-road",
});

assert.equal(visibleInPublicExplore(priv), false);
assert.equal(visibleInPublicExplore(shared), true);
assert.equal(mayContributeSavedGeometry(priv), false);
assert.equal(mayContributeSavedGeometry(shared), true);
assert.equal(mayContributeRideTrack(undefined), true);
assert.equal(mayContributeRideTrack(priv), false);
assert.equal(mayContributeRideTrack(shared), true);
assert.equal(mayContributeRideTrack(catalog), true);

assert.equal(allowsStimmen(priv), false);
assert.equal(stimmenTourIdOf(priv), null);
assert.equal(allowsStimmen(shared), true);
assert.equal(stimmenTourIdOf(shared), "gpx-2");
assert.equal(allowsStimmen(catalog), true);
assert.equal(stimmenTourIdOf(catalog), "r-bodensee-road");

const recorded = route({ id: "recorded-abc", source: "import" });
assert.equal(allowsStimmen(recorded), false);
assert.equal(stimmenTourIdOf(recorded), null);

const list = [priv, shared, catalog];
assert.equal(filterSavedByVisibility(list, "all_mine").length, 3);
assert.deepEqual(
  filterSavedByVisibility(list, "private").map((r) => r.id),
  ["gpx-1", "r-bodensee-road"]
);
assert.deepEqual(
  filterSavedByVisibility(list, "shared").map((r) => r.id),
  ["gpx-2"]
);

assert.deepEqual(
  shareableRouteIds(["gpx-1", "gpx-2", "r-bodensee-road"], list),
  ["gpx-2", "r-bodensee-road"]
);

const honesty = shareHonesty(
  route({
    id: "gpx-track",
    visibility: "shared",
    geometry: { type: "LineString", coordinates: [[8.6, 49.4], [8.7, 49.5]] },
  })
);
assert.match(honesty, /Server/);
assert.match(honesty, /eingeloggt/);

console.log("routeVisibility.test.ts OK");
