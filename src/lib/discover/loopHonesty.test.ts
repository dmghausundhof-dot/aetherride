/**
 * Loop honesty flags — align #37.
 * Run: npx tsx src/lib/discover/loopHonesty.test.ts
 */
import { isHonestLoopSuggestion, seedIsLoopFlag } from "./loopHonesty";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(seedIsLoopFlag({ is_loop: true }) === true, "is_loop true");
assert(seedIsLoopFlag({ is_loop: false }) === false, "is_loop false");
assert(seedIsLoopFlag({}) === false, "missing is_loop is not a loop");
assert(seedIsLoopFlag({ loop: true }) === true, "legacy loop true");
assert(seedIsLoopFlag({ closed: true }) === true, "closed true");
assert(isHonestLoopSuggestion({ loop: true }) === true, "suggestion loop");
assert(isHonestLoopSuggestion({ loop: false }) === false, "suggestion linear");

console.log("loopHonesty.test.ts OK");
