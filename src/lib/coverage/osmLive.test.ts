/**
 * Live S-Grade: echte OSM-Keys, keine City-Cycleways, kein sac_scale.
 * npx tsx src/lib/coverage/osmLive.test.ts
 */
import assert from "node:assert/strict";
import {
  isHonestOsmSGrade,
  normalizeMtbScale,
  osmSGradeOverpassParts,
} from "./osmLive";

function testHonestScale() {
  assert.equal(isHonestOsmSGrade("S0"), true);
  assert.equal(isHonestOsmSGrade("S1"), true);
  assert.equal(isHonestOsmSGrade("S2"), true);
  assert.equal(isHonestOsmSGrade("S3"), true);
  assert.equal(isHonestOsmSGrade("S3+"), true);
  assert.equal(isHonestOsmSGrade("offen"), false);
  assert.equal(isHonestOsmSGrade(""), false);
  assert.equal(isHonestOsmSGrade("T2"), false);
}

function testNormalizeKeepsTaggedGrades() {
  assert.equal(normalizeMtbScale("0"), "S0");
  assert.equal(normalizeMtbScale("2"), "S2");
  assert.equal(isHonestOsmSGrade(normalizeMtbScale("3")), true);
  assert.equal(isHonestOsmSGrade(normalizeMtbScale("s3+")), true);
  assert.equal(isHonestOsmSGrade(normalizeMtbScale("")), false);
}

function testOverpassPartsAreScaleOnly() {
  const q = osmSGradeOverpassParts("(47.0,7.0,47.4,7.4)").join("\n");
  assert.match(q, /\["mtb:scale"\]/);
  assert.match(q, /\["mtb:scale:imba"\]/);
  assert.equal(q.includes("mtb_scale"), false);
  assert.equal(q.includes("cycleway"), false);
  assert.equal(q.includes("sac_scale"), false);
  assert.equal(q.includes("living_street"), false);
}

testHonestScale();
testNormalizeKeepsTaggedGrades();
testOverpassPartsAreScaleOnly();
console.log("osmLive.test.ts: ok");
