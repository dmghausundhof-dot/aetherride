/**
 * Run: npx tsx src/lib/catalog/publicTourSuggestion.test.ts
 */
import assert from "node:assert/strict";
import { suggestionFromPublicTour } from "./publicTourSuggestion";

const hit = suggestionFromPublicTour("r-heidelberg-neckar-voll");
assert.ok(hit);
assert.equal(hit!.id, "r-heidelberg-neckar-voll");
assert.equal(hit!.loop, true);
assert.equal(hit!.category, "gravel");
assert.ok(hit!.center);
assert.equal(suggestionFromPublicTour("missing-tour"), null);
console.log("publicTourSuggestion.test.ts OK");
