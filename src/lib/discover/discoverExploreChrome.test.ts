/**
 * Run: npx tsx src/lib/discover/discoverExploreChrome.test.ts
 */
import assert from "node:assert/strict";
import { DEFAULT_ROUTE_FILTERS } from "../routing/routeFilters";
import {
  DEFAULT_AROUND_KM,
  DEFAULT_FILTER_MINUTES,
  DISCOVER_LENS_FILTERS,
  aroundFilterActive,
  aroundKmDisplay,
  countActiveRouteFilters,
  matchesExploreQuery,
  resetDiscoverAround,
  resetDiscoverSheetFilters,
} from "./discoverExploreChrome";

assert.equal(DEFAULT_AROUND_KM, 35);
assert.equal(aroundKmDisplay(null), 35);
assert.equal(aroundKmDisplay(40), 40);

assert.equal(
  countActiveRouteFilters(DISCOVER_LENS_FILTERS, DEFAULT_FILTER_MINUTES),
  0,
  "60-Min-Rundkurs-Linse ist kein Badge",
);
assert.equal(
  countActiveRouteFilters(DEFAULT_ROUTE_FILTERS, 60),
  1,
  "Linse ohne Rundkurs zählt",
);
assert.equal(
  countActiveRouteFilters(
    { ...DEFAULT_ROUTE_FILTERS, sport: "gravel", maxDistanceKm: 40 },
    90,
  ),
  2,
  "Zeit + Sport — Umkreis zählt nicht am Filter-Badge",
);
assert.equal(
  countActiveRouteFilters(
    { ...DISCOVER_LENS_FILTERS, maxDistanceKm: 40 },
    DEFAULT_FILTER_MINUTES,
  ),
  0,
  "Nur Distanz: Filter-Badge bleibt leer",
);
assert.equal(aroundFilterActive(null), false);
assert.equal(aroundFilterActive(40), true);
assert.deepEqual(
  resetDiscoverSheetFilters({
    ...DEFAULT_ROUTE_FILTERS,
    sport: "gravel",
    maxDistanceKm: 40,
  }),
  { ...DISCOVER_LENS_FILTERS, maxDistanceKm: 40 },
  "Filter-Reset lässt Umkreis",
);
assert.deepEqual(
  resetDiscoverAround({ ...DISCOVER_LENS_FILTERS, maxDistanceKm: 40 }),
  DISCOVER_LENS_FILTERS,
  "Umkreis-Reset lässt Form und Sport",
);
assert.equal(
  countActiveRouteFilters(
    { ...DISCOVER_LENS_FILTERS, visibility: "private" },
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

console.log("discoverExploreChrome.test.ts OK");
