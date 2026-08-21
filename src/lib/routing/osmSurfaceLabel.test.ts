/**
 * npx tsx src/lib/routing/osmSurfaceLabel.test.ts
 */
import assert from "node:assert/strict";
import { osmSurfaceGroup, osmSurfaceLabel } from "./osmSurfaceLabel";

assert.equal(osmSurfaceGroup("fine_gravel"), "gravel");
assert.equal(osmSurfaceGroup("asphalt"), "asphalt");
assert.equal(osmSurfaceGroup("dirt"), "trail");
assert.equal(osmSurfaceGroup("unknown_xyz"), null);

const labels = { asphalt: "Asphalt", gravel: "Schotter", trail: "Naturboden" };
assert.equal(osmSurfaceLabel("fine_gravel", labels), "Schotter");
assert.equal(osmSurfaceLabel("mystery_way", labels), "mystery way");

console.log("osmSurfaceLabel.test.ts OK");
