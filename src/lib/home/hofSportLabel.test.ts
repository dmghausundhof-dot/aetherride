/**
 * npx tsx src/lib/home/hofSportLabel.test.ts
 */
import assert from "node:assert/strict";
import { hofSportLabel } from "./hofSportLabel";

assert.equal(hofSportLabel("mtb_am"), "MTB");
assert.equal(hofSportLabel("mtb_am", true), "E-MTB");
assert.equal(hofSportLabel("etrekking"), "E-Trekking");
assert.equal(hofSportLabel("urban", true), "E-City");
assert.equal(hofSportLabel("cargo"), "Lastenrad");
assert.equal(hofSportLabel("folding", true), "E-Faltrad");
assert.equal(hofSportLabel("road"), "Rennrad");

console.log("hofSportLabel.test.ts OK");
