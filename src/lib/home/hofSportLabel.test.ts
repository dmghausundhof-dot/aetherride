/**
 * npx tsx src/lib/home/hofSportLabel.test.ts
 */
import assert from "node:assert/strict";
import { fallbackBikeName, hofSportLabel, resolvedBikeName } from "./hofSportLabel";

assert.equal(hofSportLabel("mtb_am"), "MTB");
assert.equal(hofSportLabel("mtb_am", true), "E-MTB");
assert.equal(hofSportLabel("etrekking"), "E-Trekking");
assert.equal(hofSportLabel("urban", true), "E-City");
assert.equal(hofSportLabel("cargo"), "Lastenrad");
assert.equal(hofSportLabel("folding", true), "E-Faltrad");
assert.equal(hofSportLabel("road"), "Rennrad");

assert.equal(fallbackBikeName("gravel"), "Gravel");
assert.equal(fallbackBikeName("urban"), "City");
assert.equal(fallbackBikeName("mtb_am"), "MTB");
assert.equal(fallbackBikeName("urban", true), "E-City");
assert.notEqual(fallbackBikeName("urban"), "Mein Bike");
assert.notEqual(fallbackBikeName("urban"), "Bike");

assert.equal(resolvedBikeName("", "gravel"), "Gravel");
assert.equal(resolvedBikeName("   ", "urban"), "City");
assert.equal(resolvedBikeName("Luna", "urban"), "Luna");
assert.equal(resolvedBikeName("Mein Bike", "urban"), "Mein Bike");

console.log("hofSportLabel.test.ts OK");
