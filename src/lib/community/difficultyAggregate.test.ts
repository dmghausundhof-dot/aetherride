/**
 * npx tsx src/lib/community/difficultyAggregate.test.ts
 */
import assert from "node:assert/strict";
import { aggregateDifficulty, parseDifficultyCrowd, parseDifficultyDelta } from "./difficultyAggregate";

assert.equal(parseDifficultyDelta(1), 1);
assert.equal(parseDifficultyDelta(-2), -2);
assert.equal(parseDifficultyDelta(9), null);
assert.equal(parseDifficultyDelta("x"), null);
assert.equal(parseDifficultyDelta(null), null);
assert.equal(parseDifficultyDelta(undefined), null);

const thin = aggregateDifficulty([1, 1, 0, -1]);
assert.equal(thin.shown, false);
assert.equal(thin.mean, null);
assert.equal(thin.n, 4);

const crowd = aggregateDifficulty([1, 1, 1, 1, 0, 1]);
assert.equal(crowd.shown, true);
assert.equal(crowd.n, 6);
assert.equal(crowd.label, "harder");

const same = aggregateDifficulty([0, 0, 0, 0, 0]);
assert.equal(same.label, "as_marked");

const easy = aggregateDifficulty([-1, -1, -1, -1, 0]);
assert.equal(easy.label, "easier");

const parsedHidden = parseDifficultyCrowd({
  n: 3,
  shown: true,
  label: "harder",
});
assert.equal(parsedHidden.shown, false);

const parsedLive = parseDifficultyCrowd({
  n: 6,
  mean: 0.8,
  shown: true,
  label: "harder",
});
assert.equal(parsedLive.shown, true);
assert.equal(parsedLive.label, "harder");

console.log("difficultyAggregate.test.ts OK");
