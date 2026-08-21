/**
 * Run: npx tsx src/lib/discover/discoverExploreChrome.test.ts
 */
import assert from "node:assert/strict";
import { DEFAULT_ROUTE_FILTERS } from "../routing/routeFilters";
import {
  DEFAULT_AROUND_KM,
  DEFAULT_FILTER_MINUTES,
  aroundFilterActive,
  aroundKmDisplay,
  countActiveRouteFilters,
  matchesExploreQuery,
  resetDiscoverAround,
  resetDiscoverSheetFilters,
  shouldFlyExploreToPlace,
  shouldOfferExplorePlaceHits,
} from "./discoverExploreChrome";

assert.equal(DEFAULT_AROUND_KM, 35);
assert.equal(aroundKmDisplay(null), 35);
assert.equal(aroundKmDisplay(40), 40);

assert.equal(
  countActiveRouteFilters(DEFAULT_ROUTE_FILTERS, DEFAULT_FILTER_MINUTES),
  0,
  "Discover-Default ist kein Badge",
);
assert.equal(
  countActiveRouteFilters({ ...DEFAULT_ROUTE_FILTERS, loopOnly: true }, 60),
  1,
  "Rundkurs zählt",
);
assert.equal(
  countActiveRouteFilters(
    { ...DEFAULT_ROUTE_FILTERS, sport: "gravel", maxAwayKm: 40 },
    90,
  ),
  2,
  "Zeit + Sport — Umkreis zählt nicht am Filter-Badge",
);
assert.equal(
  countActiveRouteFilters(
    { ...DEFAULT_ROUTE_FILTERS, maxAwayKm: 40 },
    DEFAULT_FILTER_MINUTES,
  ),
  0,
  "Nur Umkreis: Filter-Badge bleibt leer",
);
assert.equal(
  countActiveRouteFilters(
    { ...DEFAULT_ROUTE_FILTERS, maxDistanceKm: 40 },
    DEFAULT_FILTER_MINUTES,
  ),
  1,
  "Tourlänge sitzt im Filter-Badge",
);
assert.equal(aroundFilterActive(null), false);
assert.equal(aroundFilterActive(40), true);
assert.deepEqual(
  resetDiscoverSheetFilters({
    ...DEFAULT_ROUTE_FILTERS,
    sport: "gravel",
    maxAwayKm: 40,
  }),
  { ...DEFAULT_ROUTE_FILTERS, maxAwayKm: 40 },
  "Filter-Reset lässt Umkreis",
);
assert.deepEqual(
  resetDiscoverAround({ ...DEFAULT_ROUTE_FILTERS, loopOnly: true, maxAwayKm: 40 }),
  { ...DEFAULT_ROUTE_FILTERS, loopOnly: true, maxAwayKm: null },
  "Umkreis-Reset lässt Form und Sport",
);
assert.equal(
  countActiveRouteFilters(
    { ...DEFAULT_ROUTE_FILTERS, visibility: "private" },
    60,
  ),
  1,
);

assert.equal(
  matchesExploreQuery({ name: "Heidelberg City Loop", category: "road" }, ""),
  true,
);
assert.equal(
  matchesExploreQuery(
    { name: "Heidelberg City Loop", category: "road" },
    "heidelberg",
  ),
  true,
);
assert.equal(
  matchesExploreQuery(
    { name: "Tempelhofer", category: "urban", reasons: ["City"] },
    "gravel",
  ),
  false,
);

assert.equal(shouldOfferExplorePlaceHits("Be"), false);
assert.equal(shouldOfferExplorePlaceHits("Ber"), true);
assert.equal(
  shouldFlyExploreToPlace("Heidelberg City Loop", ["Heidelberg City Loop"]),
  false,
);
assert.equal(shouldFlyExploreToPlace("Walldorf", ["Heidelberg City Loop"]), true);

console.log("discoverExploreChrome.test.ts OK");
