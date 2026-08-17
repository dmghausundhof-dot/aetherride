/**
 * npx tsx src/lib/catalog/editorialSets.test.ts
 */
import assert from "node:assert/strict";
import { listEditorialSets } from "./editorialSets";
import { getPublicTour } from "./publicTours";

const sets = listEditorialSets(3);
assert.ok(sets.length >= 1, "at least one region with ≥3 catalog tours");
for (const s of sets) {
  assert.ok(s.tourIds.length >= 3);
  assert.equal(s.count, s.tourIds.length);
  assert.ok(s.id.startsWith("set-"));
  for (const id of s.tourIds) {
    assert.ok(getPublicTour(id), `set ${s.id} lists unknown ${id}`);
  }
}

const rn = sets.find((s) => s.regionSlug === "rhein-neckar");
assert.ok(rn, "rhein-neckar is an editorial set");
assert.ok(rn!.name.includes("Rhein"));

console.log("editorialSets.test.ts OK");
